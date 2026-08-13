import 'dart:async';
import 'agent_backend.dart';
import 'plugin_manager.dart';
import 'cc_process_manager.dart';
import 'cc_runner.dart';
import 'model_router.dart';
import 'artifact_verifier.dart';
import '../models/session.dart';
import '../models/task_record.dart';
import '../models/plugin.dart';

class _QueuedTask {
  final DesignCategory domain;
  final String softwareName;
  final String task;
  final String? overrideModel;
  final String pendingId;
  final int maxIterations;
  final ArtifactVerifier? verifier;
  final Completer<TaskRecord> completer;

  _QueuedTask({
    required this.domain,
    required this.softwareName,
    required this.task,
    this.overrideModel,
    required this.pendingId,
    this.maxIterations = 3,
    this.verifier,
  }) : completer = Completer<TaskRecord>();
}

class TaskOrchestrator {
  final PluginManager _pluginManager;
  final CCProcessManager _ccManager;
  final ModelRouter _modelRouter;
  AgentBackend backend;
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
    AgentBackend? backend,
    this.maxConcurrent = 3,
    this.maxQueueSize = 100,
  })  : _pluginManager = pluginManager,
        _ccManager = ccManager,
        _modelRouter = modelRouter,
        backend = backend ?? CCRunner();

  Future<TaskRecord> submitTask({
    required DesignCategory domain,
    required String softwareName,
    required String task,
    String? overrideModel,
    String? taskId,
    int maxIterations = 3,
    ArtifactVerifier? verifier,
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
        maxIterations: maxIterations,
        verifier: verifier,
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
      final isClaude = backend.id == 'claude';
      final model = isClaude
          ? _modelRouter.route(domain: domain, task: task, overrideModel: overrideModel)
          : null;
      final state = await plugin.getCurrentState();
      String? ccSessionId;
      if (isClaude) {
        ccSessionId = _ccManager
            .createSession(software: softwareName, capabilities: plugin.capabilities, state: state)
            .id;
      }

      // 生成失败（API 报错、无脚本、会话失效）时不得把任务描述当脚本执行。
      TaskRecord failGenerated(String error) {
        if (ccSessionId != null) _ccManager.closeSession(ccSessionId);
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
      if (await backend.isAvailable()) {
        try {
          if (isClaude) {
            final generated = await _ccManager.executeWithClaude(
              sessionId: ccSessionId!, task: task, model: model!,
              runner: backend, scriptLanguage: plugin.scriptLanguage,
              taskKey: record.id,
            );
            if (generated['success'] == false || generated['script'] == null) {
              return failGenerated(
                (generated['error'] as String?) ?? 'Claude Code failed to generate a script',
              );
            }
            generatedScript = generated['script'] as String;
          } else {
            final generated = await backend.execute(
              task: task,
              software: softwareName,
              capabilities: plugin.capabilities.toJson(),
              state: state.toJson(),
              model: model,
              scriptLanguage: plugin.scriptLanguage,
              key: record.id,
            );
            if (!generated.success || generated.script == null) {
              return failGenerated(
                generated.error ?? '${backend.displayName} failed to generate a script',
              );
            }
            generatedScript = generated.script!;
          }
        } catch (_) {
          return failGenerated('${backend.displayName} execution failed');
        }
      }

      // 创作闭环：生成→执行→验证→反馈→重新生成，直到验证通过或达上限。
      // 取消语义：循环顶部与循环后各保留一次取消检查，与单轮版本一致。
      final effectiveMax = maxIterations > 0 ? maxIterations : 1;
      final iterationLog = <String>[];
      var feedback = '';
      var iterationsRun = 0;
      var lastVerification = const VerificationResult(passed: true, summary: '');
      ScriptResult? result;
      try {
        for (var iteration = 1; iteration <= effectiveMax; iteration++) {
          // A cancel during generation kills the CLI process; do not run the
          // local script for a task the user already cancelled.
          if (_tasks[record.id]?.status == TaskStatus.cancelled) {
            return _tasks[record.id]!;
          }

          if (iteration > 1) {
            final enrichedTask =
                '$task\n\n【第 ${iteration - 1} 轮执行反馈】\n$feedback\n请根据反馈修正脚本后重新生成。';
            if (isClaude) {
              final generated = await _ccManager.executeWithClaude(
                sessionId: ccSessionId!, task: enrichedTask, model: model!,
                runner: backend, scriptLanguage: plugin.scriptLanguage,
                taskKey: record.id,
              );
              if (generated['success'] == false || generated['script'] == null) {
                iterationLog.add('第 $iteration 轮重新生成失败: ${generated['error']}');
                break;
              }
              generatedScript = generated['script'] as String;
            } else {
              final generated = await backend.execute(
                task: enrichedTask,
                software: softwareName,
                capabilities: plugin.capabilities.toJson(),
                state: state.toJson(),
                model: model,
                scriptLanguage: plugin.scriptLanguage,
                key: record.id,
              );
              if (!generated.success || generated.script == null) {
                iterationLog.add('第 $iteration 轮重新生成失败: ${generated.error}');
                break;
              }
              generatedScript = generated.script!;
            }
            // A cancel during regeneration must not run the stale script.
            if (_tasks[record.id]?.status == TaskStatus.cancelled) {
              return _tasks[record.id]!;
            }
          }

          result = await plugin.execute(generatedScript);
          iterationsRun = iteration;
          iterationLog.add(
            '第 $iteration 轮执行: ${result.success ? '成功' : '失败'}'
            '${result.error != null ? ' - ${result.error}' : ''}',
          );
          if (result.success) {
            if (verifier == null) break;
            final verification = await verifier.verify(result);
            lastVerification = verification;
            iterationLog.add(
              '第 $iteration 轮验证: ${verification.passed ? '通过' : '未通过 - ${verification.summary}'}',
            );
            if (verification.passed) break;
            feedback = '执行成功但验证未通过: ${verification.summary}';
          } else {
            feedback = '执行失败: ${result.error}';
          }
        }
      } finally {
        // 本地脚本异常退出时也关闭 CC 会话，避免泄漏到空闲驱逐。
        if (ccSessionId != null) _ccManager.closeSession(ccSessionId);
      }

      // A cancel during local execution must not overwrite the cancelled
      // record (cancelTask already marked it cancelled).
      if (_tasks[record.id]?.status == TaskStatus.cancelled) {
        return _tasks[record.id]!;
      }

      final scriptContent = result?.output ?? '';
      // 验证未通过时即使脚本执行成功也算失败——闭环的核心语义。
      final verificationPassed = lastVerification.passed;
      final taskSucceeded = result?.success == true && verificationPassed;
      final taskError = result?.success == true && !verificationPassed
          ? '验证未通过: ${lastVerification.summary}'
          : result?.error;

      final updated = TaskRecord(
        id: record.id,
        sessionId: softwareName,
        task: task,
        script: scriptContent,
        scriptLanguage: plugin.scriptLanguage,
        modelUsed: model,
        status: taskSucceeded ? TaskStatus.completed : TaskStatus.failed,
        error: taskError,
        artifacts: result?.artifacts ?? const [],
        iterations: iterationsRun > 0 ? iterationsRun : 1,
        maxIterations: effectiveMax,
        iterationLog: iterationLog,
        createdAt: record.createdAt,
        completedAt: DateTime.now(),
      );
      _tasks[record.id] = updated;

      _getOrCreateSession(domain, softwareName).addRecord(
        task: task, script: scriptContent, scriptLanguage: plugin.scriptLanguage, modelUsed: model ?? '',
        status: taskSucceeded ? TaskStatus.completed : TaskStatus.failed,
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
      iterations: task.iterations,
      maxIterations: task.maxIterations,
      iterationLog: task.iterationLog,
      createdAt: task.createdAt,
      completedAt: DateTime.now(),
    );

    final queueIndex = _taskQueue.indexWhere((q) => q.pendingId == taskId);
    if (queueIndex >= 0) {
      final queued = _taskQueue.removeAt(queueIndex);
      _tasks[taskId] = cancelled;
      _recordCancelledInSession(task);
      if (!queued.completer.isCompleted) {
        queued.completer.complete(cancelled);
      }
      return;
    }

    if (task.status == TaskStatus.running) {
      backend.cancel(key: taskId);
    }
    _tasks[taskId] = cancelled;
    _recordCancelledInSession(task);
  }

  /// Persist the cancellation in the session history so cancelled tasks
  /// survive a restart (running records are only added on completion).
  void _recordCancelledInSession(TaskRecord task) {
    final session = _sessions[task.sessionId];
    if (session == null) return;
    session.addRecord(
      task: task.task,
      script: task.script ?? '',
      scriptLanguage: task.scriptLanguage ?? 'text',
      modelUsed: task.modelUsed ?? '',
      status: TaskStatus.cancelled,
    );
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
      maxIterations: queued.maxIterations,
      verifier: queued.verifier,
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
