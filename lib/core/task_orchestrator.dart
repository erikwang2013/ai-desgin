import 'plugin_manager.dart';
import 'cc_process_manager.dart';
import 'cc_runner.dart';
import 'model_router.dart';
import '../models/session.dart';
import '../models/task_record.dart';

class TaskOrchestrator {
  final PluginManager _pluginManager;
  final CCProcessManager _ccManager;
  final ModelRouter _modelRouter;
  final int maxConcurrent;

  final Map<String, Session> _sessions = {};
  final Map<String, TaskRecord> _tasks = {};
  int _activeCount = 0;

  TaskOrchestrator({
    required PluginManager pluginManager,
    required CCProcessManager ccManager,
    required ModelRouter modelRouter,
    this.maxConcurrent = 3,
  })  : _pluginManager = pluginManager,
        _ccManager = ccManager,
        _modelRouter = modelRouter;

  Future<TaskRecord> submitTask({
    required DesignCategory domain,
    required String softwareName,
    required String task,
    String? overrideModel,
  }) async {
    final plugin = _pluginManager.get(softwareName);
    if (plugin == null) {
      final record = TaskRecord(sessionId: '', task: task, status: TaskStatus.failed, error: 'Software not found: $softwareName');
      _tasks[record.id] = record;
      return record;
    }

    if (_activeCount >= maxConcurrent) {
      final record = TaskRecord(sessionId: softwareName, task: task, status: TaskStatus.failed, error: 'Too many concurrent tasks (max $maxConcurrent)');
      _tasks[record.id] = record;
      return record;
    }
    _activeCount++;

    final session = _getOrCreateSession(domain, softwareName);
    final record = TaskRecord(sessionId: session.id, task: task, status: TaskStatus.running);
    _tasks[record.id] = record;

    try {
      final model = _modelRouter.route(domain: domain, task: task, overrideModel: overrideModel);
      final state = await plugin.getCurrentState();
      final ccSession = _ccManager.createSession(software: softwareName, capabilities: plugin.capabilities, state: state);

      String generatedScript = task;
      final runner = CCRunner();
      if (await runner.isAvailable()) {
        try {
          final generated = await _ccManager.executeWithClaude(
            sessionId: ccSession.id, task: task, model: model,
          );
          generatedScript = (generated['script'] as String?) ?? task;
        } catch (_) {
          // Fall back to raw task text if Claude CLI fails
        }
      }

      final result = await plugin.execute(generatedScript);
      _ccManager.closeSession(ccSession.id);

      final scriptContent = result.output ?? '';

      final updated = TaskRecord(
        id: record.id,
        sessionId: softwareName,
        task: task,
        script: scriptContent,
        scriptLanguage: plugin.scriptLanguage,
        modelUsed: model,
        status: result.success ? TaskStatus.completed : TaskStatus.failed,
        error: result.error,
        artifacts: result.artifacts,
        createdAt: record.createdAt,
        completedAt: DateTime.now(),
      );
      _tasks[record.id] = updated;

      _getOrCreateSession(domain, softwareName).addRecord(
        task: task, script: scriptContent, scriptLanguage: plugin.scriptLanguage, modelUsed: model,
        status: result.success ? TaskStatus.completed : TaskStatus.failed,
      );

      _activeCount--;
      return updated;
    } catch (e) {
      _activeCount--;
      final failed = TaskRecord(
        id: record.id, sessionId: session.id, task: task,
        status: TaskStatus.failed, error: e.toString(),
        createdAt: record.createdAt, completedAt: DateTime.now(),
      );
      _tasks[record.id] = failed;
      return failed;
    }
  }

  Session? getCurrentSession(String softwareName) => _sessions[softwareName];

  TaskRecord? getTask(String taskId) => _tasks[taskId];

  void cancelTask(String taskId) {
    final task = _tasks[taskId];
    if (task != null && task.status != TaskStatus.cancelled) {
      _tasks[taskId] = TaskRecord(
        id: task.id,
        sessionId: task.sessionId,
        task: task.task,
        script: task.script,
        scriptLanguage: task.scriptLanguage,
        modelUsed: task.modelUsed,
        status: TaskStatus.cancelled,
        error: task.error,
        artifacts: task.artifacts,
        createdAt: task.createdAt,
        completedAt: DateTime.now(),
      );
    }
  }

  int get activeTaskCount => _activeCount;

  Session _getOrCreateSession(DesignCategory domain, String softwareName) {
    return _sessions.putIfAbsent(softwareName, () => Session(domain: domain, softwareName: softwareName));
  }
}
