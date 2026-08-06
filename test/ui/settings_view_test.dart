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
  });
}
