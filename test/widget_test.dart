import 'package:flutter_test/flutter_test.dart';

import 'package:ai_design_studio/app.dart';
import 'package:ai_design_studio/ui/chat_view.dart';

void main() {
  testWidgets('App renders chat view by default', (WidgetTester tester) async {
    await tester.pumpWidget(const AiDesignApp());

    expect(find.byType(ChatView), findsOneWidget);
    expect(find.text('描述你想要的设计操作...'), findsOneWidget);
  });
}
