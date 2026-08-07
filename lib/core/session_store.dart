import 'dart:convert';
import 'dart:math' as math;
import 'package:sqlite3/sqlite3.dart' hide Session;
import '../models/session.dart';
import '../models/task_record.dart';

/// 基于 package:sqlite3（支持 SQLCipher 加密）的会话存储。
/// 公开 API 与 sqflite 版本保持一致，仅底层驱动不同。
class SessionStore {
  final Database _db;
  SessionStore(this._db);

  static void onCreate(Database db, int version) {
    db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        software_name TEXT NOT NULL,
        context_json TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE task_records (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        task TEXT NOT NULL,
        script TEXT,
        script_language TEXT,
        model_used TEXT,
        status TEXT NOT NULL,
        error TEXT,
        artifacts_json TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');
    db.execute('CREATE INDEX idx_task_session ON task_records(session_id)');
    db.execute('CREATE INDEX idx_sessions_software ON sessions(software_name)');
  }

  static void onUpgrade(Database db, int oldVersion, int newVersion) {
    // Future migrations go here. Example:
    // if (oldVersion < 2) { db.execute('ALTER TABLE sessions ADD COLUMN ...'); }
  }

  Future<T> _txn<T>(Future<T> Function() action) async {
    _db.execute('BEGIN');
    try {
      final result = await action();
      _db.execute('COMMIT');
      return result;
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> save(Session session) async {
    // 会话与记录同事务写入，避免中途失败留下孤儿 session 行。
    await _txn(() async {
      _db.execute(
        'INSERT OR REPLACE INTO sessions '
        '(id, domain, software_name, context_json, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          session.id,
          session.domain.name,
          session.softwareName,
          jsonEncode({
            'softwareState': session.context.softwareState,
            'userPreferences': session.context.userPreferences,
            'recentActions': session.context.recentActions,
          }),
          session.createdAt.toIso8601String(),
        ],
      );

      final rows =
          _db.select('SELECT id FROM task_records WHERE session_id = ?', [session.id]);
      final existingIds = rows.map((r) => r['id'] as String).toSet();

      final newRecords =
          session.history.where((r) => !existingIds.contains(r.id)).toList();
      if (newRecords.isEmpty) return;

      for (final record in newRecords) {
        _db.execute(
          'INSERT OR REPLACE INTO task_records '
          '(id, session_id, task, script, script_language, model_used, status, '
          'error, artifacts_json, created_at, completed_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            record.id,
            session.id,
            record.task,
            record.script,
            record.scriptLanguage,
            record.modelUsed,
            record.status.name,
            record.error,
            jsonEncode(record.artifacts),
            record.createdAt.toIso8601String(),
            record.completedAt?.toIso8601String(),
          ],
        );
      }
    });
  }

  Future<Session?> load(String sessionId) async {
    final rows = _db.select('SELECT * FROM sessions WHERE id = ?', [sessionId]);
    if (rows.isEmpty) return null;

    final row = rows.first;
    final records = _db.select(
      'SELECT * FROM task_records WHERE session_id = ? ORDER BY created_at ASC',
      [sessionId],
    );

    return Session(
      id: row['id'] as String,
      domain: DesignCategory.values.firstWhere((d) => d.name == row['domain'], orElse: () => DesignCategory.web),
      softwareName: row['software_name'] as String,
      createdAt: _parseDate(row['created_at'] as String?),
      context: _parseContext(row['context_json'] as String?),
      history: records.map(_deserializeRecord).whereType<TaskRecord>().toList(),
    );
  }

  Future<List<Session>> listRecent({int limit = 50}) async {
    final rows = _db.select('SELECT * FROM sessions ORDER BY created_at DESC LIMIT ?', [limit]);
    return _loadSessionRowsWithHistory(rows);
  }

  Future<List<Session>> listBySoftware(String softwareName) async {
    final rows = _db.select(
      'SELECT * FROM sessions WHERE software_name = ? ORDER BY created_at DESC',
      [softwareName],
    );
    return _loadSessionRowsWithHistory(rows);
  }

  Future<List<Session>> search(String query) async {
    final rows = _db.select(
      "SELECT DISTINCT s.* FROM sessions s "
      "INNER JOIN task_records t ON t.session_id = s.id "
      "WHERE t.task LIKE ? ESCAPE '\\' ORDER BY s.created_at DESC",
      ['%${_escapeLike(query)}%'],
    );
    return _loadSessionRowsWithHistory(rows);
  }

  Future<List<Session>> _loadSessionRowsWithHistory(List<Row> rows) async {
    if (rows.isEmpty) return [];

    final sessionIds = rows.map((r) => r['id'] as String).toList();
    // 分批查询，避开 SQLite 单条 IN 列表 999 个变量的上限。
    final allRecords = <Row>[];
    for (var i = 0; i < sessionIds.length; i += 500) {
      final chunk = sessionIds.sublist(i, math.min(i + 500, sessionIds.length));
      final placeholders = List.filled(chunk.length, '?').join(',');
      allRecords.addAll(_db.select(
        'SELECT * FROM task_records WHERE session_id IN ($placeholders) ORDER BY created_at ASC',
        chunk,
      ));
    }

    final recordsBySession = <String, List<TaskRecord>>{};
    for (final rec in allRecords) {
      final sid = rec['session_id'] as String;
      final record = _deserializeRecord(rec);
      if (record != null) {
        recordsBySession.putIfAbsent(sid, () => []).add(record);
      }
    }

    final sessions = <Session>[];
    for (final r in rows) {
      final sid = r['id'] as String;
      sessions.add(Session(
        id: sid,
        domain: DesignCategory.values.firstWhere((d) => d.name == r['domain'], orElse: () => DesignCategory.web),
        softwareName: r['software_name'] as String,
        createdAt: _parseDate(r['created_at'] as String?),
        context: _parseContext(r['context_json'] as String?),
        history: recordsBySession[sid] ?? [],
      ));
    }
    return sessions;
  }

  DateTime _parseDate(String? iso) {
    try {
      return DateTime.parse(iso!);
    } catch (_) {
      // 脏日期降级为当前时间，不炸整个加载。
      return DateTime.now();
    }
  }

  SessionContext _parseContext(String? json) {
    if (json == null) return SessionContext();
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return SessionContext(
        softwareState: Map<String, dynamic>.from(data['softwareState'] ?? {}),
        userPreferences: Map<String, dynamic>.from(data['userPreferences'] ?? {}),
        recentActions: List<String>.from(data['recentActions'] ?? []),
      );
    } catch (_) {
      return SessionContext();
    }
  }

