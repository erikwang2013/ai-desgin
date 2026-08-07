import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fil'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutDescription1.
  ///
  /// In en, this message translates to:
  /// **'An AI-driven design software automation tool.'**
  String get aboutDescription1;

  /// No description provided for @aboutDescription2.
  ///
  /// In en, this message translates to:
  /// **'Covers 6 design domains and 62+ mainstream design software with AI-driven script generation and execution.'**
  String get aboutDescription2;

  /// No description provided for @aboutDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer: erik'**
  String get aboutDeveloper;

  /// No description provided for @aboutPackageName.
  ///
  /// In en, this message translates to:
  /// **'Package name: Ai Desgin'**
  String get aboutPackageName;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'AI Design v{version}'**
  String aboutVersion(Object version);

  /// No description provided for @agentBackend.
  ///
  /// In en, this message translates to:
  /// **'Agent Backend'**
  String get agentBackend;

  /// No description provided for @agentBackendDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the agent CLI used to generate scripts'**
  String get agentBackendDesc;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @apiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'API Endpoint'**
  String get apiEndpoint;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Design'**
  String get appTitle;

  /// Localized label for autoExecute
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get autoExecute;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available ({count})'**
  String available(Object count);

  /// No description provided for @backendClaude.
  ///
  /// In en, this message translates to:
  /// **'Claude Code'**
  String get backendClaude;

  /// No description provided for @backendCodex.
  ///
  /// In en, this message translates to:
  /// **'Codex'**
  String get backendCodex;

  /// No description provided for @backendGemini.
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get backendGemini;

  /// No description provided for @backendHermes.
  ///
  /// In en, this message translates to:
  /// **'Hermes'**
  String get backendHermes;

  /// No description provided for @backendOpenclaw.
  ///
  /// In en, this message translates to:
  /// **'OpenClaw'**
  String get backendOpenclaw;

  /// No description provided for @backendOpencode.
  ///
  /// In en, this message translates to:
  /// **'OpenCode'**
  String get backendOpencode;

  /// No description provided for @backendReasonix.
  ///
  /// In en, this message translates to:
  /// **'Reasonix'**
  String get backendReasonix;

  /// Localized label for cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @claudeInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Install failed, check npm environment'**
  String get claudeInstallFailed;

  /// No description provided for @claudeUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get claudeUpToDate;

  /// No description provided for @claudeVersion.
  ///
  /// In en, this message translates to:
  /// **'Claude Code Version'**
  String get claudeVersion;

  /// Localized label for close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Localized label for copied
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// Localized label for copy
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @defaultModel.
  ///
  /// In en, this message translates to:
  /// **'Default Model'**
  String get defaultModel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all {count} sessions?'**
  String deleteAllConfirm(Object count);

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this session?'**
  String get deleteConfirm;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected ({count})'**
  String deleteSelected(Object count);

  /// No description provided for @designDomains.
  ///
  /// In en, this message translates to:
  /// **'Design Domains'**
  String get designDomains;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @echoPrefix.
  ///
  /// In en, this message translates to:
  /// **'Echo'**
  String get echoPrefix;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @hintText.
  ///
  /// In en, this message translates to:
  /// **'Describe the design operation you want...'**
  String get hintText;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @historyList.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyList;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @installClaude.
  ///
  /// In en, this message translates to:
  /// **'Install Claude Code 2.1.143'**
  String get installClaude;

  /// No description provided for @installPlugin.
  ///
  /// In en, this message translates to:
  /// **'Install Plugin'**
  String get installPlugin;

  /// No description provided for @installSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} installed successfully'**
  String installSuccess(Object name);

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed ({count})'**
  String installed(Object count);

  /// No description provided for @installedPlugins.
  ///
  /// In en, this message translates to:
  /// **'Installed Plugins'**
  String get installedPlugins;

  /// No description provided for @installingClaude.
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get installingClaude;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please respond in English.'**
  String get languageInstruction;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// Localized label for manualExecute
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualExecute;

  /// No description provided for @modelConfig.
  ///
  /// In en, this message translates to:
  /// **'Model Config'**
  String get modelConfig;

  /// No description provided for @modelConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage API endpoint and keys'**
  String get modelConfigDesc;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistory;

  /// No description provided for @noHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Completed sessions will appear here'**
  String get noHistoryHint;

  /// No description provided for @noOutput.
  ///
  /// In en, this message translates to:
  /// **'(no output)'**
  String get noOutput;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No Tasks'**
  String get noTasks;

  /// No description provided for @noTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your design requirements in the chat panel; tasks will appear here.'**
  String get noTasksHint;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @pluginMarket.
  ///
  /// In en, this message translates to:
  /// **'Plugin Marketplace'**
  String get pluginMarket;

  /// No description provided for @pluginMarketDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse and install plugins'**
  String get pluginMarketDesc;

  /// No description provided for @proxyHost.
  ///
  /// In en, this message translates to:
  /// **'Proxy Host'**
  String get proxyHost;

  /// No description provided for @proxyPort.
  ///
  /// In en, this message translates to:
  /// **'Proxy Port'**
  String get proxyPort;

  /// No description provided for @proxySettings.
  ///
  /// In en, this message translates to:
  /// **'Proxy Settings'**
  String get proxySettings;

  /// No description provided for @proxySettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure network proxy'**
  String get proxySettingsDesc;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saveSuccess;

  /// Localized label for searchPlugins
  ///
  /// In en, this message translates to:
  /// **'Search plugins...'**
  String get searchPlugins;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @tabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabPlugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get tabPlugins;

  /// No description provided for @tabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// No description provided for @targetSoftware.
  ///
  /// In en, this message translates to:
  /// **'Target Software:'**
  String get targetSoftware;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get taskCompleted;

  /// No description provided for @taskFailed.
  ///
  /// In en, this message translates to:
  /// **'Task failed'**
  String get taskFailed;

  /// No description provided for @taskList.
  ///
  /// In en, this message translates to:
  /// **'Task List'**
  String get taskList;

  /// No description provided for @tasksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks'**
  String tasksCount(Object count);

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @uninstallSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} uninstalled'**
  String uninstallSuccess(Object name);

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fa',
    'fil',
    'fr',
    'hi',
    'ja',
    'ko',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fil':
      return AppLocalizationsFil();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
