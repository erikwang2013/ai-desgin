// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get about => 'के बारे में';

  @override
  String get aboutDescription1 =>
      'एक AI-संचालित डिज़ाइन सॉफ़्टवेयर स्वचालन उपकरण।';

  @override
  String get aboutDescription2 =>
      '6 डिज़ाइन क्षेत्रों और 62+ प्रमुख डिज़ाइन सॉफ़्टवेयर के लिए AI स्क्रिप्ट जनरेशन और निष्पादन।';

  @override
  String get aboutDeveloper => 'डेवलपर: erik';

  @override
  String get aboutPackageName => 'पैकेज का नाम: Ai Desgin';

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
  String get all => 'सभी';

  @override
  String get apiEndpoint => 'API एंडपॉइंट';

  @override
  String get apiKey => 'API कुंजी';

  @override
  String get appTitle => 'AI Design';

  @override
  String get artifacts => 'आर्टिफैक्ट्स';

  @override
  String get autoExecute => 'स्वचालित';

  @override
  String available(Object count) {
    return 'उपलब्ध ($count)';
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
  String get cancel => 'रद्द करें';

  @override
  String get categoryAd => 'विज्ञापन डिज़ाइन';

  @override
  String get categoryArch => 'वास्तुकला';

  @override
  String get categoryIndustrial => 'औद्योगिक डिज़ाइन';

  @override
  String get categoryInterior => 'आंतरिक डिज़ाइन';

  @override
  String get categoryThreeD => '3D डिज़ाइन';

  @override
  String get categoryWeb => 'वेब डिज़ाइन';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get close => 'बंद करें';

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String get completed => 'पूर्ण';

  @override
  String get connected => 'कनेक्टेड';

  @override
  String get copied => 'कॉपी हो गया';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get defaultModel => 'डिफ़ॉल्ट मॉडल';

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
  String get designDomains => 'डिज़ाइन क्षेत्र';

  @override
  String get disconnected => 'डिस्कनेक्टेड';

  @override
  String get done => 'Done';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get endpointUrl => 'एंडपॉइंट URL';

  @override
  String get enterExportPath => 'निर्यात पथ दर्ज करें (.zip)';

  @override
  String get enterPluginPackagePath => 'Enter plugin package (.zip) path';

  @override
  String get errorPrefix => 'त्रुटि';

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
  String get hintText => 'अपनी इच्छित डिज़ाइन कार्रवाई का वर्णन करें...';

  @override
  String get history => 'इतिहास';

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
  String get inProgress => 'प्रगति में';

  @override
  String get install => 'इंस्टॉल करें';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installPlugin => 'प्लगइन इंस्टॉल करें';

  @override
  String installSuccess(Object name) {
    return '$name सफलतापूर्वक इंस्टॉल हुआ';
  }

  @override
  String installed(Object count) {
    return 'इंस्टॉल किया गया ($count)';
  }

  @override
  String get installedPlugins => 'इंस्टॉल किए गए प्लगइन्स';

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
  String get language => 'भाषा';

  @override
  String get languageInstruction => 'कृपया हिंदी में उत्तर दें।';

  @override
  String get manage => 'Manage';

  @override
  String get manualExecute => 'मैन्युअल';

  @override
  String get rustConnected => 'Rust core connected · registry from Rust';

  @override
  String get rustDisconnected =>
      'Rust core offline · using built-in Dart registry';

  @override
  String get modelConfig => 'मॉडल कॉन्फ़िगरेशन';

  @override
  String get modelConfigDesc => 'API एंडपॉइंट और कुंजियाँ प्रबंधित करें';

  @override
  String get navigation => 'नेविगेशन';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get historySearchHint => 'इतिहास खोजें';

  @override
  String get searchNoResults => 'कोई मेल खाता सत्र नहीं';

  @override
  String get deleteFailed => 'हटाना विफल';

  @override
  String get exportMarkdown => 'Markdown निर्यात करें';

  @override
  String get openDirectory => 'फ़ोल्डर खोलें';

  @override
  String get openFailed => 'खोलना विफल';

  @override
  String get openFile => 'फ़ाइल खोलें';

  @override
  String get more => 'और';

  @override
  String get noOutput => '(कोई आउटपुट नहीं)';

  @override
  String get noPluginsToExport => 'No installed plugins to export';

  @override
  String get noTasks => 'कोई कार्य नहीं';

  @override
  String get noTasksHint =>
      'चैट पैनल में डिज़ाइन आवश्यकताएँ दर्ज करें; कार्य यहाँ दिखाई देंगे।';

  @override
  String get ok => 'ठीक है';

  @override
  String get pluginMarket => 'प्लगइन मार्केटप्लेस';

  @override
  String get pluginMarketDesc => 'प्लगइन ब्राउज़ करें और इंस्टॉल करें';

  @override
  String get proxyHost => 'प्रॉक्सी होस्ट';

  @override
  String get proxyHostRequired => 'Proxy host is required when a port is set';

  @override
  String get proxyPort => 'प्रॉक्सी पोर्ट';

  @override
  String get proxySettings => 'प्रॉक्सी सेटिंग्स';

  @override
  String get proxySettingsDesc => 'नेटवर्क प्रॉक्सी कॉन्फ़िगर करें';

  @override
  String get refreshConnectionStatus => 'कनेक्शन स्थिति रीफ़्रेश करें';

  @override
  String get remoteConfigSaveFailed => 'Failed to save remote endpoint config';

  @override
  String get remoteConfigSaved => 'Remote endpoint config saved';

  @override
  String get remoteEndpoint => 'Remote Endpoint';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'सहेजें';

  @override
  String get saveSuccess => 'सफलतापूर्वक सहेजा गया';

  @override
  String get searchPlugins => 'प्लगइन खोजें...';

  @override
  String get selectPluginToExport => 'Select plugin to export';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get stop => 'रोकें';

  @override
  String get tabChat => 'चैट';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlugins => 'प्लगइन्स';

  @override
  String get tabTasks => 'कार्य';

  @override
  String get targetSoftware => 'लक्ष्य सॉफ़्टवेयर:';

  @override
  String get taskCompleted => 'कार्य पूर्ण';

  @override
  String get taskFailed => 'कार्य विफल';

  @override
  String get taskList => 'कार्य सूची';

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get uninstall => 'अनइंस्टॉल करें';

  @override
  String uninstallSuccess(Object name) {
    return '$name अनइंस्टॉल किया गया';
  }

  @override
  String get unknownError => 'अज्ञात त्रुटि';
}
