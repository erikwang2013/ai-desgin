import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/task_orchestrator.dart';
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
    String? sessionId,
  }) async {
    return CCResult(script: 'echo "$task"', explanation: 'fake', modelUsed: model ?? 'fake-model');
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
      ccRunner: FakeCCRunner(),
      maxConcurrent: 2,
    );
  });

  test('submitTask completes with success for known software', () async {
    final task = await orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'say hello');
    expect(task.status, TaskStatus.completed);
    expect(task.task, 'say hello');
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

  test('cancelTask cancels a pending task', () async {
    final task = await orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'cancel me');
    orchestrator.cancelTask(task.id);
    final cancelled = orchestrator.getTask(task.id);
    expect(cancelled?.status, TaskStatus.cancelled);
  });

  test('getTask returns null for unknown id', () {
    expect(orchestrator.getTask('nonexistent'), isNull);
  });
}
