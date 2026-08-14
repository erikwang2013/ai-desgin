import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/session.dart';
import '../core/plugin_manager.dart';
import '../core/version.dart';
import '../core/builtin_plugins.dart';
import '../plugin_sdk/design_plugin.dart';
import 'category_labels.dart';

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
  String _query = '';

  List<PluginInfo> get _visiblePlugins {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _plugins;
    return _plugins
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.id.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q))
        .toList();
  }

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
        var existing = widget.pluginManager.get(id);
        if (existing == null) {
          // 外部插件重启后包目录仍在磁盘：从清单重建，保证卸载列表与重装可用。
          final dir = widget.pluginManager.externalPackageDir(id);
          final manifest =
              dir == null ? null : PluginManager.readExternalManifest(dir);
          if (dir != null && manifest != null) {
            existing = ExternalScriptPlugin(manifest: manifest, packageDir: dir);
          }
        }
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
    PluginInfo infoFor(DesignPlugin p, {required bool installed}) => PluginInfo(
      id: p.id,
      name: p.name,
      description: p is ExternalScriptPlugin && p.manifest.description.isNotEmpty
          ? p.manifest.description
          : (softwareDescriptions[p.id] ?? '${p.name} 插件'),
      icon: softwareIcons[p.id] ?? '🔌',
      category: p.category.label,
      installed: installed,
      version: p.version,
    );
    final byId = <String, PluginInfo>{};
    for (final p in widget.pluginManager.getAll()) {
      byId[p.id] = infoFor(p, installed: !_removedPlugins.containsKey(p.id));
    }
    // 卸载的插件保持可列出（Available 区），重启后也能重新安装。
    for (final p in _removedPlugins.values) {
      byId.putIfAbsent(p.id, () => infoFor(p, installed: false));
    }
    for (final p in builtInPlugins) {
      byId.putIfAbsent(p.id, () => infoFor(p, installed: false));
    }
    return byId.values.toList();
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

  static const _zipGroup = XTypeGroup(label: 'ZIP', extensions: ['zip']);

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  /// 选择器不可用时（无桌面 portal/zenity 的受限环境）回退到手输路径。
  Future<String?> _askForPath(String title, {String hint = ''}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n?.ok ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importFromLocal() async {
    final l10n = AppLocalizations.of(context);
    String? path;
    try {
      final file = await openFile(acceptedTypeGroups: const [_zipGroup]);
      path = file?.path;
    } catch (_) {
      path = await _askForPath(
        l10n?.enterPluginPackagePath ?? 'Enter plugin package (.zip) path',
        hint: '/path/to/plugin.zip',
      );
    }
    if (path == null || path.isEmpty || !mounted) return;
    try {
      final supportDir = await getApplicationSupportDirectory();
      final result = await PluginPackageCodec.importFromZip(path, supportDir.path);
      widget.pluginManager.registerExternal(result.manifest, result.packageDir);
      if (!mounted) return;
      setState(() => _plugins = _buildPluginsFromManager());
      _showSnack(l10n?.importSuccess(result.manifest.name, result.manifest.scripts.length) ??
          'Imported "${result.manifest.name}" with ${result.manifest.scripts.length} scripts');
    } catch (e) {
      _showSnack(l10n?.importFailed('$e') ?? 'Import failed: $e');
    }
  }

  Future<void> _exportPlugin() async {
    final l10n = AppLocalizations.of(context);
    final installed = _plugins.where((p) => p.installed).toList();
    if (installed.isEmpty) {
      _showSnack(l10n?.noPluginsToExport ?? 'No installed plugins to export');
      return;
    }
    final selected = await showDialog<PluginInfo>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n?.selectPluginToExport ?? 'Select plugin to export'),
        children: [
          for (final p in installed)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('${p.icon} ${p.name} (${p.version})'),
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;

    String? savePath;
    try {
      final loc = await getSaveLocation(
        suggestedName: '${selected.id}.zip',
        acceptedTypeGroups: const [_zipGroup],
      );
      savePath = loc?.path;
    } catch (_) {
      savePath = await _askForPath(
        l10n?.enterExportPath ?? 'Enter export path (.zip)',
        hint: '/path/to/${selected.id}.zip',
      );
    }
    if (savePath == null || savePath.isEmpty || !mounted) return;
    try {
      final plugin = widget.pluginManager.get(selected.id);
      if (plugin == null) throw StateError('Plugin not found: ${selected.id}');
      await PluginPackageCodec.exportToZip(
        plugin,
        packageDir: widget.pluginManager.externalPackageDir(selected.id),
        description: selected.description,
        zipPath: savePath,
      );
      _showSnack(l10n?.exportPluginSuccess(savePath) ?? 'Exported to $savePath');
    } catch (e) {
      _showSnack(l10n?.exportPluginFailed('$e') ?? 'Export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final installed = _visiblePlugins.where((p) => p.installed).toList();
    final available = _visiblePlugins.where((p) => !p.installed).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.pluginMarket ?? 'Plugin Marketplace'),
        actions: [
          // 用无 ripple 的点击区（TextButton 的 InkSparkle 在无 GPU 测试环境加载失败）。
          GestureDetector(
            onTap: _importFromLocal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.file_open, size: 18),
                  const SizedBox(width: 4),
                  Text(l10n?.importAction ?? 'Import'),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _exportPlugin,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.file_download, size: 18),
                  const SizedBox(width: 4),
                  Text(l10n?.exportAction ?? 'Export'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: l10n?.searchPlugins ?? 'Search plugins...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
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
            child: Text(
              categoryFromString(plugin.category).localizedLabel(l10n),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
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
