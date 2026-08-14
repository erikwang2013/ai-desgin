import 'dart:developer' as dev;
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:yaml/yaml.dart';
import '../bridge/api.dart' as bridge_api;
import '../bridge/frb_generated.dart';
import '../plugin_sdk/design_plugin.dart';
import '../models/plugin.dart';
import '../models/software_capabilities.dart';
import '../models/session.dart';
import 'version.dart' show appVersion;
import 'builtin_plugins.dart' show builtInPlugins;

class PluginManager {
  final Map<String, DesignPlugin> _plugins = {};

  /// 外部导入插件的包目录（zip 解压位置），用于导出/清理。
  final Map<String, String> _externalPackageDirs = {};

  /// Rust 内核是否成功加载（FFI 失败时为 false，走 Dart 常量回退）。
  bool rustConnected = false;

  /// Rust 注册表为权威源；FFI 不可用时回退到 Dart 常量（builtin_plugins.dart）。
  static Future<PluginManager> create() async {
    final pm = PluginManager();
    try {
      await RustLib.init();
      final json = await bridge_api.getBuiltinPlugins();
      final list = jsonDecode(json) as List;
      for (final item in list) {
        pm.register(BuiltInPlugin.fromRustJson(item as Map<String, dynamic>));
      }
      pm.rustConnected = true;
    } catch (e) {
      dev.log('Rust FFI unavailable, falling back to Dart registry: $e',
          name: 'PluginManager');
      for (final p in builtInPlugins) {
        pm.register(p);
      }
    }
    return pm;
  }

  void register(DesignPlugin plugin) {
    if (_plugins.containsKey(plugin.id)) {
      dev.log('Plugin "${plugin.id}" already registered, overwriting',
          name: 'PluginManager');
    }
    _plugins[plugin.id] = plugin;
  }

  DesignPlugin? get(String id) => _plugins[id];

  List<DesignPlugin> getAll() => _plugins.values.toList();

  List<DesignPlugin> getByCategory(DesignCategory category) {
    return _plugins.values.where((p) => p.category == category).toList();
  }

  void unregister(String id) {
    _plugins.remove(id);
  }

  /// 注册外部导入的脚本型插件（zip 包 → manifest + 脚本文件集合）。
  /// 外部插件不动态编译/加载 Dart 代码，注册为可执行脚本型插件。
  void registerExternal(ExternalPluginManifest manifest, String packageDir) {
    if (manifest.id.trim().isEmpty) {
      throw ArgumentError.value(manifest.id, 'id', '外部插件清单必须包含非空 id');
    }
    register(ExternalScriptPlugin(manifest: manifest, packageDir: packageDir));
    _externalPackageDirs[manifest.id] = packageDir;
  }

  /// 外部插件包的磁盘目录；内置插件返回 null。
  String? externalPackageDir(String id) => _externalPackageDirs[id];

  Future<void> initializeAll(PluginContext ctx) async {
    // 单个插件初始化失败不阻止其余插件（快速失败会让整批停摆）。
    await Future.wait(_plugins.values.map((p) async {
      try {
        await p.initialize(ctx);
      } catch (e) {
        dev.log('Plugin "${p.id}" initialize failed: $e', name: 'PluginManager');
      }
    }));
  }

  Future<void> disposeAll() async {
    final plugins = List<DesignPlugin>.from(_plugins.values);
    for (final plugin in plugins) {
      await plugin.dispose();
    }
    _plugins.clear();
    _externalPackageDirs.clear();
  }
}

DesignCategory categoryFromString(String? raw) {
  return switch (raw) {
    'ad' => DesignCategory.ad,
    'industrial' => DesignCategory.industrial,
    'threeD' => DesignCategory.threeD,
    'arch' => DesignCategory.arch,
    'interior' => DesignCategory.interior,
    _ => DesignCategory.web,
  };
}

/// 外部插件包清单：元数据（名称/分类/能力/脚本语言）+ 可执行脚本文件集合。
class ExternalPluginManifest {
  final String id;
  final String name;
  final String version;
  final String scriptLanguage;
  final String description;
  final DesignCategory category;
  final SoftwareCapabilities capabilities;
  final List<String> scripts;

