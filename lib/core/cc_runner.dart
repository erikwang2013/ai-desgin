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
  Process? _currentProcess;

  CCRunner({this.claudeCliPath});

  String get _cliPath => claudeCliPath ?? 'claude';

  void cancel() {
    _currentProcess?.kill();
    _currentProcess = null;
  }

  /// Check if Claude Code CLI is available
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run(
        _cliPath,
        ['--version'],
      ).timeout(const Duration(seconds: 10));
      return result.exitCode == 0;
    } on TimeoutException {
      _log.warning('Claude Code CLI version check timed out');
      return false;
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
      _currentProcess = process;

      process.stdin.write(prompt);
      await process.stdin.flush();
      await process.stdin.close();

      final results = await Future.wait([
        process.stdout.transform(utf8.decoder).join(),
        process.stderr.transform(utf8.decoder).join(),
      ]).timeout(const Duration(seconds: 120));
      _currentProcess = null;
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
      _currentProcess = null;
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
For Sketch: use JavaScript (sketchtool)
For Photoshop: use JavaScript (ExtendScript)
For Illustrator: use JavaScript (ExtendScript)
For InDesign: use JavaScript (ExtendScript)
For Blender: use Python (bpy API)
For Maya: use Python (maya.cmds / pymel)
For 3ds Max: use MaxScript or Python (pymxs)
For Cinema 4D: use Python (c4d module)
For Fusion 360: use Python (fusion API)
For AutoCAD: use AutoLISP
For Revit: use Python (Revit API / pyRevit) or C#
For SketchUp: use Ruby (SketchUp API)
For Rhino: use Python (rhinoscriptsyntax)
For FreeCAD: use Python (FreeCAD API)
For OpenSCAD: use SCAD language
For slicing software: use CLI commands or config files
For general web design: use HTML/CSS/JavaScript
''';
  }
}
