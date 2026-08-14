// lib/ui/task_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/task_record.dart';
import '../core/session_store.dart';

class TaskItem {
  final String id;
  final String title;
  final String software;
  final TaskStatus status;
  final DateTime createdAt;
  final String? modelUsed;
  final String? script;

  /// 当前进度阶段描述（如「正在生成脚本…」），运行中任务展示在卡片上。
  final String? progressStage;

  TaskItem({
    required this.id,
    required this.title,
    required this.software,
    required this.status,
    required this.createdAt,
    this.modelUsed,
    this.script,
    this.progressStage,
  });
}

class TaskDashboard extends StatefulWidget {
  final List<TaskItem>? initialTasks;
  final SessionStore? sessionStore;
  final ValueChanged<String>? onCancel;
  final String Function(String id)? resolveSoftwareName;
  const TaskDashboard({
    super.key,
    this.initialTasks,
    this.sessionStore,
    this.onCancel,
    this.resolveSoftwareName,
  });

  @override
  State<TaskDashboard> createState() => TaskDashboardState();
}

class TaskDashboardState extends State<TaskDashboard> {
  final List<TaskItem> _tasks = [];
  String _filterKey = 'all';

  static const _maxTasks = 500;

  @override
  void initState() {
    super.initState();
    if (widget.initialTasks != null) {
      _tasks.addAll(widget.initialTasks!);
    }
    _restoreHistory();
  }

  Future<void> _restoreHistory() async {
    final store = widget.sessionStore;
    if (store == null) return;
    try {
      final sessions = await store.listRecent(limit: _maxTasks);
      final items = sessions
          .expand((s) => s.history.map((r) => TaskItem(
                id: r.id,
                title: r.task,
                software: widget.resolveSoftwareName?.call(s.softwareName) ??
                    s.softwareName,
                status: r.status,
                createdAt: r.createdAt,
                modelUsed: r.modelUsed,
                script: r.script,
              )))
          .toList();
      if (items.isEmpty || !mounted) return;
      setState(() {
        _tasks.addAll(items);
        _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        while (_tasks.length > _maxTasks) {
          _tasks.removeLast();
        }
      });
    } catch (_) {
      // History restore is non-critical; dashboard still works
    }
  }

  void addTask(TaskItem task) {
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx >= 0) {
        // 同 id 已存在（如进度占位卡片）时替换为最新状态。
        _tasks[idx] = task;
        return;
      }
      _tasks.insert(0, task);
      while (_tasks.length > _maxTasks) {
        _tasks.removeLast();
      }
    });
  }

  /// 更新运行中任务的进度阶段描述（由编排器 onProgress 回调驱动）。
  void updateTaskProgress(String taskId, String stage) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx < 0) return;
    setState(() {
      final t = _tasks[idx];
      _tasks[idx] = TaskItem(
        id: t.id,
        title: t.title,
        software: t.software,
        status: TaskStatus.running,
        createdAt: t.createdAt,
        modelUsed: t.modelUsed,
        script: t.script,
        progressStage: stage,
      );
    });
  }

  List<TaskItem> get _filteredTasks {
    if (_filterKey == 'all') return _tasks;
    if (_filterKey == 'inProgress') return _tasks.where((t) => t.status == TaskStatus.running || t.status == TaskStatus.pending).toList();
    if (_filterKey == 'completed') return _tasks.where((t) => t.status == TaskStatus.completed).toList();
    return _tasks;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(l10n?.noTasks ?? 'No Tasks', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(l10n?.noTasksHint ?? 'Enter your design requirements in the chat panel; tasks will appear here.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredTasks.length,
            itemBuilder: (context, index) => _buildTaskCard(_filteredTasks[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final l10n = AppLocalizations.of(context);
    final allLabel = l10n?.all ?? 'All';
    final inProgressLabel = l10n?.inProgress ?? 'In Progress';
    final completedLabel = l10n?.completed ?? 'Completed';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Text(l10n?.taskList ?? 'Task List', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          _buildChip(allLabel, 'all', _filterKey == 'all'),
          const SizedBox(width: 8),
          _buildChip(inProgressLabel, 'inProgress', _filterKey == 'inProgress'),
          const SizedBox(width: 8),
          _buildChip(completedLabel, 'completed', _filterKey == 'completed'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String key, bool selected) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _filterKey = key),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    final l10n = AppLocalizations.of(context);
    final statusIcon = switch (task.status) {
      TaskStatus.completed => Icons.check_circle,
      TaskStatus.failed => Icons.error,
      TaskStatus.running => Icons.hourglass_top,
      _ => Icons.schedule,
    };
    final statusColor = switch (task.status) {
      TaskStatus.completed => Colors.green,
      TaskStatus.failed => Colors.red,
      TaskStatus.running => Colors.orange,
      _ => Colors.grey,
    };
    final timeStr = '${task.createdAt.hour}:${task.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor, size: 24),
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(task.software, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                if (task.modelUsed != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(task.modelUsed!, style: TextStyle(fontSize: 10, color: Colors.indigo.shade700)),
                  ),
              ],
            ),
            if (task.status == TaskStatus.running && task.progressStage != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  task.progressStage!,
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onCancel != null &&
                (task.status == TaskStatus.running || task.status == TaskStatus.pending))
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n?.cancel ?? 'Cancel',
                onPressed: () => _cancelTask(task),
              ),
            Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        onTap: task.script == null ? null : () => _showTaskDetail(task),
      ),
    );
  }

  void _cancelTask(TaskItem task) {
    widget.onCancel?.call(task.id);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx < 0) return;
    setState(() {
      _tasks[idx] = TaskItem(
        id: task.id,
        title: task.title,
        software: task.software,
        status: TaskStatus.cancelled,
        createdAt: task.createdAt,
        modelUsed: task.modelUsed,
        script: task.script,
      );
    });
  }

  void _showTaskDetail(TaskItem task) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 320),
          child: SingleChildScrollView(
            child: SelectableText(
              task.script ?? '',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final script = task.script;
              if (script != null) {
                Clipboard.setData(ClipboardData(text: script));
              }
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(l10n?.copied ?? 'Copied'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Text(l10n?.copy ?? 'Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n?.close ?? 'Close'),
          ),
        ],
      ),
    );
  }
}
