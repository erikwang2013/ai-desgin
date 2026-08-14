import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/cc_process_manager.dart';
import 'package:ai_design_studio/core/cc_runner.dart';
import 'package:ai_design_studio/models/software_capabilities.dart';

/// Runner that stays "running" until its gate is completed, recording cancels.
class _HangingRunner extends CCRunner {
  final List<String> cancelled = [];
  final Completer<void> started = Completer<void>();
  final Completer<CCResult> gate = Completer<CCResult>();

  @override
  Future<CCResult> execute({
    required String task,
    required String software,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> state,
    String? model,
    String? scriptLanguage,
    String? key,
  }) {
    started.complete();
    return gate.future;
  }

  @override
  void cancel({String? key}) {
    if (key != null) cancelled.add(key);
  }
}

void main() {
  late CCProcessManager manager;

  setUp(() {
    manager = CCProcessManager(maxProcesses: 2, idleTimeoutSeconds: 300);
  });

  test('createSession returns session with id', () {
    const caps = SoftwareCapabilities(actions: [], fileFormats: []);
    const state = SoftwareState();
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    expect(session.id, isNotEmpty);
  });

  test('active session count does not exceed maxProcesses', () {
    const caps = SoftwareCapabilities(actions: [], fileFormats: []);
    const state = SoftwareState();
    manager.createSession(software: 'a', capabilities: caps, state: state);
    manager.createSession(software: 'b', capabilities: caps, state: state);
    manager.createSession(software: 'c', capabilities: caps, state: state);
    expect(manager.activeSessionCount, lessThanOrEqualTo(2));
  });

  test('getSession retrieves by id', () {
    const caps = SoftwareCapabilities(actions: [], fileFormats: []);
    const state = SoftwareState();
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    final retrieved = manager.getSession(session.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.software, 'figma');
  });

  test('closeSession removes session', () {
    const caps = SoftwareCapabilities(actions: [], fileFormats: []);
    const state = SoftwareState();
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    manager.closeSession(session.id);
    expect(manager.getSession(session.id), isNull);
    expect(manager.activeSessionCount, 0);
  });

  test('full manager evicts the idle session, keeping the busy one', () async {
    final runner = _HangingRunner();
    final manager = CCProcessManager(maxProcesses: 2, idleTimeoutSeconds: 300);
    addTearDown(manager.dispose);
    const caps = SoftwareCapabilities(actions: [], fileFormats: []);
    const state = SoftwareState();
    final idle = manager.createSession(software: 'a', capabilities: caps, state: state);
    final busy = manager.createSession(software: 'b', capabilities: caps, state: state);

    final exec = manager.executeWithClaude(
      sessionId: busy.id, task: 't1', model: 'm', runner: runner, taskKey: 'task-1');
    await runner.started.future;

    manager.createSession(software: 'c', capabilities: caps, state: state);
    expect(manager.getSession(idle.id), isNull);
    expect(manager.getSession(busy.id), isNotNull);
    expect(runner.cancelled, isEmpty);

    runner.gate.complete(CCResult.failure('done'));
    await exec;
  });

  test('full manager with all sessions busy refuses a new session', () async {
    final runner = _HangingRunner();
    final manager = CCProcessManager(maxProcesses: 1, idleTimeoutSeconds: 300);
    addTearDown(manager.dispose);
    const caps = SoftwareCapabilities(actions: [], fileFormats: []);
    const state = SoftwareState();
    final s1 = manager.createSession(software: 'a', capabilities: caps, state: state);

    final exec = manager.executeWithClaude(
      sessionId: s1.id, task: 't1', model: 'm', runner: runner, taskKey: 'task-1');
    await runner.started.future;

    expect(() => manager.createSession(software: 'b', capabilities: caps, state: state),
        throwsStateError);
    expect(manager.getSession(s1.id), isNotNull);
    expect(runner.cancelled, isEmpty);

    runner.gate.complete(CCResult.failure('done'));
    await exec;
  });

  test('idle sessions are evicted after idleTimeoutSeconds', () async {
    final manager = CCProcessManager(maxProcesses: 3, idleTimeoutSeconds: 1);
    addTearDown(manager.dispose);
    const caps = SoftwareCapabilities(actions: [], fileFormats: []);
    const state = SoftwareState();
    final s1 = manager.createSession(software: 'a', capabilities: caps, state: state);

    // inSeconds truncates, so wait past 2 s to exceed the 1 s threshold.
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    manager.createSession(software: 'b', capabilities: caps, state: state);

    expect(manager.getSession(s1.id), isNull);
    expect(manager.activeSessionCount, 1);
  });

  test('idle eviction skips sessions with a running task', () async {
    final runner = _HangingRunner();
    final manager = CCProcessManager(maxProcesses: 3, idleTimeoutSeconds: 1);
    addTearDown(manager.dispose);
    const caps = SoftwareCapabilities(actions: [], fileFormats: []);
    const state = SoftwareState();
    final s1 = manager.createSession(software: 'a', capabilities: caps, state: state);

    final exec = manager.executeWithClaude(
      sessionId: s1.id, task: 't1', model: 'm', runner: runner, taskKey: 'task-1');
    await runner.started.future;

    // 等待超过 idleTimeoutSeconds：正在执行任务的会话不应被驱逐。
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    manager.createSession(software: 'b', capabilities: caps, state: state);

    expect(manager.getSession(s1.id), isNotNull);
    expect(manager.activeSessionCount, 2);

    runner.gate.complete(CCResult.failure('done'));
    await exec;
  });

  test('dispose cancels tracked processes and clears sessions', () async {
    final runner = _HangingRunner();
    final manager = CCProcessManager(maxProcesses: 3, idleTimeoutSeconds: 300);
    const caps = SoftwareCapabilities(actions: [], fileFormats: []);
    const state = SoftwareState();
    final s1 = manager.createSession(software: 'a', capabilities: caps, state: state);

    final exec = manager.executeWithClaude(
      sessionId: s1.id, task: 't1', model: 'm', runner: runner, taskKey: 'task-1');
    await runner.started.future;

    manager.dispose();
    expect(runner.cancelled, contains('task-1'));
    expect(manager.activeSessionCount, 0);

    runner.gate.complete(CCResult.failure('done'));
    await exec;
  });

  test('buildRequest creates valid JSON-RPC request', () {
    const caps = SoftwareCapabilities(actions: ['export'], fileFormats: ['png']);
    const state = SoftwareState(activeDocument: 'test.fig');
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    final request = manager.buildRequest(sessionId: session.id, task: 'export to PNG', model: 'claude-sonnet-4-6');

    expect(request['method'], 'design.execute');
    expect(request['params']['task'], 'export to PNG');
    expect(request['params']['model'], 'claude-sonnet-4-6');
    expect(request['params']['software'], 'figma');
    expect(request['params']['capabilities']['actions'], contains('export'));
    expect(request['params']['state']['activeDocument'], 'test.fig');
  });
}
