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

  /// 写事务串行门闩：并发 save/delete 会 BEGIN-in-BEGIN 报错。
  /// 空闲时事务在调用方栈内同步执行（保持旧版语义，兼容 testWidgets 的
  /// FakeAsync）；忙时把后续写链到队列延后执行，同一时刻只有一个事务。
  bool _writeBusy = false;
  Future<void> _writeQueue = Future<void>.value();

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

  Future<T> _txn<T>(Future<T> Function() action) {
    if (_writeBusy) {
      // 忙：链到队列末尾，等前一个事务结束再跑（生产环境真实并发场景）。
      final deferred = _writeQueue.then((_) => _txn(action));
      _writeQueue = deferred.then((_) {}, onError: (_) {});
      return deferred;
    }
    _writeBusy = true;
    try {
      _db.execute('BEGIN');
      final result = action();
      // action 为纯同步 SQL 的闭包，future 已同步完成；成功/失败分支延后到
      // 微任务提交或回滚，等价旧版 `await action()` 后的行为。
      return result.then((r) {
        _writeBusy = false;
        _db.execute('COMMIT');
        return r;
      }, onError: (Object e, StackTrace st) {
        _writeBusy = false;
        _db.execute('ROLLBACK');
        throw e;
      });
    } catch (_) {
      // BEGIN 或 action 同步抛出：立即回滚。
      _writeBusy = false;
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

  /// 列表路径投影：只取展示列，跳过 script/error/context_json 大字段，
  /// 详情/导出按需走 [load]/[loadTaskRecord]/[listRecentFull]。
  Future<List<Session>> listRecent({int limit = 50}) async {
    final rows = _db.select(
      'SELECT id, domain, software_name, created_at FROM sessions '
      'ORDER BY created_at DESC LIMIT ?',
      [limit],
    );
    return _loadSessionRowsProjected(rows);
  }

  /// 全量列表（含 script/error/context），仅历史导出等低频场景使用。
  Future<List<Session>> listRecentFull({int limit = 50}) async {
    final rows = _db.select('SELECT * FROM sessions ORDER BY created_at DESC LIMIT ?', [limit]);
    return _loadSessionRowsWithHistory(rows);
  }

  /// 按记录 id 取全量记录（含 script/error），详情对话框懒加载用。
  Future<TaskRecord?> loadTaskRecord(String recordId) async {
    final rows = _db.select('SELECT * FROM task_records WHERE id = ?', [recordId]);
    if (rows.isEmpty) return null;
    return _deserializeRecord(rows.first);
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
    final recordsBySession = await _fetchRecordsBySession(
      rows.map((r) => r['id'] as String).toList(),
      projected: false,
    );
    return _buildSessions(rows, recordsBySession);
  }

  /// 列表投影加载：记录只取展示列（无 script/error），会话不含 context_json。
  Future<List<Session>> _loadSessionRowsProjected(List<Row> rows) async {
    if (rows.isEmpty) return [];
    final recordsBySession = await _fetchRecordsBySession(
      rows.map((r) => r['id'] as String).toList(),
      projected: true,
    );
    return _buildSessions(rows, recordsBySession);
  }

  /// 按 session id 批量取记录；projected 时跳过 script/error 大字段。
  Future<Map<String, List<TaskRecord>>> _fetchRecordsBySession(
    List<String> sessionIds, {
    required bool projected,
  }) async {
    // 分批查询，避开 SQLite 单条 IN 列表 999 个变量的上限。
    final columns = projected
        ? 'id, session_id, task, script_language, model_used, status, '
            'artifacts_json, created_at, completed_at'
        : '*';
    final recordsBySession = <String, List<TaskRecord>>{};
    for (var i = 0; i < sessionIds.length; i += 500) {
      final chunk = sessionIds.sublist(i, math.min(i + 500, sessionIds.length));
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = _db.select(
        'SELECT $columns FROM task_records WHERE session_id IN ($placeholders) '
        'ORDER BY created_at ASC',
        chunk,
      );
      for (final rec in rows) {
        final sid = rec['session_id'] as String;
        final record = _deserializeRecord(rec, projected: projected);
        if (record != null) {
          recordsBySession.putIfAbsent(sid, () => []).add(record);
        }
      }
    }
    return recordsBySession;
  }

  List<Session> _buildSessions(
    List<Row> rows,
    Map<String, List<TaskRecord>> recordsBySession,
  ) {
    return [
      for (final r in rows)
        Session(
          id: r['id'] as String,
          domain: DesignCategory.values.firstWhere(
            (d) => d.name == r['domain'],
            orElse: () => DesignCategory.web,
          ),
          softwareName: r['software_name'] as String,
          createdAt: _parseDate(r['created_at'] as String?),
          // 投影查询未取 context_json 时为 null，降级为空上下文。
          context: _parseContext(r['context_json'] as String?),
          history: recordsBySession[r['id'] as String] ?? [],
        ),
    ];
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

  TaskRecord? _deserializeRecord(Row row, {bool projected = false}) {
    try {
      return TaskRecord(
        id: row['id'] as String,
        sessionId: row['session_id'] as String,
        task: row['task'] as String,
        script: projected ? null : row['script'] as String?,
        scriptLanguage: row['script_language'] as String?,
        modelUsed: row['model_used'] as String?,
        status: TaskStatus.values.firstWhere((s) => s.name == row['status'], orElse: () => TaskStatus.failed),
        error: projected ? null : row['error'] as String?,
        artifacts: List<String>.from(jsonDecode(row['artifacts_json'] as String? ?? '[]')),
        createdAt: DateTime.parse(row['created_at'] as String),
        completedAt: row['completed_at'] != null ? DateTime.parse(row['completed_at'] as String) : null,
      );
    } catch (_) {
      // 单条脏数据（坏 JSON/坏日期）降级跳过，不炸整个会话加载。
      return null;
    }
  }

  /// 将全部会话（含消息记录）序列化为 JSON 文本，供历史导出使用。
  /// 纯函数不访问数据库，便于单元测试。
  static String exportSessionsToJson(List<Session> sessions) => jsonEncode({
        'app': 'ai-design',
        'exportedAt': DateTime.now().toIso8601String(),
        'sessions': [
          for (final s in sessions)
            {
              'id': s.id,
              'domain': s.domain.name,
              'softwareName': s.softwareName,
              'createdAt': s.createdAt.toIso8601String(),
              'context': {
                'softwareState': s.context.softwareState,
                'userPreferences': s.context.userPreferences,
                'recentActions': s.context.recentActions,
              },
              'records': [
                for (final r in s.history)
                  {
                    'id': r.id,
                    'sessionId': r.sessionId,
                    'task': r.task,
                    'script': r.script,
                    'scriptLanguage': r.scriptLanguage,
                    'modelUsed': r.modelUsed,
                    'status': r.status.name,
                    'error': r.error,
                    'artifacts': r.artifacts,
                    'iterations': r.iterations,
                    'maxIterations': r.maxIterations,
                    'iterationLog': r.iterationLog,
                    'createdAt': r.createdAt.toIso8601String(),
                    'completedAt': r.completedAt?.toIso8601String(),
                  },
              ],
            },
        ],
      });
}
