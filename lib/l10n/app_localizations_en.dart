// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => 'Design Domains';

  @override
  String get navigation => 'Navigation';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabPlugins => 'Plugins';

  @override
  String get settings => 'Settings';

  @override
  String get targetSoftware => 'Target Software:';

  @override
  String get hintText => 'Describe the design operation you want...';

  @override
  String get modelConfig => 'Model Config';

  @override
  String get modelConfigDesc => 'Manage API endpoint and keys';

  @override
  String get pluginMarket => 'Plugin Marketplace';

  @override
  String get pluginMarketDesc => 'Browse and install plugins';

  @override
  String get proxySettings => 'Proxy Settings';

  @override
  String get proxySettingsDesc => 'Configure network proxy';

  @override
  String get about => 'About';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get aboutDescription1 =>
      'An AI-driven design software automation tool.';

  @override
  String get aboutDescription2 =>
      'Covers 6 design domains and 50+ mainstream design software with AI-driven script generation and execution.';

  @override
  String get installedPlugins => 'Installed Plugins';

  @override
  String get installPlugin => 'Install Plugin';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get all => 'All';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get taskList => 'Task List';

  @override
  String get noTasks => 'No Tasks';

  @override
  String get noTasksHint =>
      'Enter your design requirements in the chat panel; tasks will appear here.';

  @override
  String installed(Object count) {
    return 'Installed ($count)';
  }

  @override
  String available(Object count) {
    return 'Available ($count)';
  }

  @override
  String get install => 'Install';

  @override
  String get uninstall => 'Uninstall';

  @override
  String installSuccess(Object name) {
    return '$name installed successfully';
  }

  @override
  String uninstallSuccess(Object name) {
    return '$name uninstalled';
  }

  @override
  String get ok => 'OK';

  @override
  String get errorPrefix => 'Error';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => 'Task completed';

  @override
  String get taskFailed => 'Task failed';

  @override
  String get noOutput => '(no output)';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get languageInstruction => 'Please respond in English.';
}
