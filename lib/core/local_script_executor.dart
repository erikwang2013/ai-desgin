import 'dart:async';
import 'dart:io';
import '../models/plugin.dart';

/// CLI 可执行命令映射：这些软件支持命令行执行生成的脚本。
/// 切片器（Cura/PrusaSlicer 等）的 CLI 只接受模型文件或 key=value 设置，
/// 无法执行生成脚本，故不列入——保持「生成脚本，提示手动执行」的诚实回退。
const Map<String, String> _cliExecutables = {
  'blender': 'blender',
  'freecad': 'freecad',
  'openscad': 'openscad',
};

class LocalScriptExecutor {
  static LocalScriptExecutor? instance;

  final Map<String, bool> _availableCache = {};
  DateTime? _lastCacheCheck;

  static const _cacheTtl = Duration(seconds: 60);
  static const _probeTimeout = Duration(seconds: 5);
  static const _executeTimeout = Duration(seconds: 120);

  bool hasCommand(String pluginId) => _cliExecutables.containsKey(pluginId);

  Future<bool> checkAvailable(String pluginId) async {
    final exe = _cliExecutables[pluginId];
    if (exe == null) return false;
    final now = DateTime.now();
    if (_lastCacheCheck != null &&
        now.difference(_lastCacheCheck!) < _cacheTtl &&
        _availableCache.containsKey(pluginId)) {
      return _availableCache[pluginId]!;
    }
    var available = false;
    try {
      final result = await Process.run(
        exe,
        ['--version'],
        runInShell: Platform.isWindows,
      ).timeout(_probeTimeout);
      available = result.exitCode == 0;
    } catch (_) {
      available = false;
    }
    _availableCache[pluginId] = available;
    _lastCacheCheck = now;
    return available;
  }

  Future<ScriptResult> execute(
    String pluginId,
    String pluginName,
    String script,
  ) async {
    final exe = _cliExecutables[pluginId];
    if (exe == null) {
      return ScriptResult.success(output: _fallbackMessage(pluginName, script));
    }

    Directory? tempDir;
    try {
      tempDir = await Directory.systemTemp.createTemp('ai_design_');
      final scriptPath = await _writeScriptFile(tempDir, pluginId, script);
      final args = _buildArgs(pluginId, scriptPath, tempDir);

      final result = await Process.run(
        exe,
        args,
        runInShell: Platform.isWindows,
      ).timeout(_executeTimeout);

      final output = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();
      if (result.exitCode == 0) {
        return ScriptResult.success(
          output: '$pluginName 脚本执行成功\n${output.isEmpty ? stderr : output}',
        );
      }
      return ScriptResult.failure(
        error: '$pluginName 脚本执行失败 (exit ${result.exitCode})\n$stderr',
      );
    } on ProcessException catch (e) {
      _availableCache[pluginId] = false;
      return ScriptResult.success(
        output: _fallbackMessage(pluginName, script, detail: e.message),
      );
    } on TimeoutException {
      return ScriptResult.failure(
        error: '$pluginName 脚本执行超时（${_executeTimeout.inSeconds}s）',
      );
    } finally {
      if (tempDir != null) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  Future<String> _writeScriptFile(
    Directory tempDir,
    String pluginId,
    String script,
  ) async {
    final ext = switch (pluginId) {
      'blender' || 'freecad' => 'py',
      'openscad' => 'scad',
      _ => 'txt',
    };
    final file = File('${tempDir.path}/script.$ext');
    await file.writeAsString(script);
    return file.path;
  }

  List<String> _buildArgs(String pluginId, String scriptPath, Directory tempDir) {
    switch (pluginId) {
      case 'blender':
        return ['--background', '--python', scriptPath];
      case 'freecad':
        return ['-c', 'exec(open(r"$scriptPath", encoding="utf-8").read())'];
      case 'openscad':
        return ['-o', '${tempDir.path}/out.stl', scriptPath];
      default:
        return [scriptPath];
    }
  }

  String _fallbackMessage(String pluginName, String script, {String? detail}) {
    final hint = detail != null && detail.isNotEmpty ? '\n($detail)' : '';
    return '未检测到 $pluginName 可执行文件，脚本已生成，请安装并启动软件后手动执行:$hint\n\n$script';
  }
}
