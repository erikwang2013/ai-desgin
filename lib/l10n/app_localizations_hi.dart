// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => 'डिज़ाइन क्षेत्र';

  @override
  String get navigation => 'नेविगेशन';

  @override
  String get tabChat => 'चैट';

  @override
  String get tabTasks => 'कार्य';

  @override
  String get tabPlugins => 'प्लगइन्स';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get targetSoftware => 'लक्ष्य सॉफ़्टवेयर:';

  @override
  String get hintText => 'अपनी इच्छित डिज़ाइन कार्रवाई का वर्णन करें...';

  @override
  String get modelConfig => 'मॉडल कॉन्फ़िगरेशन';

  @override
  String get modelConfigDesc => 'API एंडपॉइंट और कुंजियाँ प्रबंधित करें';

  @override
  String get pluginMarket => 'प्लगइन मार्केटप्लेस';

  @override
  String get pluginMarketDesc => 'प्लगइन ब्राउज़ करें और इंस्टॉल करें';

  @override
  String get proxySettings => 'प्रॉक्सी सेटिंग्स';

  @override
  String get proxySettingsDesc => 'नेटवर्क प्रॉक्सी कॉन्फ़िगर करें';

  @override
  String get about => 'के बारे में';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String get aboutDescription1 =>
      'एक AI-संचालित डिज़ाइन सॉफ़्टवेयर स्वचालन उपकरण।';

  @override
  String get aboutDescription2 =>
      '6 डिज़ाइन क्षेत्रों और 47+ प्रमुख डिज़ाइन सॉफ़्टवेयर के लिए AI स्क्रिप्ट जनरेशन और निष्पादन।';

  @override
  String get installedPlugins => 'इंस्टॉल किए गए प्लगइन्स';

  @override
  String get installPlugin => 'प्लगइन इंस्टॉल करें';

  @override
  String get connected => 'कनेक्टेड';

  @override
  String get disconnected => 'डिस्कनेक्टेड';

  @override
  String get all => 'सभी';

  @override
  String get inProgress => 'प्रगति में';

  @override
  String get completed => 'पूर्ण';

  @override
  String get taskList => 'कार्य सूची';

  @override
  String get noTasks => 'कोई कार्य नहीं';

  @override
  String get noTasksHint =>
      'चैट पैनल में डिज़ाइन आवश्यकताएँ दर्ज करें; कार्य यहाँ दिखाई देंगे।';

  @override
  String installed(Object count) {
    return 'इंस्टॉल किया गया ($count)';
  }

  @override
  String available(Object count) {
    return 'उपलब्ध ($count)';
  }

  @override
  String get install => 'इंस्टॉल करें';

  @override
  String get uninstall => 'अनइंस्टॉल करें';

  @override
  String installSuccess(Object name) {
    return '$name सफलतापूर्वक इंस्टॉल हुआ';
  }

  @override
  String uninstallSuccess(Object name) {
    return '$name अनइंस्टॉल किया गया';
  }

  @override
  String get ok => 'ठीक है';

  @override
  String get errorPrefix => 'त्रुटि';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => 'कार्य पूर्ण';

  @override
  String get taskFailed => 'कार्य विफल';

  @override
  String get noOutput => '(कोई आउटपुट नहीं)';

  @override
  String get unknownError => 'अज्ञात त्रुटि';

  @override
  String get languageInstruction => 'कृपया हिंदी में उत्तर दें।';
}
