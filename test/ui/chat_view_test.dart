import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_design_studio/ui/chat_view.dart';

void main() {
  testWidgets('ChatView shows input field and send button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatView()));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('Send button is disabled when input is empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatView()));
    final sendButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(sendButton.onPressed, isNull);
  });

  testWidgets('Typing text enables send button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatView()));
    await tester.enterText(find.byType(TextField), 'create a blue circle');
    await tester.pump();
    final sendButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(sendButton.onPressed, isNotNull);
  });

  testWidgets('Pressing send adds message and clears input', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatView()));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('loading state shows stop button that triggers cancel callback', (tester) async {
    var cancelled = false;
    final completer = Completer<String>();
    await tester.pumpWidget(MaterialApp(
      home: ChatView(
        onSubmit: (_) => completer.future,
        onCancel: () => cancelled = true,
      ),
    ));

    await tester.enterText(find.byType(TextField), 'slow task');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // 加载中：发送键切换为停止键。
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.send), findsNothing);

    await tester.tap(find.byIcon(Icons.stop));
    expect(cancelled, isTrue);
  });

  testWidgets('stop button is disabled when no cancel callback provided', (tester) async {
    final completer = Completer<String>();
    await tester.pumpWidget(MaterialApp(
      home: ChatView(onSubmit: (_) => completer.future),
    ));

    await tester.enterText(find.byType(TextField), 'slow task');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    final stopButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.stop),
    );
    expect(stopButton.onPressed, isNull);
  });
}
