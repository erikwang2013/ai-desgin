import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/version.dart';
import '../core/plugin_manager.dart';
import 'plugin_marketplace.dart';

class SettingsView extends StatelessWidget {
  final PluginManager? pluginManager;

  const SettingsView({super.key, this.pluginManager});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settings ?? 'Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.api),
            title: Text(l10n?.modelConfig ?? 'Model Config'),
            subtitle: Text(l10n?.modelConfigDesc ?? 'Manage API endpoint and keys'),
            onTap: () => _showComingSoon(context, l10n?.modelConfig ?? 'Model Config'),
          ),
          ListTile(
            leading: const Icon(Icons.extension),
            title: Text(l10n?.pluginMarket ?? 'Plugin Marketplace'),
            subtitle: Text(l10n?.pluginMarketDesc ?? 'Browse and install plugins'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PluginMarketplace(pluginManager: pluginManager)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wifi),
            title: Text(l10n?.proxySettings ?? 'Proxy Settings'),
            subtitle: Text(l10n?.proxySettingsDesc ?? 'Configure network proxy'),
            onTap: () => _showComingSoon(context, l10n?.proxySettings ?? 'Proxy Settings'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n?.about ?? 'About'),
            subtitle: Text(l10n?.aboutVersion(appVersion) ?? 'AI Design v$appVersion'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature - ${l10n?.comingSoon ?? 'Coming Soon'}'), duration: const Duration(seconds: 2)),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n?.appTitle ?? 'AI Design'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n?.aboutVersion(appVersion) ?? 'Version: v$appVersion'),
            const SizedBox(height: 8),
            Text(l10n?.aboutDescription1 ?? 'An AI-driven design software automation tool.'),
            const SizedBox(height: 8),
            Text(l10n?.aboutDescription2 ?? 'Covers 6 design domains and 47+ mainstream design software with AI-driven script generation and execution.'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n?.ok ?? 'OK'))],
      ),
    );
  }
}
