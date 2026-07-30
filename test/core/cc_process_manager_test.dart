import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/cc_process_manager.dart';
import 'package:ai_design_studio/models/software_capabilities.dart';

void main() {
  late CCProcessManager manager;

  setUp(() {
    manager = CCProcessManager(maxProcesses: 2, idleTimeoutSeconds: 300);
  });

  test('createSession returns session with id', () {
    final caps = const SoftwareCapabilities(actions: [], fileFormats: []);
    final state = const SoftwareState();
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    expect(session.id, isNotEmpty);
  });

  test('active session count does not exceed maxProcesses', () {
    final caps = const SoftwareCapabilities(actions: [], fileFormats: []);
    final state = const SoftwareState();
    manager.createSession(software: 'a', capabilities: caps, state: state);
    manager.createSession(software: 'b', capabilities: caps, state: state);
    manager.createSession(software: 'c', capabilities: caps, state: state);
    expect(manager.activeSessionCount, lessThanOrEqualTo(2));
  });

  test('getSession retrieves by id', () {
    final caps = const SoftwareCapabilities(actions: [], fileFormats: []);
    final state = const SoftwareState();
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    final retrieved = manager.getSession(session.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.software, 'figma');
  });

  test('closeSession removes session', () {
    final caps = const SoftwareCapabilities(actions: [], fileFormats: []);
    final state = const SoftwareState();
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    manager.closeSession(session.id);
    expect(manager.getSession(session.id), isNull);
    expect(manager.activeSessionCount, 0);
  });

  test('buildRequest creates valid JSON-RPC request', () {
    final caps = const SoftwareCapabilities(actions: ['export'], fileFormats: ['png']);
    final state = const SoftwareState(activeDocument: 'test.fig');
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
