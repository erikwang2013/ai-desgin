import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/cc_runner.dart';
import '../../core/model_router.dart';
import '../../l10n/app_localizations.dart';
import 'error_localizer.dart';

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
      _showError(localizeError(AppLocalizations.of(context), error));
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
