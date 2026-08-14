import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' hide Session;
import 'package:ai_design_studio/core/session_store.dart';
import 'package:ai_design_studio/models/session.dart';
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

  testWidgets('running task shows progress stage and updates via updateTaskProgress', (tester) async {
    final key = GlobalKey<TaskDashboardState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          key: key,
          initialTasks: [
            TaskItem(
              id: 't4',
              title: 'slow',
              software: 'blender',
              status: TaskStatus.running,
              createdAt: DateTime(2026, 8, 6, 10, 34),
              progressStage: '正在生成脚本…',
            ),
          ],
          onCancel: (id) {},
        ),
      ),
    ));
    expect(find.text('正在生成脚本…'), findsOneWidget);

    key.currentState!.updateTaskProgress('t4', '正在执行…');
    await tester.pump();
    expect(find.text('正在执行…'), findsOneWidget);
    expect(find.text('正在生成脚本…'), findsNothing);
  });

  testWidgets('completed task does not show progress stage', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          initialTasks: [
            TaskItem(
              id: 't5',
              title: 'done',
              software: 'figma',
              status: TaskStatus.completed,
              createdAt: DateTime(2026, 8, 6, 10, 35),
              progressStage: '正在验证…',
            ),
          ],
          onCancel: (id) {},
        ),
      ),
    ));
    expect(find.text('正在验证…'), findsNothing);
  });

  testWidgets('restored history shows display name via resolveSoftwareName', (tester) async {
    final db = sqlite3.openInMemory();
    SessionStore.onCreate(db, 1);
    final store = SessionStore(db);

    final session = Session(
      domain: DesignCategory.threeD,
      softwareName: 'blender',
      history: [
        TaskRecord(
          sessionId: 's1',
          task: 'render',
          status: TaskStatus.completed,
          createdAt: DateTime(2026, 8, 6, 10, 33),
        ),
      ],
    );
    await store.save(session);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          sessionStore: store,
          onCancel: (id) {},
          resolveSoftwareName: (id) => id == 'blender' ? 'Blender' : id,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Blender'), findsOneWidget);
    expect(find.text('blender'), findsNothing);

    db.close();
  });
}
