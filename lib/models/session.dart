import 'package:uuid/uuid.dart';
import 'task_record.dart';

const _uuid = Uuid();

enum DesignCategory { web, ad, industrial, threeD, arch, interior }

extension DesignCategoryLabel on DesignCategory {
  String get label => switch (this) {
    DesignCategory.web => 'Web 设计',
    DesignCategory.ad => '广告设计',
    DesignCategory.industrial => '工业设计',
    DesignCategory.threeD => '3D 设计',
    DesignCategory.arch => '建筑设计',
    DesignCategory.interior => '装修设计',
  };
}

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
  /// 历史上限：超出时截断最旧记录，防止无限增长。
  static const int maxHistory = 500;

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
    if (history.length > maxHistory) {
      history.removeRange(0, history.length - maxHistory);
    }
    return record;
  }
}
