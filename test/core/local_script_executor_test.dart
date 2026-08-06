import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/local_script_executor.dart';

void main() {
  test('hasCommand only for CLI-capable plugins', () {
    final executor = LocalScriptExecutor();
    expect(executor.hasCommand('blender'), isTrue);
    expect(executor.hasCommand('freecad'), isTrue);
    expect(executor.hasCommand('openscad'), isTrue);
    // Slicers accept model files, not generated scripts — honest manual fallback
    expect(executor.hasCommand('cura'), isFalse);
    expect(executor.hasCommand('prusaslicer'), isFalse);
    expect(executor.hasCommand('figma'), isFalse);
    expect(executor.hasCommand('photoshop'), isFalse);
  });

  test('execute falls back to generated script for non-CLI plugins', () async {
    final executor = LocalScriptExecutor();
    final result = await executor.execute('figma', 'Figma', 'console.log("hi");');
    expect(result.success, isTrue);
    expect(result.output, contains('脚本已生成'));
    expect(result.output, contains('console.log("hi");'));
  });
}
