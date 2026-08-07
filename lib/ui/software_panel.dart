import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/session.dart';
import '../core/plugin_manager.dart';
import '../core/local_script_executor.dart';
import '../core/builtin_plugins.dart';
import '../plugin_sdk/design_plugin.dart';
import 'plugin_marketplace.dart';

class SoftwarePanel extends StatefulWidget {
  final PluginManager pluginManager;
  final Map<String, bool>? connectionStatus;
  final Future<void> Function()? onRefresh;

  const SoftwarePanel({super.key, required this.pluginManager, this.connectionStatus, this.onRefresh});

  @override
  State<SoftwarePanel> createState() => _SoftwarePanelState();
}

class _SoftwarePanelState extends State<SoftwarePanel> {
  String _query = '';

  List<DesignPlugin> get _filtered {
    final all = widget.pluginManager.getAll();
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((p) => p.name.toLowerCase().contains(q) || p.id.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plugins = _filtered;
    final groups = <DesignCategory, List<DesignPlugin>>{};
    for (final p in plugins) {
      groups.putIfAbsent(p.category, () => []).add(p);
    }
    final order = [
      DesignCategory.industrial,
      DesignCategory.threeD,
      DesignCategory.ad,
      DesignCategory.web,
      DesignCategory.interior,
      DesignCategory.arch,
    ];
    final sortedGroups = order
        .where(groups.containsKey)
        .map((c) => (c, groups[c]!))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(l10n?.installedPlugins ?? 'Installed Plugins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (widget.onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh connection status',
                  onPressed: () => widget.onRefresh!(),
                ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n?.installPlugin ?? 'Install Plugin'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PluginMarketplace(pluginManager: widget.pluginManager))),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            widget.pluginManager.rustConnected
                ? 'Rust 内核已连接 · 注册表来自 Rust'
                : 'Rust 内核未连接 · 使用 Dart 内置注册表',
            style: TextStyle(
              fontSize: 11,
              color: widget.pluginManager.rustConnected
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: l10n?.searchPlugins ?? 'Search plugins...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final (category, list) in sortedGroups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    '${category.label} (${list.length})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                ...list.map((p) => _buildSoftwareCard(context, p, l10n)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoftwareCard(BuildContext context, DesignPlugin plugin, AppLocalizations? l10n) {
    final connected = widget.connectionStatus?[plugin.id] ?? false;
    final autoCli = LocalScriptExecutor.instance?.hasCommand(plugin.id) ?? false;
    final icon = softwareIcons[plugin.id] ?? '🔌';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plugin.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('v${plugin.version}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            _buildModeBadge(autoCli, l10n),
            const SizedBox(width: 8),
            _buildStatusIndicator(autoCli && connected, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBadge(bool autoCli, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: autoCli ? Colors.indigo.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: autoCli ? Colors.indigo.shade200 : Colors.orange.shade200),
      ),
      child: Text(
        autoCli ? (l10n?.autoExecute ?? 'Auto') : (l10n?.manualExecute ?? 'Manual'),
        style: TextStyle(fontSize: 11, color: autoCli ? Colors.indigo.shade700 : Colors.orange.shade800),
      ),
    );
  }

  Widget _buildStatusIndicator(bool connected, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: connected ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: connected ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? (l10n?.connected ?? 'Connected') : (l10n?.disconnected ?? 'Disconnected'),
            style: TextStyle(
              fontSize: 11,
              color: connected ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
