import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final _log = Logger('CCRunner');

class CCResult {
  final String? script;
  final String? scriptLanguage;
  final String? explanation;
  final String? modelUsed;
  final bool success;
  final String? error;

  CCResult({
    this.script,
    this.scriptLanguage,
    this.explanation,
    this.modelUsed,
    this.success = true,
    this.error,
  });

  factory CCResult.fromJson(Map<String, dynamic> json) {
    return CCResult(
      script: json['script'] as String?,
      scriptLanguage: json['scriptLanguage'] as String?,
      explanation: json['explanation'] as String?,
      modelUsed: json['modelUsed'] as String?,
      success: json['success'] as bool? ?? true,
    );
  }

  factory CCResult.failure(String error) {
    return CCResult(success: false, error: error);
  }
}

class CCRunner {
  final String? claudeCliPath;

  CCRunner({this.claudeCliPath});

  String get _cliPath => claudeCliPath ?? 'claude';

  /// Check if Claude Code CLI is available
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run(_cliPath, ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      _log.warning('Claude Code CLI not found: $e');
      return false;
    }
  }

  /// Send a design task to Claude Code and get back a generated script
  Future<CCResult> execute({
    required String task,
    required String software,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> state,
    String? model,
    String? sessionId,
  }) async {
    final prompt = _buildPrompt(
      task: task,
      software: software,
      capabilities: capabilities,
      state: state,
      model: model,
    );

    try {
      final process = await Process.start(
        _cliPath,
        ['--print', '--output-format', 'json'],
        environment: {
          ...Platform.environment,
          if (model != null) 'CLAUDE_DEFAULT_MODEL': model,
        },
      );

      process.stdin.write(prompt);
      await process.stdin.close();

      final results = await Future.wait([
        process.stdout.transform(utf8.decoder).join(),
        process.stderr.transform(utf8.decoder).join(),
      ]);
      final output = results[0];
      final errors = results[1];

      if (errors.isNotEmpty) {
        _log.info('Claude Code stderr: $errors');
      }

      // Parse the JSON response
      final lines = output.split('\n').where((l) => l.trim().isNotEmpty);
      for (final line in lines) {
        try {
          final json = jsonDecode(line.trim()) as Map<String, dynamic>;
          if (json.containsKey('result')) {
            return CCResult.fromJson(json['result'] as Map<String, dynamic>);
          }
        } catch (_) {
          // Skip non-JSON lines
        }
      }

      // If we got text output but no JSON, return the raw text as explanation
      if (output.trim().isNotEmpty) {
        return CCResult(
          script: output.trim(),
          explanation: 'Claude Code raw output',
          modelUsed: model ?? 'default',
        );
      }

      return CCResult.failure('No output from Claude Code');
    } catch (e) {
      _log.severe('Claude Code execution failed: $e');
      return CCResult.failure('Claude Code execution failed: $e');
    }
  }

  /// Test-only accessor for prompt building
  @visibleForTesting
  String buildPromptForTest({
    required String task,
    required String software,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> state,
  }) {
    return _buildPrompt(
      task: task,
      software: software,
      capabilities: capabilities,
      state: state,
    );
  }

  String _buildPrompt({
    required String task,
    required String software,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> state,
    String? model,
  }) {
    final caps = jsonEncode(capabilities);
    final currentState = jsonEncode(state);

    final modelHint = model != null ? '\nMODEL: $model' : '';

    return '''
You are controlling $software design software. Generate a script to accomplish the following task.

SOFTWARE: $software
CAPABILITIES (what the software can do):
$caps

CURRENT STATE:
$currentState
$modelHint

TASK: $task

IMPORTANT RULES:
1. Generate ONLY the script code, no explanations in the script itself
2. Use the software's native scripting language
3. Be precise - use exact API calls based on the capabilities listed above
4. Include error handling in the script where appropriate
5. The script should be self-contained and executable immediately

Output your response as JSON with these fields:
- "script": the actual script code to execute
- "explanation": brief explanation of what the script does (in Chinese)
- "scriptLanguage": the scripting language used

For Figma: use JavaScript (Figma Plugin API)
For Blender: use Python (bpy API)
For AutoCAD: use AutoLISP
For Photoshop: use JavaScript (ExtendScript)
For general web design: use HTML/CSS/JavaScript
''';
  }
}
