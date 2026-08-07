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
      'Couvre 6 domaines de conception et plus de 62 logiciels avec génération de scripts par IA.';

  @override
  String get aboutPackageName => 'Nom du paquet : Ai Desgin';

  @override
  String get aboutDeveloper => 'Développeur : erik';

  @override
  String get retry => 'Retry';

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

  @override
  String get language => 'Langue';

  @override
  String get apiEndpoint => 'Point d\'accès API';

  @override
  String get apiKey => 'Clé API';

  @override
  String get defaultModel => 'Modèle par défaut';

  @override
  String get save => 'Enregistrer';

  @override
  String get proxyHost => 'Hôte du proxy';

  @override
  String get proxyPort => 'Port du proxy';

  @override
  String get saveSuccess => 'Enregistré avec succès';

  @override
  String get history => 'Historique';

  @override
  String get searchPlugins => 'Rechercher des plugins...';

  @override
  String get autoExecute => 'Auto';

  @override
  String get manualExecute => 'Manuel';

  @override
  String get copied => 'Copié';

  @override
  String get copy => 'Copier';

  @override
  String get close => 'Fermer';

  @override
  String get cancel => 'Annuler';

  @override
  String get tabHistory => 'History';

  @override
  String get historyList => 'History';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get manage => 'Manage';

  @override
  String get done => 'Done';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAll => 'Delete All';

  @override
  String deleteSelected(Object count) {
    return 'Delete Selected ($count)';
  }

  @override
  String get deleteConfirm => 'Delete this session?';

  @override
  String deleteAllConfirm(Object count) {
    return 'Delete all $count sessions?';
  }

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get agentBackend => 'Agent Backend';

  @override
  String get agentBackendDesc =>
      'Choose the agent CLI used to generate scripts';

  @override
  String get backendClaude => 'Claude Code';

  @override
  String get backendCodex => 'Codex';

  @override
  String get backendGemini => 'Gemini';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installingClaude => 'Installing...';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';
}
