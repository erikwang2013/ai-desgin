import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

/// 后端 API Key 设置页：Codex 与 Gemini 的 key 在 app 启动时从 prefs
/// 读取（openai_api_key / gemini_api_key）但一直无 UI 可写，此处补上。
/// Claude Code 与 Remote Endpoint 各有独立设置页，不在此重复。
/// 保存空 key 即清除覆盖值，回退到 CLI 自身登录凭证（env 兜底）。
class BackendCredentialsPage extends StatefulWidget {
  /// 保存成功后回调（prefs 已写入），供上层更新启动时缓存的值。
  final void Function(String openaiApiKey, String geminiApiKey)?
      onCredentialsSaved;

  const BackendCredentialsPage({super.key, this.onCredentialsSaved});

  @override
  State<BackendCredentialsPage> createState() =>
      _BackendCredentialsPageState();
}

class _BackendCredentialsPageState extends State<BackendCredentialsPage> {
  static const _openaiKeyKey = 'openai_api_key';
  static const _geminiKeyKey = 'gemini_api_key';

  final _openaiCtrl = TextEditingController();
  final _geminiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _openaiCtrl.dispose();
    _geminiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _openaiCtrl.text = prefs.getString(_openaiKeyKey) ?? '';
      _geminiCtrl.text = prefs.getString(_geminiKeyKey) ?? '';
    } catch (_) {}
  }

  Future<void> _save() async {
    final openaiKey = _openaiCtrl.text.trim();
    final geminiKey = _geminiCtrl.text.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_openaiKeyKey, openaiKey);
      await prefs.setString(_geminiKeyKey, geminiKey);
    } catch (_) {}
    widget.onCredentialsSaved?.call(openaiKey, geminiKey);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)?.saveSuccess ?? 'Saved successfully'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.apiKey ?? 'API Key')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _openaiCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText:
                  '${l10n?.backendCodex ?? 'Codex'} ${l10n?.apiKey ?? 'API Key'}',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _geminiCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText:
                  '${l10n?.backendGemini ?? 'Gemini'} ${l10n?.apiKey ?? 'API Key'}',
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
