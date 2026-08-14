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

  /// 回退标记：软件未安装/平台不支持时输出为"手动执行"提示而非真实执行结果，
  /// ArtifactVerifier 据此跳过失败特征与产物检查。
  final bool manualFallback;

  const ScriptResult({
    required this.success,
    this.output,
    this.error,
    this.artifacts = const [],
    this.metadata,
    this.manualFallback = false,
  });

  factory ScriptResult.success({
    String? output,
    List<String> artifacts = const [],
    Map<String, dynamic>? metadata,
    bool manualFallback = false,
  }) {
    return ScriptResult(
      success: true,
      output: output,
      artifacts: artifacts,
      metadata: metadata,
      manualFallback: manualFallback,
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
