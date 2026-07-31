import 'dart:async';
import 'plugin_manager.dart';
import 'cc_process_manager.dart';
import 'cc_runner.dart';
import 'model_router.dart';
import '../models/session.dart';
import '../models/task_record.dart';

class _QueuedTask {
  final DesignCategory domain;
  final String softwareName;
  final String task;
  final String? overrideModel;
  final Completer<TaskRecord> completer;

  _QueuedTask({
    required this.domain,
    required this.softwareName,
    required this.task,
    this.overrideModel,
  }) : completer = Completer<TaskRecord>();
}

class TaskOrchestrator {
  final PluginManager _pluginManager;
  final CCProcessManager _ccManager;
  final ModelRouter _modelRouter;
  final CCRunner _ccRunner;
  final int maxConcurrent;
  final int maxQueueSize;

  final Map<String, Session> _sessions = {};
  final Map<String, TaskRecord> _tasks = {};
  int _activeCount = 0;
  final List<_QueuedTask> _taskQueue = [];

  TaskOrchestrator({
    required PluginManager pluginManager,
    required CCProcessManager ccManager,
    required ModelRouter modelRouter,
    CCRunner? ccRunner,
    this.maxConcurrent = 3,
    this.maxQueueSize = 100,
  })  : _pluginManager = pluginManager,
        _ccManager = ccManager,
        _modelRouter = modelRouter,
        _ccRunner = ccRunner ?? CCRunner();

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
      if (_taskQueue.length >= maxQueueSize) {
        final record = TaskRecord(sessionId: softwareName, task: task,
            status: TaskStatus.failed, error: 'Task queue full (max $maxQueueSize)');
        _tasks[record.id] = record;
        return record;
      }
      final queued = _QueuedTask(domain: domain, softwareName: softwareName, task: task, overrideModel: overrideModel);
      _taskQueue.add(queued);
      final pending = TaskRecord(sessionId: softwareName, task: task, status: TaskStatus.pending);
      _tasks[pending.id] = pending;
      _processQueue();
      return queued.completer.future;
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
      if (await _ccRunner.isAvailable()) {
        try {
          final generated = await _ccManager.executeWithClaude(
            sessionId: ccSession.id, task: task, model: model, runner: _ccRunner,
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

      return updated;
    } catch (e) {
      final failed = TaskRecord(
        id: record.id, sessionId: session.id, task: task,
        status: TaskStatus.failed, error: e.toString(),
        createdAt: record.createdAt, completedAt: DateTime.now(),
      );
      _tasks[record.id] = failed;
      return failed;
    } finally {
      _activeCount--;
      _processQueue();
    }
  }

  Session? getCurrentSession(String softwareName) => _sessions[softwareName];

  TaskRecord? getTask(String taskId) => _tasks[taskId];

  void cancelTask(String taskId) {
    final task = _tasks[taskId];
    if (task != null && task.status != TaskStatus.cancelled) {
      _ccRunner.cancel();

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

  void _processQueue() {
    if (_taskQueue.isEmpty || _activeCount >= maxConcurrent) return;

    final queued = _taskQueue.removeAt(0);
    submitTask(
      domain: queued.domain,
      softwareName: queued.softwareName,
      task: queued.task,
      overrideModel: queued.overrideModel,
    ).then((result) {
      if (!queued.completer.isCompleted) {
        queued.completer.complete(result);
      }
    }).catchError((e) {
      if (!queued.completer.isCompleted) {
        queued.completer.completeError(e);
      }
    });
  }

  /// Evict old task records to prevent unbounded memory growth
  void pruneTasks({int keep = 100}) {
    if (_tasks.length <= keep) return;
    final sorted = _tasks.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));
    for (var i = 0; i < sorted.length - keep; i++) {
      _tasks.remove(sorted[i].key);
    }
  }
}
