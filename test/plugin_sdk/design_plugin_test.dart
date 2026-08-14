import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/plugin_sdk/design_plugin.dart';
import 'package:ai_design_studio/models/plugin.dart';
import 'package:ai_design_studio/models/software_capabilities.dart';
import 'package:ai_design_studio/models/session.dart';

class FakeFigmaPlugin extends DesignPlugin {
  @override
  String get id => 'com.aidesign.figma';

  @override
  String get name => 'Figma';

  @override
  String get version => '1.0.0';

  @override
  DesignCategory get category => DesignCategory.web;

  @override
  String get scriptLanguage => 'javascript';

  @override
  SoftwareCapabilities get capabilities => const SoftwareCapabilities(
        actions: ['创建画布', '添加矩形', '设置填充色', '导出PNG'],
        fileFormats: ['fig', 'png', 'svg'],
      );

  @override
  Future<bool> initialize(PluginContext ctx) async => true;

  @override
  Future<void> dispose() async {}

  @override
  Future<ConnectionStatus> checkConnection() async =>
      ConnectionStatus.disconnected;

  @override
  Future<bool> connect(ConnectionConfig config) async => true;

  @override
  Future<ScriptResult> execute(String script,
      {ProgressCallback? onProgress, String? key}) async {
    onProgress?.call(0.5);
    onProgress?.call(1.0);
    return ScriptResult.success(output: 'ok');
  }

  @override
  Future<ScriptResult> preview(String script) async {
    return ScriptResult.success(output: 'preview ok');
  }

  @override
  Future<SoftwareState> getCurrentState() async => const SoftwareState(
        activeDocument: 'untitled.fig',
        layers: ['Layer 1', 'Rectangle 1'],
      );
}

void main() {
  late FakeFigmaPlugin plugin;
  setUp(() => plugin = FakeFigmaPlugin());

  test('plugin metadata is correct', () {
    expect(plugin.id, 'com.aidesign.figma');
    expect(plugin.name, 'Figma');
    expect(plugin.category, DesignCategory.web);
    expect(plugin.scriptLanguage, 'javascript');
  });

  test('fromRustJson tolerates malformed capability entries', () {
    final plugin = BuiltInPlugin.fromRustJson({
      'id': 'bad',
      'name': 'Bad',
      'category': 'web',
      'script_language': 'javascript',
      'capabilities': {
        // 非 List 字段与非字符串元素都应跳过，而不是抛错或逃逸惰性 cast。
        'actions': 'not-a-list',
        'file_formats': ['ok', 123, null],
      },
    });
    expect(plugin.id, 'bad');
    expect(plugin.capabilities.actions, isEmpty);
    expect(plugin.capabilities.fileFormats, ['ok']);
  });

  test('initialize sets up plugin', () async {
    final result =
        await plugin.initialize(const PluginContext(pluginPath: '/tmp/plugin'));
    expect(result, true);
  });

  test('capabilities lists available actions', () {
    expect(plugin.capabilities.actions, contains('创建画布'));
    expect(plugin.capabilities.fileFormats, contains('fig'));
  });

  test('execute returns result and reports progress', () async {
    final progress = <double>[];
    final result =
        await plugin.execute('create rectangle', onProgress: (p) => progress.add(p));
    expect(result.success, true);
    expect(progress, [0.5, 1.0]);
  });

  test('preview does not modify state', () async {
    final result = await plugin.preview('create rectangle');
    expect(result.success, true);
    expect(result.output, 'preview ok');
  });

  test('getCurrentState returns document snapshot', () async {
    final state = await plugin.getCurrentState();
    expect(state.activeDocument, 'untitled.fig');
    expect(state.layers.length, 2);
  });
}
