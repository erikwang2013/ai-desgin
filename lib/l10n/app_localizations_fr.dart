// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => 'Domaines de design';

  @override
  String get navigation => 'Navigation';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabTasks => 'Tâches';

  @override
  String get tabPlugins => 'Plugins';

  @override
  String get settings => 'Paramètres';

  @override
  String get targetSoftware => 'Logiciel cible :';

  @override
  String get hintText => 'Décrivez l\'opération de design souhaitée...';

  @override
  String get modelConfig => 'Configuration du modèle';

  @override
  String get modelConfigDesc => 'Gérer l\'endpoint API et les clés';

  @override
  String get pluginMarket => 'Marché des plugins';

  @override
  String get pluginMarketDesc => 'Parcourir et installer des plugins';

  @override
  String get proxySettings => 'Paramètres proxy';

  @override
  String get proxySettingsDesc => 'Configurer le proxy réseau';

  @override
  String get about => 'À propos';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get aboutDescription1 =>
      'Un outil d\'automatisation de conception piloté par l\'IA.';

  @override
  String get aboutDescription2 =>
      'Couvre 6 domaines de conception et plus de 47 logiciels avec génération de scripts par IA.';

  @override
  String get installedPlugins => 'Plugins installés';

  @override
  String get installPlugin => 'Installer un plugin';

  @override
  String get connected => 'Connecté';

  @override
  String get disconnected => 'Déconnecté';

  @override
  String get all => 'Tout';

  @override
  String get inProgress => 'En cours';

  @override
  String get completed => 'Terminé';

  @override
  String get taskList => 'Liste des tâches';

  @override
  String get noTasks => 'Aucune tâche';

  @override
  String get noTasksHint =>
      'Saisissez vos exigences dans le chat ; les tâches apparaîtront ici.';

  @override
  String installed(Object count) {
    return 'Installé ($count)';
  }

  @override
  String available(Object count) {
    return 'Disponible ($count)';
  }

  @override
  String get install => 'Installer';

  @override
  String get uninstall => 'Désinstaller';

  @override
  String installSuccess(Object name) {
    return '$name installé avec succès';
  }

  @override
  String uninstallSuccess(Object name) {
    return '$name désinstallé';
  }

  @override
  String get ok => 'OK';

  @override
  String get errorPrefix => 'Erreur';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => 'Tâche terminée';

  @override
  String get taskFailed => 'Échec de la tâche';

  @override
  String get noOutput => '(aucune sortie)';

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String get languageInstruction => 'Veuillez répondre en français.';
}
