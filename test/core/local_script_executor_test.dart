import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/local_script_executor.dart';
import 'package:ai_design_studio/core/script_executor_configs.dart';

void main() {
  test('hasCommand only for CLI-capable plugins', () {
    final executor = LocalScriptExecutor();
    expect(executor.hasCommand('blender'), isTrue);
    expect(executor.hasCommand('freecad'), isTrue);
    expect(executor.hasCommand('openscad'), isTrue);
    // 新增 CLI 执行软件（创作闭环首批）
    expect(executor.hasCommand('autocad'), isTrue);
    expect(executor.hasCommand('rhino'), isTrue);
    expect(executor.hasCommand('photoshop'), isTrue);
    expect(executor.hasCommand('illustrator'), isTrue);
    expect(executor.hasCommand('fusion360'), isTrue);
    expect(executor.hasCommand('sketchup'), isTrue);
    expect(executor.hasCommand('sketch'), isTrue);
    // Slicers: CLI accepts model files — wired for direct model slicing
    expect(executor.hasCommand('cura'), isTrue);
    expect(executor.hasCommand('prusaslicer'), isTrue);
    expect(executor.hasCommand('orcaslicer'), isTrue);
    expect(executor.hasCommand('chitubox'), isTrue);
    expect(executor.hasCommand('lychee'), isTrue);
    expect(executor.hasCommand('simplify3d'), isTrue);
    // SolidWorks via cscript COM wrapper (Windows-only)
    expect(executor.hasCommand('solidworks'), isTrue);
    // Revit has no real CLI — honest manual-execution fallback
    expect(executor.hasCommand('revit'), isFalse);
    expect(executor.hasCommand('figma'), isFalse);
  });

  test('slicer args pass model path straight to CLI', () {
    final configs = defaultExecutorConfigs();
    final cura = configs.firstWhere((c) => c.pluginId == 'cura');
    final tempDir = Directory.systemTemp.createTempSync('test_');
    try {
      final script = File('${tempDir.path}/model.stl')
        ..writeAsStringSync('/models/cube.stl');
      final args = cura.args(script.path, tempDir);
      expect(args, contains('slice'));
      expect(args, contains('/models/cube.stl'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('execute falls back to generated script for non-CLI plugins', () async {
    final executor = LocalScriptExecutor();
    final result = await executor.execute('figma', 'Figma', 'console.log("hi");');
    expect(result.success, isTrue);
    expect(result.output, contains('脚本已生成'));
    expect(result.output, contains('console.log("hi");'));
  });
}
