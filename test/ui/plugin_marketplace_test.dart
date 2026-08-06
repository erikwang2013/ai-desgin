import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    expect(find.text('Installed (62)'), findsOneWidget);
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

  testWidgets('Uninstall persists across marketplace instances', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: PluginMarketplace(pluginManager: _createTestPluginManager()),
    ));

    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Sketch'),
      matching: find.text('Uninstall'),
    ));
    await tester.pumpAndSettle();

    // Fresh manager + fresh marketplace should re-apply the saved state,
    // keeping the uninstalled plugin listable in the Available section.
    await tester.pumpWidget(MaterialApp(
      home: PluginMarketplace(pluginManager: _createTestPluginManager()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Installed (61)'), findsOneWidget);

    // The Available section sits below 61 installed tiles; scroll to it.
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Sketch'), 300, scrollable: scrollable);
    expect(find.text('Available (1)'), findsOneWidget);
    expect(find.text('Sketch'), findsOneWidget);

    // Let the 'Sketch uninstalled' snackbar expire: it covers the bottom of
    // the viewport where the Install button sits, which would make the tap
    // miss its target.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Reinstall restores the plugin to the Installed section.
    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Sketch'),
      matching: find.text('Install'),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Installed (62)'), -300, scrollable: scrollable);
    expect(find.text('Installed (62)'), findsOneWidget);
  });
}
