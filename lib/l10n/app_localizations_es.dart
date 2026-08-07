// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => 'Dominios de diseño';

  @override
  String get navigation => 'Navegación';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabTasks => 'Tareas';

  @override
  String get tabPlugins => 'Plugins';

  @override
  String get settings => 'Configuración';

  @override
  String get targetSoftware => 'Software objetivo:';

  @override
  String get hintText => 'Describe la operación de diseño que deseas...';

  @override
  String get modelConfig => 'Configuración del modelo';

  @override
  String get modelConfigDesc => 'Gestionar endpoint API y claves';

  @override
  String get pluginMarket => 'Mercado de plugins';

  @override
  String get pluginMarketDesc => 'Explorar e instalar plugins';

  @override
  String get proxySettings => 'Configuración de proxy';

  @override
  String get proxySettingsDesc => 'Configurar proxy de red';

  @override
  String get about => 'Acerca de';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get aboutDescription1 =>
      'Una herramienta de automatización de diseño impulsada por IA.';

  @override
  String get aboutDescription2 =>
      'Cubre 6 dominios de diseño y más de 62 software de diseño con generación de scripts por IA.';

  @override
  String get aboutDeveloper => 'Desarrollador: erik';

  @override
  String get installedPlugins => 'Plugins instalados';

  @override
  String get installPlugin => 'Instalar plugin';

  @override
  String get connected => 'Conectado';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get all => 'Todo';

  @override
  String get inProgress => 'En progreso';

  @override
  String get completed => 'Completado';

  @override
  String get taskList => 'Lista de tareas';

  @override
  String get noTasks => 'Sin tareas';

  @override
  String get noTasksHint =>
      'Ingresa los requisitos de diseño en el chat; las tareas aparecerán aquí.';

  @override
  String installed(Object count) {
    return 'Instalado ($count)';
  }

  @override
  String available(Object count) {
    return 'Disponible ($count)';
  }

  @override
  String get install => 'Instalar';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String installSuccess(Object name) {
    return '$name instalado correctamente';
  }

  @override
  String uninstallSuccess(Object name) {
    return '$name desinstalado';
  }

  @override
  String get ok => 'OK';

  @override
  String get errorPrefix => 'Error';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => 'Tarea completada';

  @override
  String get taskFailed => 'Error en la tarea';

  @override
  String get noOutput => '(sin salida)';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get languageInstruction => 'Por favor, responde en español.';

  @override
  String get language => 'Idioma';

  @override
  String get apiEndpoint => 'Punto de conexión API';

  @override
  String get apiKey => 'Clave API';

  @override
  String get defaultModel => 'Modelo predeterminado';

  @override
  String get save => 'Guardar';

  @override
  String get proxyHost => 'Host del proxy';

  @override
  String get proxyPort => 'Puerto del proxy';

  @override
  String get saveSuccess => 'Guardado correctamente';

  @override
  String get history => 'Historial';

  @override
  String get searchPlugins => 'Buscar complementos...';

  @override
  String get autoExecute => 'Auto';

  @override
  String get manualExecute => 'Manual';

  @override
  String get copied => 'Copiado';

  @override
  String get copy => 'Copiar';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';
}
