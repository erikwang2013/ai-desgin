// lib/ui/task_dashboard.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/task_record.dart';

class TaskItem {
  final String id;
  final String title;
  final String software;
  final TaskStatus status;
  final DateTime createdAt;
  final String? modelUsed;

  TaskItem({
    required this.id,
    required this.title,
    required this.software,
    required this.status,
    required this.createdAt,
    this.modelUsed,
  });
}

class TaskDashboard extends StatefulWidget {
  final List<TaskItem>? initialTasks;
  const TaskDashboard({super.key, this.initialTasks});

  @override
  State<TaskDashboard> createState() => TaskDashboardState();
}

class TaskDashboardState extends State<TaskDashboard> {
  final List<TaskItem> _tasks = [];
  String _filterKey = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialTasks != null) {
      _tasks.addAll(widget.initialTasks!);
    }
  }

  static const _maxTasks = 500;

  void addTask(TaskItem task) {
    setState(() {
      _tasks.insert(0, task);
      while (_tasks.length > _maxTasks) {
        _tasks.removeLast();
      }
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
          _buildChip(allLabel, _filterKey == 'all'),
          const SizedBox(width: 8),
          _buildChip(inProgressLabel, _filterKey == 'inProgress'),
          const SizedBox(width: 8),
          _buildChip(completedLabel, _filterKey == 'completed'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() {
        if (label == (AppLocalizations.of(context)?.all ?? 'All')) {
          _filterKey = 'all';
        } else if (label == (AppLocalizations.of(context)?.inProgress ?? 'In Progress')) {
          _filterKey = 'inProgress';
        } else {
          _filterKey = 'completed';
        }
      }),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTaskCard(TaskItem task) {
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
        subtitle: Row(
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
        trailing: Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ),
    );
  }
}
