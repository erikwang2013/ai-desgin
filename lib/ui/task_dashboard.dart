// lib/ui/task_dashboard.dart
import 'package:flutter/material.dart';

class TaskItem {
  final String id;
  final String title;
  final String software;
  final String status; // pending, running, completed, failed
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
  State<TaskDashboard> createState() => _TaskDashboardState();
}

class _TaskDashboardState extends State<TaskDashboard> {
  final List<TaskItem> _tasks = [];
  String _filter = '全部';

  @override
  void initState() {
    super.initState();
    if (widget.initialTasks != null) {
      _tasks.addAll(widget.initialTasks!);
    }
  }

  void addTask(TaskItem task) {
    setState(() => _tasks.insert(0, task));
  }

  List<TaskItem> get _filteredTasks {
    if (_filter == '全部') return _tasks;
    if (_filter == '进行中') return _tasks.where((t) => t.status == 'running' || t.status == 'pending').toList();
    if (_filter == '已完成') return _tasks.where((t) => t.status == 'completed').toList();
    return _tasks;
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('暂无任务', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('在对话面板中输入设计需求，任务将显示在这里', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          const Text('任务列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          _buildChip('全部', _filter == '全部'),
          const SizedBox(width: 8),
          _buildChip('进行中', _filter == '进行中'),
          const SizedBox(width: 8),
          _buildChip('已完成', _filter == '已完成'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _filter = label),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    final statusIcon = switch (task.status) {
      'completed' => Icons.check_circle,
      'failed' => Icons.error,
      'running' => Icons.hourglass_top,
      _ => Icons.schedule,
    };
    final statusColor = switch (task.status) {
      'completed' => Colors.green,
      'failed' => Colors.red,
      'running' => Colors.orange,
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
