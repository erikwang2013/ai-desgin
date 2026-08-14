import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/cc_runner.dart';
import '../../l10n/app_localizations.dart';
import 'error_localizer.dart';

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
      // 重建 scheme 前缀：只存裸 host，若回显时不还原，再次保存会因
      // 正则匹配不到 scheme 而静默降级成 http（HTTPS 代理变明文）。
      final scheme = prefs.getString(_schemeKey) ?? '';
      final host = prefs.getString(_hostKey) ?? '';
      _hostCtrl.text = scheme.isNotEmpty && host.isNotEmpty ? '$scheme://$host' : host;
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
      _showError(localizeError(AppLocalizations.of(context), error));
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
    // host 里已带端口（如 127.0.0.1:7890）再填端口会拼出非法 URL。
    if (port.isNotEmpty && host.contains(':')) {
      return 'Invalid proxy host (put the port in the port field only)';
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
