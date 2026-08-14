import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_design_studio/l10n/app_localizations.dart';

/// 解析抽象类源文件，提取全部成员名（getter + 带参方法）。
List<String> abstractMembers(String source) {
  final getters = RegExp(r'String get (\w+);')
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet();
  final methods = RegExp(r'String (\w+)\([^)]*\);')
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet();
  return [...getters, ...methods]..sort();
}

/// 解析具体 locale 文件，提取被 @override 的成员名。
List<String> overriddenMembers(String source) {
  final getters = RegExp(r'@override\s+String get (\w+)')
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet();
  final methods = RegExp(r'@override\s+String (\w+)\([^)]*\)')
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet();
  return [...getters, ...methods]..sort();
}

/// 按名称调用实例成员；未覆盖的成员名直接抛错，保证 dispatch 与抽象类同步。
String invokeMember(AppLocalizations l, String name) {
  switch (name) {
    case 'about':
      return l.about;
    case 'aboutDescription1':
      return l.aboutDescription1;
    case 'aboutDescription2':
      return l.aboutDescription2;
    case 'aboutDeveloper':
      return l.aboutDeveloper;
    case 'aboutPackageName':
      return l.aboutPackageName;
    case 'agentBackend':
      return l.agentBackend;
    case 'agentBackendDesc':
      return l.agentBackendDesc;
    case 'all':
      return l.all;
    case 'apiEndpoint':
      return l.apiEndpoint;
    case 'apiKey':
      return l.apiKey;
    case 'appTitle':
      return l.appTitle;
    case 'autoExecute':
      return l.autoExecute;
    case 'backendClaude':
      return l.backendClaude;
    case 'backendCodex':
      return l.backendCodex;
    case 'backendGemini':
      return l.backendGemini;
    case 'backendHermes':
      return l.backendHermes;
    case 'backendOpenclaw':
      return l.backendOpenclaw;
    case 'backendOpencode':
      return l.backendOpencode;
    case 'backendReasonix':
      return l.backendReasonix;
    case 'cancel':
      return l.cancel;
    case 'categoryAd':
      return l.categoryAd;
    case 'categoryArch':
      return l.categoryArch;
    case 'categoryIndustrial':
      return l.categoryIndustrial;
    case 'categoryInterior':
      return l.categoryInterior;
    case 'categoryThreeD':
      return l.categoryThreeD;
    case 'categoryWeb':
      return l.categoryWeb;
    case 'claudeInstallFailed':
      return l.claudeInstallFailed;
    case 'claudeUpToDate':
      return l.claudeUpToDate;
    case 'claudeVersion':
      return l.claudeVersion;
    case 'close':
      return l.close;
    case 'comingSoon':
      return l.comingSoon;
    case 'completed':
      return l.completed;
    case 'connected':
      return l.connected;
    case 'copied':
      return l.copied;
    case 'copy':
      return l.copy;
    case 'defaultModel':
      return l.defaultModel;
    case 'delete':
      return l.delete;
    case 'deleteAll':
      return l.deleteAll;
    case 'deleteConfirm':
      return l.deleteConfirm;
    case 'designDomains':
      return l.designDomains;
    case 'disconnected':
      return l.disconnected;
    case 'done':
      return l.done;
    case 'echoPrefix':
      return l.echoPrefix;
    case 'endpointUrl':
      return l.endpointUrl;
    case 'enterExportPath':
      return l.enterExportPath;
    case 'enterPluginPackagePath':
      return l.enterPluginPackagePath;
    case 'errorPrefix':
      return l.errorPrefix;
    case 'exportAction':
      return l.exportAction;
    case 'exportHistory':
      return l.exportHistory;
    case 'exportHistoryFailed':
      return l.exportHistoryFailed;
    case 'exportNoSessions':
      return l.exportNoSessions;
    case 'hintText':
      return l.hintText;
    case 'history':
      return l.history;
    case 'historyList':
      return l.historyList;
    case 'importAction':
      return l.importAction;
    case 'inProgress':
      return l.inProgress;
    case 'install':
      return l.install;
    case 'installClaude':
      return l.installClaude;
    case 'installPlugin':
      return l.installPlugin;
    case 'installedPlugins':
      return l.installedPlugins;
    case 'installingClaude':
      return l.installingClaude;
    case 'invalidEndpointUrl':
      return l.invalidEndpointUrl;
    case 'invalidModelName':
      return l.invalidModelName;
    case 'invalidProxyHostPath':
      return l.invalidProxyHostPath;
    case 'invalidProxyHostSpaces':
      return l.invalidProxyHostSpaces;
    case 'invalidProxyPort':
      return l.invalidProxyPort;
    case 'language':
      return l.language;
    case 'languageInstruction':
      return l.languageInstruction;
    case 'manage':
      return l.manage;
    case 'manualExecute':
      return l.manualExecute;
    case 'modelConfig':
      return l.modelConfig;
    case 'modelConfigDesc':
      return l.modelConfigDesc;
    case 'navigation':
      return l.navigation;
    case 'noHistory':
      return l.noHistory;
    case 'noHistoryHint':
      return l.noHistoryHint;
    case 'noOutput':
      return l.noOutput;
    case 'noPluginsToExport':
      return l.noPluginsToExport;
    case 'noTasks':
      return l.noTasks;
    case 'noTasksHint':
      return l.noTasksHint;
    case 'ok':
      return l.ok;
    case 'pluginMarket':
      return l.pluginMarket;
    case 'pluginMarketDesc':
      return l.pluginMarketDesc;
    case 'proxyHost':
      return l.proxyHost;
    case 'proxyHostRequired':
      return l.proxyHostRequired;
    case 'proxyPort':
      return l.proxyPort;
    case 'proxySettings':
      return l.proxySettings;
    case 'proxySettingsDesc':
      return l.proxySettingsDesc;
    case 'remoteConfigSaveFailed':
      return l.remoteConfigSaveFailed;
    case 'remoteConfigSaved':
      return l.remoteConfigSaved;
    case 'remoteEndpoint':
      return l.remoteEndpoint;
    case 'retry':
      return l.retry;
    case 'rustConnected':
      return l.rustConnected;
    case 'rustDisconnected':
      return l.rustDisconnected;
    case 'save':
      return l.save;
    case 'saveSuccess':
      return l.saveSuccess;
    case 'searchPlugins':
      return l.searchPlugins;
    case 'selectPluginToExport':
      return l.selectPluginToExport;
    case 'settings':
      return l.settings;
    case 'tabChat':
      return l.tabChat;
    case 'tabHistory':
      return l.tabHistory;
    case 'tabPlugins':
      return l.tabPlugins;
    case 'tabTasks':
      return l.tabTasks;
    case 'targetSoftware':
      return l.targetSoftware;
    case 'taskCompleted':
      return l.taskCompleted;
    case 'taskFailed':
      return l.taskFailed;
    case 'taskList':
      return l.taskList;
    case 'uninstall':
      return l.uninstall;
    case 'unknownError':
      return l.unknownError;
    case 'aboutVersion':
      return l.aboutVersion('x');
    case 'available':
      return l.available('x');
    case 'deleteAllConfirm':
      return l.deleteAllConfirm('x');
    case 'deleteSelected':
      return l.deleteSelected('x');
    case 'exportPluginFailed':
      return l.exportPluginFailed('x');
    case 'exportPluginSuccess':
      return l.exportPluginSuccess('x');
    case 'importFailed':
      return l.importFailed('x');
    case 'importSuccess':
      return l.importSuccess('x', 'x');
    case 'installSuccess':
      return l.installSuccess('x');
    case 'installed':
      return l.installed('x');
    case 'tasksCount':
      return l.tasksCount('x');
    case 'uninstallSuccess':
      return l.uninstallSuccess('x');
    default:
      throw StateError('未处理的本地化成员: $name，请同步更新 invokeMember');
  }
}

