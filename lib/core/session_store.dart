import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/session.dart';
import '../models/task_record.dart';

class SessionStore {
  final Database _db;
  SessionStore(this._db);

  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        software_name TEXT NOT NULL,
        context_json TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
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
    await db.execute('CREATE INDEX idx_task_session ON task_records(session_id)');
    await db.execute('CREATE INDEX idx_sessions_software ON sessions(software_name)');
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here. Example:
    // if (oldVersion < 2) { await db.execute('ALTER TABLE sessions ADD COLUMN ...'); }
  }

  Future<void> save(Session session) async {
    await _db.insert('sessions', {
      'id': session.id,
      'domain': session.domain.name,
      'software_name': session.softwareName,
      'context_json': jsonEncode({
        'softwareState': session.context.softwareState,
        'userPreferences': session.context.userPreferences,
        'recentActions': session.context.recentActions,
      }),
      'created_at': session.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final existingRows = await _db.query('task_records',
        columns: ['id'], where: 'session_id = ?', whereArgs: [session.id]);
    final existingIds = existingRows.map((r) => r['id'] as String).toSet();

    final newRecords = session.history.where((r) => !existingIds.contains(r.id)).toList();
    if (newRecords.isEmpty) return;

    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (final record in newRecords) {
        batch.insert('task_records', {
          'id': record.id,
          'session_id': session.id,
          'task': record.task,
          'script': record.script,
          'script_language': record.scriptLanguage,
          'model_used': record.modelUsed,
          'status': record.status.name,
          'error': record.error,
          'artifacts_json': jsonEncode(record.artifacts),
          'created_at': record.createdAt.toIso8601String(),
          'completed_at': record.completedAt?.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Session?> load(String sessionId) async {
    final rows = await _db.query('sessions', where: 'id = ?', whereArgs: [sessionId]);
    if (rows.isEmpty) return null;

    final row = rows.first;
    final contextData = jsonDecode(row['context_json'] as String? ?? '{}');

    final records = await _db.query(
      'task_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );

    return Session(
      id: row['id'] as String,
      domain: DesignCategory.values.firstWhere((d) => d.name == row['domain'], orElse: () => DesignCategory.web),
      softwareName: row['software_name'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      context: SessionContext(
        softwareState: Map<String, dynamic>.from(contextData['softwareState'] ?? {}),
        userPreferences: Map<String, dynamic>.from(contextData['userPreferences'] ?? {}),
        recentActions: List<String>.from(contextData['recentActions'] ?? []),
      ),
      history: records.map(_deserializeRecord).toList(),
    );
  }

  Future<List<Session>> listBySoftware(String softwareName) async {
    final rows = await _db.query(
      'sessions',
      where: 'software_name = ?',
      whereArgs: [softwareName],
      orderBy: 'created_at DESC',
    );
    return _loadSessionRowsWithHistory(rows);
  }

  Future<List<Session>> search(String query) async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT s.* FROM sessions s
      INNER JOIN task_records t ON t.session_id = s.id
      WHERE t.task LIKE ? ESCAPE '\\' ORDER BY s.created_at DESC
    ''', ['%${_escapeLike(query)}%']);
    return _loadSessionRowsWithHistory(rows);
  }

  Future<List<Session>> _loadSessionRowsWithHistory(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return [];

    final sessionIds = rows.map((r) => r['id'] as String).toList();
    final placeholders = List.filled(sessionIds.length, '?').join(',');
    final allRecords = await _db.rawQuery(
      'SELECT * FROM task_records WHERE session_id IN ($placeholders) ORDER BY created_at ASC',
      sessionIds,
    );

    final recordsBySession = <String, List<TaskRecord>>{};
    for (final rec in allRecords) {
      final sid = rec['session_id'] as String;
      recordsBySession.putIfAbsent(sid, () => []).add(_deserializeRecord(rec));
    }

    final sessions = <Session>[];
    for (final r in rows) {
      final sid = r['id'] as String;
      sessions.add(Session(
        id: sid,
        domain: DesignCategory.values.firstWhere((d) => d.name == r['domain'], orElse: () => DesignCategory.web),
        softwareName: r['software_name'] as String,
        createdAt: DateTime.parse(r['created_at'] as String),
        context: _parseContext(r['context_json'] as String?),
        history: recordsBySession[sid] ?? [],
      ));
    }
    return sessions;
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
    await _db.delete('task_records', where: 'session_id = ?', whereArgs: [sessionId]);
    await _db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  String _escapeLike(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
  }

  TaskRecord _deserializeRecord(Map<String, dynamic> row) {
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
  }
}
