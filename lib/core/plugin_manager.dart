import 'dart:developer' as dev;
import '../plugin_sdk/design_plugin.dart';
import '../models/session.dart';

class PluginManager {
  final Map<String, DesignPlugin> _plugins = {};

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
