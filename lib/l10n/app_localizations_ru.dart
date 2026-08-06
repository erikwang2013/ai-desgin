// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => 'Области дизайна';

  @override
  String get navigation => 'Навигация';

  @override
  String get tabChat => 'Чат';

  @override
  String get tabTasks => 'Задачи';

  @override
  String get tabPlugins => 'Плагины';

  @override
  String get settings => 'Настройки';

  @override
  String get targetSoftware => 'Целевое ПО:';

  @override
  String get hintText => 'Опишите желаемую операцию дизайна...';

  @override
  String get modelConfig => 'Конфигурация модели';

  @override
  String get modelConfigDesc => 'Управление endpoint API и ключами';

  @override
  String get pluginMarket => 'Маркет плагинов';

  @override
  String get pluginMarketDesc => 'Просмотр и установка плагинов';

  @override
  String get proxySettings => 'Настройки прокси';

  @override
  String get proxySettingsDesc => 'Настройка сетевого прокси';

  @override
  String get about => 'О программе';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => 'Скоро';

  @override
  String get aboutDescription1 =>
      'Инструмент автоматизации дизайна на основе ИИ.';

  @override
  String get aboutDescription2 =>
      'Охватывает 6 областей дизайна и 62+ программ для автоматизированной генерации скриптов.';

  @override
  String get installedPlugins => 'Установленные плагины';

  @override
  String get installPlugin => 'Установить плагин';

  @override
  String get connected => 'Подключено';

  @override
  String get disconnected => 'Не подключено';

  @override
  String get all => 'Все';

  @override
  String get inProgress => 'В процессе';

  @override
  String get completed => 'Завершено';

  @override
  String get taskList => 'Список задач';

  @override
  String get noTasks => 'Нет задач';

  @override
  String get noTasksHint => 'Введите требования в чате; задачи появятся здесь.';

  @override
  String installed(Object count) {
    return 'Установлено ($count)';
  }

  @override
  String available(Object count) {
    return 'Доступно ($count)';
  }

  @override
  String get install => 'Установить';

  @override
  String get uninstall => 'Удалить';

  @override
  String installSuccess(Object name) {
    return '$name успешно установлен';
  }

  @override
  String uninstallSuccess(Object name) {
    return '$name удалён';
  }

  @override
  String get ok => 'OK';

  @override
  String get errorPrefix => 'Ошибка';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => 'Задача выполнена';

  @override
  String get taskFailed => 'Ошибка задачи';

  @override
  String get noOutput => '(нет вывода)';

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get languageInstruction => 'Пожалуйста, отвечайте на русском языке.';

  @override
  String get language => 'Язык';

  @override
  String get apiEndpoint => 'Конечная точка API';

  @override
  String get apiKey => 'API-ключ';

  @override
  String get defaultModel => 'Модель по умолчанию';

  @override
  String get save => 'Сохранить';

  @override
  String get proxyHost => 'Прокси-хост';

  @override
  String get proxyPort => 'Прокси-порт';

  @override
  String get saveSuccess => 'Сохранено';

  @override
  String get history => 'История';

  @override
  String get searchPlugins => 'Поиск плагинов...';

  @override
  String get autoExecute => 'Авто';

  @override
  String get manualExecute => 'Вручную';

  @override
  String get copied => 'Скопировано';

  @override
  String get copy => 'Копировать';

  @override
  String get close => 'Закрыть';

  @override
  String get cancel => 'Отмена';
}
