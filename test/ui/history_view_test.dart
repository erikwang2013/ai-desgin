import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' hide Session;
import 'package:ai_design_studio/core/session_store.dart';
import 'package:ai_design_studio/models/session.dart';
import 'package:ai_design_studio/models/task_record.dart';
import 'package:ai_design_studio/ui/history_view.dart';

void main() {
  late SessionStore store;
  late Database db;

  setUp(() {
    db = sqlite3.openInMemory();
    SessionStore.onCreate(db, 1);
    store = SessionStore(db);
  });

  tearDown(() => db.close());

  Future<void> saveSessions(WidgetTester tester, List<Session> sessions) async {
    for (final s in sessions) {
      await store.save(s);
    }
  }

  Future<void> pumpHistory(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HistoryView(
          sessionStore: store,
          resolveSoftwareName: (id) => id == 'figma' ? 'Figma' : id,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  // Fixed created_at values so listRecent (DESC by created_at) order is
  // deterministic: s3 newest, then s2, then s1.
  Session makeSession(String id, String task, {DesignCategory domain = DesignCategory.web, String software = 'figma'}) {
    final day = int.parse(id.substring(1));
    final s = Session(
      id: id,
      domain: domain,
      softwareName: software,
      createdAt: DateTime(2026, 8, day),
    );
    s.addRecord(task: task, script: 'print(1)', scriptLanguage: 'python', modelUsed: 'haiku');
    return s;
  }

  testWidgets('empty state shows no-history message', (tester) async {
    await pumpHistory(tester);
    expect(find.text('No history'), findsOneWidget);
    // Manage button rendered but disabled when the list is empty.
    final manageBtn = tester.widget<TextButton>(
      find.ancestor(of: find.text('Manage'), matching: find.byType(TextButton)),
    );
    expect(manageBtn.onPressed, isNull);
  });

  testWidgets('lists sessions with first-task title', (tester) async {
    await saveSessions(tester, [
      makeSession('s1', 'create button'),
      makeSession('s2', 'render scene'),
    ]);
    await pumpHistory(tester);

    expect(find.text('create button'), findsOneWidget);
    expect(find.text('render scene'), findsOneWidget);
    expect(find.textContaining('Figma'), findsNWidgets(2));
    expect(find.textContaining('1 tasks'), findsNWidgets(2));
  });

  testWidgets('single delete removes one session after confirmation', (tester) async {
    await saveSessions(tester, [
      makeSession('s1', 'create button'),
      makeSession('s2', 'render scene'),
    ]);
    await pumpHistory(tester);

    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    // listRecent orders newest first, so the first delete button is s2.
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('Delete this session?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('render scene'), findsNothing);
    expect(find.text('create button'), findsOneWidget);
    expect(await store.load('s2'), isNull);
    expect(await store.load('s1'), isNotNull);
  });

  testWidgets('failed delete keeps the session in the list and shows an error', (tester) async {
    await saveSessions(tester, [makeSession('s1', 'create button')]);
    // 删除抛错的 store：DB 仍持有会话，UI 不应假删除。
    final failing = _FailingDeleteStore(db);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HistoryView(sessionStore: failing)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('create button'), findsOneWidget);
    expect(find.text('Delete failed'), findsOneWidget);
    expect(await store.load('s1'), isNotNull);
  });

  testWidgets('cancelling single delete keeps the session', (tester) async {
    await saveSessions(tester, [makeSession('s1', 'create button')]);
    await pumpHistory(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('create button'), findsOneWidget);
    expect(await store.load('s1'), isNotNull);
  });

  testWidgets('manage mode toggles checkboxes and batch deletes selected', (tester) async {
    await saveSessions(tester, [
      makeSession('s1', 'create button'),
      makeSession('s2', 'render scene'),
      makeSession('s3', 'export jpg'),
    ]);
    await pumpHistory(tester);

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();

    expect(find.byType(CheckboxListTile), findsNWidgets(3));
    expect(find.text('Delete Selected (0)'), findsNothing);

    // Newest first: at(0)=s3, at(1)=s2.
    await tester.tap(find.byType(CheckboxListTile).at(0));
    await tester.tap(find.byType(CheckboxListTile).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Delete Selected (2)'), findsOneWidget);

    await tester.tap(find.text('Delete Selected (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all 2 sessions?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('export jpg'), findsNothing);
    expect(find.text('render scene'), findsNothing);
    expect(find.text('create button'), findsOneWidget);
    expect(await store.load('s3'), isNull);
    expect(await store.load('s2'), isNull);
    expect(await store.load('s1'), isNotNull);
  });

  testWidgets('Done exits manage mode', (tester) async {
    await saveSessions(tester, [makeSession('s1', 'create button')]);
    await pumpHistory(tester);

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('Delete All removes every session after confirmation', (tester) async {
    await saveSessions(tester, [
      makeSession('s1', 'create button'),
      makeSession('s2', 'render scene'),
    ]);
    await pumpHistory(tester);

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete All'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all 2 sessions?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No history'), findsOneWidget);
    final remaining = await store.listRecent();
    expect(remaining, isEmpty);
  });

  testWidgets('tapping a session shows its task records in a dialog', (tester) async {
    await saveSessions(tester, [makeSession('s1', 'create button')]);
    await pumpHistory(tester);

    await tester.tap(find.text('create button'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('create button'), findsWidgets);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('session card menu offers Export Markdown', (tester) async {
    await saveSessions(tester, [makeSession('s1', 'create button')]);
    await pumpHistory(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('导出 Markdown'), findsOneWidget);
  });

  group('buildSessionMarkdown', () {
    test('includes session metadata and per-task details', () {
      final session = Session(
        id: 's1',
        domain: DesignCategory.threeD,
        softwareName: 'blender',
        createdAt: DateTime(2026, 8, 14, 10, 30),
      );
      session.history.add(TaskRecord(
        sessionId: 's1',
        task: 'create sofa',
        script: 'bpy.ops.mesh.primitive_cube_add()',
        scriptLanguage: 'python',
        modelUsed: 'claude-sonnet-4-6',
        status: TaskStatus.completed,
        completedAt: DateTime(2026, 8, 14, 10, 32),
        artifacts: const ['/tmp/out/sofa.png'],
      ));
      session.history.add(TaskRecord(
        sessionId: 's1',
        task: 'export render',
        status: TaskStatus.failed,
        error: 'timeout',
        createdAt: DateTime(2026, 8, 14, 10, 35),
      ));

      final md = buildSessionMarkdown(session, softwareDisplayName: 'Blender');
      expect(md, contains('# 会话导出: Blender'));
      expect(md, contains('会话 ID: s1'));
      expect(md, contains('软件: Blender'));
      expect(md, contains('3D 设计'));
      expect(md, contains('创建时间: 2026-08-14 10:30'));
      expect(md, contains('任务数: 2'));
      expect(md, contains('## 任务 1: create sofa'));
      expect(md, contains('状态: 已完成'));
      expect(md, contains('完成时间: 2026-08-14 10:32'));
      expect(md, contains('模型: claude-sonnet-4-6'));
      expect(md, contains('```python'));
      expect(md, contains('bpy.ops.mesh.primitive_cube_add()'));
      expect(md, contains('- /tmp/out/sofa.png'));
      expect(md, contains('## 任务 2: export render'));
      expect(md, contains('状态: 失败'));
      expect(md, contains('timeout'));
    });

    test('includes iteration log timeline and cancelled status', () {
      final session = Session(domain: DesignCategory.web, softwareName: 'figma');
      session.history.add(TaskRecord(
        sessionId: session.id,
        task: 'rename layer',
        status: TaskStatus.cancelled,
        iterationLog: const ['step1', 'step2'],
      ));

      final md = buildSessionMarkdown(session);
      expect(md, contains('**时间线**'));
      expect(md, contains('- step1'));
      expect(md, contains('- step2'));
      expect(md, contains('状态: 已取消'));
    });

    test('empty session still exports metadata', () {
      final session = Session(
        id: 's-empty',
        domain: DesignCategory.web,
        softwareName: 'figma',
      );
      final md = buildSessionMarkdown(session);
      expect(md, contains('会话 ID: s-empty'));
      expect(md, contains('任务数: 0'));
      expect(md, contains('该会话没有任务记录'));
    });
  });
}

class _FailingDeleteStore extends SessionStore {
  _FailingDeleteStore(super.db);

  @override
  Future<void> delete(String sessionId) async {
    throw Exception('db locked');
  }
}
