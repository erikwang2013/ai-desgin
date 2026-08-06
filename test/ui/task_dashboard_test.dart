import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/models/task_record.dart';
import 'package:ai_design_studio/ui/task_dashboard.dart';

void main() {
  testWidgets('running task shows cancel button that cancels and marks cancelled', (tester) async {
    final cancelledIds = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          initialTasks: [
            TaskItem(
              id: 't1',
              title: 'slow',
              software: 'blender',
              status: TaskStatus.running,
              createdAt: DateTime(2026, 8, 6, 10, 30),
            ),
          ],
          onCancel: (id) => cancelledIds.add(id),
        ),
      ),
    ));

    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(cancelledIds, ['t1']);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('pending task shows cancel button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          initialTasks: [
            TaskItem(
              id: 't2',
              title: 'queued',
              software: 'figma',
              status: TaskStatus.pending,
              createdAt: DateTime(2026, 8, 6, 10, 31),
            ),
          ],
          onCancel: (id) {},
        ),
      ),
    ));
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('completed task shows no cancel button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          initialTasks: [
            TaskItem(
              id: 't3',
              title: 'done',
              software: 'figma',
              status: TaskStatus.completed,
              createdAt: DateTime(2026, 8, 6, 10, 32),
            ),
          ],
          onCancel: (id) {},
        ),
      ),
    ));
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
