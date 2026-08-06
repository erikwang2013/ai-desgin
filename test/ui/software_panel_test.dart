import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_design_studio/core/plugin_manager.dart';
import 'package:ai_design_studio/core/builtin_plugins.dart';
import 'package:ai_design_studio/core/local_script_executor.dart';
import 'package:ai_design_studio/ui/software_panel.dart';

PluginManager _createTestPluginManager() {
  final pm = PluginManager();
  for (final p in builtInPlugins) {
    pm.register(p);
  }
  return pm;
}

void main() {
  Future<void> pumpPanel(WidgetTester tester) async {
    LocalScriptExecutor.instance = LocalScriptExecutor();
    addTearDown(() => LocalScriptExecutor.instance = null);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SoftwarePanel(pluginManager: _createTestPluginManager())),
    ));
  }

  testWidgets('Software panel shows Auto/Manual badges per plugin', (tester) async {
    await pumpPanel(tester);

    await tester.enterText(find.byType(TextField), 'blender');
    await tester.pump();
    expect(find.text('Auto'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'figma');
    await tester.pump();
    expect(find.text('Manual'), findsOneWidget);
  });

  testWidgets('Software panel groups plugins by domain', (tester) async {
    await pumpPanel(tester);

    // First group header is visible at the top of the list
    expect(find.textContaining('工业设计'), findsOneWidget);
  });

  testWidgets('Software panel search filters plugins', (tester) async {
    await pumpPanel(tester);

    await tester.enterText(find.byType(TextField), 'figma');
    await tester.pump();
    expect(find.text('Figma'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'blender');
    await tester.pump();
    expect(find.text('Blender'), findsOneWidget);
    expect(find.text('Figma'), findsNothing);
  });
}
