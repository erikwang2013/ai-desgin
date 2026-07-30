import '../models/plugin.dart';
import '../models/software_capabilities.dart';
import '../models/session.dart';

/// Callback type for reporting script execution progress (0.0 to 1.0).
typedef ProgressCallback = void Function(double progress);

/// Context provided to a plugin during initialization.
class PluginContext {
  final String pluginPath;
  final Map<String, String>? env;

  const PluginContext({required this.pluginPath, this.env});
}

/// Abstract interface that all design software plugins must implement.
///
/// Each concrete plugin (e.g. Figma, Photoshop, Blender) provides its own
/// implementation of these methods, wrapping the software's native API.
abstract class DesignPlugin {
  /// Unique identifier for the plugin (e.g. "com.aidesign.figma").
  String get id;

  /// Human-readable display name (e.g. "Figma").
  String get name;

  /// Semantic version of the plugin.
  String get version;

  /// Primary design domain this plugin targets.
  DesignCategory get category;

  /// Scripting language used by the target software (e.g. "javascript").
  String get scriptLanguage;

  /// Describes what actions and formats the software supports.
  SoftwareCapabilities get capabilities;

  /// Initialize the plugin with the given context.
  ///
  /// Returns `true` if initialization succeeded.
  Future<bool> initialize(PluginContext ctx);

  /// Release all resources held by the plugin.
  Future<void> dispose();

  /// Check whether the plugin can reach the target software.
  Future<ConnectionStatus> checkConnection();

  /// Establish a connection to the target software using [config].
  ///
  /// Returns `true` if the connection was established.
  Future<bool> connect(ConnectionConfig config);

  /// Execute [script] in the target software.
  ///
  /// Optionally reports progress via [onProgress].
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress});

  /// Preview the effect of [script] without modifying the document state.
  Future<ScriptResult> preview(String script);

  /// Get a snapshot of the current software state (open document, layers, etc.).
  Future<SoftwareState> getCurrentState();
}
