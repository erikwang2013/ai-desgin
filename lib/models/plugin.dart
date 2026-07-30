enum ConnectionStatus { disconnected, connecting, connected, error }

class PluginMeta {
  final String id;
  final String name;
  final String version;
  final String scriptLanguage;

  const PluginMeta({
    required this.id,
    required this.name,
    required this.version,
    required this.scriptLanguage,
  });
}

class ScriptResult {
  final bool success;
  final String? output;
  final String? error;
  final List<String> artifacts;
  final Map<String, dynamic>? metadata;

  const ScriptResult({
    required this.success,
    this.output,
    this.error,
    this.artifacts = const [],
    this.metadata,
  });

  factory ScriptResult.success({
    String? output,
    List<String> artifacts = const [],
    Map<String, dynamic>? metadata,
  }) {
    return ScriptResult(
      success: true,
      output: output,
      artifacts: artifacts,
      metadata: metadata,
    );
  }

  factory ScriptResult.failure({required String error}) {
    return ScriptResult(success: false, error: error);
  }
}

class ConnectionConfig {
  final String host;
  final int port;
  final Map<String, String>? extra;

  const ConnectionConfig({
    required this.host,
    required this.port,
    this.extra,
  });
}
