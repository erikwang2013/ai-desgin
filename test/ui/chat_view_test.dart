import 'dart:async';

import 'package:flutter/services.dart';
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

  testWidgets('assistant message renders image artifact inline', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChatView(
        onSubmit: (_) async => 'Task completed',
        onArtifacts: (_) async => ['/tmp/out/render.png'],
      ),
    ));
    await tester.enterText(find.byType(TextField), 'render scene');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Task completed'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('non-image artifact renders as file chip with its name', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChatView(
        onSubmit: (_) async => 'Task completed',
        onArtifacts: (_) async => ['/tmp/out/report.csv'],
      ),
    ));
    await tester.enterText(find.byType(TextField), 'export report');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('report.csv'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('onArtifacts failure is swallowed and message still shows', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChatView(
        onSubmit: (_) async => 'Task completed',
        onArtifacts: (_) async => throw Exception('boom'),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'render scene');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Task completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assistant message copy button copies the response text', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(MaterialApp(
      home: ChatView(onSubmit: (_) async => 'layer.create(); export()'),
    ));
    await tester.enterText(find.byType(TextField), 'make a layer');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    expect(copied, 'layer.create(); export()');
  });
}
