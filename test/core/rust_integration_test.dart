import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/plugin_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PluginManager.create() 在无动态库环境下走 Dart 回退', () async {
    final pm = await PluginManager.create();
    // 测试环境没有 libai_design_core.so，RustLib.init() 必然失败 → 回退路径。
    expect(pm.rustConnected, isFalse);
    expect(pm.getAll(), isNotEmpty);
  });

  test('回退注册表包含完整 62 个内置插件', () async {
    final pm = await PluginManager.create();
    final plugins = pm.getAll();
    expect(plugins.length, 62);
    // id 集合唯一，覆盖全部 6 个分类。
    final ids = plugins.map((p) => p.id).toSet();
    expect(ids.length, 62);
    final categories = plugins.map((p) => p.category).toSet();
    expect(categories.length, 6);
  });

  test('回退插件携带中文能力数据', () async {
    final pm = await PluginManager.create();
    final figma = pm.get('figma');
    expect(figma, isNotNull);
    expect(figma!.capabilities.actions, isNotEmpty);
    expect(figma.capabilities.actions.first, contains('画布'));
  });
}
