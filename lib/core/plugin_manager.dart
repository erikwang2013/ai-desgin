import 'dart:developer' as dev;
import 'dart:convert';
import '../bridge/api.dart' as bridge_api;
import '../bridge/frb_generated.dart';
import '../plugin_sdk/design_plugin.dart';
import '../models/session.dart';
import 'builtin_plugins.dart' show builtInPlugins;

class PluginManager {
  final Map<String, DesignPlugin> _plugins = {};

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
  }
}