  const ExternalPluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.scriptLanguage,
    this.description = '',
    this.category = DesignCategory.web,
    this.capabilities = const SoftwareCapabilities(actions: [], fileFormats: []),
    this.scripts = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'script_language': scriptLanguage,
    if (description.isNotEmpty) 'description': description,
    'category': category.name,
    'capabilities': capabilities.toJson(),
    'scripts': scripts,
  };

  factory ExternalPluginManifest.fromJson(Map<String, dynamic> json) {
    final caps = json['capabilities'] as Map<String, dynamic>? ?? const {};
    return ExternalPluginManifest(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? appVersion,
      scriptLanguage: json['script_language'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: categoryFromString(json['category'] as String?),
      capabilities: SoftwareCapabilities(
        actions: (caps['actions'] as List?)?.cast<String>() ?? const [],
        fileFormats: (caps['file_formats'] as List?)?.cast<String>() ?? const [],
      ),
      scripts: (json['scripts'] as List?)?.cast<String>() ?? const [],
    );
  }

  /// 解析 zip 包内的 pubspec.yaml（name/version/description + 可选 design_plugin 节）。
  factory ExternalPluginManifest.fromYaml(String text) {
    final doc = loadYaml(text);
    if (doc is! Map) {
      throw const FormatException('Invalid pubspec.yaml');
    }
    final dp = doc['design_plugin'];
    final dpMap = dp is Map ? dp : const <dynamic, dynamic>{};
    final caps = dpMap['capabilities'];
    final capsMap = caps is Map ? caps : const <dynamic, dynamic>{};
    return ExternalPluginManifest(
      id: doc['name']?.toString() ?? '',
      name: doc['name']?.toString() ?? '',
      version: doc['version']?.toString() ?? appVersion,
      scriptLanguage: dpMap['script_language']?.toString() ?? '',
      description: doc['description']?.toString() ?? '',
      category: categoryFromString(dpMap['category']?.toString()),
      capabilities: SoftwareCapabilities(
        actions: (capsMap['actions'] as List?)?.cast<String>() ?? const [],
        fileFormats: (capsMap['file_formats'] as List?)?.cast<String>() ?? const [],
      ),
      scripts: (dpMap['scripts'] as List?)?.cast<String>() ?? const [],
    );
  }
}

/// 外部脚本型插件：包 = 元数据 + 脚本文件集合，不动态加载 Dart 代码。
class ExternalScriptPlugin implements DesignPlugin {
  final ExternalPluginManifest manifest;
  final String packageDir;

  ExternalScriptPlugin({required this.manifest, required this.packageDir});

  @override
  String get id => manifest.id;
  @override
  String get name => manifest.name;
  @override
  String get version => manifest.version;
  @override
  DesignCategory get category => manifest.category;
  @override
  String get scriptLanguage => manifest.scriptLanguage;
  @override
  SoftwareCapabilities get capabilities => manifest.capabilities;

  @override
  Future<bool> initialize(PluginContext ctx) async => true;

  @override
  Future<void> dispose() async {}

  @override
  Future<ConnectionStatus> checkConnection() async => ConnectionStatus.disconnected;

  @override
  Future<bool> connect(ConnectionConfig config) async => false;

  @override
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async {
    return ScriptResult.success(
      output: '外部脚本型插件 "${manifest.name}"：脚本文件位于 $packageDir。'
          '${script.isEmpty ? '' : '\n\n待执行脚本:\n$script'}',
      metadata: {'package_dir': packageDir, 'scripts': manifest.scripts},
    );
  }

  @override
  Future<ScriptResult> preview(String script) async {
    return ScriptResult.success(output: '[预览] $script');
  }

  @override
  Future<SoftwareState> getCurrentState() async => const SoftwareState();
}

