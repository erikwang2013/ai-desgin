import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'agent_backend.dart';
import 'text_codec.dart';

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

/// 终止进程：kill（SIGTERM）后等待退出；POSIX 下 5 秒未退出升级 SIGKILL。
/// Windows 的 kill() 本身即 TerminateProcess（强杀），无需升级。
Future<void> terminateProcess(Process process) async {
  process.kill();
  if (Platform.isWindows) {
    await process.exitCode.catchError((_) => -1);
    return;
  }
  try {
    await process.exitCode.timeout(const Duration(seconds: 5));
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
  }
}

class CCRunner implements AgentBackend {
  /// 内置 Claude Code 固定版本（npm 安装目标）。
  static const pinnedClaudeVersion = '2.1.143';

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

  @override
  String get id => 'claude';

  @override
  String get displayName => 'Claude Code';

  @override
  String? get defaultModel => null;

  /// 已安装 Claude Code 的版本（取前三个点分数字段），未安装返回 null。
  static Future<String?> installedVersion() async {
    try {
      final result = await Process.run(
        'claude',
        ['--version'],
      ).timeout(const Duration(seconds: 10));
      if (result.exitCode != 0) return null;
      final match = RegExp(r'(\d+)\.(\d+)\.(\d+)')
          .firstMatch((result.stdout as String).trim());
      if (match == null) return null;
      return '${match.group(1)}.${match.group(2)}.${match.group(3)}';
    } catch (_) {
      return null;
    }
  }

  /// 通过 npm 全局安装固定版本 Claude Code。
  static Future<bool> installPinnedVersion() async {
    try {
      final result = await Process.run(
        'npm',
        ['install', '-g', '@anthropic-ai/claude-code@$pinnedClaudeVersion'],
        runInShell: Platform.isWindows,
      ).timeout(const Duration(minutes: 10));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Kill the process for [key]; without a key, kill all tracked processes.
  @override
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
  @override
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
  @override
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

    final taskKey = key ?? 'default';
    Process? process;
    try {
      process = await Process.start(
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
      _processes.remove(taskKey)?.kill();
      _processes[taskKey] = process;

      // 启动即并发消费 stdout/stderr，避免子进程边读边写时 64KB 管道死锁。
      // Windows 控制台可能输出 GBK 等非 UTF-8 文本，缓冲字节后按编码解码。
      // 缓冲有上限（保留尾部 8MB），防止失控长输出耗尽内存。
      final stdoutBuffer = CappedOutputBuffer();
      final stderrBuffer = CappedOutputBuffer();
      final stdoutFuture = process.stdout.forEach(stdoutBuffer.add);
      final stderrFuture = process.stderr.forEach(stderrBuffer.add);
      process.stdin.write(prompt);
      await process.stdin.flush();
      await process.stdin.close();

      final exitCode = await process.exitCode.timeout(timeout);
      await Future.wait([stdoutFuture, stderrFuture]).timeout(timeout);
      // 同 key 可能已被新任务替换（replace 语义），只移除自己注册的实例，
      // 避免旧任务收尾时误删新任务的进程，导致 cancel 失效。
      if (identical(_processes[taskKey], process)) {
        _processes.remove(taskKey);
      }
      final output = decodeConsoleOutput(stdoutBuffer.takeBytes());
      var errors = decodeConsoleOutput(stderrBuffer.takeBytes());

      // 非零退出（API key 错误、崩溃）时 stdout 里的文本不是生成脚本。
      if (exitCode != 0) {
        if (stderrBuffer.truncated) errors = '$errors\n…[stderr 截断]';
        return CCResult.failure(
          'Claude Code exited with code $exitCode'
          '${errors.isNotEmpty ? ': ${errors.trim()}' : ''}',
        );
      }

      // JSON 解析需要完整输出：截断后无法可靠解析，明确报错而非误用残缺结果。
      if (stdoutBuffer.truncated) {
        return CCResult.failure(
          'Claude Code 输出超过 ${kMaxAgentOutputBytes ~/ (1024 * 1024)}MB 上限，已截断',
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
      // Kill the subprocess on timeout/error to avoid orphaned Claude CLI processes。
      // 只清理自己注册的实例：同 key 已被替换时不误杀新任务。
      if (identical(_processes[taskKey], process)) {
        _processes.remove(taskKey);
      }
      if (process != null) {
        await terminateProcess(process);
      }
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
