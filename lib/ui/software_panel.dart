import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/session.dart';
import '../core/plugin_manager.dart';
import '../core/builtin_plugins.dart';
import '../plugin_sdk/design_plugin.dart';
import 'plugin_marketplace.dart';

class SoftwarePanel extends StatelessWidget {
  final PluginManager pluginManager;
  final Map<String, bool>? connectionStatus;

  const SoftwarePanel({super.key, required this.pluginManager, this.connectionStatus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plugins = pluginManager.getAll();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(l10n?.installedPlugins ?? 'Installed Plugins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n?.installPlugin ?? 'Install Plugin'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PluginMarketplace(pluginManager: pluginManager))),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: plugins.length,
            itemBuilder: (context, index) => _buildSoftwareCard(context, plugins[index], l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildSoftwareCard(BuildContext context, DesignPlugin plugin, AppLocalizations? l10n) {
    final status = connectionStatus?[plugin.id] ?? false;
    final icon = softwareIcons[plugin.id] ?? '🔌';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plugin.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    plugin.category.label,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text('v${plugin.version}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            _buildStatusIndicator(status, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool connected, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: connected ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 12,
              color: connected ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
