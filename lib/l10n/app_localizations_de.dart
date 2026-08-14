// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get about => 'Über';

  @override
  String get aboutDescription1 =>
      'Ein KI-gesteuertes Automatisierungstool für Designsoftware.';

  @override
  String get aboutDescription2 =>
      'Deckt 6 Designbereiche und über 62 Designprogramme mit KI-Skripterstellung ab.';

  @override
  String get aboutDeveloper => 'Entwickler: erik';

  @override
  String get aboutPackageName => 'Paketname: Ai Desgin';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get agentBackend => 'Agent Backend';

  @override
  String get agentBackendDesc =>
      'Choose the agent CLI used to generate scripts';

  @override
  String get all => 'Alle';

  @override
  String get apiEndpoint => 'API-Endpunkt';

  @override
  String get apiKey => 'API-Schlüssel';

  @override
  String get appTitle => 'AI Design';

  @override
  String get autoExecute => 'Auto';

  @override
  String available(Object count) {
    return 'Verfügbar ($count)';
  }

  @override
  String get backendClaude => 'Claude Code';

  @override
  String get backendCodex => 'Codex';

  @override
  String get backendGemini => 'Gemini';

  @override
  String get backendHermes => 'Hermes';

  @override
  String get backendOpenclaw => 'OpenClaw';

  @override
  String get backendOpencode => 'OpenCode';

  @override
  String get backendReasonix => 'Reasonix';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get categoryAd => 'Werbung';

  @override
  String get categoryArch => 'Architektur';

  @override
  String get categoryIndustrial => 'Industriedesign';

  @override
  String get categoryInterior => 'Innenarchitektur';

  @override
  String get categoryThreeD => '3D-Design';

  @override
  String get categoryWeb => 'Webdesign';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get close => 'Schließen';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get connected => 'Verbunden';

  @override
  String get copied => 'Kopiert';

  @override
  String get copy => 'Kopieren';

  @override
  String get defaultModel => 'Standardmodell';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAll => 'Delete All';

  @override
  String deleteAllConfirm(Object count) {
    return 'Delete all $count sessions?';
  }

  @override
  String get deleteConfirm => 'Delete this session?';

  @override
  String deleteSelected(Object count) {
    return 'Delete Selected ($count)';
  }

  @override
  String get designDomains => 'Designbereiche';

  @override
  String get disconnected => 'Nicht verbunden';

  @override
  String get done => 'Done';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get endpointUrl => 'Endpunkt-URL';

  @override
  String get enterExportPath => 'Exportpfad eingeben (.zip)';

  @override
  String get enterPluginPackagePath => 'Enter plugin package (.zip) path';

  @override
  String get errorPrefix => 'Fehler';

  @override
  String get exportAction => 'Export';

  @override
  String exportPluginFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String exportPluginSuccess(Object path) {
    return 'Exported to $path';
  }

  @override
  String get exportHistory => 'Export';

  @override
  String get exportHistoryFailed => 'Export failed';

  @override
  String get exportNoSessions => 'No sessions to export';

  @override
  String get hintText => 'Beschreiben Sie die gewünschte Design-Operation...';

  @override
  String get history => 'Verlauf';

  @override
  String get historyList => 'History';

  @override
  String get importAction => 'Import';

  @override
  String importFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String importSuccess(Object name, Object count) {
    return 'Imported \"$name\" with $count scripts';
  }

  @override
  String get inProgress => 'In Bearbeitung';

  @override
  String get install => 'Installieren';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installPlugin => 'Plugin installieren';

  @override
  String installSuccess(Object name) {
    return '$name erfolgreich installiert';
  }

  @override
  String installed(Object count) {
    return 'Installiert ($count)';
  }

  @override
  String get installedPlugins => 'Installierte Plugins';

  @override
  String get installingClaude => 'Installing...';

  @override
  String get invalidEndpointUrl =>
      'Invalid endpoint URL (e.g. https://api.example.com/v1)';

  @override
  String get invalidModelName =>
      'Invalid model name (letters, digits, dot, dash, underscore only)';

  @override
  String get invalidProxyHostPath =>
      'Invalid proxy host (host name only, no path)';

  @override
  String get invalidProxyHostSpaces => 'Invalid proxy host (no spaces allowed)';

  @override
  String get invalidProxyPort => 'Invalid proxy port (1-65535)';

  @override
  String get language => 'Sprache';

  @override
  String get languageInstruction => 'Bitte antworten Sie auf Deutsch.';

  @override
  String get manage => 'Manage';

  @override
  String get manualExecute => 'Manuell';

  @override
  String get rustConnected => 'Rust core connected · registry from Rust';

  @override
  String get rustDisconnected =>
      'Rust core offline · using built-in Dart registry';

  @override
  String get modelConfig => 'Modellkonfiguration';

  @override
  String get modelConfigDesc => 'API-Endpunkt und Schlüssel verwalten';

  @override
  String get navigation => 'Navigation';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get historySearchHint => 'Verlauf suchen';

  @override
  String get searchNoResults => 'Keine passenden Sitzungen';

  @override
  String get deleteFailed => 'Löschen fehlgeschlagen';

  @override
  String get exportMarkdown => 'Als Markdown exportieren';

  @override
  String get openFailed => 'Öffnen fehlgeschlagen';

  @override
  String get more => 'Mehr';

  @override
  String get noOutput => '(keine Ausgabe)';

  @override
  String get noPluginsToExport => 'No installed plugins to export';

  @override
  String get noTasks => 'Keine Aufgaben';

  @override
  String get noTasksHint =>
      'Geben Sie Designanforderungen im Chat ein; Aufgaben erscheinen hier.';

  @override
  String get ok => 'OK';

  @override
  String get pluginMarket => 'Plugin-Marktplatz';

  @override
  String get pluginMarketDesc => 'Plugins durchsuchen und installieren';

  @override
  String get proxyHost => 'Proxy-Host';

  @override
  String get proxyHostRequired => 'Proxy host is required when a port is set';

  @override
  String get proxyPort => 'Proxy-Port';

  @override
  String get proxySettings => 'Proxy-Einstellungen';

  @override
  String get proxySettingsDesc => 'Netzwerk-Proxy konfigurieren';

  @override
  String get remoteConfigSaveFailed => 'Failed to save remote endpoint config';

  @override
  String get remoteConfigSaved => 'Remote endpoint config saved';

  @override
  String get remoteEndpoint => 'Remote Endpoint';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Speichern';

  @override
  String get saveSuccess => 'Erfolgreich gespeichert';

  @override
  String get searchPlugins => 'Plugins suchen...';

  @override
  String get selectPluginToExport => 'Select plugin to export';

  @override
  String get settings => 'Einstellungen';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlugins => 'Plugins';

  @override
  String get tabTasks => 'Aufgaben';

  @override
  String get targetSoftware => 'Zielsoftware:';

  @override
  String get taskCompleted => 'Aufgabe abgeschlossen';

  @override
  String get taskFailed => 'Aufgabe fehlgeschlagen';

  @override
  String get taskList => 'Aufgabenliste';

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get uninstall => 'Deinstallieren';

  @override
  String uninstallSuccess(Object name) {
    return '$name deinstalliert';
  }

  @override
  String get unknownError => 'Unbekannter Fehler';
}
