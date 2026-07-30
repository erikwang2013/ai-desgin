import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_design_studio/ui/plugin_marketplace.dart';

void main() {
  testWidgets('Plugin marketplace shows installed and available plugins', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PluginMarketplace()));
    expect(find.text('插件市场'), findsOneWidget);
    expect(find.text('已安装 (4)'), findsOneWidget);
    expect(find.text('可安装 (4)'), findsOneWidget);
    expect(find.text('Figma'), findsOneWidget);
    expect(find.text('Sketch'), findsOneWidget);
  });

  testWidgets('Install button toggles plugin status', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PluginMarketplace()));

    // Find the Sketch tile and its install button
    final sketchTile = find.widgetWithText(ListTile, 'Sketch');
    expect(sketchTile, findsOneWidget);

    final installButton = find.descendant(
      of: sketchTile,
      matching: find.text('安装'),
    );
    expect(installButton, findsOneWidget);

    await tester.tap(installButton);
    await tester.pumpAndSettle();

    // Should show success snackbar
    expect(find.text('Sketch 安装成功'), findsOneWidget);
  });
}
