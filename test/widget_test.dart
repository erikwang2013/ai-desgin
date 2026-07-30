import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_design_studio/app.dart';

void main() {
  testWidgets('App displays placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const AiDesignApp());

    expect(find.byType(Placeholder), findsOneWidget);
  });
}
