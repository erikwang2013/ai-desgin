// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => 'Designbereiche';

  @override
  String get navigation => 'Navigation';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabTasks => 'Aufgaben';

  @override
  String get tabPlugins => 'Plugins';

  @override
  String get settings => 'Einstellungen';

  @override
  String get targetSoftware => 'Zielsoftware:';

  @override
  String get hintText => 'Beschreiben Sie die gewünschte Design-Operation...';

  @override
  String get modelConfig => 'Modellkonfiguration';

  @override
  String get modelConfigDesc => 'API-Endpunkt und Schlüssel verwalten';

  @override
  String get pluginMarket => 'Plugin-Marktplatz';

  @override
  String get pluginMarketDesc => 'Plugins durchsuchen und installieren';

  @override
  String get proxySettings => 'Proxy-Einstellungen';

  @override
  String get proxySettingsDesc => 'Netzwerk-Proxy konfigurieren';

  @override
  String get about => 'Über';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get aboutDescription1 =>
      'Ein KI-gesteuertes Automatisierungstool für Designsoftware.';

  @override
  String get aboutDescription2 =>
      'Deckt 6 Designbereiche und über 62 Designprogramme mit KI-Skripterstellung ab.';

  @override
  String get aboutPackageName => 'Paketname: Ai Desgin';

  @override
  String get aboutDeveloper => 'Entwickler: erik';

  @override
  String get retry => 'Retry';

  @override
  String get installedPlugins => 'Installierte Plugins';

  @override
  String get installPlugin => 'Plugin installieren';

  @override
  String get connected => 'Verbunden';

  @override
  String get disconnected => 'Nicht verbunden';

  @override
  String get all => 'Alle';

  @override
  String get inProgress => 'In Bearbeitung';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get taskList => 'Aufgabenliste';

  @override
  String get noTasks => 'Keine Aufgaben';

  @override
  String get noTasksHint =>
      'Geben Sie Designanforderungen im Chat ein; Aufgaben erscheinen hier.';

  @override
  String installed(Object count) {
    return 'Installiert ($count)';
  }

  @override
  String available(Object count) {
    return 'Verfügbar ($count)';
  }

  @override
  String get install => 'Installieren';

  @override
  String get uninstall => 'Deinstallieren';

  @override
  String installSuccess(Object name) {
    return '$name erfolgreich installiert';
  }

  @override
  String uninstallSuccess(Object name) {
    return '$name deinstalliert';
  }

  @override
  String get ok => 'OK';

  @override
  String get errorPrefix => 'Fehler';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => 'Aufgabe abgeschlossen';

  @override
  String get taskFailed => 'Aufgabe fehlgeschlagen';

  @override
  String get noOutput => '(keine Ausgabe)';

  @override
  String get unknownError => 'Unbekannter Fehler';

  @override
  String get languageInstruction => 'Bitte antworten Sie auf Deutsch.';

  @override
  String get language => 'Sprache';

  @override
  String get apiEndpoint => 'API-Endpunkt';

  @override
  String get apiKey => 'API-Schlüssel';

  @override
  String get defaultModel => 'Standardmodell';

  @override
  String get save => 'Speichern';

  @override
  String get proxyHost => 'Proxy-Host';

  @override
  String get proxyPort => 'Proxy-Port';

  @override
  String get saveSuccess => 'Erfolgreich gespeichert';

  @override
  String get history => 'Verlauf';

  @override
  String get searchPlugins => 'Plugins suchen...';

  @override
  String get autoExecute => 'Auto';

  @override
  String get manualExecute => 'Manuell';

  @override
  String get copied => 'Kopiert';

  @override
  String get copy => 'Kopieren';

  @override
  String get close => 'Schließen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get tabHistory => 'History';

  @override
  String get historyList => 'History';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get manage => 'Manage';

  @override
  String get done => 'Done';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAll => 'Delete All';

  @override
  String deleteSelected(Object count) {
    return 'Delete Selected ($count)';
  }

  @override
  String get deleteConfirm => 'Delete this session?';

  @override
  String deleteAllConfirm(Object count) {
    return 'Delete all $count sessions?';
  }

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get agentBackend => 'Agent Backend';

  @override
  String get agentBackendDesc =>
      'Choose the agent CLI used to generate scripts';

  @override
  String get backendClaude => 'Claude Code';

  @override
  String get backendCodex => 'Codex';

  @override
  String get backendGemini => 'Gemini';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installingClaude => 'Installing...';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';
}
