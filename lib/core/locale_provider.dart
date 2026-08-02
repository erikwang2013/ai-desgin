import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';
  Locale _locale = const Locale('zh');

  Locale get locale => _locale;

  static const supportedLocales = [
    Locale('zh'),
    Locale('en'),
    Locale('ru'),
    Locale('es'),
    Locale('ko'),
    Locale('ja'),
    Locale('fr'),
    Locale('de'),
    Locale('ar'),
    Locale('fil'),
    Locale('hi'),
    Locale('fa'),
  ];

  static const languageNames = {
    'zh': '中文',
    'en': 'English',
    'ru': 'Русский',
    'es': 'Español',
    'ko': '한국어',
    'ja': '日本語',
    'fr': 'Français',
    'de': 'Deutsch',
    'ar': 'العربية',
    'fil': 'Filipino',
    'hi': 'हिन्दी',
    'fa': 'فارسی',
  };

  static const languageInstructions = {
    'zh': '请使用中文回复。',
    'en': 'Please respond in English.',
    'ru': 'Пожалуйста, отвечайте на русском языке.',
    'es': 'Por favor, responde en español.',
    'ko': '한국어로 답변해 주세요.',
    'ja': '日本語で返信してください。',
    'fr': 'Veuillez répondre en français.',
    'de': 'Bitte antworten Sie auf Deutsch.',
    'ar': 'الرجاء الرد باللغة العربية.',
    'fil': 'Mangyaring tumugon sa wikang Filipino.',
    'hi': 'कृपया हिंदी में उत्तर दें।',
    'fa': 'لطفاً به فارسی پاسخ دهید.',
  };

  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (_) {
      // Default to zh on failure
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale.languageCode);
    } catch (_) {
      // Non-critical; locale still applied for this session
    }
  }

  String get languageInstruction =>
      languageInstructions[_locale.languageCode] ?? languageInstructions['zh']!;
}
