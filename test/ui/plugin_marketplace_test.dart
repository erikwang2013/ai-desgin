import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_design_studio/core/plugin_manager.dart';
import 'package:ai_design_studio/core/builtin_plugins.dart';
import 'package:ai_design_studio/ui/plugin_marketplace.dart';

PluginManager _createTestPluginManager() {
  final pm = PluginManager();
  for (final p in builtInPlugins) {
    pm.register(p);
  }
  return pm;
}

void main() {
  final pm = _createTestPluginManager();

  testWidgets('Plugin marketplace shows installed plugins', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PluginMarketplace(pluginManager: pm)));
    expect(find.text('插件市场'), findsOneWidget);
    expect(find.text('已安装 (47)'), findsOneWidget);
    expect(find.text('Figma'), findsOneWidget);
    expect(find.text('Sketch'), findsOneWidget);
    expect(find.text('Photoshop'), findsOneWidget);
  });

  testWidgets('Uninstall button toggles plugin status', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PluginMarketplace(pluginManager: pm)));

    final sketchTile = find.widgetWithText(ListTile, 'Sketch');
    expect(sketchTile, findsOneWidget);

    final uninstallButton = find.descendant(
      of: sketchTile,
      matching: find.text('卸载'),
    );
    expect(uninstallButton, findsOneWidget);

    await tester.tap(uninstallButton);
    await tester.pumpAndSettle();

    expect(find.text('Sketch 已卸载'), findsOneWidget);
  });
}
