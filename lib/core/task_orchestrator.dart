import 'dart:async';
import 'plugin_manager.dart';
import 'cc_process_manager.dart';
import 'cc_runner.dart';
import 'model_router.dart';
import '../models/session.dart';
import '../models/task_record.dart';
import '../models/plugin.dart';

class _QueuedTask {
  final DesignCategory domain;
  final String softwareName;
  final String task;
  final String? overrideModel;
  final String pendingId;
  final Completer<TaskRecord> completer;

  _QueuedTask({
    required this.domain,
    required this.softwareName,
    required this.task,
    this.overrideModel,
    required this.pendingId,
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

  ModelRouter get modelRouter => _modelRouter;

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
    String? taskId,
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
      final pending = TaskRecord(sessionId: softwareName, task: task, status: TaskStatus.pending);
      _tasks[pending.id] = pending;
      final queued = _QueuedTask(
        domain: domain,
        softwareName: softwareName,
        task: task,
        overrideModel: overrideModel,
        pendingId: pending.id,
      );
      _taskQueue.add(queued);
      _processQueue();
      return queued.completer.future;
    }
    _activeCount++;

    _getOrCreateSession(domain, softwareName);
    final record = TaskRecord(id: taskId, sessionId: softwareName, task: task, status: TaskStatus.running);
    _tasks[record.id] = record;

    try {
      final model = _modelRouter.route(domain: domain, task: task, overrideModel: overrideModel);
      final state = await plugin.getCurrentState();
      final ccSession = _ccManager.createSession(software: softwareName, capabilities: plugin.capabilities, state: state);

      // 生成失败（API 报错、无脚本、会话失效）时不得把任务描述当脚本执行。
      TaskRecord failGenerated(String error) {
        _ccManager.closeSession(ccSession.id);
        if (_tasks[record.id]?.status == TaskStatus.cancelled) {
          return _tasks[record.id]!;
        }
        final failed = TaskRecord(
          id: record.id, sessionId: softwareName, task: task,
          status: TaskStatus.failed, error: error,
          createdAt: record.createdAt, completedAt: DateTime.now(),
        );
        _tasks[record.id] = failed;
        return failed;
      }

      String generatedScript = task;
      if (await _ccRunner.isAvailable()) {
        try {
          final generated = await _ccManager.executeWithClaude(
            sessionId: ccSession.id, task: task, model: model,
            runner: _ccRunner, scriptLanguage: plugin.scriptLanguage,
            taskKey: record.id,
          );
          if (generated['success'] == false || generated['script'] == null) {
            return failGenerated(
              (generated['error'] as String?) ?? 'Claude Code failed to generate a script',
            );
          }
          generatedScript = generated['script'] as String;
        } catch (_) {
          return failGenerated('Claude Code execution failed');
        }
      }

      // A cancel during Claude generation kills the CLI process; do not
      // run the local script for a task the user already cancelled.
      if (_tasks[record.id]?.status == TaskStatus.cancelled) {
        _ccManager.closeSession(ccSession.id);
        return _tasks[record.id]!;
      }

      ScriptResult result;
      try {
        result = await plugin.execute(generatedScript);
      } finally {
        // 本地脚本异常退出时也关闭 CC 会话，避免泄漏到空闲驱逐。
        _ccManager.closeSession(ccSession.id);
      }

      // A cancel during local execution must not overwrite the cancelled
      // record (cancelTask already marked it cancelled).
      if (_tasks[record.id]?.status == TaskStatus.cancelled) {
        return _tasks[record.id]!;
      }

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
      final existing = _tasks[record.id];
      if (existing?.status == TaskStatus.cancelled) return existing!;
      final failed = TaskRecord(
        id: record.id, sessionId: softwareName, task: task,
        status: TaskStatus.failed, error: e.toString(),
        createdAt: record.createdAt, completedAt: DateTime.now(),
      );
      _tasks[record.id] = failed;
      return failed;
    } finally {
      _activeCount--;
      _processQueue();
      pruneTasks();
    }
  }

  Session? getCurrentSession(String softwareName) => _sessions[softwareName];

  TaskRecord? getTask(String taskId) => _tasks[taskId];

  /// All task records (for dashboards and testing).
  Iterable<TaskRecord> get tasks => _tasks.values;

  /// Cancel a queued or running task. Completed/failed records are kept as-is.
  void cancelTask(String taskId) {
    final task = _tasks[taskId];
    if (task == null || task.status == TaskStatus.cancelled) return;
    if (task.status == TaskStatus.completed || task.status == TaskStatus.failed) return;

    final cancelled = TaskRecord(
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

    final queueIndex = _taskQueue.indexWhere((q) => q.pendingId == taskId);
    if (queueIndex >= 0) {
      final queued = _taskQueue.removeAt(queueIndex);
      _tasks[taskId] = cancelled;
      if (!queued.completer.isCompleted) {
        queued.completer.complete(cancelled);
      }
      return;
    }

    if (task.status == TaskStatus.running) {
      _ccRunner.cancel(key: taskId);
    }
    _tasks[taskId] = cancelled;
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
      taskId: queued.pendingId,
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

  /// Evict old finished task records to prevent unbounded memory growth.
  /// Running/pending tasks are never pruned.
  void pruneTasks({int keep = 200}) {
    if (_tasks.length <= keep) return;
    final terminal = _tasks.entries
        .where((e) => e.value.status != TaskStatus.running &&
            e.value.status != TaskStatus.pending)
        .toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));
    var excess = _tasks.length - keep;
    for (final entry in terminal) {
      if (excess <= 0) break;
      _tasks.remove(entry.key);
      excess--;
    }
  }
}
