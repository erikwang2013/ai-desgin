import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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

  testWidgets('restored history shows display name via resolveSoftwareName', (tester) async {
    // Real sqflite-ffi IO must run outside the widget test's fake-async zone.
    await tester.runAsync(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: SessionStore.onCreate,
      );
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
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('Blender'), findsOneWidget);
      expect(find.text('blender'), findsNothing);

      await db.close();
    });
  });
}
