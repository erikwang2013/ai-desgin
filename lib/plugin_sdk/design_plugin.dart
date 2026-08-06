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
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress});
  Future<ScriptResult> preview(String script);
  Future<SoftwareState> getCurrentState();
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
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async {
    final executor = LocalScriptExecutor.instance;
    if (executor != null && executor.hasCommand(id)) {
      return executor.execute(id, name, script);
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
}
