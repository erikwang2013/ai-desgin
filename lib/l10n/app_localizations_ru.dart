// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get about => 'О программе';

  @override
  String get aboutDescription1 =>
      'Инструмент автоматизации дизайна на основе ИИ.';

  @override
  String get aboutDescription2 =>
      'Охватывает 6 областей дизайна и 62+ программ для автоматизированной генерации скриптов.';

  @override
  String get aboutDeveloper => 'Разработчик: erik';

  @override
  String get aboutPackageName => 'Имя пакета: Ai Desgin';

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
  String get all => 'Все';

  @override
  String get apiEndpoint => 'Конечная точка API';

  @override
  String get apiKey => 'API-ключ';

  @override
  String get appTitle => 'AI Design';

  @override
  String get autoExecute => 'Авто';

  @override
  String available(Object count) {
    return 'Доступно ($count)';
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
  String get cancel => 'Отмена';

  @override
  String get categoryAd => 'Рекламный дизайн';

  @override
  String get categoryArch => 'Архитектура';

  @override
  String get categoryIndustrial => 'Промышленный дизайн';

  @override
  String get categoryInterior => 'Дизайн интерьера';

  @override
  String get categoryThreeD => '3D-дизайн';

  @override
  String get categoryWeb => 'Веб-дизайн';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get close => 'Закрыть';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get completed => 'Завершено';

  @override
  String get connected => 'Подключено';

  @override
  String get copied => 'Скопировано';

  @override
  String get copy => 'Копировать';

  @override
  String get defaultModel => 'Модель по умолчанию';

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
  String get designDomains => 'Области дизайна';

  @override
  String get disconnected => 'Не подключено';

  @override
  String get done => 'Done';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get endpointUrl => 'URL конечной точки';

  @override
  String get enterExportPath => 'Введите путь экспорта (.zip)';

  @override
  String get enterPluginPackagePath => 'Enter plugin package (.zip) path';

  @override
  String get errorPrefix => 'Ошибка';

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
  String get hintText => 'Опишите желаемую операцию дизайна...';

  @override
  String get history => 'История';

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
  String get inProgress => 'В процессе';

  @override
  String get install => 'Установить';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installPlugin => 'Установить плагин';

  @override
  String installSuccess(Object name) {
    return '$name успешно установлен';
  }

  @override
  String installed(Object count) {
    return 'Установлено ($count)';
  }

  @override
  String get installedPlugins => 'Установленные плагины';

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
  String get language => 'Язык';

  @override
  String get languageInstruction => 'Пожалуйста, отвечайте на русском языке.';

  @override
  String get manage => 'Manage';

  @override
  String get manualExecute => 'Вручную';

  @override
  String get rustConnected => 'Rust core connected · registry from Rust';

  @override
  String get rustDisconnected =>
      'Rust core offline · using built-in Dart registry';

  @override
  String get modelConfig => 'Конфигурация модели';

  @override
  String get modelConfigDesc => 'Управление endpoint API и ключами';

  @override
  String get navigation => 'Навигация';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get historySearchHint => 'Поиск по истории';

  @override
  String get searchNoResults => 'Нет совпадающих сессий';

  @override
  String get deleteFailed => 'Не удалось удалить';

  @override
  String get exportMarkdown => 'Экспорт в Markdown';

  @override
  String get openFailed => 'Не удалось открыть';

  @override
  String get more => 'Ещё';

  @override
  String get noOutput => '(нет вывода)';

  @override
  String get noPluginsToExport => 'No installed plugins to export';

  @override
  String get noTasks => 'Нет задач';

  @override
  String get noTasksHint => 'Введите требования в чате; задачи появятся здесь.';

  @override
  String get ok => 'OK';

  @override
  String get pluginMarket => 'Маркет плагинов';

  @override
  String get pluginMarketDesc => 'Просмотр и установка плагинов';

  @override
  String get proxyHost => 'Прокси-хост';

  @override
  String get proxyHostRequired => 'Proxy host is required when a port is set';

  @override
  String get proxyPort => 'Прокси-порт';

  @override
  String get proxySettings => 'Настройки прокси';

  @override
  String get proxySettingsDesc => 'Настройка сетевого прокси';

  @override
  String get remoteConfigSaveFailed => 'Failed to save remote endpoint config';

  @override
  String get remoteConfigSaved => 'Remote endpoint config saved';

  @override
  String get remoteEndpoint => 'Remote Endpoint';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Сохранить';

  @override
  String get saveSuccess => 'Сохранено';

  @override
  String get searchPlugins => 'Поиск плагинов...';

  @override
  String get selectPluginToExport => 'Select plugin to export';

  @override
  String get settings => 'Настройки';

  @override
  String get tabChat => 'Чат';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlugins => 'Плагины';

  @override
  String get tabTasks => 'Задачи';

  @override
  String get targetSoftware => 'Целевое ПО:';

  @override
  String get taskCompleted => 'Задача выполнена';

  @override
  String get taskFailed => 'Ошибка задачи';

  @override
  String get taskList => 'Список задач';

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get uninstall => 'Удалить';

  @override
  String uninstallSuccess(Object name) {
    return '$name удалён';
  }

  @override
  String get unknownError => 'Неизвестная ошибка';
}
