// lib/ui/task_dashboard.dart
import 'dart:io';

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
  final List<String> artifacts;

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
    this.artifacts = const [],
    this.progressStage,
  });
}

class TaskDashboard extends StatefulWidget {
  final List<TaskItem>? initialTasks;
  final SessionStore? sessionStore;
  /// 取消回调返回 orchestrator 取消后的最新状态，UI 据此回填；
  /// 返回 null 时回退为 cancelled。
  final TaskStatus? Function(String)? onCancel;
  /// 失败任务重试回调：以任务原始描述重新提交（原样重提，新 taskId）。
  final Future<void> Function(String task)? onRetry;
  /// 产物打开回调（测试注入用）；为 null 时按平台走系统打开器。
  final Future<bool> Function(String path, bool isFile)? openArtifact;
  final String Function(String id)? resolveSoftwareName;
  const TaskDashboard({
    super.key,
    this.initialTasks,
    this.sessionStore,
    this.onCancel,
    this.onRetry,
    this.openArtifact,
    this.resolveSoftwareName,
  });

  @override
  State<TaskDashboard> createState() => TaskDashboardState();
}

class TaskDashboardState extends State<TaskDashboard> {
  final List<TaskItem> _tasks = [];
  String _filterKey = 'all';

  /// id → 列表下标，避免 updateTaskProgress 每次全表扫描。
  final Map<String, int> _taskIndex = {};

  static const _maxTasks = 500;

  void _rebuildIndex() {
    _taskIndex.clear();
    for (var i = 0; i < _tasks.length; i++) {
      _taskIndex[_tasks[i].id] = i;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialTasks != null) {
      _tasks.addAll(widget.initialTasks!);
      _rebuildIndex();
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
                artifacts: r.artifacts,
              )))
          .toList();
      if (items.isEmpty || !mounted) return;
      setState(() {
        _tasks.addAll(items);
        _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        while (_tasks.length > _maxTasks) {
          _tasks.removeLast();
        }
        _rebuildIndex();
      });
    } catch (_) {
      // History restore is non-critical; dashboard still works
    }
  }

  void addTask(TaskItem task) {
    if (!mounted) return;
    setState(() {
      final idx = _taskIndex[task.id];
      if (idx != null) {
        // 同 id 已存在（如进度占位卡片）时替换为最新状态。
        _tasks[idx] = task;
        return;
      }
      _tasks.insert(0, task);
      while (_tasks.length > _maxTasks) {
        _taskIndex.remove(_tasks.removeLast().id);
      }
      _rebuildIndex();
    });
  }

  /// 更新运行中任务的进度阶段描述（由编排器 onProgress 回调驱动）。
  void updateTaskProgress(String taskId, String stage) {
    if (!mounted) return;
    final idx = _taskIndex[taskId];
    if (idx == null || idx >= _tasks.length) return;
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
        artifacts: t.artifacts,
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

    // 过滤结果只计算一次，避免 itemCount 与每个 itemBuilder 重复全量过滤。
    final filtered = _filteredTasks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildTaskCard(filtered[index]),
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
            if (task.status == TaskStatus.failed && widget.onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: l10n?.retry ?? 'Retry',
                onPressed: () => _retryTask(task),
              ),
            Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        onTap: task.script == null && task.artifacts.isEmpty
            ? null
            : () => _showTaskDetail(task),
      ),
    );
  }

  /// 失败任务一键重试：把任务描述原样交回提交入口（新 taskId 重新排队）。
  void _retryTask(TaskItem task) {
    widget.onRetry?.call(task.title);
  }

  void _cancelTask(TaskItem task) {
    // 以 orchestrator 实际结果回填：任务已先完成时 cancelTask 是 no-op，
    // 这里不得把已完成记录误标成 cancelled 造成 UI/历史漂移。
    final status = widget.onCancel?.call(task.id) ?? TaskStatus.cancelled;
    final idx = _taskIndex[task.id];
    if (idx == null || idx >= _tasks.length) return;
    setState(() {
      _tasks[idx] = TaskItem(
        id: task.id,
        title: task.title,
        software: task.software,
        status: status,
        createdAt: task.createdAt,
        modelUsed: task.modelUsed,
        script: task.script,
        artifacts: task.artifacts,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  task.script ?? '',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                if (task.artifacts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Artifacts',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  for (final path in task.artifacts) _buildArtifactRow(path),
                ],
              ],
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

  Widget _buildArtifactRow(String path) {
    final parts = path.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).toList();
    final name = parts.isEmpty ? path : parts.last;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        path,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 16),
            tooltip: 'Open file',
            visualDensity: VisualDensity.compact,
            onPressed: () => _openArtifact(path, isFile: true),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open, size: 16),
            tooltip: 'Open directory',
            visualDensity: VisualDensity.compact,
            onPressed: () => _openArtifact(path, isFile: false),
          ),
        ],
      ),
    );
  }

  /// 打开产物文件（isFile=true）或所在目录（isFile=false）。
  /// 失败/异常一律 SnackBar 提示，不向调用方抛异常。
  Future<void> _openArtifact(String path, {required bool isFile}) async {
    final opener = widget.openArtifact;
    var ok = false;
    try {
      ok = opener != null
          ? await opener(path, isFile)
          : await _openWithSystem(path, isFile: isFile);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Open failed'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  /// 按平台调用系统打开器：Linux xdg-open / macOS open / Windows start。
  Future<bool> _openWithSystem(String path, {required bool isFile}) async {
    final target = isFile ? path : File(path).parent.path;
    final List<String> cmd;
    if (Platform.isWindows) {
      cmd = ['cmd', '/c', 'start', '', target];
    } else if (Platform.isMacOS) {
      cmd = ['open', target];
    } else {
      cmd = ['xdg-open', target];
    }
    final result = await Process.start(cmd.first, cmd.sublist(1));
    final code = await result.exitCode;
    return code == 0;
  }
}
