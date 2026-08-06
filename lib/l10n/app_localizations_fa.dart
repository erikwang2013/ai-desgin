// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => 'حوزه‌های طراحی';

  @override
  String get navigation => 'ناوبری';

  @override
  String get tabChat => 'گفتگو';

  @override
  String get tabTasks => 'وظایف';

  @override
  String get tabPlugins => 'افزونه‌ها';

  @override
  String get settings => 'تنظیمات';

  @override
  String get targetSoftware => 'نرم‌افزار هدف:';

  @override
  String get hintText => 'عملیات طراحی مورد نظر خود را توضیح دهید...';

  @override
  String get modelConfig => 'پیکربندی مدل';

  @override
  String get modelConfigDesc => 'مدیریت endpoint API و کلیدها';

  @override
  String get pluginMarket => 'بازار افزونه‌ها';

  @override
  String get pluginMarketDesc => 'مرور و نصب افزونه‌ها';

  @override
  String get proxySettings => 'تنظیمات پروکسی';

  @override
  String get proxySettingsDesc => 'پیکربندی پروکسی شبکه';

  @override
  String get about => 'درباره';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => 'به زودی';

  @override
  String get aboutDescription1 =>
      'ابزار خودکارسازی نرم‌افزار طراحی مبتنی بر هوش مصنوعی.';

  @override
  String get aboutDescription2 =>
      'پوشش 6 حوزه طراحی و بیش از 62 نرم‌افزار طراحی با تولید و اجرای اسکریپت هوش مصنوعی.';

  @override
  String get installedPlugins => 'افزونه‌های نصب شده';

  @override
  String get installPlugin => 'نصب افزونه';

  @override
  String get connected => 'متصل';

  @override
  String get disconnected => 'قطع';

  @override
  String get all => 'همه';

  @override
  String get inProgress => 'در حال انجام';

  @override
  String get completed => 'تکمیل شده';

  @override
  String get taskList => 'لیست وظایف';

  @override
  String get noTasks => 'بدون وظیفه';

  @override
  String get noTasksHint =>
      'نیازمندی‌های طراحی را در پنل گفتگو وارد کنید؛ وظایف در اینجا نمایش داده می‌شوند.';

  @override
  String installed(Object count) {
    return 'نصب شده ($count)';
  }

  @override
  String available(Object count) {
    return 'در دسترس ($count)';
  }

  @override
  String get install => 'نصب';

  @override
  String get uninstall => 'حذف';

  @override
  String installSuccess(Object name) {
    return '$name با موفقیت نصب شد';
  }

  @override
  String uninstallSuccess(Object name) {
    return '$name حذف شد';
  }

  @override
  String get ok => 'تأیید';

  @override
  String get errorPrefix => 'خطا';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => 'وظیفه تکمیل شد';

  @override
  String get taskFailed => 'وظیفه ناموفق بود';

  @override
  String get noOutput => '(بدون خروجی)';

  @override
  String get unknownError => 'خطای ناشناخته';

  @override
  String get languageInstruction => 'لطفاً به فارسی پاسخ دهید.';

  @override
  String get language => 'زبان';

  @override
  String get apiEndpoint => 'نقطه پایانی API';

  @override
  String get apiKey => 'کلید API';

  @override
  String get defaultModel => 'مدل پیش‌فرض';

  @override
  String get save => 'ذخیره';

  @override
  String get proxyHost => 'میزبان پروکسی';

  @override
  String get proxyPort => 'پورت پروکسی';

  @override
  String get saveSuccess => 'با موفقیت ذخیره شد';

  @override
  String get history => 'تاریخچه';

  @override
  String get searchPlugins => 'جستجوی افزونهها...';

  @override
  String get autoExecute => 'خودکار';

  @override
  String get manualExecute => 'دستی';

  @override
  String get copied => 'کپی شد';

  @override
  String get copy => 'کپی';

  @override
  String get close => 'بستن';
}
