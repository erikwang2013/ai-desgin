import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/plugin_manager.dart';
import 'package:ai_design_studio/plugin_sdk/design_plugin.dart';
import 'package:ai_design_studio/models/plugin.dart';
import 'package:ai_design_studio/models/software_capabilities.dart';
import 'package:ai_design_studio/models/session.dart';

class StubPlugin extends DesignPlugin {
  final String _id;
  StubPlugin(this._id);

  @override String get id => _id;
  @override String get name => 'Stub $_id';
  @override String get version => '0.0.1';
  @override DesignCategory get category => DesignCategory.web;
  @override String get scriptLanguage => 'javascript';
  @override SoftwareCapabilities get capabilities => const SoftwareCapabilities(actions: [], fileFormats: []);

  @override Future<bool> initialize(PluginContext ctx) async => true;
  @override Future<void> dispose() async {}
  @override Future<ConnectionStatus> checkConnection() async => ConnectionStatus.disconnected;
  @override Future<bool> connect(ConnectionConfig config) async => true;
  @override Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async => ScriptResult.success();
  @override Future<ScriptResult> preview(String script) async => ScriptResult.success();
  @override Future<SoftwareState> getCurrentState() async => const SoftwareState();
}

void main() {
  test('register adds plugin to registry', () {
    final manager = PluginManager();
    manager.register(StubPlugin('test.1'));
    expect(manager.getAll().length, 1);
  });

  test('get returns plugin by id', () {
    final manager = PluginManager();
    manager.register(StubPlugin('a'));
    manager.register(StubPlugin('b'));
    expect(manager.get('b')?.id, 'b');
  });

  test('get returns null for unknown id', () {
    final manager = PluginManager();
    expect(manager.get('nonexistent'), isNull);
  });

  test('getByCategory filters plugins', () {
    final manager = PluginManager();
    manager.register(StubPlugin('web.1'));
    manager.register(StubPlugin('web.2'));
    expect(manager.getByCategory(DesignCategory.web).length, 2);
  });

  test('unregister removes plugin', () {
    final manager = PluginManager();
    final plugin = StubPlugin('to.remove');
    manager.register(plugin);
    manager.unregister('to.remove');
    expect(manager.getAll().length, 0);
  });

  test('initializeAll calls initialize on all plugins', () async {
    final manager = PluginManager();
    manager.register(StubPlugin('a'));
    manager.register(StubPlugin('b'));
    await manager.initializeAll(const PluginContext(pluginPath: '/tmp'));
  });

  test('disposeAll disposes all plugins and clears registry', () async {
    final manager = PluginManager();
    manager.register(StubPlugin('a'));
    await manager.initializeAll(const PluginContext(pluginPath: '/tmp'));
    await manager.disposeAll();
    expect(manager.getAll().length, 0);
  });
}