  Future<void> delete(String sessionId) async {
    await _txn(() async {
      _db.execute('DELETE FROM task_records WHERE session_id = ?', [sessionId]);
      _db.execute('DELETE FROM sessions WHERE id = ?', [sessionId]);
    });
  }

  /// 单事务内批量删除，失败则全部回滚。
  Future<void> deleteMany(List<String> sessionIds) async {
    if (sessionIds.isEmpty) return;
    await _txn(() async {
      for (final id in sessionIds) {
        _db.execute('DELETE FROM task_records WHERE session_id = ?', [id]);
        _db.execute('DELETE FROM sessions WHERE id = ?', [id]);
      }
    });
  }

  String _escapeLike(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
  }

  TaskRecord? _deserializeRecord(Row row) {
    try {
      return TaskRecord(
        id: row['id'] as String,
        sessionId: row['session_id'] as String,
        task: row['task'] as String,
        script: row['script'] as String?,
        scriptLanguage: row['script_language'] as String?,
        modelUsed: row['model_used'] as String?,
        status: TaskStatus.values.firstWhere((s) => s.name == row['status'], orElse: () => TaskStatus.failed),
        error: row['error'] as String?,
        artifacts: List<String>.from(jsonDecode(row['artifacts_json'] as String? ?? '[]')),
        createdAt: DateTime.parse(row['created_at'] as String),
        completedAt: row['completed_at'] != null ? DateTime.parse(row['completed_at'] as String) : null,
      );
    } catch (_) {
      // 单条脏数据（坏 JSON/坏日期）降级跳过，不炸整个会话加载。
      return null;
    }
  }
}
