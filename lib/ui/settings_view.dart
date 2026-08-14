import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../core/version.dart';
import '../core/plugin_manager.dart';
import '../core/model_router.dart';
import '../core/locale_provider.dart';
import '../core/cc_runner.dart';
import 'agent_backend_view.dart';
import 'plugin_marketplace.dart';

class SettingsView extends StatelessWidget {
  final PluginManager? pluginManager;
  final LocaleProvider? localeProvider;
  final ModelRouter? modelRouter;
  final String? currentBackendId;
  final ValueChanged<String>? onBackendChanged;

  const SettingsView({
    super.key,
    this.pluginManager,
    this.localeProvider,
    this.modelRouter,
    this.currentBackendId,
    this.onBackendChanged,
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

class ModelConfigPage extends StatefulWidget {
  final ModelRouter? modelRouter;

  const ModelConfigPage({super.key, this.modelRouter});

  @override
  State<ModelConfigPage> createState() => _ModelConfigPageState();
}

class _ModelConfigPageState extends State<ModelConfigPage> {
  static const _endpointKey = 'api_endpoint';
  static const _apiKeyKey = 'api_key';
  static const _modelKey = 'default_model';

  final _endpointCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _endpointCtrl.text = prefs.getString(_endpointKey) ?? '';
      _apiKeyCtrl.text = prefs.getString(_apiKeyKey) ?? '';
      _modelCtrl.text = prefs.getString(_modelKey) ?? '';
    } catch (_) {}
  }

  Future<void> _save() async {
    final endpoint = _endpointCtrl.text.trim();
    final apiKey = _apiKeyCtrl.text.trim();
    final model = _modelCtrl.text.trim();

    final error = _validate(endpoint: endpoint, model: model);
    if (error != null) {
      _showError(_localizeError(AppLocalizations.of(context), error));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_endpointKey, endpoint);
      await prefs.setString(_apiKeyKey, apiKey);
      await prefs.setString(_modelKey, model);
    } catch (_) {}
    CCRunner.apiBaseUrl = endpoint;
    CCRunner.apiAuthToken = apiKey;
    if (model.isNotEmpty) widget.modelRouter?.setDefaultModel(model);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.saveSuccess ?? 'Saved successfully'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Empty API key is allowed (unauthenticated local environments);
  /// the endpoint must be a valid http(s) URL when provided.
  String? _validate({required String endpoint, required String model}) {
    if (endpoint.isNotEmpty) {
      final uri = Uri.tryParse(endpoint);
      if (uri == null ||
          !(uri.isScheme('http') || uri.isScheme('https')) ||
          uri.host.isEmpty) {
        return 'Invalid endpoint URL (e.g. https://api.example.com/v1)';
      }
    }
    if (model.isNotEmpty && !RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(model)) {
      return 'Invalid model name (letters, digits, dot, dash, underscore only)';
    }
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.modelConfig ?? 'Model Config')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _endpointCtrl,
            decoration: InputDecoration(
              labelText: l10n?.apiEndpoint ?? 'API Endpoint',
              hintText: 'https://api.example.com/v1',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n?.apiKey ?? 'API Key',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelCtrl,
            decoration: InputDecoration(
              labelText: l10n?.defaultModel ?? 'Default Model',
              hintText: 'claude-sonnet-4-6',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }
}

String _localizeError(AppLocalizations? l10n, String error) {
  switch (error) {
    case 'Invalid endpoint URL (e.g. https://api.example.com/v1)':
      return l10n?.invalidEndpointUrl ?? error;
    case 'Invalid model name (letters, digits, dot, dash, underscore only)':
      return l10n?.invalidModelName ?? error;
    case 'Invalid proxy host (no spaces allowed)':
      return l10n?.invalidProxyHostSpaces ?? error;
    case 'Invalid proxy host (host name only, no path)':
      return l10n?.invalidProxyHostPath ?? error;
    case 'Invalid proxy port (1-65535)':
      return l10n?.invalidProxyPort ?? error;
    case 'Proxy host is required when a port is set':
      return l10n?.proxyHostRequired ?? error;
  }
  return error;
}

class ProxySettingsPage extends StatefulWidget {
  const ProxySettingsPage({super.key});

  @override
  State<ProxySettingsPage> createState() => _ProxySettingsPageState();
}

class _ProxySettingsPageState extends State<ProxySettingsPage> {
  static const _hostKey = 'proxy_host';
  static const _portKey = 'proxy_port';
  static const _schemeKey = 'proxy_scheme';

  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _hostCtrl.text = prefs.getString(_hostKey) ?? '';
      _portCtrl.text = prefs.getString(_portKey) ?? '';
    } catch (_) {}
  }

  Future<void> _save() async {
    final host = _hostCtrl.text.trim();
    final port = _portCtrl.text.trim();

    // Accept a scheme-prefixed host, store it bare and rebuild the scheme.
    // Normalize before validating so paths (http://x.com/path) are rejected
    // instead of being spliced into a malformed proxy URL.
    final scheme = RegExp(r'^(https?)://').firstMatch(host)?.group(1) ?? 'http';
    final normalized = host.replaceFirst(RegExp(r'^https?://'), '');
    final error = _validate(host: normalized, port: port);
    if (error != null) {
      _showError(_localizeError(AppLocalizations.of(context), error));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_hostKey, normalized);
      await prefs.setString(_portKey, port);
      await prefs.setString(_schemeKey, scheme);
    } catch (_) {}
    if (normalized.isEmpty) {
      CCRunner.proxyEnvironment = null;
    } else {
      final base = port.isEmpty ? '$scheme://$normalized' : '$scheme://$normalized:$port';
      CCRunner.proxyEnvironment = {
        'HTTP_PROXY': base,
        'HTTPS_PROXY': base,
      };
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.saveSuccess ?? 'Saved successfully'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Empty host clears the proxy; a port requires a host and must be 1-65535.
  String? _validate({required String host, required String port}) {
    if (host.contains(' ')) {
      return 'Invalid proxy host (no spaces allowed)';
    }
    if (host.contains('/')) {
      return 'Invalid proxy host (host name only, no path)';
    }
    if (port.isNotEmpty) {
      final value = int.tryParse(port);
      if (value == null || value < 1 || value > 65535) {
        return 'Invalid proxy port (1-65535)';
      }
      if (host.isEmpty) {
        return 'Proxy host is required when a port is set';
      }
    }
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.proxySettings ?? 'Proxy Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _hostCtrl,
            decoration: InputDecoration(
              labelText: l10n?.proxyHost ?? 'Proxy Host',
              hintText: '127.0.0.1',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n?.proxyPort ?? 'Proxy Port',
              hintText: '7890',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }
}
