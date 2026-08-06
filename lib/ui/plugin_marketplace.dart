import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/session.dart';
import '../core/plugin_manager.dart';
import '../core/version.dart';
import '../core/builtin_plugins.dart';
import '../plugin_sdk/design_plugin.dart';

class PluginInfo {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final bool installed;
  final String version;

  const PluginInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.installed = false,
    this.version = appVersion,
  });
}

PluginManager _createDefaultPluginManager() {
  final pm = PluginManager();
  for (final p in builtInPlugins) {
    pm.register(p);
  }
  return pm;
}

class PluginMarketplace extends StatefulWidget {
  final PluginManager pluginManager;

  PluginMarketplace({super.key, PluginManager? pluginManager})
      : pluginManager = pluginManager ?? _createDefaultPluginManager();

  @override
  State<PluginMarketplace> createState() => _PluginMarketplaceState();
}

class _PluginMarketplaceState extends State<PluginMarketplace> {
  static const _prefsKey = 'uninstalled_plugin_ids';

  late final List<PluginInfo> _plugins;
  final Map<String, DesignPlugin> _removedPlugins = {};

  @override
  void initState() {
    super.initState();
    _plugins = _buildPluginsFromManager();
    _loadUninstalled();
  }

  Future<void> _loadUninstalled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_prefsKey) ?? const [];
      for (final id in ids) {
        final existing = widget.pluginManager.get(id);
        if (existing != null) {
          _removedPlugins[id] = existing;
          widget.pluginManager.unregister(id);
        }
      }
      if (ids.isNotEmpty && mounted) {
        setState(() {
          _plugins = _buildPluginsFromManager();
        });
      }
    } catch (_) {
      // No persistence available (tests, restricted env); in-memory only
    }
  }

  Future<void> _persistUninstalled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _removedPlugins.keys.toList());
    } catch (_) {}
  }

  List<PluginInfo> _buildPluginsFromManager() {
    return widget.pluginManager.getAll().map((p) {
      final icon = softwareIcons[p.id] ?? '🔌';
      return PluginInfo(
        id: p.id,
        name: p.name,
        description: softwareDescriptions[p.id] ?? '${p.name} 插件',
        icon: icon,
        category: p.category.label,
        installed: !_removedPlugins.containsKey(p.id),
        version: p.version,
      );
    }).toList();
  }

  void _toggleInstall(PluginInfo plugin) {
    final pm = widget.pluginManager;
    if (plugin.installed) {
      final existing = pm.get(plugin.id);
      if (existing != null) _removedPlugins[plugin.id] = existing;
      pm.unregister(plugin.id);
    } else {
      final saved = _removedPlugins.remove(plugin.id);
      if (saved != null) {
        pm.register(saved);
      } else {
        final builtin = builtInPlugins.cast<DesignPlugin?>().firstWhere(
          (p) => p!.id == plugin.id,
          orElse: () => null,
        );
        if (builtin != null) pm.register(builtin);
      }
    }

    setState(() {
      final idx = _plugins.indexWhere((p) => p.id == plugin.id);
      if (idx >= 0) {
        _plugins[idx] = PluginInfo(
          id: plugin.id,
          name: plugin.name,
          description: plugin.description,
          icon: plugin.icon,
          category: plugin.category,
          installed: !plugin.installed,
          version: plugin.version,
        );
      }
    });
    _persistUninstalled();

    final l10n = AppLocalizations.of(context);
    if (!plugin.installed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.installSuccess(plugin.name) ?? '${plugin.name} installed successfully'), duration: const Duration(seconds: 2)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.uninstallSuccess(plugin.name) ?? '${plugin.name} uninstalled'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final installed = _plugins.where((p) => p.installed).toList();
    final available = _plugins.where((p) => !p.installed).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.pluginMarket ?? 'Plugin Marketplace')),
      body: ListView(
        children: [
          if (installed.isNotEmpty) ...[
            _sectionHeader(l10n?.installed(installed.length) ?? 'Installed (${installed.length})'),
            ...installed.map((p) => _buildPluginTile(p, l10n)),
          ],
          if (available.isNotEmpty) ...[
            _sectionHeader(l10n?.available(available.length) ?? 'Available (${available.length})'),
            ...available.map((p) => _buildPluginTile(p, l10n)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildPluginTile(PluginInfo plugin, AppLocalizations? l10n) {
    return ListTile(
      leading: Text(plugin.icon, style: const TextStyle(fontSize: 28)),
      title: Row(
        children: [
          Text(plugin.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(plugin.category, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(plugin.description, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ),
      trailing: plugin.installed
          ? OutlinedButton(
              onPressed: () => _toggleInstall(plugin),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n?.uninstall ?? 'Uninstall'),
            )
          : ElevatedButton(
              onPressed: () => _toggleInstall(plugin),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n?.install ?? 'Install'),
            ),
    );
  }
}
