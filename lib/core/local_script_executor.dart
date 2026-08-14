import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

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

  final Map<String, ScriptExecutorConfig> _configs;
  final Map<String, bool> _availableCache = {};
  DateTime? _lastCacheCheck;

  /// 带 key 的 execute 注册的运行中进程，[cancel] 据此 kill 中断。
  final Map<String, Process> _running = {};

  /// 已取消的 key 集合：cancel 先于进程注册或晚于退出时保持语义一致。
  final Set<String> _cancelled = {};

  LocalScriptExecutor({Map<String, ScriptExecutorConfig>? configs})
      : _configs = configs ?? _cliExecutables;

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

  /// 单产物大小上限（50MB）与单次收集总量上限（200MB），超限跳过。
  static const _maxArtifactSize = 50 * 1024 * 1024;
  static const _maxArtifactTotal = 200 * 1024 * 1024;

  /// 持久产物目录保留时长：超过 7 天的旧产物在下次收集时顺带清理。
  static const _artifactRetention = Duration(days: 7);

  bool hasCommand(String pluginId) => _configs.containsKey(pluginId);

  Future<bool> checkAvailable(String pluginId) async {
    final config = _configs[pluginId];
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
        runInShell: false,
      ).timeout(_probeTimeout);
      available = result.exitCode == 0;
    } catch (_) {
      available = false;
    }
    _availableCache[pluginId] = available;
    _lastCacheCheck = now;
    return available;
  }

  /// 执行脚本。key 非空时注册进程并可用 [cancel] 中断；所有 CLI 调用均为
  /// 参数化（runInShell: false），脚本内容中的 &/| 等字符不会被 shell 解释。
  Future<ScriptResult> execute(
    String pluginId,
    String pluginName,
    String script, {
    String? key,
  }) async {
    final config = _configs[pluginId];
    if (config == null || !config.supportsPlatform(Platform.operatingSystem)) {
      return ScriptResult.success(
        output: _fallbackMessage(pluginName, script),
        manualFallback: true,
      );
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
        runInShell: false,
      );
      if (key != null) {
        _running[key] = process;
        if (_cancelled.contains(key)) {
          // cancel 先于进程注册（Process.start 等待期间）已调用，立即终止。
          process.kill();
        }
      }
      // 启动即并发消费 stdout/stderr，超时 kill 后管道随即关闭。
      // Windows 下 Blender 等软件可能输出 GBK 等非 UTF-8 文本，缓冲字节后按编码解码。
      final stdoutFuture =
          process.stdout.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
      final stderrFuture =
          process.stderr.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
      final exitCode = await process.exitCode.timeout(_executeTimeout);
      if (key != null && _cancelled.remove(key)) {
        return ScriptResult.failure(error: '$pluginName 脚本已取消');
      }
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
        manualFallback: true,
      );
    } on TimeoutException {
      // 超时是放弃 Future 而非杀进程，挂死的 Blender/FreeCAD 会继续运行。
      process?.kill();
      return ScriptResult.failure(
        error: '$pluginName 脚本执行超时（${_executeTimeout.inSeconds}s）',
      );
    } finally {
      if (key != null) {
        _running.remove(key);
        _cancelled.remove(key);
      }
      if (tempDir != null) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  /// 取消指定 key 的运行中进程。key 无条件记入取消集合，保证 Process.start
  /// 尚未完成注册期间的取消不被丢失；进程已存在时立即 kill。
  void cancel(String key) {
    _cancelled.add(key);
    final process = _running[key];
    if (process != null) {
      process.kill();
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
  /// 安全约束：不跟随符号链接、复制前 realpath 校验产物必须位于临时目录内、
  /// 单文件/总量超限跳过；持久目录顺带清理超过 7 天的旧产物。
  Future<List<String>> _collectArtifacts(Directory tempDir) async {
    final artifactsDir =
        Directory('${Directory.systemTemp.path}/ai_design_artifacts');
    try {
      await artifactsDir.create(recursive: true);
    } catch (_) {
      return const [];
    }
    await _cleanupStaleArtifacts(artifactsDir);
    final String tempReal;
    try {
      tempReal = await tempDir.resolveSymbolicLinks();
    } catch (_) {
      return const [];
    }
    final paths = <String>[];
    var totalBytes = 0;
    try {
      await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final dot = entity.path.lastIndexOf('.');
        if (dot < 0) continue;
        final ext = entity.path.substring(dot + 1).toLowerCase();
        if (!_artifactExtensions.contains(ext)) continue;
        try {
          // 符号链接目标在临时目录外的一律跳过，防止收集越界读取。
          final real = await entity.resolveSymbolicLinks();
          if (!real.startsWith('$tempReal${Platform.pathSeparator}')) continue;
          final size = await entity.length();
          if (size > _maxArtifactSize || totalBytes + size > _maxArtifactTotal) {
            debugPrint('跳过产物（超限 ${size ~/ 1024}KB）: ${entity.path}');
            continue;
          }
          totalBytes += size;
          final dest = '${artifactsDir.path}/'
              '${DateTime.now().microsecondsSinceEpoch}_${entity.uri.pathSegments.last}';
          await entity.copy(dest);
          paths.add(dest);
        } catch (_) {}
      }
    } catch (_) {}
    return paths;
  }

  /// 删除持久产物目录中超过 [_artifactRetention] 的旧文件（仅写入时顺带检查）。
  Future<void> _cleanupStaleArtifacts(Directory artifactsDir) async {
    final cutoff = DateTime.now().subtract(_artifactRetention);
    try {
      await for (final entity in artifactsDir.list(followLinks: false)) {
        if (entity is! File) continue;
        try {
          if (entity.statSync().modified.isBefore(cutoff)) {
            await entity.delete();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  String _fallbackMessage(String pluginName, String script, {String? detail}) {
    final hint = detail != null && detail.isNotEmpty ? '\n($detail)' : '';
    return '未检测到 $pluginName 可执行文件，脚本已生成，请安装并启动软件后手动执行:$hint\n\n$script';
  }
}
