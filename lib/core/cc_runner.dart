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
      error: json['error'] as String?,
    );
  }

  factory CCResult.failure(String error) {
    return CCResult(success: false, error: error);
  }
}

class CCRunner {
  /// Proxy env vars (e.g. HTTP_PROXY/HTTPS_PROXY) applied to CLI subprocesses.
  static Map<String, String>? proxyEnvironment;

  /// Optional Anthropic-compatible API base URL (overrides CLI defaults).
  static String? apiBaseUrl;

  /// Optional API key (ANTHROPIC_AUTH_TOKEN) for the configured endpoint.
  static String? apiAuthToken;

  /// Response-language instruction injected into prompts (from locale).
  static String? responseLanguage;

  final String? claudeCliPath;
  final Duration timeout;
  final Map<String, Process> _processes = {};
  bool? _cachedAvailable;
  DateTime? _lastAvailabilityCheck;

  static const _availabilityCacheTtl = Duration(seconds: 60);

  CCRunner({this.claudeCliPath, this.timeout = const Duration(seconds: 120)});

  String get _cliPath => claudeCliPath ?? 'claude';

  /// Kill the process for [key]; without a key, kill all tracked processes.
  void cancel({String? key}) {
    if (key != null) {
      _processes.remove(key)?.kill();
      return;
    }
    for (final p in _processes.values) {
      p.kill();
    }
    _processes.clear();
  }

  /// Check if Claude Code CLI is available (cached for 60s)
  Future<bool> isAvailable() async {
    if (_cachedAvailable != null && _lastAvailabilityCheck != null) {
      if (DateTime.now().difference(_lastAvailabilityCheck!) < _availabilityCacheTtl) {
        return _cachedAvailable!;
      }
    }
    try {
      final result = await Process.run(
        _cliPath,
        ['--version'],
      ).timeout(const Duration(seconds: 10));
      _cachedAvailable = result.exitCode == 0;
    } on TimeoutException {
      _log.warning('Claude Code CLI version check timed out');
      _cachedAvailable = false;
    } catch (e) {
      _log.warning('Claude Code CLI not found: $e');
      _cachedAvailable = false;
    }
    _lastAvailabilityCheck = DateTime.now();
    return _cachedAvailable!;
  }

  /// Send a design task to Claude Code and get back a generated script.
  /// [key] identifies the task so it can be cancelled independently.
  Future<CCResult> execute({
    required String task,
    required String software,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> state,
    String? model,
    String? scriptLanguage,
    String? key,
  }) async {
    final prompt = _buildPrompt(
      task: task,
      software: software,
      capabilities: capabilities,
      state: state,
      model: model,
      scriptLanguage: scriptLanguage ?? 'javascript',
    );

    try {
      final process = await Process.start(
        _cliPath,
        ['--print', '--output-format', 'json'],
        environment: {
          ...Platform.environment,
          'CLAUDE_DEFAULT_MODEL': ?model,
          if (apiBaseUrl != null && apiBaseUrl!.isNotEmpty) 'ANTHROPIC_BASE_URL': apiBaseUrl!,
          if (apiAuthToken != null && apiAuthToken!.isNotEmpty) 'ANTHROPIC_AUTH_TOKEN': apiAuthToken!,
          ...?proxyEnvironment,
        },
      );
      final taskKey = key ?? 'default';
      _processes.remove(taskKey)?.kill();
      _processes[taskKey] = process;

      // 启动即并发消费 stdout/stderr，避免子进程边读边写时 64KB 管道死锁。
      // Windows 控制台可能输出 GBK 等非 UTF-8 文本，宽容解码避免抛异常。
      const lenient = Utf8Decoder(allowMalformed: true);
      final stdoutFuture = process.stdout.transform(lenient).join();
      final stderrFuture = process.stderr.transform(lenient).join();
      process.stdin.write(prompt);
      await process.stdin.flush();
      await process.stdin.close();

      final exitCode = await process.exitCode.timeout(timeout);
      final results = await Future.wait([stdoutFuture, stderrFuture]).timeout(timeout);
      _processes.remove(taskKey);
      final output = results[0];
      final errors = results[1];

      // 非零退出（API key 错误、崩溃）时 stdout 里的文本不是生成脚本。
      if (exitCode != 0) {
        return CCResult.failure(
          'Claude Code exited with code $exitCode'
          '${errors.isNotEmpty ? ': ${errors.trim()}' : ''}',
        );
      }

      if (errors.isNotEmpty) {
        _log.info('Claude Code stderr: $errors');
      }

      // Parse the JSON response — try full output first, then line-by-line
      try {
        final json = jsonDecode(output.trim()) as Map<String, dynamic>;
        if (json.containsKey('result')) {
          return CCResult.fromJson(json['result'] as Map<String, dynamic>);
        }
      } catch (_) {
        // Not a single JSON object; fall through to line-by-line
      }
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
      // Kill the subprocess on timeout/error to avoid orphaned Claude CLI processes
      _processes.remove(key ?? 'default')?.kill();
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
    String scriptLanguage = 'javascript',
  }) {
    return _buildPrompt(
      task: task,
      software: software,
      capabilities: capabilities,
      state: state,
      scriptLanguage: scriptLanguage,
    );
  }

  String _buildPrompt({
    required String task,
    required String software,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> state,
    String? model,
    required String scriptLanguage,
  }) {
    final caps = jsonEncode(capabilities);
    final currentState = jsonEncode(state);
    final modelHint = model != null ? '\nMODEL: $model' : '';
    final langHint = _describeLanguage(scriptLanguage);
    final languageHint = responseLanguage != null && responseLanguage!.isNotEmpty
        ? '\n$responseLanguage'
        : '';

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
2. Script language: $langHint
3. Be precise - use exact API calls based on the capabilities listed above
4. Include error handling in the script where appropriate
5. The script should be self-contained and executable immediately

Output your response as JSON with these fields:
- "script": the actual script code to execute
- "explanation": brief explanation of what the script does (in Chinese)
- "scriptLanguage": the scripting language used
$languageHint
''';
  }

  String _describeLanguage(String lang) {
    switch (lang.toLowerCase()) {
      case 'javascript':
        return 'JavaScript (ExtendScript for Adobe apps, Plugin API for Figma)';
      case 'python':
        return 'Python (bpy for Blender, maya.cmds for Maya, Fusion API, Substance API, or general Python)';
      case 'lisp':
        return 'AutoLISP (AutoCAD native scripting)';
      case 'ruby':
        return 'Ruby (SketchUp API)';
      case 'lua':
        return 'Lua (Lightroom SDK)';
      case 'vba':
        return 'VBA (SolidWorks / Office macro automation)';
      case 'scad':
        return 'OpenSCAD script (CSG modeling)';
      case 'rest':
        return 'REST API (web service automation)';
      case 'cli':
        return 'CLI command (slicer / headless automation)';
      default:
        return lang;
    }
  }
}
