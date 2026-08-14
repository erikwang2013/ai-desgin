import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_design_studio/core/cc_runner.dart';
import 'package:ai_design_studio/core/script_executor_configs.dart';
import 'package:ai_design_studio/ui/settings/model_config_page.dart';
import 'package:ai_design_studio/ui/settings/proxy_settings_page.dart';
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

      // 脚本执行路径区加入后 About 位于列表底部，先滚动到可见。
      await tester.dragUntilVisible(
        find.text('About'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('github.com/erikwang2013/ai-desgin'),
          findsOneWidget);
      expect(find.text('Developer: erik'), findsOneWidget);
    });
  });

  group('Script executor path overrides', () {
    testWidgets('saves and restores custom executable path per plugin',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      const blenderPath = r'C:\Program Files\Blender Foundation\Blender 4.2\blender.exe';
      final blenderField = find.widgetWithText(TextField, 'Blender');
      expect(blenderField, findsOneWidget);
      expect(find.widgetWithText(TextField, 'FreeCAD'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'OpenSCAD'), findsOneWidget);
      expect(find.text('自动探测顺序：自定义路径 → PATH → 常见安装目录'),
          findsOneWidget);

      await tester.enterText(blenderField, blenderPath);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(executorPathOverrideKey('blender')),
        blenderPath,
      );
      expect(prefs.getString(executorPathOverrideKey('freecad')), isNull);

      // 重新进入设置页：回显已保存的自定义路径。
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Blender'))
            .controller
            ?.text,
        blenderPath,
      );
    });
  });
}
