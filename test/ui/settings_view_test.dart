import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_design_studio/core/cc_runner.dart';
import 'package:ai_design_studio/ui/settings_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CCRunner.apiBaseUrl = null;
    CCRunner.apiAuthToken = null;
    CCRunner.proxyEnvironment = null;
  });

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ModelConfigPage validation', () {
    testWidgets('rejects invalid endpoint URL without saving', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ModelConfigPage()));

      await tester.enterText(find.byType(TextField).at(0), 'not-a-url');
      await tapSave(tester);

      expect(find.textContaining('Invalid endpoint'), findsOneWidget);
      expect(CCRunner.apiBaseUrl, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('api_endpoint'), isNull);
    });

    testWidgets('rejects malformed model name without saving', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ModelConfigPage()));

      await tester.enterText(
          find.byType(TextField).at(0), 'https://api.example.com/v1');
      await tester.enterText(find.byType(TextField).at(2), 'bad model!');
      await tapSave(tester);

      expect(find.textContaining('Invalid model name'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('api_endpoint'), isNull);
    });

    testWidgets('saves valid config and applies it to CCRunner', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ModelConfigPage()));

      await tester.enterText(
          find.byType(TextField).at(0), 'https://api.example.com/v1');
      await tester.enterText(find.byType(TextField).at(1), 'sk-ant-test');
      await tester.enterText(find.byType(TextField).at(2), 'claude-sonnet-4-6');
      await tapSave(tester);

      expect(find.text('Saved successfully'), findsOneWidget);
      expect(CCRunner.apiBaseUrl, 'https://api.example.com/v1');
      expect(CCRunner.apiAuthToken, 'sk-ant-test');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('api_endpoint'), 'https://api.example.com/v1');
      expect(prefs.getString('api_key'), 'sk-ant-test');
      expect(prefs.getString('default_model'), 'claude-sonnet-4-6');
    });
  });

  group('ProxySettingsPage validation', () {
    testWidgets('rejects non-numeric port without saving', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProxySettingsPage()));

      await tester.enterText(find.byType(TextField).at(0), '127.0.0.1');
      await tester.enterText(find.byType(TextField).at(1), 'abc');
      await tapSave(tester);

      expect(find.textContaining('Invalid proxy port'), findsOneWidget);
      expect(CCRunner.proxyEnvironment, isNull);
    });

    testWidgets('rejects out-of-range port', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProxySettingsPage()));

      await tester.enterText(find.byType(TextField).at(0), '127.0.0.1');
      await tester.enterText(find.byType(TextField).at(1), '70000');
      await tapSave(tester);

      expect(find.textContaining('Invalid proxy port'), findsOneWidget);
    });

    testWidgets('rejects port without a host', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProxySettingsPage()));

      await tester.enterText(find.byType(TextField).at(1), '7890');
      await tapSave(tester);

      expect(find.textContaining('Proxy host is required'), findsOneWidget);
      expect(CCRunner.proxyEnvironment, isNull);
    });

    testWidgets('saves valid proxy, stripping an optional scheme', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProxySettingsPage()));

      await tester.enterText(
          find.byType(TextField).at(0), 'http://127.0.0.1');
      await tester.enterText(find.byType(TextField).at(1), '7890');
      await tapSave(tester);

      expect(find.text('Saved successfully'), findsOneWidget);
      expect(CCRunner.proxyEnvironment,
          {'HTTP_PROXY': 'http://127.0.0.1:7890', 'HTTPS_PROXY': 'http://127.0.0.1:7890'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('proxy_host'), '127.0.0.1');
      expect(prefs.getString('proxy_port'), '7890');
    });

    testWidgets('rejects a port embedded in the host alongside a port field', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProxySettingsPage()));

      await tester.enterText(find.byType(TextField).at(0), '127.0.0.1:7890');
      await tester.enterText(find.byType(TextField).at(1), '7890');
      await tapSave(tester);

      expect(find.textContaining('put the port in the port field'), findsOneWidget);
      expect(CCRunner.proxyEnvironment, isNull);
    });

    testWidgets('restores saved scheme into the host field and keeps it on re-save', (tester) async {
      SharedPreferences.setMockInitialValues({
        'proxy_scheme': 'https',
        'proxy_host': 'proxy.example.com',
        'proxy_port': '8443',
      });
      await tester.pumpWidget(const MaterialApp(home: ProxySettingsPage()));
      await tester.pumpAndSettle();

      // 回显带 scheme 前缀，再次保存不会降级成 http。
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
        'https://proxy.example.com',
      );

      await tapSave(tester);
      expect(CCRunner.proxyEnvironment,
          {'HTTP_PROXY': 'https://proxy.example.com:8443', 'HTTPS_PROXY': 'https://proxy.example.com:8443'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('proxy_scheme'), 'https');
    });
  });

  group('About dialog links', () {
    testWidgets('shows GitHub and developer links', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('github.com/erikwang2013/ai-desgin'),
          findsOneWidget);
      expect(find.text('Developer: erik'), findsOneWidget);
    });
  });
}
