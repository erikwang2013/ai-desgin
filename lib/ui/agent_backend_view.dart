import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/agent_backend.dart';
import '../core/cc_runner.dart';
import '../core/codex_backend.dart';
import '../core/gemini_backend.dart';
import '../core/cli_agent_backend.dart';

/// Agent 后端设置页：切换 Claude Code / Codex / Gemini / OpenCode /
/// OpenClaw / Hermes / Reasonix + 固定版本安装。
class AgentBackendView extends StatefulWidget {
  final String? currentBackendId;
  final ValueChanged<String>? onBackendChanged;

  const AgentBackendView({super.key, this.currentBackendId, this.onBackendChanged});

  @override
  State<AgentBackendView> createState() => _AgentBackendViewState();
}

class _AgentBackendViewState extends State<AgentBackendView> {
  final List<AgentBackend> _backends = [
    CCRunner(),
    CodexBackend(),
    GeminiBackend(),
    openCodeBackend,
    openClawBackend,
    hermesBackend,
    reasonixBackend,
  ];
  late String _selected;
  String? _installedVersion;
  bool _checkedVersion = false;
  bool _installing = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentBackendId ?? 'claude';
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    final version = await CCRunner.installedVersion();
    if (mounted) {
      setState(() {
        _installedVersion = version;
        _checkedVersion = true;
      });
    }
  }

  Future<void> _installClaude() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _installing = true);
    final ok = await CCRunner.installPinnedVersion();
    if (!mounted) return;
    setState(() => _installing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (l10n?.claudeUpToDate ?? 'Claude Code ${CCRunner.pinnedClaudeVersion} installed')
          : (l10n?.claudeInstallFailed ?? 'Install failed, check npm')),
      duration: const Duration(seconds: 3),
    ));
    _checkVersion();
  }

  String _backendLabel(String id, AppLocalizations? l10n) {
    return switch (id) {
      'codex' => l10n?.backendCodex ?? 'Codex',
      'gemini' => l10n?.backendGemini ?? 'Gemini',
      'opencode' => l10n?.backendOpencode ?? 'OpenCode',
      'openclaw' => l10n?.backendOpenclaw ?? 'OpenClaw',
      'hermes' => l10n?.backendHermes ?? 'Hermes',
      'reasonix' => l10n?.backendReasonix ?? 'Reasonix',
      _ => l10n?.backendClaude ?? 'Claude Code',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final needsInstall = _installedVersion != CCRunner.pinnedClaudeVersion;
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.agentBackend ?? 'Agent Backend')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n?.agentBackendDesc ?? 'Choose the agent CLI used to generate scripts'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selected,
            items: [
              for (final b in _backends)
                DropdownMenuItem(value: b.id, child: Text(_backendLabel(b.id, l10n))),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selected = v);
              widget.onBackendChanged?.call(v);
            },
          ),
          const Divider(height: 32),
          Text(
            l10n?.claudeVersion ?? 'Claude Code Version',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  !_checkedVersion
                      ? '...'
                      : _installedVersion == null
                          ? '—'
                          : 'v$_installedVersion',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (needsInstall)
                FilledButton.icon(
                  onPressed: _installing ? null : _installClaude,
                  icon: _installing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(_installing
                      ? (l10n?.installingClaude ?? 'Installing...')
                      : (l10n?.installClaude ?? 'Install Claude Code ${CCRunner.pinnedClaudeVersion}')),
                )
              else
                Text(
                  l10n?.claudeUpToDate ?? 'Up to date',
                  style: TextStyle(color: Colors.green[700]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