/// zip 插件包导入/导出编解码。
/// 包结构：根目录含 plugin.json（或 pubspec.yaml）+ 可选脚本文件。
class PluginPackageCodec {
  /// 解压 zipPath 到 `destRoot/<id>`，识别并解析 manifest。
  static Future<({ExternalPluginManifest manifest, String packageDir})> importFromZip(
    String zipPath,
    String destRoot,
  ) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? manifestFile;
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final base = _baseName(f.name);
      if (base == 'plugin.json' || base == 'pubspec.yaml') {
        manifestFile = f;
        break;
      }
    }
    if (manifestFile == null) {
      throw const FormatException('zip 内未找到 plugin.json 或 pubspec.yaml 清单');
    }

    final rootPrefix = _rootOf(manifestFile.name);
    final text = utf8.decode(_bytes(manifestFile.content));
    final manifest = _baseName(manifestFile.name) == 'plugin.json'
        ? ExternalPluginManifest.fromJson(jsonDecode(text) as Map<String, dynamic>)
        : ExternalPluginManifest.fromYaml(text);
    if (manifest.id.trim().isEmpty) {
      throw const FormatException('插件清单缺少 id/name');
    }

    final packageDir = '$destRoot/${manifest.id}';
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final rel = _relativeUnder(f.name, rootPrefix);
      if (rel == null || rel.split('/').contains('..')) continue;
      final out = File('$packageDir/$rel');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(_bytes(f.content));
    }

    final scripts = manifest.scripts.isNotEmpty
        ? manifest.scripts
        : archive.files
            .where((f) => f.isFile && f.name != manifestFile!.name)
            .map((f) => _relativeUnder(f.name, rootPrefix))
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toList();
    return (
      manifest: ExternalPluginManifest(
        id: manifest.id,
        name: manifest.name,
        version: manifest.version,
        scriptLanguage: manifest.scriptLanguage,
        description: manifest.description,
        category: manifest.category,
        capabilities: manifest.capabilities,
        scripts: scripts,
      ),
      packageDir: packageDir,
    );
  }

  /// 导出插件为 zip：plugin.json +（外部插件的）脚本文件。
  static Future<void> exportToZip(
    DesignPlugin plugin, {
    String? packageDir,
    String? description,
    required String zipPath,
  }) async {
    final scripts = packageDir == null ? const <String>[] : _listScriptFiles(packageDir);
    final manifest = ExternalPluginManifest(
      id: plugin.id,
      name: plugin.name,
      version: plugin.version,
      scriptLanguage: plugin.scriptLanguage,
      description: description ?? '',
      category: plugin.category,
      capabilities: plugin.capabilities,
      scripts: scripts,
    );
    final archive = Archive();
    archive.addFile(
      ArchiveFile('plugin.json', 0, utf8.encode(jsonEncode(manifest.toJson()))),
    );
    if (packageDir != null) {
      final base = Directory(packageDir);
      if (await base.exists()) {
        for (final rel in scripts) {
          final file = File('$packageDir/$rel');
          if (await file.exists()) {
            archive.addFile(ArchiveFile(rel, 0, await file.readAsBytes()));
          }
        }
      }
    }
    final encoded = ZipEncoder().encode(archive);
    await File(zipPath).writeAsBytes(encoded);
  }

  /// 包目录下的脚本文件（相对路径），排除清单文件（导出时自行写入 plugin.json）。
  static List<String> _listScriptFiles(String packageDir) {
    final base = Directory(packageDir);
    if (!base.existsSync()) return const [];
    final files = <String>[];
    for (final entity in base.listSync(recursive: true)) {
      if (entity is! File) continue;
      final name = _baseName(entity.path);
      if (name == 'plugin.json' || name == 'pubspec.yaml') continue;
      files.add(entity.path.substring(base.path.length + 1).replaceAll('\\', '/'));
    }
    files.sort();
    return files;
  }

  static String _baseName(String name) {
    final idx = name.lastIndexOf('/');
    return idx < 0 ? name : name.substring(idx + 1);
  }

  /// manifest 所在目录作为包根（支持 zip 根目录或单层目录包裹两种布局）。
  static String _rootOf(String manifestName) {
    final idx = manifestName.lastIndexOf('/');
    return idx <= 0 ? '' : manifestName.substring(0, idx);
  }

  static String? _relativeUnder(String name, String prefix) {
    if (prefix.isEmpty) return name;
    if (!name.startsWith('$prefix/')) return null;
    final rel = name.substring(prefix.length + 1);
    return rel.isEmpty ? null : rel;
  }

  static List<int> _bytes(dynamic content) {
    if (content is String) return utf8.encode(content);
    if (content is List<int>) return content;
    throw const FormatException('Unsupported zip entry content');
  }
}
