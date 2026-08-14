import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_design_studio/ui/settings/backend_credentials_page.dart';
import 'package:ai_design_studio/ui/settings_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('BackendCredentialsPage', () {
    testWidgets('loads saved keys from prefs', (tester) async {
      SharedPreferences.setMockInitialValues({
        'openai_api_key': 'sk-openai-1',
        'gemini_api_key': 'gem-key-1',
      });
      await tester.pumpWidget(const MaterialApp(home: BackendCredentialsPage()));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
        'sk-openai-1',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
        'gem-key-1',
      );
    });

    testWidgets('renders password-masked key fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BackendCredentialsPage()));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byType(TextField).at(0)).obscureText,
          isTrue);
      expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
          isTrue);
    });

    testWidgets('saves keys to prefs and notifies callback', (tester) async {
      String? savedOpenai;
      String? savedGemini;
      await tester.pumpWidget(MaterialApp(
        home: BackendCredentialsPage(
          onCredentialsSaved: (openai, gemini) {
            savedOpenai = openai;
            savedGemini = gemini;
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'sk-openai-2');
      await tester.enterText(find.byType(TextField).at(1), 'gem-key-2');
      await tapSave(tester);

      expect(find.text('Saved successfully'), findsOneWidget);
      expect(savedOpenai, 'sk-openai-2');
      expect(savedGemini, 'gem-key-2');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('openai_api_key'), 'sk-openai-2');
      expect(prefs.getString('gemini_api_key'), 'gem-key-2');
    });

    testWidgets('clearing keys restores env/CLI-login fallback', (tester) async {
      SharedPreferences.setMockInitialValues({
        'openai_api_key': 'sk-openai-1',
        'gemini_api_key': 'gem-key-1',
      });
      await tester.pumpWidget(const MaterialApp(home: BackendCredentialsPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '   ');
      await tester.enterText(find.byType(TextField).at(1), '');
      await tapSave(tester);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('openai_api_key'), '');
      expect(prefs.getString('gemini_api_key'), '');
    });
  });

  group('SettingsView tile navigation', () {
    testWidgets('navigates to BackendCredentialsPage from settings',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('API Key'));
      await tester.pumpAndSettle();

      expect(find.byType(BackendCredentialsPage), findsOneWidget);
    });
  });
}
