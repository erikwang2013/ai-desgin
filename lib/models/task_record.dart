import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TaskStatus { pending, running, completed, failed, cancelled }

class TaskRecord {
  final String id;
  final String sessionId;
  final String task;
  final String? script;
  final String? scriptLanguage;
  final String? modelUsed;
  final TaskStatus status;
  final String? error;
  final List<String> artifacts;
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskRecord({
    String? id,
    required this.sessionId,
    required this.task,
    this.script,
    this.scriptLanguage,
    this.modelUsed,
    this.status = TaskStatus.pending,
    this.error,
    this.artifacts = const [],
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();
}
