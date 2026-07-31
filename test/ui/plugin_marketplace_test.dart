import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_design_studio/ui/plugin_marketplace.dart';

void main() {
  testWidgets('Plugin marketplace shows installed plugins', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PluginMarketplace()));
    expect(find.text('插件市场'), findsOneWidget);
    expect(find.text('已安装 (27)'), findsOneWidget);
    expect(find.text('Figma'), findsOneWidget);
    expect(find.text('Sketch'), findsOneWidget);
    expect(find.text('Revit'), findsOneWidget);
  });

  testWidgets('Uninstall button toggles plugin status', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PluginMarketplace()));

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
