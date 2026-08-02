# Multi-Language Support Design

**Date**: 2026-08-02
**Status**: Approved

## Overview

Add i18n/l10n support to AI Design Studio for 12 languages, translating both UI text and AI conversation responses.

## Languages

| Code | Language | Direction |
|------|----------|-----------|
| zh | Chinese (default) | LTR |
| en | English (fallback) | LTR |
| ru | Russian | LTR |
| es | Spanish | LTR |
| ko | Korean | LTR |
| ja | Japanese | LTR |
| fr | French | LTR |
| de | German | LTR |
| ar | Arabic | RTL |
| fil | Filipino | LTR |
| hi | Hindi | LTR |
| fa | Persian | RTL |

## Approach

Flutter official ARB-based localization using `flutter_localizations` + `intl` + `shared_preferences`.

## File Structure

```
lib/
  l10n/
    app_zh.arb          # Chinese (default)
    app_en.arb          # English (fallback for missing keys)
    app_ru.arb
    app_es.arb
    app_ko.arb
    app_ja.arb
    app_fr.arb
    app_de.arb
    app_ar.arb          # RTL
    app_fil.arb
    app_hi.arb
    app_fa.arb          # RTL
  core/
    locale_provider.dart
  ui/
    language_selector.dart
```

## Data Flow

```
Language switch
  → LanguageSelector
    → LocaleProvider.setLocale('en')
      → SharedPreferences (persist)
      → notifyListeners()
        → MaterialApp rebuilds with new locale
          → Widgets use AppLocalizations.of(context) for text
        → TaskOrchestrator reads current locale,
          injects language instruction into AI prompt
```

## Key Changes

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `intl`, `shared_preferences` deps; enable `generate: true` in flutter section |
| `lib/main.dart` | Init locale provider before runApp |
| `lib/app.dart` | Add `localizationsDelegates`, `supportedLocales`, `locale` to MaterialApp |
| `lib/core/locale_provider.dart` | New — ChangeNotifier managing locale state, persistence, AI instruction |
| `lib/l10n/*.arb` | New — 12 ARB files with translated strings |
| `lib/core/task_orchestrator.dart` | Inject language instruction when submitting task |
| `lib/ui/shell.dart` | Add language switcher at sidebar bottom |
| `lib/ui/settings_view.dart` | Add language selection list item |
| `lib/ui/chat_view.dart` | Replace hardcoded Chinese with AppLocalizations |
| `lib/ui/software_panel.dart` | Replace hardcoded Chinese with AppLocalizations |
| `lib/ui/task_dashboard.dart` | Replace hardcoded Chinese with AppLocalizations |
| `lib/ui/plugin_marketplace.dart` | Replace hardcoded Chinese with AppLocalizations |

## LocaleProvider

```dart
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh');
  Locale get locale => _locale;

  Future<void> loadSavedLocale();          // Load from SharedPreferences on startup
  Future<void> setLocale(Locale locale);   // Switch and persist
  String get languageInstruction;          // e.g. "请使用中文回复。" for injection into AI prompt
  List<Locale> get supportedLocales;       // All 12 locales
}
```

## AI Language Instruction

In `TaskOrchestrator.submitTask()`, prepend a language directive to the task prompt based on current locale. Example:
- zh: `请使用中文回复。`
- en: `Please respond in English.`
- ja: `日本語で返信してください。`
- ...etc for all 12 languages

## Fallback Strategy

- ARB fallback: `app_en.arb` is the fallback locale — missing keys in any language default to English
- SharedPreferences read failure: default to Chinese ('zh'), app functions normally
- Language instruction injection failure: task proceeds without instruction, no error

## RTL Support

`ar` (Arabic) and `fa` (Persian) locales automatically trigger RTL layout via Flutter's `Directionality` widget, handled by `flutter_localizations`.

## Testing

- `LocaleProvider` unit tests: switch language, verify persistence and restore
- ARB integrity test: verify all 12 ARB files contain identical key sets
- `TaskOrchestrator` test: verify language instruction is correctly injected into prompt
- Manual: visual check of RTL layout for Arabic and Persian
