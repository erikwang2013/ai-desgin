import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary;
import 'package:ai_design_studio/bridge/api.dart' as bridge_api;
import 'package:ai_design_studio/bridge/frb_generated.dart';

/// 两态冒烟的核心证据：本机构建产物存在时，显式 dlopen .so 验证
/// Rust 注册表真实可用（62 条、分类/能力正确）；产物缺失时跳过
/// （CI/未构建环境），该场景由 rust_integration_test.dart 的回退路径覆盖。
void main() {
  const soPath = 'build/linux/x64/release/bundle/lib/libai_design_core.so';

  test('FFI 链路：Rust 注册表可加载且数据完整', () async {
    if (!File(soPath).existsSync()) {
      markTestSkipped('未构建 libai_design_core.so，跳过 FFI 验证');
      return;
    }
    final lib = ExternalLibrary.open(soPath);
    await RustLib.init(externalLibrary: lib);
    final json = await bridge_api.getBuiltinPlugins();
    final list = jsonDecode(json) as List;
    expect(list.length, 62);
    final ids = list.map((e) => e['id']).toSet();
    expect(ids.length, 62);
    // 分类与能力数据完整：抽查 figma 一条。
    final figma = list.cast<Map<String, dynamic>>().firstWhere((e) => e['id'] == 'figma');
    final caps = figma['capabilities'] as Map<String, dynamic>;
    expect(figma['category'], 'web');
    expect((caps['actions'] as List), isNotEmpty);
    expect((caps['file_formats'] as List), isNotEmpty);
    // 版本函数可用。
    final version = await bridge_api.rustVersion();
    expect(version, isNotEmpty);
  });
}
