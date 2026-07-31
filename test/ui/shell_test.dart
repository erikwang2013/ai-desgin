import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_design_studio/ui/shell.dart';
import 'package:ai_design_studio/models/session.dart';

void main() {
  testWidgets('Shell renders sidebar and content area', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell(selectedDomain: DesignCategory.web, child: Text('Content'))));
    expect(find.text('AI Design'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('Sidebar renders domain switcher', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell(selectedDomain: DesignCategory.web, child: Text('test'))));
    expect(find.text('Web 设计'), findsOneWidget);
    expect(find.text('3D 设计'), findsOneWidget);
    expect(find.text('建筑设计'), findsOneWidget);
  });

  testWidgets('Selecting domain fires callback', (tester) async {
    DesignCategory? selected;
    await tester.pumpWidget(MaterialApp(
      home: AppShell(selectedDomain: DesignCategory.web, child: const Text('test'), onDomainChanged: (d) => selected = d),
    ));
    await tester.tap(find.text('工业设计'));
    await tester.pumpAndSettle();
    expect(selected, DesignCategory.industrial);
  });
}
