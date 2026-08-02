// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => 'مجالات التصميم';

  @override
  String get navigation => 'التنقل';

  @override
  String get tabChat => 'المحادثة';

  @override
  String get tabTasks => 'المهام';

  @override
  String get tabPlugins => 'الإضافات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get targetSoftware => 'البرنامج المستهدف:';

  @override
  String get hintText => 'صف عملية التصميم التي تريدها...';

  @override
  String get modelConfig => 'إعدادات النموذج';

  @override
  String get modelConfigDesc => 'إدارة نقطة نهاية API والمفاتيح';

  @override
  String get pluginMarket => 'سوق الإضافات';

  @override
  String get pluginMarketDesc => 'تصفح وتثبيت الإضافات';

  @override
  String get proxySettings => 'إعدادات الوكيل';

  @override
  String get proxySettingsDesc => 'تكوين وكيل الشبكة';

  @override
  String get about => 'حول';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => 'قريباً';

  @override
  String get aboutDescription1 =>
      'أداة أتمتة برامج التصميم مدعومة بالذكاء الاصطناعي.';

  @override
  String get aboutDescription2 =>
      'تغطي 6 مجالات تصميم وأكثر من 50 برنامج تصميم مع إنشاء وتنفيذ النصوص بالذكاء الاصطناعي.';

  @override
  String get installedPlugins => 'الإضافات المثبتة';

  @override
  String get installPlugin => 'تثبيت إضافة';

  @override
  String get connected => 'متصل';

  @override
  String get disconnected => 'غير متصل';

  @override
  String get all => 'الكل';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get completed => 'مكتمل';

  @override
  String get taskList => 'قائمة المهام';

  @override
  String get noTasks => 'لا توجد مهام';

  @override
  String get noTasksHint =>
      'أدخل متطلبات التصميم في لوحة المحادثة؛ ستظهر المهام هنا.';

  @override
  String installed(Object count) {
    return 'مثبت ($count)';
  }

  @override
  String available(Object count) {
    return 'متاح ($count)';
  }

  @override
  String get install => 'تثبيت';

  @override
  String get uninstall => 'إلغاء التثبيت';

  @override
  String installSuccess(Object name) {
    return 'تم تثبيت $name بنجاح';
  }

  @override
  String uninstallSuccess(Object name) {
    return 'تم إلغاء تثبيت $name';
  }

  @override
  String get ok => 'موافق';

  @override
  String get errorPrefix => 'خطأ';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => 'اكتملت المهمة';

  @override
  String get taskFailed => 'فشلت المهمة';

  @override
  String get noOutput => '(لا يوجد مخرجات)';

  @override
  String get unknownError => 'خطأ غير معروف';

  @override
  String get languageInstruction => 'الرجاء الرد باللغة العربية.';
}
