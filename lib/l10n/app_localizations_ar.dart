// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get about => 'حول';

  @override
  String get aboutDescription1 =>
      'أداة أتمتة برامج التصميم مدعومة بالذكاء الاصطناعي.';

  @override
  String get aboutDescription2 =>
      'تغطي 6 مجالات تصميم وأكثر من 62 برنامج تصميم مع إنشاء وتنفيذ النصوص بالذكاء الاصطناعي.';

  @override
  String get aboutDeveloper => 'المطوّر: erik';

  @override
  String get aboutPackageName => 'اسم الحزمة: Ai Desgin';

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
  String get all => 'الكل';

  @override
  String get apiEndpoint => 'نقطة نهاية API';

  @override
  String get apiKey => 'مفتاح API';

  @override
  String get appTitle => 'AI Design';

  @override
  String get autoExecute => 'تلقائي';

  @override
  String available(Object count) {
    return 'متاح ($count)';
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
  String get cancel => 'إلغاء';

  @override
  String get categoryAd => 'تصميم الإعلانات';

  @override
  String get categoryArch => 'العمارة';

  @override
  String get categoryIndustrial => 'التصميم الصناعي';

  @override
  String get categoryInterior => 'التصميم الداخلي';

  @override
  String get categoryThreeD => 'تصميم ثلاثي الأبعاد';

  @override
  String get categoryWeb => 'تصميم الويب';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get close => 'إغلاق';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get completed => 'مكتمل';

  @override
  String get connected => 'متصل';

  @override
  String get copied => 'تم النسخ';

  @override
  String get copy => 'نسخ';

  @override
  String get defaultModel => 'النموذج الافتراضي';

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
  String get designDomains => 'مجالات التصميم';

  @override
  String get disconnected => 'غير متصل';

  @override
  String get done => 'Done';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get endpointUrl => 'عنوان نقطة النهاية';

  @override
  String get enterExportPath => 'أدخل مسار التصدير (.zip)';

  @override
  String get enterPluginPackagePath => 'Enter plugin package (.zip) path';

  @override
  String get errorPrefix => 'خطأ';

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
  String get hintText => 'صف عملية التصميم التي تريدها...';

  @override
  String get history => 'السجل';

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
  String get inProgress => 'قيد التنفيذ';

  @override
  String get install => 'تثبيت';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installPlugin => 'تثبيت إضافة';

  @override
  String installSuccess(Object name) {
    return 'تم تثبيت $name بنجاح';
  }

  @override
  String installed(Object count) {
    return 'مثبت ($count)';
  }

  @override
  String get installedPlugins => 'الإضافات المثبتة';

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
  String get language => 'اللغة';

  @override
  String get languageInstruction => 'الرجاء الرد باللغة العربية.';

  @override
  String get manage => 'Manage';

  @override
  String get manualExecute => 'يدوي';

  @override
  String get rustConnected => 'Rust core connected · registry from Rust';

  @override
  String get rustDisconnected =>
      'Rust core offline · using built-in Dart registry';

  @override
  String get modelConfig => 'إعدادات النموذج';

  @override
  String get modelConfigDesc => 'إدارة نقطة نهاية API والمفاتيح';

  @override
  String get navigation => 'التنقل';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get noOutput => '(لا يوجد مخرجات)';

  @override
  String get noPluginsToExport => 'No installed plugins to export';

  @override
  String get noTasks => 'لا توجد مهام';

  @override
  String get noTasksHint =>
      'أدخل متطلبات التصميم في لوحة المحادثة؛ ستظهر المهام هنا.';

  @override
  String get ok => 'موافق';

  @override
  String get pluginMarket => 'سوق الإضافات';

  @override
  String get pluginMarketDesc => 'تصفح وتثبيت الإضافات';

  @override
  String get proxyHost => 'مضيف الوكيل';

  @override
  String get proxyHostRequired => 'Proxy host is required when a port is set';

  @override
  String get proxyPort => 'منفذ الوكيل';

  @override
  String get proxySettings => 'إعدادات الوكيل';

  @override
  String get proxySettingsDesc => 'تكوين وكيل الشبكة';

  @override
  String get remoteConfigSaveFailed => 'Failed to save remote endpoint config';

  @override
  String get remoteConfigSaved => 'Remote endpoint config saved';

  @override
  String get remoteEndpoint => 'Remote Endpoint';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'حفظ';

  @override
  String get saveSuccess => 'تم الحفظ بنجاح';

  @override
  String get searchPlugins => 'ابحث عن الإضافات...';

  @override
  String get selectPluginToExport => 'Select plugin to export';

  @override
  String get settings => 'الإعدادات';

  @override
  String get tabChat => 'المحادثة';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlugins => 'الإضافات';

  @override
  String get tabTasks => 'المهام';

  @override
  String get targetSoftware => 'البرنامج المستهدف:';

  @override
  String get taskCompleted => 'اكتملت المهمة';

  @override
  String get taskFailed => 'فشلت المهمة';

  @override
  String get taskList => 'قائمة المهام';

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get uninstall => 'إلغاء التثبيت';

  @override
  String uninstallSuccess(Object name) {
    return 'تم إلغاء تثبيت $name';
  }

  @override
  String get unknownError => 'خطأ غير معروف';
}
