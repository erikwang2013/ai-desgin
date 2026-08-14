import 'dart:async';
import 'dart:io';
import '../models/plugin.dart';
import 'script_executor_configs.dart';
import 'text_codec.dart';

/// CLI 可执行命令注册表：这些软件支持命令行执行生成的脚本。
/// 切片器（Cura/PrusaSlicer）的 CLI 只接受模型文件路径直传 + 参数化
/// 切片，见 script_executor_configs.dart 中对应配置。
final Map<String, ScriptExecutorConfig> _cliExecutables = {
  for (final config in defaultExecutorConfigs()) config.pluginId: config,
};

class LocalScriptExecutor {
  static LocalScriptExecutor? instance;

  final Map<String, bool> _availableCache = {};
  DateTime? _lastCacheCheck;

  static const _cacheTtl = Duration(seconds: 60);
  static const _probeTimeout = Duration(seconds: 5);
  static const _executeTimeout = Duration(seconds: 120);

  /// 可验证产物扩展名白名单（小写，不含点）。
  static const _artifactExtensions = {
    'png', 'jpg', 'jpeg', 'webp', 'bmp', 'tiff',
    'svg', 'pdf', 'gcode', 'stl', '3mf', 'obj',
    'dwg', 'dxf', 'step', 'stp', 'fbx', 'blend',
    'ai', 'skp', 'psd', 'glb', 'gltf',
  };

  bool hasCommand(String pluginId) => _cliExecutables.containsKey(pluginId);

  Future<bool> checkAvailable(String pluginId) async {
    final config = _cliExecutables[pluginId];
    if (config == null || !config.supportsPlatform(Platform.operatingSystem)) {
      return false;
    }
    final now = DateTime.now();
    if (_lastCacheCheck != null &&
        now.difference(_lastCacheCheck!) < _cacheTtl &&
        _availableCache.containsKey(pluginId)) {
      return _availableCache[pluginId]!;
    }
    var available = false;
    try {
      final result = await Process.run(
        config.executable,
        config.probeArgs,
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
    final config = _cliExecutables[pluginId];
    if (config == null || !config.supportsPlatform(Platform.operatingSystem)) {
      return ScriptResult.success(output: _fallbackMessage(pluginName, script));
    }

    Directory? tempDir;
    Process? process;
    try {
      tempDir = await Directory.systemTemp.createTemp('ai_design_');
      final scriptPath = await _writeScriptFile(tempDir, config, script);
      final args = config.args(scriptPath, tempDir);

      process = await Process.start(
        config.executable,
        args,
        environment: {...Platform.environment, 'AI_DESIGN_SCRIPT': scriptPath},
        runInShell: Platform.isWindows,
      );
      // 启动即并发消费 stdout/stderr，超时 kill 后管道随即关闭。
      // Windows 下 Blender 等软件可能输出 GBK 等非 UTF-8 文本，缓冲字节后按编码解码。
      final stdoutFuture =
          process.stdout.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
      final stderrFuture =
          process.stderr.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
      final exitCode = await process.exitCode.timeout(_executeTimeout);
      final output = decodeConsoleOutput(await stdoutFuture).trim();
      final stderr = decodeConsoleOutput(await stderrFuture).trim();
      if (exitCode == 0) {
        final artifacts = await _collectArtifacts(tempDir);
        return ScriptResult.success(
          output: '$pluginName 脚本执行成功\n${output.isEmpty ? stderr : output}',
          artifacts: artifacts,
        );
      }
      return ScriptResult.failure(
        error: '$pluginName 脚本执行失败 (exit $exitCode)\n$stderr',
      );
    } on ProcessException catch (e) {
      _availableCache[pluginId] = false;
      _lastCacheCheck = DateTime.now();
      return ScriptResult.success(
        output: _fallbackMessage(pluginName, script, detail: e.message),
      );
    } on TimeoutException {
      // 超时是放弃 Future 而非杀进程，挂死的 Blender/FreeCAD 会继续运行。
      process?.kill();
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
    ScriptExecutorConfig config,
    String script,
  ) async {
    final file = File('${tempDir.path}/script.${config.scriptExtension}');
    await file.writeAsString(script);
    return file.path;
  }

  /// 收集临时目录中白名单扩展名的产物文件。临时目录执行完即删除，
  /// 故先复制到持久目录再返回路径，保证 ArtifactVerifier 的存在性检查可验证。
  Future<List<String>> _collectArtifacts(Directory tempDir) async {
    final artifactsDir =
        Directory('${Directory.systemTemp.path}/ai_design_artifacts');
    try {
      await artifactsDir.create(recursive: true);
    } catch (_) {
      return const [];
    }
    final paths = <String>[];
    try {
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is! File) continue;
        final dot = entity.path.lastIndexOf('.');
        if (dot < 0) continue;
        final ext = entity.path.substring(dot + 1).toLowerCase();
        if (!_artifactExtensions.contains(ext)) continue;
        final dest = '${artifactsDir.path}/'
            '${DateTime.now().microsecondsSinceEpoch}_${entity.uri.pathSegments.last}';
        try {
          await entity.copy(dest);
          paths.add(dest);
        } catch (_) {}
      }
    } catch (_) {}
    return paths;
  }

  String _fallbackMessage(String pluginName, String script, {String? detail}) {
    final hint = detail != null && detail.isNotEmpty ? '\n($detail)' : '';
    return '未检测到 $pluginName 可执行文件，脚本已生成，请安装并启动软件后手动执行:$hint\n\n$script';
  }
}