void main() {
  final l10nDir = Directory('${Directory.current.path}/lib/l10n');
  final abstractSource = File('${l10nDir.path}/app_localizations.dart')
      .readAsStringSync();
  final allMembers = abstractMembers(abstractSource);
  final localeFiles = l10nDir
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'app_localizations_\w+\.dart$').hasMatch(f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('抽象类成员与 invokeMember dispatch 完全一致', () {
    final probe = lookupAppLocalizations(const Locale('en'));
    for (final name in allMembers) {
      // 若 dispatch 缺失该成员会抛 StateError
      expect(() => invokeMember(probe, name), returnsNormally,
          reason: 'dispatch 缺少成员 $name');
    }
  });

  test('每个 locale 文件覆盖抽象类全部成员', () {
    expect(localeFiles, isNotEmpty);
    for (final file in localeFiles) {
      final src = file.readAsStringSync();
      final missing =
          allMembers.toSet().difference(overriddenMembers(src).toSet());
      expect(missing, isEmpty,
          reason: '${file.uri.pathSegments.last} 缺少成员: $missing');
    }
  });

  test('每个具体 locale 类都已注册到 lookupAppLocalizations', () {
    for (final file in localeFiles) {
      final className =
          file.readAsStringSync().split('\n').firstWhere((l) => l.contains('class AppLocalizations')).trim();
      final match = RegExp(r'class (AppLocalizations\w+)').firstMatch(className);
      expect(match, isNotNull, reason: '${file.uri.pathSegments.last} 未找到类声明');
      final name = match!.group(1)!;
      expect(abstractSource.contains('return $name();'), isTrue,
          reason: '$name 未注册到 lookupAppLocalizations');
    }
  });

  test('每个支持的语言可实例化，且所有成员返回非空字符串', () {
    expect(AppLocalizations.supportedLocales.length, localeFiles.length,
        reason: 'supportedLocales 与 locale 文件数量不一致');
    for (final locale in AppLocalizations.supportedLocales) {
      final instance = lookupAppLocalizations(locale);
      expect(instance, isNotNull);
      expect(instance.localeName, locale.languageCode);
      for (final name in allMembers) {
        final value = invokeMember(instance, name);
        expect(value, isNotEmpty,
            reason: '${locale.languageCode}.$name 返回了空字符串');
      }
    }
  });

  test('8 个曾缺失的 key 在非英文语言中已有真实翻译（非英文回退）', () {
    // 曾因 arb 缺 key 而回退英文的 8 个 key，补译后必须与英文模板不同。
    // fr.categoryArch 例外：法语 'Architecture' 与英文同形，属真实翻译。
    const affectedKeys = [
      'categoryAd', 'categoryArch', 'categoryIndustrial', 'categoryInterior',
      'categoryThreeD', 'categoryWeb', 'endpointUrl', 'enterExportPath',
    ];
    const knownSameAsEnglish = {'fr:categoryArch'};
    final en = lookupAppLocalizations(const Locale('en'));
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == 'en') continue;
      final instance = lookupAppLocalizations(locale);
      for (final key in affectedKeys) {
        final value = invokeMember(instance, key);
        expect(value, isNotEmpty,
            reason: '${locale.languageCode}.$key 返回了空字符串');
        if (knownSameAsEnglish.contains('${locale.languageCode}:$key')) {
          continue;
        }
        expect(value, isNot(equals(invokeMember(en, key))),
            reason: '${locale.languageCode}.$key 仍为英文回退（未翻译）');
      }
    }
  });
}
