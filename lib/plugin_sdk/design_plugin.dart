import '../models/plugin.dart';
import '../models/software_capabilities.dart';
import '../models/session.dart';
import '../core/version.dart';
import '../core/local_script_executor.dart';

typedef ProgressCallback = void Function(double progress);

class PluginContext {
  final String pluginPath;
  final Map<String, String>? env;

  const PluginContext({required this.pluginPath, this.env});
}

abstract class DesignPlugin {
  String get id;
  String get name;
  String get version;
  DesignCategory get category;
  String get scriptLanguage;
  SoftwareCapabilities get capabilities;

  Future<bool> initialize(PluginContext ctx);
  Future<void> dispose();
  Future<ConnectionStatus> checkConnection();
  Future<bool> connect(ConnectionConfig config);
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress, String? key});
  Future<ScriptResult> preview(String script);
  Future<SoftwareState> getCurrentState();

  /// 取消正在执行的本地脚本（key 为任务 id，缺省回退插件 id）。默认 no-op；
  /// BuiltInPlugin 转发给执行器。
  Future<void> cancel({String? key}) async {}
}

class BuiltInPlugin implements DesignPlugin {
  @override
  final String id;
  @override
  final String name;
  @override
  final String version;
  @override
  final DesignCategory category;
  @override
  final String scriptLanguage;
  @override
  final SoftwareCapabilities capabilities;

  const BuiltInPlugin({
    required this.id,
    required this.name,
    this.version = appVersion,
    required this.category,
    required this.scriptLanguage,
    required this.capabilities,
  });

  /// 从 Rust 注册表 JSON（registry.rs 序列化）构造；未知 category 回退 web。
  factory BuiltInPlugin.fromRustJson(Map<String, dynamic> json) {
    final category = switch (json['category'] as String? ?? '') {
      'ad' => DesignCategory.ad,
      'industrial' => DesignCategory.industrial,
      'threeD' => DesignCategory.threeD,
      'arch' => DesignCategory.arch,
      'interior' => DesignCategory.interior,
      _ => DesignCategory.web,
    };
    final caps = json['capabilities'] as Map<String, dynamic>? ?? const {};
    // whereType + toList 是急切转换：cast<String> 惰性抛错会逃出调用方
    // try/catch（PluginManager.create），等 UI 首次访问时才炸。坏字段跳过。
    List<String> stringList(Object? raw) =>
        raw is List ? raw.whereType<String>().toList() : const [];
    return BuiltInPlugin(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: category,
      scriptLanguage: json['script_language'] as String? ?? '',
      capabilities: SoftwareCapabilities(
        actions: stringList(caps['actions']),
        fileFormats: stringList(caps['file_formats']),
      ),
    );
  }

  @override
  Future<bool> initialize(PluginContext ctx) async => true;

  @override
  Future<void> dispose() async {}

  @override
  Future<ConnectionStatus> checkConnection() async {
    final executor = LocalScriptExecutor.instance;
    if (executor != null && executor.hasCommand(id)) {
      final available = await executor.checkAvailable(id);
      return available ? ConnectionStatus.connected : ConnectionStatus.disconnected;
    }
    return ConnectionStatus.disconnected;
  }

  @override
  Future<bool> connect(ConnectionConfig config) async => false;

  @override
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress, String? key}) async {
    final executor = LocalScriptExecutor.instance;
    if (executor != null && executor.hasCommand(id)) {
      // key 用调用方传入的任务 id，避免同软件并发任务按插件 id 互杀；缺省回退插件 id。
      return executor.execute(id, name, script, key: key ?? id);
    }
    return ScriptResult.success(
      output: '脚本已生成，请在实际软件中执行:\n\n$script',
    );
  }

  @override
  Future<ScriptResult> preview(String script) async {
    return ScriptResult.success(output: '[预览] $script');
  }

  @override
  Future<SoftwareState> getCurrentState() async => const SoftwareState();

  @override
  Future<void> cancel({String? key}) async {
    final executor = LocalScriptExecutor.instance;
    if (executor != null && executor.hasCommand(id)) {
      executor.cancel(key ?? id);
    }
  }
}
