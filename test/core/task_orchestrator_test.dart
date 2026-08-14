import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/task_orchestrator.dart';
import 'package:ai_design_studio/core/artifact_verifier.dart';
import 'package:ai_design_studio/core/plugin_manager.dart';
import 'package:ai_design_studio/core/cc_process_manager.dart';
import 'package:ai_design_studio/core/cc_runner.dart';
import 'package:ai_design_studio/core/model_router.dart';
import 'package:ai_design_studio/plugin_sdk/design_plugin.dart';
import 'package:ai_design_studio/models/session.dart';
import 'package:ai_design_studio/models/plugin.dart';
import 'package:ai_design_studio/models/software_capabilities.dart';
import 'package:ai_design_studio/models/task_record.dart';

class EchoPlugin extends DesignPlugin {
  @override String get id => 'echo';
  @override String get name => 'Echo';
  @override String get version => '0.1.0';
  @override DesignCategory get category => DesignCategory.web;
  @override String get scriptLanguage => 'text';
  @override SoftwareCapabilities get capabilities => const SoftwareCapabilities(actions: ['echo'], fileFormats: []);

  @override Future<bool> initialize(PluginContext ctx) async => true;
  @override Future<void> dispose() async {}
  @override Future<ConnectionStatus> checkConnection() async => ConnectionStatus.connected;
  @override Future<bool> connect(ConnectionConfig config) async => true;
  @override Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async {
    return ScriptResult.success(output: 'executed: $script');
  }
  @override Future<ScriptResult> preview(String script) async => ScriptResult.success(output: 'preview: $script');
  @override Future<SoftwareState> getCurrentState() async => const SoftwareState();
}

/// Plugin whose execute() always fails — exercises the closed-loop retry.
class FailingEchoPlugin extends EchoPlugin {
  int executeCount = 0;

  @override
  String get id => 'failing';

  @override
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async {
    executeCount++;
    return ScriptResult.failure(error: 'simulated failure $executeCount');
  }
}

/// Plugin that fails once then succeeds — the closed-loop's core value path.
class FailOncePlugin extends EchoPlugin {
  int executeCount = 0;

  @override
  String get id => 'failonce';

  @override
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async {
    executeCount++;
    if (executeCount == 1) {
      return ScriptResult.failure(error: 'first attempt failed');
    }
    return ScriptResult.success(output: 'executed: $script');
  }
}

/// Verifier that always fails — exercises verification-exhaustion failure.
class _NeverPassVerifier extends ArtifactVerifier {
  const _NeverPassVerifier();

  @override
  Future<VerificationResult> verify(ScriptResult result) async {
    return const VerificationResult(passed: false, summary: 'always fails');
  }
}

class FakeCCRunner extends CCRunner {
  final bool available;
  FakeCCRunner({this.available = false});

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<CCResult> execute({
    required String task,
    required String software,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> state,
    String? model,
    String? scriptLanguage,
    String? key,
  }) async {
    return CCResult(script: 'echo "$task"', explanation: 'fake', modelUsed: model ?? 'fake-model');
  }
}

/// Plugin whose execute() blocks until [release] completes — lets tests
/// observe and cancel a task while it is mid-flight.
class GatedEchoPlugin extends EchoPlugin {
  final Completer<void> release;
  GatedEchoPlugin({required this.release});

  @override
  String get id => 'gated';

  @override
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async {
    await release.future;
    return super.execute(script, onProgress: onProgress);
  }
}

/// Plugin that counts local script executions.
class CountingEchoPlugin extends EchoPlugin {
  int executeCalls = 0;

  @override
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async {
    executeCalls++;
    return super.execute(script, onProgress: onProgress);
  }
}

/// Second software for multi-session tests.
class OtherEchoPlugin extends EchoPlugin {
  @override
  String get id => 'other';
}

/// Gated plugin that records cancel() calls — exercises the cancel wire-up.
class CancellingGatedPlugin extends GatedEchoPlugin {
  int cancelCalls = 0;

