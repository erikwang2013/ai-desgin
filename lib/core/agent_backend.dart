import 'dart:convert';
import 'cc_runner.dart';

/// 可切换的 Agent CLI 后端统一接口：Claude Code / Codex / Gemini。
abstract class AgentBackend {
  String get id;

  String get displayName;

  Future<bool> isAvailable();

  Future<CCResult> execute({
    required String task,
    required String software,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> state,
    String? model,
    String? scriptLanguage,
    String? key,
  });

  void cancel({String? key});

  /// 非 claude 后端的默认模型名；null 表示用 CLI 自己的默认模型。
  String? get defaultModel => null;
}

/// 面向通用编码 agent（Codex/Gemini）的提示词：要求输出代码块而非 JSON。
String buildCodeBlockPrompt({
  required String task,
  required String software,
  required Map<String, dynamic> capabilities,
  required Map<String, dynamic> state,
  required String scriptLanguage,
}) {
  return '''
You are controlling $software design software. Generate a script to accomplish the following task.

SOFTWARE: $software
CAPABILITIES (what the software can do):
${jsonEncode(capabilities)}

CURRENT STATE:
${jsonEncode(state)}

TASK: $task

IMPORTANT RULES:
1. Output ONLY the script code inside a single markdown code block (```), no other text
2. Script language: $scriptLanguage
3. Be precise - use exact API calls based on the capabilities listed above
4. Include error handling in the script where appropriate
5. The script should be self-contained and executable immediately
''';
}

/// 从输出中提取第一个 ``` 代码块；没有代码块返回 null。
String? extractScriptFromMarkdown(String output) {
  final match = RegExp(r'```[a-zA-Z0-9_+-]*\s*\n([\s\S]*?)```').firstMatch(output);
  if (match == null) return null;
  final script = match.group(1)!.trim();
  return script.isEmpty ? null : script;
}
