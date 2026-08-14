// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get about => 'Tungkol Sa';

  @override
  String get aboutDescription1 =>
      'Isang AI-driven na tool sa automation ng design software.';

  @override
  String get aboutDescription2 =>
      'Sakop ang 6 na domain ng disenyo at 62+ pangunahing design software gamit ang AI script generation.';

  @override
  String get aboutDeveloper => 'Developer: erik';

  @override
  String get aboutPackageName => 'Pangalan ng package: Ai Desgin';

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
  String get all => 'Lahat';

  @override
  String get apiEndpoint => 'API Endpoint';

  @override
  String get apiKey => 'API Key';

  @override
  String get appTitle => 'AI Design';

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
  String get cancel => 'Kanselahin';

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
  String get close => 'Isara';

  @override
  String get comingSoon => 'Malapit Na';

  @override
  String get completed => 'Tapos Na';

  @override
  String get connected => 'Nakakonekta';

  @override
  String get copied => 'Nakopya';

  @override
  String get copy => 'Kopyahin';

  @override
  String get defaultModel => 'Default na Modelo';

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
  String get designDomains => 'Mga Domain ng Disenyo';

  @override
  String get disconnected => 'Hindi Nakakonekta';

  @override
  String get done => 'Done';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get errorPrefix => 'Error';

  @override
  String get hintText => 'Ilarawan ang nais na operasyon ng disenyo...';

  @override
  String get history => 'Kasaysayan';

  @override
  String get historyList => 'History';

  @override
  String get inProgress => 'Isinasagawa';

  @override
  String get install => 'I-install';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installPlugin => 'Mag-install ng Plugin';

  @override
  String installSuccess(Object name) {
    return 'Matagumpay na na-install ang $name';
  }

  @override
  String installed(Object count) {
    return 'Naka-install ($count)';
  }

  @override
  String get installedPlugins => 'Mga Naka-install na Plugin';

  @override
  String get installingClaude => 'Installing...';

  @override
  String get language => 'Wika';

  @override
  String get languageInstruction => 'Mangyaring tumugon sa wikang Filipino.';

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
  String get modelConfig => 'Configuration ng Modelo';

  @override
  String get modelConfigDesc => 'Pamahalaan ang API endpoint at mga susi';

  @override
  String get navigation => 'Nabigasyon';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get noOutput => '(walang output)';

  @override
  String get noTasks => 'Walang Gawain';

  @override
  String get noTasksHint =>
      'Ilagay ang mga kinakailangan sa disenyo sa chat panel; lalabas dito ang mga gawain.';

  @override
  String get ok => 'OK';

  @override
  String get pluginMarket => 'Plugin Marketplace';

  @override
  String get pluginMarketDesc => 'Mag-browse at mag-install ng mga plugin';

  @override
  String get proxyHost => 'Proxy Host';

  @override
  String get proxyPort => 'Proxy Port';

  @override
  String get proxySettings => 'Mga Setting ng Proxy';

  @override
  String get proxySettingsDesc => 'I-configure ang network proxy';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'I-save';

  @override
  String get saveSuccess => 'Matagumpay na na-save';

  @override
  String get searchPlugins => 'Maghanap ng mga plugin...';

  @override
  String get settings => 'Mga Setting';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlugins => 'Mga Plugin';

  @override
  String get tabTasks => 'Mga Gawain';

  @override
  String get targetSoftware => 'Target na Software:';

  @override
  String get taskCompleted => 'Tapos na ang gawain';

  @override
  String get taskFailed => 'Nabigo ang gawain';

  @override
  String get taskList => 'Listahan ng Gawain';

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get uninstall => 'I-uninstall';

  @override
  String uninstallSuccess(Object name) {
    return 'Na-uninstall ang $name';
  }

  @override
  String get unknownError => 'Hindi kilalang error';
}
