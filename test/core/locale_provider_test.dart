import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_design_studio/core/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('loadSavedLocale', () {
    test('defaults to zh when nothing is saved', () async {
      final provider = LocaleProvider();
      await provider.loadSavedLocale();
      expect(provider.locale, const Locale('zh'));
    });

    test('restores a supported locale', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      final provider = LocaleProvider();
      await provider.loadSavedLocale();
      expect(provider.locale, const Locale('en'));
    });

    test('ignores an unsupported code and keeps the default zh', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'xx'});
      final provider = LocaleProvider();
      await provider.loadSavedLocale();
      expect(provider.locale, const Locale('zh'));
    });
  });

  group('setLocale', () {
    test('applies the locale, notifies listeners and persists it', () async {
      final provider = LocaleProvider();
      var notified = 0;
      provider.addListener(() => notified++);

      await provider.setLocale(const Locale('ja'));

      expect(provider.locale, const Locale('ja'));
      expect(notified, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'ja');
    });

    test('a fresh provider restores the persisted locale', () async {
      final provider = LocaleProvider();
      await provider.setLocale(const Locale('de'));

      final restored = LocaleProvider();
      await restored.loadSavedLocale();
      expect(restored.locale, const Locale('de'));
    });
  });

  group('languageInstruction', () {
    test('returns the instruction for the current locale', () async {
      final provider = LocaleProvider();
      expect(provider.languageInstruction, '请使用中文回复。');

      await provider.setLocale(const Locale('en'));
      expect(provider.languageInstruction, 'Please respond in English.');
    });

    test('falls back to zh for unsupported locales', () async {
      final provider = LocaleProvider();
      await provider.setLocale(const Locale('xx'));
      expect(provider.languageInstruction, '请使用中文回复。');
    });
  });

  test('supportedLocales and languageNames cover the same codes', () {
    final codes = LocaleProvider.supportedLocales.map((l) => l.languageCode).toSet();
    expect(codes, containsAll(LocaleProvider.languageNames.keys));
  });
}
