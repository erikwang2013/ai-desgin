import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// 每插件最近一次探测时间：缓存 TTL 按插件独立计算，
  /// 避免一次探测刷新所有插件的缓存。
  final Map<String, DateTime> _lastProbe = {};

  /// 带 key 的 execute 注册的运行中进程，[cancel] 据此 kill 中断。
  final Map<String, Process> _running = {};

  /// 已取消的 key 集合：cancel 先于进程注册或晚于退出时保持语义一致。
  final Set<String> _cancelled = {};

  LocalScriptExecutor({
    Map<String, ScriptExecutorConfig>? configs,
    this.probeTimeout = _probeTimeout,
    this.environment,
  }) : _configs = configs ?? _cliExecutables;

  /// 路径探测用环境变量快照：PATH 查找与安装目录 %VAR% 展开使用此环境，
  /// 测试可注入模拟各平台（如 Windows 的 ProgramFiles），null 用真实环境。
  final Map<String, String>? environment;

  /// PATH 与常见安装目录探测结果缓存（会话级）：避免每次执行重复扫描磁盘；
  /// 用户覆盖路径每次执行前重新读取，设置页修改即时生效。
  final Map<String, String?> _probeCache = {};

  Map<String, String> get _env => environment ?? Platform.environment;

  /// 探测超时：可注入以便测试覆盖超时 kill 路径。
  final Duration probeTimeout;

  static const _cacheTtl = Duration(seconds: 60);
  static const _probeTimeout = Duration(seconds: 5);
  static const _executeTimeout = Duration(seconds: 120);

  /// 输出缓冲上限：超过两倍上限时丢弃头部，只保留尾部 64KB，
  /// 防止失控脚本长输出把内存打爆。
  static const _maxOutputBytes = 64 * 1024;

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

  /// 解析可执行文件路径，解析顺序：① 用户覆盖路径（设置页）→
  /// ② PATH → ③ 常见安装目录探测 → ④ 兜底原 executable 名（启动失败
  /// 时由调用方走 manualFallback）。探测失败一律静默降级，不抛异常。
  /// PATH/安装目录结果会话内缓存；覆盖路径每次读取保证即时生效。
  Future<String> _resolveExecutable(
    String pluginId,
    ScriptExecutorConfig config,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final override = prefs.getString(executorPathOverrideKey(pluginId));
      if (override != null && override.trim().isNotEmpty) {
        final path = override.trim();
        if (File(path).existsSync()) return path;
      }
    } catch (_) {
      // 读取失败视为未配置覆盖，继续下一级探测。
    }
    final cached = _probeCache[pluginId];
    if (cached != null) return cached;
    String? resolved;
    try {
      if (!File(config.executable).isAbsolute) {
        resolved = lookupExecutableInPath(config.executable, _env['PATH'] ?? '');
        resolved ??= _probeInstallDirs(config);
      }
    } catch (_) {
      resolved = null;
    }
    final effective = resolved ?? config.executable;
    _probeCache[pluginId] = effective;
    return effective;
  }

  /// 常见安装目录探测：逐候选展开环境变量并用通配符首匹配（目录条目
  /// 排序后取首个），全部落空返回 null。
  String? _probeInstallDirs(ScriptExecutorConfig config) {
    final patterns = config.installPaths[Platform.operatingSystem];
    if (patterns == null || patterns.isEmpty) return null;
    for (final raw in patterns) {
      final expanded = expandEnvPattern(raw, _env);
      if (expanded == null) continue; // 环境变量缺失，跳过该候选
      final hit = globFirstMatch(expanded);
      if (hit != null) return hit;
    }
    return null;
  }

  /// 在 PATH 目录序列中查找可执行文件（Windows 附加 PATHEXT 扩展名）。
  @visibleForTesting
  static String? lookupExecutableInPath(String executable, String pathEnv) {
    if (pathEnv.isEmpty) return null;
    final separators = Platform.isWindows ? ';' : ':';
    final extensions = Platform.isWindows
        ? (Platform.environment['PATHEXT'] ?? '.EXE;.BAT;.CMD')
            .split(';')
            .where((e) => e.isNotEmpty)
            .toList()
        : const <String>[];
    for (final dir in pathEnv.split(separators)) {
      if (dir.isEmpty) continue;
      final candidate = File('$dir${Platform.pathSeparator}$executable');
      if (_isExecutableFile(candidate.path)) return candidate.path;
      for (final ext in extensions) {
        final withExt = File('${candidate.path}$ext');
        if (_isExecutableFile(withExt.path)) return withExt.path;
      }
    }
    return null;
  }

  /// 展开模式中的 %VAR% 环境变量；任一变量缺失时返回 null（候选跳过）。
  @visibleForTesting
  static String? expandEnvPattern(String pattern, Map<String, String> env) {
    var missing = false;
    final expanded = pattern.replaceAllMapped(
      RegExp(r'%([^%]+)%'),
      (m) {
        final value = env[m.group(1)!];
        if (value == null || value.isEmpty) {
          missing = true;
          return m.group(0)!;
        }
        return value;
      },
    );
    return missing ? null : expanded;
  }

  /// 对可能含 `*` 通配符的路径模式做首匹配：逐段扫描目录（条目按名称
  /// 排序保证确定性），返回第一个存在且可执行的完整文件路径。
  @visibleForTesting
  static String? globFirstMatch(String pattern) {
    final segments = pattern.split(Platform.pathSeparator);
    if (segments.isEmpty) return null;
    List<String> bases;
    var index = 1;
    if (segments.first.isEmpty) {
      // POSIX 绝对路径 /a/b → ['', 'a', 'b']，根为 /。
      bases = const [''];
    } else if (segments.first.endsWith(':')) {
      // Windows 盘符 C:\a\b → ['C:', 'a', 'b']。
      bases = ['${segments.first}${Platform.pathSeparator}'];
    } else {
      bases = [segments.first];
    }
    for (; index < segments.length; index++) {
      final matcher = _segmentMatcher(segments[index]);
      final isLast = index == segments.length - 1;
      final next = <String>[];
      for (final base in bases) {
        try {
          final dir = Directory(base.isEmpty ? '/' : base);
          if (!dir.existsSync()) continue;
          final entries = dir.listSync(followLinks: false).toList()
            ..sort((a, b) => a.path.compareTo(b.path));
          for (final entry in entries) {
            final name =
                entry.path.split(Platform.pathSeparator).last;
            if (!matcher.hasMatch(name)) continue;
            if (isLast) {
              if (entry is File && _isExecutableFile(entry.path)) {
                return entry.path;
              }
            } else if (entry is Directory) {
              next.add(entry.path);
            }
          }
        } catch (_) {}
      }
      if (next.isEmpty) return null;
      bases = next;
    }
    return bases.isEmpty ? null : bases.first;
  }

  /// 段级通配匹配：`*` 匹配任意字符，其余字符按字面转义（大小写不敏感）。
  static RegExp _segmentMatcher(String segment) {
    final buffer = StringBuffer('^');
    for (final ch in segment.split('')) {
      if (ch == '*') {
        buffer.write('.*');
      } else if (RegExp(r'[\\^$.|?+()[\]{}]').hasMatch(ch)) {
        buffer.write('\\$ch');
      } else {
        buffer.write(ch);
      }
    }
    buffer.write(r'$');
    return RegExp(buffer.toString(), caseSensitive: false);
  }

  /// 文件存在且（POSIX 下）具有任一执行位。
  static bool _isExecutableFile(String path) {
    try {
      final stat = FileStat.statSync(path);
      if (stat.type != FileSystemEntityType.file) return false;
      // 0111（octal）：属主/组/其他任一执行位。
      return Platform.isWindows || stat.mode & 0x49 != 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkAvailable(String pluginId) async {
    final config = _configs[pluginId];
    if (config == null || !config.supportsPlatform(Platform.operatingSystem)) {
      return false;
    }
    final now = DateTime.now();
    final last = _lastProbe[pluginId];
    if (last != null &&
        now.difference(last) < _cacheTtl &&
        _availableCache.containsKey(pluginId)) {
      return _availableCache[pluginId]!;
    }
    var available = false;
    Process? process;
    try {
      process = await Process.start(
        await _resolveExecutable(pluginId, config),
        config.probeArgs,
        runInShell: false,
      );
      final exitCode = await process.exitCode.timeout(probeTimeout);
      available = exitCode == 0;
    } catch (_) {
      available = false;
    } finally {
      // Process.run 的 timeout 不会终止子进程：超时后手动 kill，避免孤儿进程。
      process?.kill();
    }
    _availableCache[pluginId] = available;
    _lastProbe[pluginId] = now;
    return available;
  }

  /// 执行脚本。key 非空时注册进程并可用 [cancel] 中断；所有 CLI 调用均为
  /// 参数化（runInShell: false），脚本内容中的 &/| 等字符不会被 shell 解释。
  /// 可执行文件路径按 覆盖路径 → PATH → 常见安装目录 顺序解析，全部落空
  /// 时保持原 executable 名启动，失败即走 manualFallback。
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
    // 输出缓冲与排空 future 声明在外层：超时分支也需要显式等待流结束。
    final stdoutBytes = <int>[];
    final stderrBytes = <int>[];
    late final Future<void> stdoutDone;
    late final Future<void> stderrDone;
    try {
      tempDir = await Directory.systemTemp.createTemp('ai_design_');
      final scriptPath = await _writeScriptFile(tempDir, config, script);
      final args = config.args(scriptPath, tempDir);
      final executable = await _resolveExecutable(pluginId, config);

      process = await Process.start(
        executable,
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
      // Windows 下 Blender 等软件可能输出 GBK 等非 UTF-8 文本，缓冲字节后按编码解码；
      // 缓冲有上限（保留尾部 64KB），防止长输出 OOM。
      stdoutDone = _drainOutput(process.stdout, stdoutBytes);
      stderrDone = _drainOutput(process.stderr, stderrBytes);
      final exitCode = await process.exitCode.timeout(_executeTimeout);
      if (key != null && _cancelled.remove(key)) {
        return ScriptResult.failure(error: '$pluginName 脚本已取消');
      }
      // 进程已退出、管道即将关闭；等待排空完成，极端情况下兜底超时防卡死。
      await Future.wait([stdoutDone, stderrDone])
          .timeout(const Duration(seconds: 5), onTimeout: () => const []);
      final output = decodeConsoleOutput(stdoutBytes).trim();
      final stderr = decodeConsoleOutput(stderrBytes).trim();
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
      _lastProbe[pluginId] = DateTime.now();
      return ScriptResult.success(
        output: _fallbackMessage(pluginName, script, detail: e.message),
        manualFallback: true,
      );
    } on TimeoutException {
      // 超时是放弃 Future 而非杀进程，挂死的 Blender/FreeCAD 会继续运行。
      // kill 后管道关闭，显式等待输出流结束，避免悬挂的流订阅残留。
      process?.kill();
      await Future.wait([stdoutDone, stderrDone])
          .timeout(const Duration(seconds: 5), onTimeout: () => const []);
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

  /// 输出流排空：字节缓冲超过两倍上限时丢弃头部只保留尾部 [_maxOutputBytes]；
  /// 进程被 kill 后管道关闭，此 future 随即完成，无悬挂订阅。
  Future<void> _drainOutput(Stream<List<int>> stream, List<int> buffer) async {
    await for (final chunk in stream) {
      buffer.addAll(chunk);
      if (buffer.length > _maxOutputBytes * 2) {
        buffer.removeRange(0, buffer.length - _maxOutputBytes);
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
