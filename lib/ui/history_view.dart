// lib/ui/history_view.dart
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/session.dart';
import '../models/task_record.dart';
import '../core/session_store.dart';

const _jsonGroup = XTypeGroup(label: 'JSON', extensions: ['json']);
const _mdGroup = XTypeGroup(label: 'Markdown', extensions: ['md']);

String _statusLabel(TaskStatus s) => switch (s) {
      TaskStatus.completed => '已完成',
      TaskStatus.failed => '失败',
      TaskStatus.running => '进行中',
      TaskStatus.pending => '排队中',
      TaskStatus.cancelled => '已取消',
    };

String _markdownTime(DateTime t) {
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} $hh:$mm';
}

/// 纯函数：把单个会话渲染为 Markdown 导出文本。
/// 不访问数据库/文件系统，便于单元测试断言。
/// 内容：会话元信息 + 每条任务（状态、时间、任务描述、脚本片段、错误、产物路径、时间线）。
String buildSessionMarkdown(Session session, {String? softwareDisplayName}) {
  final software = softwareDisplayName ?? session.softwareName;
  final sb = StringBuffer();
  sb.writeln('# 会话导出: $software');
  sb.writeln();
  sb.writeln('## 会话信息');
  sb.writeln();
  sb.writeln('- 会话 ID: ${session.id}');
  sb.writeln('- 软件: $software');
  sb.writeln('- 领域: ${session.domain.label}');
  sb.writeln('- 创建时间: ${_markdownTime(session.createdAt)}');
  sb.writeln('- 任务数: ${session.history.length}');
  sb.writeln();
  if (session.history.isEmpty) {
    sb.writeln('（该会话没有任务记录）');
    return sb.toString();
  }
  for (var i = 0; i < session.history.length; i++) {
    final r = session.history[i];
    sb.writeln('## 任务 ${i + 1}: ${r.task}');
    sb.writeln();
    sb.writeln('- 状态: ${_statusLabel(r.status)}');
    sb.writeln('- 创建时间: ${_markdownTime(r.createdAt)}');
    if (r.completedAt != null) sb.writeln('- 完成时间: ${_markdownTime(r.completedAt!)}');
    if (r.modelUsed != null) sb.writeln('- 模型: ${r.modelUsed}');
    sb.writeln();
    if (r.script != null && r.script!.isNotEmpty) {
      sb.writeln('**脚本**');
      sb.writeln();
      sb.writeln('```${r.scriptLanguage ?? ''}');
      sb.writeln(r.script);
      sb.writeln('```');
      sb.writeln();
    }
    if (r.error != null && r.error!.isNotEmpty) {
      sb.writeln('**错误信息**');
      sb.writeln();
      sb.writeln('> ${r.error}');
      sb.writeln();
    }
    if (r.artifacts.isNotEmpty) {
      sb.writeln('**产物文件**');
      sb.writeln();
      for (final a in r.artifacts) {
        sb.writeln('- $a');
      }
      sb.writeln();
    }
    if (r.iterationLog.isNotEmpty) {
      sb.writeln('**时间线**');
      sb.writeln();
      for (final step in r.iterationLog) {
        sb.writeln('- $step');
      }
      sb.writeln();
    }
  }
  return sb.toString();
}

class HistoryView extends StatefulWidget {
  final SessionStore? sessionStore;
  /// 列表数据共享加载器（app.dart 注入，与 TaskDashboard 共享一次查询）；
  /// 为 null 时回退 sessionStore 自查询。
  final Future<List<Session>> Function()? loadSessions;
  final String Function(String id)? resolveSoftwareName;
  const HistoryView({
    super.key,
    this.sessionStore,
    this.loadSessions,
    this.resolveSoftwareName,
  });

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

  /// 增量更新：任务完成后把最新会话直接替换/插入列表，避免整表重查。
  void updateSession(Session session) {
    if (!mounted) return;
    setState(() {
      final idx = _sessions.indexWhere((s) => s.id == session.id);
      if (idx >= 0) {
        _sessions[idx] = session;
      } else {
        _sessions.insert(0, session);
        while (_sessions.length > _maxSessions) {
          _sessions.removeLast();
        }
      }
      _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _load() async {
    var result = <Session>[];
    final loader = widget.loadSessions;
    final store = widget.sessionStore;
    if (loader != null || store != null) {
      try {
        result = await (loader ?? () => store!.listRecent(limit: _maxSessions))();
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
      var sessions = List<Session>.of(_sessions);
      // 列表投影不含 script/error：导出前取全量，保证导出内容完整。
      final store = widget.sessionStore;
      if (store != null) {
        try {
          final full = await store.listRecentFull(limit: _maxSessions);
          if (full.isNotEmpty) sessions = full;
        } catch (_) {}
      }
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

  /// 单个会话导出为 Markdown：走 file_selector 选保存位置，复用 JSON 导出的
  /// 保存/失败提示模式，失败静默降级为 SnackBar。
  Future<void> _exportSessionMarkdown(Session s) async {
    final l10n = AppLocalizations.of(context);
    String? savePath;
    try {
      final loc = await getSaveLocation(
        suggestedName: 'ai-design-session.md',
        acceptedTypeGroups: const [_mdGroup],
      );
      savePath = loc?.path;
    } catch (_) {
      // 选择器不可用时按取消处理
    }
    if (savePath == null || !mounted) return;

    try {
      // 列表投影不含 script/error：导出单个会话前按 id 取全量。
      var target = s;
      final store = widget.sessionStore;
      if (store != null) {
        try {
          final full = await store.load(s.id);
          if (full != null) target = full;
        } catch (_) {}
      }
      final software =
          widget.resolveSoftwareName?.call(target.softwareName) ?? target.softwareName;
      await File(savePath)
          .writeAsString(buildSessionMarkdown(target, softwareDisplayName: software));
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
    var deleted = true;
    try {
      if (store != null) {
        if (single) {
          await store.delete(ids.first);
        } else {
          await store.deleteMany(ids);
        }
      }
    } catch (_) {
      // 删除失败时保留列表项：数据库仍持有该会话，
      // 从 UI 移除会造成刷新后"复活"的假删除。
      deleted = false;
    }
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Delete failed'),
      ));
      return;
    }
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    tooltip: 'More',
                    onSelected: (value) {
                      if (value == 'export_md') _exportSessionMarkdown(s);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'export_md', child: Text('导出 Markdown')),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: l10n?.delete ?? 'Delete',
                    onPressed: () => _confirmDelete([s]),
                  ),
                ],
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
      onTap: () => _showRecordScript(r, l10n),
    );
  }

  /// 列表投影不含 script：点击时按记录懒加载全量；无存储时静默无操作。
  void _showRecordScript(TaskRecord r, AppLocalizations? l10n) {
    if (r.script != null) {
      _showScriptDialog(r, l10n);
      return;
    }
    final store = widget.sessionStore;
    if (store == null) return;
    store.loadTaskRecord(r.id).then((full) {
      if (full?.script == null || !mounted) return;
      _showScriptDialog(full!, l10n);
    }).catchError((_) {});
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
