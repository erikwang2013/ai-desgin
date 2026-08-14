// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get aboutDescription1 =>
      'An AI-driven design software automation tool.';

  @override
  String get aboutDescription2 =>
      'Covers 6 design domains and 62+ mainstream design software with AI-driven script generation and execution.';

  @override
  String get aboutDeveloper => 'Developer: erik';

  @override
  String get aboutPackageName => 'Package name: Ai Desgin';

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
  String get all => 'All';

  @override
  String get apiEndpoint => 'API Endpoint';

  @override
  String get apiKey => 'API Key';

  @override
  String get appTitle => 'AI Design';

  @override
  String get artifacts => 'Artifacts';

  @override
  String get autoExecute => 'Auto';

  @override
  String available(Object count) {
    return 'Available ($count)';
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
  String get cancel => 'Cancel';

  @override
  String get categoryAd => 'Advertising Design';

  @override
  String get categoryArch => 'Architecture';

  @override
  String get categoryIndustrial => 'Industrial Design';

  @override
  String get categoryInterior => 'Interior Design';

  @override
  String get categoryThreeD => '3D Design';

  @override
  String get categoryWeb => 'Web Design';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get close => 'Close';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get completed => 'Completed';

  @override
  String get connected => 'Connected';

  @override
  String get copied => 'Copied';

  @override
  String get copy => 'Copy';

  @override
  String get defaultModel => 'Default Model';

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
  String get designDomains => 'Design Domains';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get done => 'Done';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get endpointUrl => 'Endpoint URL';

  @override
  String get enterExportPath => 'Enter export path (.zip)';

  @override
  String get enterPluginPackagePath => 'Enter plugin package (.zip) path';

  @override
  String get errorPrefix => 'Error';

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
  String get hintText => 'Describe the design operation you want...';

  @override
  String get history => 'History';

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
  String get inProgress => 'In Progress';

  @override
  String get install => 'Install';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installPlugin => 'Install Plugin';

  @override
  String installSuccess(Object name) {
    return '$name installed successfully';
  }

  @override
  String installed(Object count) {
    return 'Installed ($count)';
  }

  @override
  String get installedPlugins => 'Installed Plugins';

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
  String get language => 'Language';

  @override
  String get languageInstruction => 'Please respond in English.';

  @override
  String get manage => 'Manage';

  @override
  String get manualExecute => 'Manual';

  @override
  String get rustConnected => 'Rust core connected · registry from Rust';

  @override
  String get rustDisconnected =>
      'Rust core offline · using built-in Dart registry';

  @override
  String get modelConfig => 'Model Config';

  @override
  String get modelConfigDesc => 'Manage API endpoint and keys';

  @override
  String get navigation => 'Navigation';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get historySearchHint => 'Search history';

  @override
  String get searchNoResults => 'No matching sessions';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get exportMarkdown => 'Export Markdown';

  @override
  String get openDirectory => 'Open directory';

  @override
  String get openFailed => 'Open failed';

  @override
  String get openFile => 'Open file';

  @override
  String get more => 'More';

  @override
  String get noOutput => '(no output)';

  @override
  String get noPluginsToExport => 'No installed plugins to export';

  @override
  String get noTasks => 'No Tasks';

  @override
  String get noTasksHint =>
      'Enter your design requirements in the chat panel; tasks will appear here.';

  @override
  String get ok => 'OK';

  @override
  String get pluginMarket => 'Plugin Marketplace';

  @override
  String get pluginMarketDesc => 'Browse and install plugins';

  @override
  String get proxyHost => 'Proxy Host';

  @override
  String get proxyHostRequired => 'Proxy host is required when a port is set';

  @override
  String get proxyPort => 'Proxy Port';

  @override
  String get proxySettings => 'Proxy Settings';

  @override
  String get proxySettingsDesc => 'Configure network proxy';

  @override
  String get refreshConnectionStatus => 'Refresh connection status';

  @override
  String get remoteConfigSaveFailed => 'Failed to save remote endpoint config';

  @override
  String get remoteConfigSaved => 'Remote endpoint config saved';

  @override
  String get remoteEndpoint => 'Remote Endpoint';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get saveSuccess => 'Saved successfully';

  @override
  String get searchPlugins => 'Search plugins...';

  @override
  String get selectPluginToExport => 'Select plugin to export';

  @override
  String get settings => 'Settings';

  @override
  String get stop => 'Stop';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlugins => 'Plugins';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get targetSoftware => 'Target Software:';

  @override
  String get taskCompleted => 'Task completed';

  @override
  String get taskFailed => 'Task failed';

  @override
  String get taskList => 'Task List';

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get uninstall => 'Uninstall';

  @override
  String uninstallSuccess(Object name) {
    return '$name uninstalled';
  }

  @override
  String get unknownError => 'Unknown error';
}
