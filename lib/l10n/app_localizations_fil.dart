// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => 'Mga Domain ng Disenyo';

  @override
  String get navigation => 'Nabigasyon';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabTasks => 'Mga Gawain';

  @override
  String get tabPlugins => 'Mga Plugin';

  @override
  String get settings => 'Mga Setting';

  @override
  String get targetSoftware => 'Target na Software:';

  @override
  String get hintText => 'Ilarawan ang nais na operasyon ng disenyo...';

  @override
  String get modelConfig => 'Configuration ng Modelo';

  @override
  String get modelConfigDesc => 'Pamahalaan ang API endpoint at mga susi';

  @override
  String get pluginMarket => 'Plugin Marketplace';

  @override
  String get pluginMarketDesc => 'Mag-browse at mag-install ng mga plugin';

  @override
  String get proxySettings => 'Mga Setting ng Proxy';

  @override
  String get proxySettingsDesc => 'I-configure ang network proxy';

  @override
  String get about => 'Tungkol Sa';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => 'Malapit Na';

  @override
  String get aboutDescription1 =>
      'Isang AI-driven na tool sa automation ng design software.';

  @override
  String get aboutDescription2 =>
      'Sakop ang 6 na domain ng disenyo at 50+ pangunahing design software gamit ang AI script generation.';

  @override
  String get installedPlugins => 'Mga Naka-install na Plugin';

  @override
  String get installPlugin => 'Mag-install ng Plugin';

  @override
  String get connected => 'Nakakonekta';

  @override
  String get disconnected => 'Hindi Nakakonekta';

  @override
  String get all => 'Lahat';

  @override
  String get inProgress => 'Isinasagawa';

  @override
  String get completed => 'Tapos Na';

  @override
  String get taskList => 'Listahan ng Gawain';

  @override
  String get noTasks => 'Walang Gawain';

  @override
  String get noTasksHint =>
      'Ilagay ang mga kinakailangan sa disenyo sa chat panel; lalabas dito ang mga gawain.';

  @override
  String installed(Object count) {
    return 'Naka-install ($count)';
  }

  @override
  String available(Object count) {
    return 'Available ($count)';
  }

  @override
  String get install => 'I-install';

  @override
  String get uninstall => 'I-uninstall';

  @override
  String installSuccess(Object name) {
    return 'Matagumpay na na-install ang $name';
  }

  @override
  String uninstallSuccess(Object name) {
    return 'Na-uninstall ang $name';
  }

  @override
  String get ok => 'OK';

  @override
  String get errorPrefix => 'Error';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => 'Tapos na ang gawain';

  @override
  String get taskFailed => 'Nabigo ang gawain';

  @override
  String get noOutput => '(walang output)';

  @override
  String get unknownError => 'Hindi kilalang error';

  @override
  String get languageInstruction => 'Mangyaring tumugon sa wikang Filipino.';
}
