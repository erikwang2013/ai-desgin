import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_design_studio/core/cc_runner.dart';
import 'package:ai_design_studio/ui/agent_backend_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // AgentBackendView 的 initState 会运行真实 `claude --version` 子进程；
  // 整个测试体放进 runAsync（真实异步 zone）让子进程正常结束，否则其
  // 10s 超时计时器在 fake-async zone 中悬空导致 "Timer is still pending"。
  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('remote endpoint validation', () {
    testWidgets('invalid URL shows error snackbar and does not save',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: AgentBackendView()));

        await tester.enterText(find.byType(TextField).at(0), 'not-a-url');
        await tapSave(tester);

        expect(find.textContaining('Invalid endpoint'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('remote_endpoint_url'), isNull);
        expect(prefs.getString('remote_endpoint_key'), isNull);
      });
    });

    testWidgets('URL without a host is rejected', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: AgentBackendView()));

        await tester.enterText(find.byType(TextField).at(0), 'https://');
        await tapSave(tester);

        expect(find.textContaining('Invalid endpoint'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('remote_endpoint_url'), isNull);
      });
    });

    testWidgets('valid URL saves url and key', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: AgentBackendView()));

        await tester.enterText(
            find.byType(TextField).at(0), 'https://api.example.com/v1');
        await tester.enterText(find.byType(TextField).at(1), 'sk-test-123');
        await tapSave(tester);

        expect(
            find.textContaining('Remote endpoint config saved'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('remote_endpoint_url'), 'https://api.example.com/v1');
        expect(prefs.getString('remote_endpoint_key'), 'sk-test-123');
      });
    });

    testWidgets('http URL with a host is accepted by the view', (tester) async {
      // 非回环 http 的拒绝发生在 RemoteBackend.execute（运行期），视图层只校验 scheme+host。
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: AgentBackendView()));

        await tester.enterText(find.byType(TextField).at(0), 'http://10.0.0.8:8080');
        await tapSave(tester);

        expect(
            find.textContaining('Remote endpoint config saved'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('remote_endpoint_url'), 'http://10.0.0.8:8080');
      });
    });
  });

  group('backend dropdown', () {
    testWidgets('switching backend fires onBackendChanged', (tester) async {
      await tester.runAsync(() async {
        String? changed;
        await tester.pumpWidget(MaterialApp(
          home: AgentBackendView(
            currentBackendId: 'gemini',
            onBackendChanged: (v) => changed = v,
          ),
        ));

        expect(find.text('Gemini'), findsOneWidget);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Codex').last);
        await tester.pumpAndSettle();

        expect(changed, 'codex');
        expect(find.text('Codex'), findsOneWidget);
      });
    });
  });

  group('pinned version state', () {
    testWidgets('version row settles consistently with the real install',
        (tester) async {
      await tester.runAsync(() async {
        final installed = await CCRunner.installedVersion();
        await tester.pumpWidget(const MaterialApp(home: AgentBackendView()));
        // 等 initState 里的 _checkVersion 真实子进程完成（本机 claude 2.1.143）。
        await Future<void>.delayed(const Duration(seconds: 3));
        await tester.pump();

        if (installed == CCRunner.pinnedClaudeVersion) {
          expect(find.text('Up to date'), findsOneWidget);
          expect(find.textContaining('Install Claude Code'), findsNothing);
        } else {
          expect(
              find.text('Install Claude Code ${CCRunner.pinnedClaudeVersion}'),
              findsOneWidget);
        }
      });
    });
  });
}