  CancellingGatedPlugin({required super.release});

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }
}

/// Runner that always reports generation failure (API error).
class FailingGeneratorRunner extends FakeCCRunner {
  FailingGeneratorRunner() : super(available: true);

  @override
  Future<CCResult> execute({
    required String task,
    required String software,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> state,
    String? model,
    String? scriptLanguage,
    String? key,
  }) async {
    return CCResult.failure('api error');
  }
}

/// Runner whose generation blocks until [gate] completes, then reports
/// failure (as when the CLI process is killed by a cancel).
class GatedFakeCCRunner extends FakeCCRunner {
  final Completer<void> gate = Completer<void>();
  final List<String> cancelledKeys = [];

  GatedFakeCCRunner() : super(available: true);

  @override
  Future<CCResult> execute({
    required String task,
    required String software,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> state,
    String? model,
    String? scriptLanguage,
    String? key,
  }) async {
    await gate.future;
    return CCResult.failure('killed by cancel');
  }

  @override
  void cancel({String? key}) {
    if (key != null) cancelledKeys.add(key);
  }
}

void main() {
  late TaskOrchestrator orchestrator;
  late PluginManager pluginManager;
  late CCProcessManager ccManager;
  late ModelRouter modelRouter;

  setUp(() async {
    pluginManager = PluginManager();
    pluginManager.register(EchoPlugin());
    ccManager = CCProcessManager();
    modelRouter = ModelRouter();
    await modelRouter.loadConfigFromString('default: claude-sonnet-4-6\nroutes: []');
    orchestrator = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: FakeCCRunner(),
      maxConcurrent: 2,
    );
  });

  test('submitTask completes with success for known software', () async {
    final task = await orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'say hello');
    expect(task.status, TaskStatus.completed);
    expect(task.task, 'say hello');
  });

  test('closed loop retries up to maxIterations when execution keeps failing', () async {
    final failing = FailingEchoPlugin();
    pluginManager.register(failing);
    final task = await orchestrator.submitTask(
      domain: DesignCategory.web, softwareName: 'failing', task: 'create',
      maxIterations: 3,
    );
    expect(task.status, TaskStatus.failed);
    expect(failing.executeCount, 3);
    expect(task.iterations, 3);
    expect(task.maxIterations, 3);
    expect(task.iterationLog, hasLength(greaterThanOrEqualTo(3)));
  });

  test('closed loop verifies result and stops on pass', () async {
    final task = await orchestrator.submitTask(
      domain: DesignCategory.web, softwareName: 'echo', task: 'say hello',
      verifier: const ArtifactVerifier(),
    );
    expect(task.status, TaskStatus.completed);
    expect(task.iterations, 1);
    expect(task.iterationLog, contains(contains('验证: 通过')));
  });

  test('closed loop retries after first failure and succeeds on second', () async {
    final failOnce = FailOncePlugin();
    pluginManager.register(failOnce);
    final task = await orchestrator.submitTask(
      domain: DesignCategory.web, softwareName: 'failonce', task: 'create',
      maxIterations: 3,
    );
    expect(task.status, TaskStatus.completed);
    expect(failOnce.executeCount, 2);
    expect(task.iterations, 2);
  });

  test('maxIterations=1 disables the closed-loop retry', () async {
    final failing = FailingEchoPlugin();
    pluginManager.register(failing);
    final task = await orchestrator.submitTask(
      domain: DesignCategory.web, softwareName: 'failing', task: 'create',
      maxIterations: 1,
    );
    expect(task.status, TaskStatus.failed);
    expect(failing.executeCount, 1);
    expect(task.maxIterations, 1);
  });

  test('verification failure exhausts retries and marks task failed', () async {
    final task = await orchestrator.submitTask(
      domain: DesignCategory.web, softwareName: 'echo', task: 'say hello',
      maxIterations: 2,
      verifier: _NeverPassVerifier(),
    );
    expect(task.status, TaskStatus.failed);
    expect(task.error, contains('验证未通过'));
    expect(task.iterations, 2);
  });

  test('submitTask fails for unknown software', () async {
    final task = await orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'nonexistent', task: 'do something');
    expect(task.status, TaskStatus.failed);
    expect(task.error, isNotNull);
  });

  test('session is created per software and records history', () async {
    await orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'task 1');
    final session = orchestrator.getCurrentSession('echo');
    expect(session, isNotNull);
    expect(session!.history.length, 1);
  });

  test('cancelTask removes a queued task and completes its future', () async {
    final release = Completer<void>();
    pluginManager.register(GatedEchoPlugin(release: release));
    final tight = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: FakeCCRunner(),
      maxConcurrent: 1,
    );
    final t1 = tight.submitTask(domain: DesignCategory.web, softwareName: 'gated', task: 'first');
    final t2 = tight.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'second');

    final pending = tight.tasks.firstWhere((t) => t.task == 'second');
    expect(pending.status, TaskStatus.pending);

    tight.cancelTask(pending.id);
    final r2 = await t2;
    expect(r2.status, TaskStatus.cancelled);
    expect(tight.getTask(pending.id)?.status, TaskStatus.cancelled);
    // 队列不再执行被取消的任务，且无幽灵记录
    expect(tight.tasks.where((t) => t.task == 'second'), hasLength(1));

    release.complete();
    await t1;
  });

  test('re-submitting a cancelled task id returns the cancelled record without running', () async {
    final release = Completer<void>();
    final gated = GatedEchoPlugin(release: release);
    final counting = CountingEchoPlugin();
    pluginManager.register(gated);
    pluginManager.register(counting);
    final tight = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: FakeCCRunner(),
      maxConcurrent: 1,
    );
    // 占住唯一并发位，让第二个任务进队列。
    final t1 = tight.submitTask(domain: DesignCategory.web, softwareName: 'gated', task: 'first');
    final t2 = tight.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'second', taskId: 'X');

    final pending = tight.tasks.firstWhere((t) => t.task == 'second');
    expect(pending.status, TaskStatus.pending);

    tight.cancelTask(pending.id);
    expect(tight.getTask(pending.id)?.status, TaskStatus.cancelled);

    // 同 id 重新提交：入口必须直接返回取消结果，不得让任务复活照跑。
    final r3 = await tight.submitTask(
      domain: DesignCategory.web, softwareName: 'echo', task: 'third', taskId: pending.id);
    expect(r3.status, TaskStatus.cancelled);
    expect(r3.task, 'second');
    expect(counting.executeCalls, 0);

    release.complete();
    await t1;
    final r2 = await t2;
    expect(r2.status, TaskStatus.cancelled);
  });

  test('pruneTasks evicts least-recently-active idle sessions beyond the cap', () async {
    pluginManager.register(OtherEchoPlugin());
    final orch = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: FakeCCRunner(),
      maxConcurrent: 2,
    );
    await orch.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'old');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await orch.submitTask(domain: DesignCategory.web, softwareName: 'other', task: 'new');

    orch.pruneTasks(keepSessions: 1);
    expect(orch.getCurrentSession('echo'), isNull);
    expect(orch.getCurrentSession('other'), isNotNull);
  });

  test('pruneTasks never evicts a session with a running task', () async {
    final release = Completer<void>();
    final gated = GatedEchoPlugin(release: release);
    pluginManager.register(gated);
    pluginManager.register(OtherEchoPlugin());
    final orch = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: FakeCCRunner(),
      maxConcurrent: 2,
    );
    final t1 = orch.submitTask(domain: DesignCategory.web, softwareName: 'gated', task: 'block');
    await orch.submitTask(domain: DesignCategory.web, softwareName: 'other', task: 'idle');

    orch.pruneTasks(keepSessions: 1);
    expect(orch.getCurrentSession('gated'), isNotNull);
    expect(orch.getCurrentSession('other'), isNull);

    release.complete();
    await t1;
  });

  test('cancelTask interrupts local script execution via plugin.cancel', () async {
    final release = Completer<void>();
    final plugin = CancellingGatedPlugin(release: release);
    pluginManager.register(plugin);
    final orch = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: FakeCCRunner(),
      maxConcurrent: 1,
    );
    final future = orch.submitTask(domain: DesignCategory.web, softwareName: 'gated', task: 'long local script');
    await pumpEventQueue();
    final running = orch.tasks.firstWhere((t) => t.task == 'long local script');
    expect(running.status, TaskStatus.running);

    orch.cancelTask(running.id);
    expect(plugin.cancelCalls, 1);
    release.complete();
    final result = await future;
    expect(result.status, TaskStatus.cancelled);
  });

  test('submitTask maps full CC sessions to a friendly failure', () async {
    final runner = GatedFakeCCRunner();
    final tightCc = CCProcessManager(maxProcesses: 1);
    final s1 = tightCc.createSession(
      software: 'echo',
      capabilities: const SoftwareCapabilities(actions: [], fileFormats: []),
      state: const SoftwareState(),
    );
    final busyExec = tightCc.executeWithClaude(
      sessionId: s1.id, task: 'occupied', model: 'm', runner: runner, taskKey: 'k1');

    final orch = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: tightCc,
      modelRouter: modelRouter,
      backend: FakeCCRunner(),
      maxConcurrent: 1,
    );
    final result = await orch.submitTask(
      domain: DesignCategory.web, softwareName: 'echo', task: 'second task');
    expect(result.status, TaskStatus.failed);
    expect(result.error, '所有 CC 会话忙碌，请稍后重试');

    runner.gate.complete();
    await busyExec;
  });

  test('session history is truncated to 500 records', () {
    final session = Session(domain: DesignCategory.web, softwareName: 'echo');
    for (var i = 0; i < 505; i++) {
      session.addRecord(task: 'task $i', script: '', scriptLanguage: '', modelUsed: '');
    }
    expect(session.history.length, 500);
    expect(session.history.first.task, 'task 5');
    expect(session.history.last.task, 'task 504');
  });

  test('cancelTask cancels a running task without overwriting its record', () async {
    final release = Completer<void>();
    pluginManager.register(GatedEchoPlugin(release: release));
    final future = orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'gated', task: 'long task');
    await pumpEventQueue();
    final running = orchestrator.tasks.firstWhere((t) => t.task == 'long task');
    expect(running.status, TaskStatus.running);

    orchestrator.cancelTask(running.id);
    release.complete();
    final result = await future;
    expect(result.status, TaskStatus.cancelled);
    expect(orchestrator.getTask(running.id)?.status, TaskStatus.cancelled);
  });

  test('cancelTask records cancelled entry in session history', () async {
    final release = Completer<void>();
    pluginManager.register(GatedEchoPlugin(release: release));
    final future = orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'gated', task: 'cancel me');
    await pumpEventQueue();
    final running = orchestrator.tasks.firstWhere((t) => t.task == 'cancel me');
    expect(running.status, TaskStatus.running);

    orchestrator.cancelTask(running.id);
    release.complete();
    final result = await future;
    expect(result.status, TaskStatus.cancelled);

    final session = orchestrator.getCurrentSession('gated');
    expect(session, isNotNull);
    final cancelledRecords = session!.history.where((r) => r.status == TaskStatus.cancelled);
    expect(cancelledRecords, hasLength(1));
    expect(cancelledRecords.first.task, 'cancel me');
  });

  test('cancelling a running task skips local script execution', () async {
    final counting = CountingEchoPlugin();
    pluginManager.register(counting);
    final runner = GatedFakeCCRunner();
    final orch = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: runner,
      maxConcurrent: 1,
    );
    final future = orch.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'slow');
    await pumpEventQueue();
    final running = orch.tasks.firstWhere((t) => t.task == 'slow');
    orch.cancelTask(running.id);
    expect(runner.cancelledKeys, contains(running.id));
    runner.gate.complete();
    final result = await future;
    expect(result.status, TaskStatus.cancelled);
    expect(counting.executeCalls, 0);
  });

  test('failed generation does not execute the task text as a script', () async {
    final counting = CountingEchoPlugin();
    pluginManager.register(counting);
    final orch = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: FailingGeneratorRunner(),
      maxConcurrent: 1,
    );
    final result = await orch.submitTask(
      domain: DesignCategory.web, softwareName: 'echo', task: '设计一个海报');
    expect(result.status, TaskStatus.failed);
    expect(result.error, contains('api error'));
    expect(counting.executeCalls, 0);
  });

  test('cancelTask does not overwrite completed history', () async {
    final task = await orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'done task');
    expect(task.status, TaskStatus.completed);
    orchestrator.cancelTask(task.id);
    expect(orchestrator.getTask(task.id)?.status, TaskStatus.completed);
  });

  test('getTask returns null for unknown id', () {
    expect(orchestrator.getTask('nonexistent'), isNull);
  });

  test('queues tasks when at maxConcurrent', () async {
    final t1 = orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'q1');
    final t2 = orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'q2');
    final t3 = orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'q3');
    final r1 = await t1;
    final r2 = await t2;
    expect(r1.status, TaskStatus.completed);
    expect(r2.status, TaskStatus.completed);
    final r3 = await t3;
    expect(r3.status, TaskStatus.completed);
    expect(r3.task, 'q3');
  });

  test('rejects when queue is full', () async {
    final tight = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: FakeCCRunner(),
      maxConcurrent: 1,
      maxQueueSize: 0,
    );
    final t1 = tight.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'busy');
    final t2 = await tight.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'rejected');
    expect(t2.status, TaskStatus.failed);
    expect(t2.error, contains('queue full'));
    await t1;
    expect(tight.activeTaskCount, 0);
  });

  test('pruneTasks evicts oldest records', () async {
    for (var i = 0; i < 5; i++) {
      await orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'prune $i');
    }
    orchestrator.pruneTasks(keep: 3);
    final remaining = orchestrator.tasks.map((t) => t.task).toList();
    expect(remaining, hasLength(3));
    expect(remaining, isNot(contains('prune 0')));
    expect(remaining, isNot(contains('prune 1')));
    expect(remaining, containsAll(['prune 2', 'prune 3', 'prune 4']));
  });

  test('onProgress reports generating/executing/verifying stages in order', () async {
    final orch = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: FakeCCRunner(available: true),
      maxConcurrent: 2,
    );
    final stages = <String>[];
    final task = await orch.submitTask(
      domain: DesignCategory.web,
      softwareName: 'echo',
      task: 'say hi',
      verifier: const ArtifactVerifier(),
      onProgress: (stage, description) => stages.add(stage),
    );
    expect(task.status, TaskStatus.completed);
    expect(stages, containsAllInOrder(['generating', 'executing', 'verifying']));
  });

  test('onProgress fires through the queue for deferred tasks', () async {
    final release = Completer<void>();
    pluginManager.register(GatedEchoPlugin(release: release));
    final tight = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      backend: FakeCCRunner(available: true),
      maxConcurrent: 1,
    );
    final stages = <String>[];
    tight.submitTask(domain: DesignCategory.web, softwareName: 'gated', task: 'first');
    final t2 = tight.submitTask(
      domain: DesignCategory.web,
      softwareName: 'echo',
      task: 'second',
      onProgress: (stage, description) => stages.add(stage),
    );
    release.complete();
    final r2 = await t2;
    expect(r2.status, TaskStatus.completed);
    expect(stages, contains('generating'));
  });
}
