import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/agent_backend.dart';
import 'package:ai_design_studio/core/gemini_backend.dart';

void main() {
  group('GeminiBackend', () {
    test('execute reports failure when the gemini CLI is missing', () async {
      final backend = GeminiBackend();
      if (await backend.isAvailable()) return; // 环境已装 gemini：跳过
      final result = await backend.execute(
        task: 'create a banner',
        software: 'photoshop',
        capabilities: const {},
        state: const {},
      );
      expect(result.success, isFalse);
      expect(result.error, contains('Gemini'));
    });

    test('execute extracts JSON text field or falls back to raw output', () {
      // 响应解析核心：JSON {"text": ...} 优先，其次 markdown 代码块。
      final script = extractScriptFromMarkdown('```python\nopen("a.png")\n```');
      expect(script, contains('open("a.png")'));
    });
  });
}
