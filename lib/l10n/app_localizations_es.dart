// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get about => 'Acerca de';

  @override
  String get aboutDescription1 =>
      'Una herramienta de automatización de diseño impulsada por IA.';

  @override
  String get aboutDescription2 =>
      'Cubre 6 dominios de diseño y más de 62 software de diseño con generación de scripts por IA.';

  @override
  String get aboutDeveloper => 'Desarrollador: erik';

  @override
  String get aboutPackageName => 'Nombre del paquete: Ai Desgin';

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
  String get all => 'Todo';

  @override
  String get apiEndpoint => 'Punto de conexión API';

  @override
  String get apiKey => 'Clave API';

  @override
  String get appTitle => 'AI Design';

  @override
  String get autoExecute => 'Auto';

  @override
  String available(Object count) {
    return 'Disponible ($count)';
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
  String get cancel => 'Cancelar';

  @override
  String get categoryAd => 'Advertising Design';

  @override
  String get categoryArch => 'Architecture';

  @override
  String get categoryIndustrial => 'Industrial Design';

  @override
  String get categoryInterior => 'Interior Design';

  @override
  String get categoryThreeD => '3D Design';

  @override
  String get categoryWeb => 'Web Design';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get close => 'Cerrar';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get completed => 'Completado';

  @override
  String get connected => 'Conectado';

  @override
  String get copied => 'Copiado';

  @override
  String get copy => 'Copiar';

  @override
  String get defaultModel => 'Modelo predeterminado';

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
  String get designDomains => 'Dominios de diseño';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get done => 'Done';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get errorPrefix => 'Error';

  @override
  String get hintText => 'Describe la operación de diseño que deseas...';

  @override
  String get history => 'Historial';

  @override
  String get historyList => 'History';

  @override
  String get inProgress => 'En progreso';

  @override
  String get install => 'Instalar';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installPlugin => 'Instalar plugin';

  @override
  String installSuccess(Object name) {
    return '$name instalado correctamente';
  }

  @override
  String installed(Object count) {
    return 'Instalado ($count)';
  }

  @override
  String get installedPlugins => 'Plugins instalados';

  @override
  String get installingClaude => 'Installing...';

  @override
  String get language => 'Idioma';

  @override
  String get languageInstruction => 'Por favor, responde en español.';

  @override
  String get manage => 'Manage';

  @override
  String get manualExecute => 'Manual';

  @override
  String get rustConnected => 'Rust core connected · registry from Rust';

  @override
  String get rustDisconnected =>
      'Rust core offline · using built-in Dart registry';

  @override
  String get modelConfig => 'Configuración del modelo';

  @override
  String get modelConfigDesc => 'Gestionar endpoint API y claves';

  @override
  String get navigation => 'Navegación';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get noOutput => '(sin salida)';

  @override
  String get noTasks => 'Sin tareas';

  @override
  String get noTasksHint =>
      'Ingresa los requisitos de diseño en el chat; las tareas aparecerán aquí.';

  @override
  String get ok => 'OK';

  @override
  String get pluginMarket => 'Mercado de plugins';

  @override
  String get pluginMarketDesc => 'Explorar e instalar plugins';

  @override
  String get proxyHost => 'Host del proxy';

  @override
  String get proxyPort => 'Puerto del proxy';

  @override
  String get proxySettings => 'Configuración de proxy';

  @override
  String get proxySettingsDesc => 'Configurar proxy de red';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Guardar';

  @override
  String get saveSuccess => 'Guardado correctamente';

  @override
  String get searchPlugins => 'Buscar complementos...';

  @override
  String get settings => 'Configuración';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlugins => 'Plugins';

  @override
  String get tabTasks => 'Tareas';

  @override
  String get targetSoftware => 'Software objetivo:';

  @override
  String get taskCompleted => 'Tarea completada';

  @override
  String get taskFailed => 'Error en la tarea';

  @override
  String get taskList => 'Lista de tareas';

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get uninstall => 'Desinstalar';

  @override
  String uninstallSuccess(Object name) {
    return '$name desinstalado';
  }

  @override
  String get unknownError => 'Error desconocido';
}
