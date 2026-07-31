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

    for (final record in session.history) {
      if (existingIds.contains(record.id)) continue;
      await _db.insert('task_records', {
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
    return _deserializeSessionRows(rows);
  }

  Future<List<Session>> search(String query) async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT s.* FROM sessions s
      INNER JOIN task_records t ON t.session_id = s.id
      WHERE t.task LIKE ? ESCAPE '\\' ORDER BY s.created_at DESC
    ''', ['%${_escapeLike(query)}%']);
    return _deserializeSessionRows(rows);
  }

  List<Session> _deserializeSessionRows(List<Map<String, dynamic>> rows) {
    return rows.map((r) => Session(
      id: r['id'] as String,
      domain: DesignCategory.values.firstWhere((d) => d.name == r['domain']),
      softwareName: r['software_name'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
      context: _parseContext(r['context_json'] as String?),
    )).toList();
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
