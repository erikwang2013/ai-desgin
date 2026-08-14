// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get about => 'درباره';

  @override
  String get aboutDescription1 =>
      'ابزار خودکارسازی نرم‌افزار طراحی مبتنی بر هوش مصنوعی.';

  @override
  String get aboutDescription2 =>
      'پوشش 6 حوزه طراحی و بیش از 62 نرم‌افزار طراحی با تولید و اجرای اسکریپت هوش مصنوعی.';

  @override
  String get aboutDeveloper => 'توسعه‌دهنده: erik';

  @override
  String get aboutPackageName => 'نام بسته: Ai Desgin';

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
  String get all => 'همه';

  @override
  String get apiEndpoint => 'نقطه پایانی API';

  @override
  String get apiKey => 'کلید API';

  @override
  String get appTitle => 'AI Design';

  @override
  String get autoExecute => 'خودکار';

  @override
  String available(Object count) {
    return 'در دسترس ($count)';
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
  String get cancel => 'لغو';

  @override
  String get categoryAd => 'طراحی تبلیغات';

  @override
  String get categoryArch => 'معماری';

  @override
  String get categoryIndustrial => 'طراحی صنعتی';

  @override
  String get categoryInterior => 'طراحی داخلی';

  @override
  String get categoryThreeD => 'طراحی سهبعدی';

  @override
  String get categoryWeb => 'طراحی وب';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get close => 'بستن';

  @override
  String get comingSoon => 'به زودی';

  @override
  String get completed => 'تکمیل شده';

  @override
  String get connected => 'متصل';

  @override
  String get copied => 'کپی شد';

  @override
  String get copy => 'کپی';

  @override
  String get defaultModel => 'مدل پیش‌فرض';

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
  String get designDomains => 'حوزه‌های طراحی';

  @override
  String get disconnected => 'قطع';

  @override
  String get done => 'Done';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get endpointUrl => 'آدرس نقطه پایانی';

  @override
  String get enterExportPath => 'مسیر خروجی را وارد کنید (.zip)';

  @override
  String get enterPluginPackagePath => 'Enter plugin package (.zip) path';

  @override
  String get errorPrefix => 'خطا';

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
  String get hintText => 'عملیات طراحی مورد نظر خود را توضیح دهید...';

  @override
  String get history => 'تاریخچه';

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
  String get inProgress => 'در حال انجام';

  @override
  String get install => 'نصب';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installPlugin => 'نصب افزونه';

  @override
  String installSuccess(Object name) {
    return '$name با موفقیت نصب شد';
  }

  @override
  String installed(Object count) {
    return 'نصب شده ($count)';
  }

  @override
  String get installedPlugins => 'افزونه‌های نصب شده';

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
  String get language => 'زبان';

  @override
  String get languageInstruction => 'لطفاً به فارسی پاسخ دهید.';

  @override
  String get manage => 'Manage';

  @override
  String get manualExecute => 'دستی';

  @override
  String get rustConnected => 'Rust core connected · registry from Rust';

  @override
  String get rustDisconnected =>
      'Rust core offline · using built-in Dart registry';

  @override
  String get modelConfig => 'پیکربندی مدل';

  @override
  String get modelConfigDesc => 'مدیریت endpoint API و کلیدها';

  @override
  String get navigation => 'ناوبری';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get noOutput => '(بدون خروجی)';

  @override
  String get noPluginsToExport => 'No installed plugins to export';

  @override
  String get noTasks => 'بدون وظیفه';

  @override
  String get noTasksHint =>
      'نیازمندی‌های طراحی را در پنل گفتگو وارد کنید؛ وظایف در اینجا نمایش داده می‌شوند.';

  @override
  String get ok => 'تأیید';

  @override
  String get pluginMarket => 'بازار افزونه‌ها';

  @override
  String get pluginMarketDesc => 'مرور و نصب افزونه‌ها';

  @override
  String get proxyHost => 'میزبان پروکسی';

  @override
  String get proxyHostRequired => 'Proxy host is required when a port is set';

  @override
  String get proxyPort => 'پورت پروکسی';

  @override
  String get proxySettings => 'تنظیمات پروکسی';

  @override
  String get proxySettingsDesc => 'پیکربندی پروکسی شبکه';

  @override
  String get remoteConfigSaveFailed => 'Failed to save remote endpoint config';

  @override
  String get remoteConfigSaved => 'Remote endpoint config saved';

  @override
  String get remoteEndpoint => 'Remote Endpoint';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'ذخیره';

  @override
  String get saveSuccess => 'با موفقیت ذخیره شد';

  @override
  String get searchPlugins => 'جستجوی افزونهها...';

  @override
  String get selectPluginToExport => 'Select plugin to export';

  @override
  String get settings => 'تنظیمات';

  @override
  String get tabChat => 'گفتگو';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlugins => 'افزونه‌ها';

  @override
  String get tabTasks => 'وظایف';

  @override
  String get targetSoftware => 'نرم‌افزار هدف:';

  @override
  String get taskCompleted => 'وظیفه تکمیل شد';

  @override
  String get taskFailed => 'وظیفه ناموفق بود';

  @override
  String get taskList => 'لیست وظایف';

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get uninstall => 'حذف';

  @override
  String uninstallSuccess(Object name) {
    return '$name حذف شد';
  }

  @override
  String get unknownError => 'خطای ناشناخته';
}
