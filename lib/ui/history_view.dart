// lib/ui/history_view.dart
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/session.dart';
import '../models/task_record.dart';
import '../core/session_store.dart';

const _jsonGroup = XTypeGroup(label: 'JSON', extensions: ['json']);

class HistoryView extends StatefulWidget {
  final SessionStore? sessionStore;
  final String Function(String id)? resolveSoftwareName;
  const HistoryView({super.key, this.sessionStore, this.resolveSoftwareName});

  @override
  State<HistoryView> createState() => HistoryViewState();
}

class HistoryViewState extends State<HistoryView> {
  static const _maxSessions = 500;

  List<Session> _sessions = [];
  bool _loading = true;
  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 新会话保存后由外部调用（app.dart 提交任务成功后）刷新列表。
  void reload() => _load();

  Future<void> _load() async {
    var result = <Session>[];
    final store = widget.sessionStore;
    if (store != null) {
      try {
        result = await store.listRecent(limit: _maxSessions);
      } catch (_) {
        // History load is non-critical; empty state shown instead
      }
    }
    if (!mounted) return;
    setState(() {
      _sessions = result;
      _loading = false;
      _selectedIds.clear();
      if (_sessions.isEmpty) _selectMode = false;
    });
  }

  String _sessionTitle(Session s) {
    if (s.history.isNotEmpty) return s.history.first.task;
    return s.softwareName;
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    return '${t.month}-${t.day} $hh:$mm';
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  Future<void> _exportAll() async {
    final l10n = AppLocalizations.of(context);
    if (_sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n?.exportNoSessions ?? 'No sessions to export'),
      ));
      return;
    }

    String? savePath;
    try {
      final loc = await getSaveLocation(
        suggestedName: 'ai-design-history.json',
        acceptedTypeGroups: const [_jsonGroup],
      );
      savePath = loc?.path;
    } catch (_) {
      // 选择器不可用时按取消处理
    }
    if (savePath == null || !mounted) return;

    try {
      final sessions = List<Session>.of(_sessions);
      await File(savePath).writeAsString(SessionStore.exportSessionsToJson(sessions));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n?.saveSuccess ?? 'Saved'),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n?.exportHistoryFailed ?? 'Export failed'),
      ));
    }
  }

  Future<void> _confirmDelete(List<Session> targets) async {
    if (targets.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final single = targets.length == 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          single
              ? l10n?.deleteConfirm ?? 'Delete this session?'
              : l10n?.deleteAllConfirm(targets.length) ??
                  'Delete all ${targets.length} sessions?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ids = targets.map((s) => s.id).toList();
    final store = widget.sessionStore;
    try {
      if (store != null) {
        if (single) {
          await store.delete(ids.first);
        } else {
          await store.deleteMany(ids);
        }
      }
    } catch (_) {
      // Non-critical; item simply stays in the list
    }
    if (!mounted) return;
    setState(() {
      _sessions.removeWhere((s) => ids.contains(s.id));
      _selectedIds.removeAll(ids);
      if (_sessions.isEmpty) _selectMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _buildHeader(l10n),
        Expanded(child: _buildBody(l10n)),
        if (_selectMode && _selectedIds.isNotEmpty) _buildSelectionBar(l10n),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Text(l10n?.historyList ?? 'History',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (_selectMode)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: Text(l10n?.deleteAll ?? 'Delete All'),
              onPressed:
                  _sessions.isEmpty ? null : () => _confirmDelete(List.of(_sessions)),
            ),
          TextButton.icon(
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: Text(l10n?.exportHistory ?? 'Export'),
            onPressed: _exportAll,
          ),
          TextButton(
            onPressed: _sessions.isEmpty
                ? null
                : () => setState(() {
                      _selectMode = !_selectMode;
                      _selectedIds.clear();
                    }),
            child: Text(_selectMode
                ? l10n?.done ?? 'Done'
                : l10n?.manage ?? 'Manage'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations? l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(l10n?.noHistory ?? 'No history',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(l10n?.noHistoryHint ?? 'Completed sessions will appear here',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) => _buildSessionCard(_sessions[index], l10n),
    );
  }

  Widget _buildSessionCard(Session s, AppLocalizations? l10n) {
    final firstRecord = s.history.isNotEmpty ? s.history.first : null;
    final status = firstRecord?.status ?? TaskStatus.completed;
    final statusIcon = switch (status) {
      TaskStatus.completed => Icons.check_circle,
      TaskStatus.failed => Icons.error,
      TaskStatus.running => Icons.hourglass_top,
      _ => Icons.schedule,
    };
    final statusColor = switch (status) {
      TaskStatus.completed => Colors.green,
      TaskStatus.failed => Colors.red,
      TaskStatus.running => Colors.orange,
      _ => Colors.grey,
    };
    final softwareName =
        widget.resolveSoftwareName?.call(s.softwareName) ?? s.softwareName;
    final subtitle =
        '$softwareName · ${_formatTime(s.createdAt)} · ${l10n?.tasksCount(s.history.length) ?? '${s.history.length} tasks'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: _selectMode
          ? CheckboxListTile(
              value: _selectedIds.contains(s.id),
              onChanged: (_) => _toggleSelection(s.id),
              secondary: Icon(statusIcon, color: statusColor, size: 24),
              title: Text(_sessionTitle(s), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.leading,
            )
          : ListTile(
              leading: Icon(statusIcon, color: statusColor, size: 24),
              title: Text(_sessionTitle(s), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: l10n?.delete ?? 'Delete',
                onPressed: () => _confirmDelete([s]),
              ),
              onTap: () => _showSessionDetail(s, l10n),
            ),
    );
  }

  Widget _buildSelectionBar(AppLocalizations? l10n) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: FilledButton.icon(
          icon: const Icon(Icons.delete, size: 18),
          label: Text(l10n?.deleteSelected(_selectedIds.length) ??
              'Delete Selected (${_selectedIds.length})'),
          onPressed: () => _confirmDelete(
            _sessions.where((s) => _selectedIds.contains(s.id)).toList(),
          ),
        ),
      ),
    );
  }

  void _showSessionDetail(Session s, AppLocalizations? l10n) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_sessionTitle(s), maxLines: 2, overflow: TextOverflow.ellipsis),
        content: s.history.isEmpty
            ? Text(s.softwareName, style: const TextStyle(fontSize: 13))
            : SizedBox(
                width: 480,
                height: 360,
                child: ListView.separated(
                  itemCount: s.history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _buildRecordRow(s.history[index], l10n),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n?.close ?? 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(TaskRecord r, AppLocalizations? l10n) {
    final statusIcon = switch (r.status) {
      TaskStatus.completed => Icons.check_circle,
      TaskStatus.failed => Icons.error,
      TaskStatus.running => Icons.hourglass_top,
      _ => Icons.schedule,
    };
    final statusColor = switch (r.status) {
      TaskStatus.completed => Colors.green,
      TaskStatus.failed => Colors.red,
      TaskStatus.running => Colors.orange,
      _ => Colors.grey,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(statusIcon, color: statusColor, size: 20),
      title: Text(r.task, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_formatTime(r.createdAt)}${r.modelUsed != null ? ' · ${r.modelUsed}' : ''}',
        style: const TextStyle(fontSize: 11),
      ),
      onTap: r.script == null ? null : () => _showScriptDialog(r, l10n),
    );
  }

  void _showScriptDialog(TaskRecord r, AppLocalizations? l10n) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(r.task, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 320),
          child: SingleChildScrollView(
            child: SelectableText(
              r.script ?? '',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n?.close ?? 'Close'),
          ),
        ],
      ),
    );
  }
}
