import 'package:uuid/uuid.dart';
import 'task_record.dart';

const _uuid = Uuid();

enum DesignCategory { web, ad, industrial, threeD, arch, interior }

class SessionContext {
  final Map<String, dynamic> softwareState;
  final Map<String, dynamic> userPreferences;
  final List<String> recentActions;

  SessionContext({
    this.softwareState = const {},
    this.userPreferences = const {},
    this.recentActions = const [],
  });
}

class Session {
  final String id;
  final DesignCategory domain;
  final String softwareName;
  final SessionContext context;
  final DateTime createdAt;
  final List<TaskRecord> history;

  Session({
    String? id,
    required this.domain,
    required this.softwareName,
    SessionContext? context,
    DateTime? createdAt,
    List<TaskRecord>? history,
  })  : id = id ?? _uuid.v4(),
        context = context ?? SessionContext(),
        createdAt = createdAt ?? DateTime.now(),
        history = history ?? [];

  TaskRecord addRecord({
    required String task,
    required String script,
    required String scriptLanguage,
    required String modelUsed,
    TaskStatus status = TaskStatus.completed,
  }) {
    final record = TaskRecord(
      sessionId: id,
      task: task,
      script: script,
      scriptLanguage: scriptLanguage,
      modelUsed: modelUsed,
      status: status,
    );
    history.add(record);
    return record;
  }
}
