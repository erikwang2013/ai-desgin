import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../core/version.dart';
import '../core/plugin_manager.dart';
import '../core/model_router.dart';
import '../core/locale_provider.dart';
import '../core/cc_runner.dart';
import 'agent_backend_view.dart';
import 'plugin_marketplace.dart';
import 'settings/backend_credentials_page.dart';
import 'settings/model_config_page.dart';
import 'settings/proxy_settings_page.dart';
import 'settings/script_executor_paths_section.dart';

class SettingsView extends StatelessWidget {
  final PluginManager? pluginManager;
  final LocaleProvider? localeProvider;
  final ModelRouter? modelRouter;
  final String? currentBackendId;
  final ValueChanged<String>? onBackendChanged;
  final void Function(String openaiApiKey, String geminiApiKey)?
      onCredentialsSaved;

  const SettingsView({
    super.key,
    this.pluginManager,
    this.localeProvider,
    this.modelRouter,
    this.currentBackendId,
    this.onBackendChanged,
    this.onCredentialsSaved,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settings ?? 'Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n?.language ?? 'Language'),
            subtitle: Text(LocaleProvider.languageNames[
                    localeProvider?.locale.languageCode ?? 'zh'] ??
                '中文'),
            onTap: () => _showLanguagePicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: Text(l10n?.agentBackend ?? 'Agent Backend'),
            subtitle: Text(l10n?.agentBackendDesc ?? 'Choose the agent CLI used to generate scripts'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AgentBackendView(
                  currentBackendId: currentBackendId,
                  onBackendChanged: onBackendChanged,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.api),
            title: Text(l10n?.modelConfig ?? 'Model Config'),
            subtitle: Text(l10n?.modelConfigDesc ?? 'Manage API endpoint and keys'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ModelConfigPage(modelRouter: modelRouter)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: Text(l10n?.apiKey ?? 'API Key'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BackendCredentialsPage(onCredentialsSaved: onCredentialsSaved),
              ),
            ),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProxySettingsPage()),
            ),
          ),
          const ScriptExecutorPathsSection(),
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

  void _showLanguagePicker(BuildContext context) {
    final provider = localeProvider;
    if (provider == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(AppLocalizations.of(dialogContext)?.language ?? 'Language'),
        children: [
          for (final locale in LocaleProvider.supportedLocales)
            SimpleDialogOption(
              onPressed: () {
                provider.setLocale(locale);
                CCRunner.responseLanguage = provider.languageInstruction;
                Navigator.pop(dialogContext);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  LocaleProvider.languageNames[locale.languageCode] ?? locale.languageCode,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
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
            Text(l10n?.aboutDescription2 ?? 'Covers 6 design domains and 62+ mainstream design software with AI-driven script generation and execution.'),
            const SizedBox(height: 8),
            Text(l10n?.aboutPackageName ?? 'Package name: Ai Desgin'),
            const SizedBox(height: 12),
            InkWell(
              onTap: () =>
                  launchUrl(Uri.parse('https://github.com/erikwang2013/ai-desgin')),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code, size: 16, color: primary),
                  const SizedBox(width: 6),
                  Text('GitHub: github.com/erikwang2013/ai-desgin',
                      style: TextStyle(color: primary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://erik.xyz')),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, size: 16, color: primary),
                  const SizedBox(width: 6),
                  Text(l10n?.aboutDeveloper ?? 'Developer: erik',
                      style: TextStyle(color: primary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n?.ok ?? 'OK'))],
      ),
    );
  }
}
