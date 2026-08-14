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
          onCancel: (id) {
            cancelledIds.add(id);
            return null;
          },
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
          onCancel: (id) => null,
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
          onCancel: (id) => null,
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
          onCancel: (id) => null,
        ),
      ),
    ));
    expect(find.text('正在生成脚本…'), findsOneWidget);

    key.currentState!.updateTaskProgress('t4', '正在执行…');
    await tester.pump();
    expect(find.text('正在执行…'), findsOneWidget);
    expect(find.text('正在生成脚本…'), findsNothing);
  });

  testWidgets('updateTaskProgress and addTask after dispose are no-ops', (tester) async {
    final key = GlobalKey<TaskDashboardState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          key: key,
          initialTasks: [
            TaskItem(
              id: 't6',
              title: 'slow',
              software: 'blender',
              status: TaskStatus.running,
              createdAt: DateTime(2026, 8, 6, 10, 36),
            ),
          ],
          onCancel: (id) => null,
        ),
      ),
    ));
    final state = key.currentState!;
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    // widget 已销毁后调用不应抛异常（异步 onProgress 回调可能晚于销毁）。
    state.updateTaskProgress('t6', '正在执行…');
    state.addTask(TaskItem(
      id: 't7',
      title: 'late',
      software: 'figma',
      status: TaskStatus.running,
      createdAt: DateTime(2026, 8, 6, 10, 37),
    ));
  });

  testWidgets('addTask with duplicate id replaces existing task', (tester) async {
    final key = GlobalKey<TaskDashboardState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          key: key,
          initialTasks: [
            TaskItem(
              id: 't8',
              title: 'original',
              software: 'figma',
              status: TaskStatus.pending,
              createdAt: DateTime(2026, 8, 6, 10, 38),
            ),
          ],
          onCancel: (id) => null,
        ),
      ),
    ));
    key.currentState!.addTask(TaskItem(
      id: 't8',
      title: 'updated',
      software: 'figma',
      status: TaskStatus.running,
      createdAt: DateTime(2026, 8, 6, 10, 38),
    ));
    await tester.pump();

    expect(find.text('original'), findsNothing);
    expect(find.text('updated'), findsOneWidget);
  });

  testWidgets('failed task shows retry button that resubmits with original title', (tester) async {
    final retried = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          initialTasks: [
            TaskItem(
              id: 'f1',
              title: 'retry me',
              software: 'figma',
              status: TaskStatus.failed,
              createdAt: DateTime(2026, 8, 6, 10, 40),
            ),
          ],
          onRetry: (task) async => retried.add(task),
        ),
      ),
    ));

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(retried, ['retry me']);
  });

  testWidgets('completed and running tasks show no retry button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          initialTasks: [
            TaskItem(
              id: 'c1',
              title: 'done',
              software: 'figma',
              status: TaskStatus.completed,
              createdAt: DateTime(2026, 8, 6, 10, 41),
            ),
            TaskItem(
              id: 'r1',
              title: 'run',
              software: 'blender',
              status: TaskStatus.running,
              createdAt: DateTime(2026, 8, 6, 10, 42),
            ),
          ],
          onRetry: (task) async {},
        ),
      ),
    ));
    expect(find.byIcon(Icons.refresh), findsNothing);
  });

  testWidgets('task detail dialog lists artifacts with open file/directory actions', (tester) async {
    final opened = <(String, bool)>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          initialTasks: [
            TaskItem(
              id: 'a1',
              title: 'with artifacts',
              software: 'figma',
              status: TaskStatus.completed,
              createdAt: DateTime(2026, 8, 6, 10, 43),
              script: 'print(1)',
              artifacts: const ['/tmp/out/a.png', '/tmp/out/b.jpg'],
            ),
          ],
          openArtifact: (path, isFile) async {
            opened.add((path, isFile));
            return true;
          },
        ),
      ),
    ));

    await tester.tap(find.text('with artifacts'));
    await tester.pumpAndSettle();
    expect(find.text('Artifacts'), findsOneWidget);
    expect(find.text('a.png'), findsOneWidget);
    expect(find.text('b.jpg'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsNWidgets(2));
    expect(find.byIcon(Icons.folder_open), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.open_in_new).first);
    await tester.pumpAndSettle();
    expect(opened, [('/tmp/out/a.png', true)]);

    await tester.tap(find.byIcon(Icons.folder_open).last);
    await tester.pumpAndSettle();
    expect(opened, [('/tmp/out/a.png', true), ('/tmp/out/b.jpg', false)]);
  });

  testWidgets('artifact-only task opens detail dialog and failed open shows snackbar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          initialTasks: [
            TaskItem(
              id: 'a2',
              title: 'bad artifact',
              software: 'figma',
              status: TaskStatus.completed,
              createdAt: DateTime(2026, 8, 6, 10, 44),
              artifacts: const ['/tmp/missing.png'],
            ),
          ],
          openArtifact: (path, isFile) async => false,
        ),
      ),
    ));

    // 无脚本但有产物：仍可打开详情。
    await tester.tap(find.text('bad artifact'));
    await tester.pumpAndSettle();
    expect(find.text('Artifacts'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.open_in_new));
    await tester.pump();
    expect(find.text('Open failed'), findsOneWidget);
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
          onCancel: (id) => null,
        ),
      ),
    ));
    expect(find.text('正在验证…'), findsNothing);
  });

  testWidgets('failed task detail dialog shows error reason', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          initialTasks: [
            TaskItem(
              id: 't6',
              title: 'broken task',
              software: 'figma',
              status: TaskStatus.failed,
              createdAt: DateTime(2026, 8, 6, 10, 36),
              error: 'verification rejected: image mismatch',
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('broken task'));
    await tester.pumpAndSettle();
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('verification rejected: image mismatch'), findsOneWidget);
  });

  testWidgets('failed task without error shows no error section', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskDashboard(
          initialTasks: [
            TaskItem(
              id: 't7',
              title: 'silent fail',
              software: 'figma',
              status: TaskStatus.failed,
              createdAt: DateTime(2026, 8, 6, 10, 37),
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('silent fail'));
    await tester.pumpAndSettle();
    expect(find.text('Error'), findsNothing);
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
          onCancel: (id) => null,
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
