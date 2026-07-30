import '../plugin_sdk/design_plugin.dart';
import '../models/session.dart';

class PluginManager {
  final Map<String, DesignPlugin> _plugins = {};

  void register(DesignPlugin plugin) {
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
    for (final plugin in _plugins.values) {
      await plugin.initialize(ctx);
    }
  }

  Future<void> disposeAll() async {
    final plugins = List<DesignPlugin>.from(_plugins.values);
    for (final plugin in plugins) {
      await plugin.dispose();
    }
    _plugins.clear();
  }
}
