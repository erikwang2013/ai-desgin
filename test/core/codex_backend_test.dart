import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/agent_backend.dart';
import 'package:ai_design_studio/core/codex_backend.dart';

void main() {
  group('CodexBackend', () {
    test('execute reports failure when the codex CLI is missing', () async {
      final backend = CodexBackend();
      if (await backend.isAvailable()) return; // 环境已装 codex：跳过
      final result = await backend.execute(
        task: 'create a poster',
        software: 'figma',
        capabilities: const {},
        state: const {},
      );
      expect(result.success, isFalse);
      expect(result.error, contains('Codex'));
    });

    test('execute resolves a markdown code block from CLI output', () {
      // 响应解析核心：从 markdown 代码块提取脚本，非 JSON 时回退原始文本。
      final script = extractScriptFromMarkdown('```javascript\ncreateNode("X")\n```');
      expect(script, contains('createNode("X")'));
      // 无代码块时返回 null，由后端回退为原始输出/失败，不抛异常。
      expect(extractScriptFromMarkdown('raw output'), isNull);
    });
  });
}
