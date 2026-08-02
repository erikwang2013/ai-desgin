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
    expect(find.text('Plugin Marketplace'), findsOneWidget);
    expect(find.text('Installed (50)'), findsOneWidget);
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
      matching: find.text('Uninstall'),
    );
    expect(uninstallButton, findsOneWidget);

    await tester.tap(uninstallButton);
    await tester.pumpAndSettle();

    expect(find.text('Sketch uninstalled'), findsOneWidget);
  });
}
