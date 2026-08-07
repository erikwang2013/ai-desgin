// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => 'デザイン分野';

  @override
  String get navigation => 'ナビゲーション';

  @override
  String get tabChat => 'チャット';

  @override
  String get tabTasks => 'タスク';

  @override
  String get tabPlugins => 'プラグイン';

  @override
  String get settings => '設定';

  @override
  String get targetSoftware => '対象ソフトウェア：';

  @override
  String get hintText => '実行したいデザイン操作を説明してください...';

  @override
  String get modelConfig => 'モデル設定';

  @override
  String get modelConfigDesc => 'APIエンドポイントとキーを管理';

  @override
  String get pluginMarket => 'プラグインマーケット';

  @override
  String get pluginMarketDesc => 'プラグインの参照とインストール';

  @override
  String get proxySettings => 'プロキシ設定';

  @override
  String get proxySettingsDesc => 'ネットワークプロキシを設定';

  @override
  String get about => 'について';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => '近日公開';

  @override
  String get aboutDescription1 => 'AI駆動のデザインソフトウェア自動化ツール。';

  @override
  String get aboutDescription2 =>
      '6つのデザイン分野、62以上の主要デザインソフトウェアに対応するAIスクリプト生成と実行。';

  @override
  String get aboutPackageName => 'パッケージ名：Ai Desgin';

  @override
  String get aboutDeveloper => '開発者: erik';

  @override
  String get retry => 'Retry';

  @override
  String get installedPlugins => 'インストール済みプラグイン';

  @override
  String get installPlugin => 'プラグインをインストール';

  @override
  String get connected => '接続済み';

  @override
  String get disconnected => '未接続';

  @override
  String get all => 'すべて';

  @override
  String get inProgress => '進行中';

  @override
  String get completed => '完了';

  @override
  String get taskList => 'タスク一覧';

  @override
  String get noTasks => 'タスクなし';

  @override
  String get noTasksHint => 'チャットパネルにデザイン要件を入力すると、タスクがここに表示されます。';

  @override
  String installed(Object count) {
    return 'インストール済み ($count)';
  }

  @override
  String available(Object count) {
    return 'インストール可能 ($count)';
  }

  @override
  String get install => 'インストール';

  @override
  String get uninstall => 'アンインストール';

  @override
  String installSuccess(Object name) {
    return '$name インストール成功';
  }

  @override
  String uninstallSuccess(Object name) {
    return '$name アンインストール済み';
  }

  @override
  String get ok => 'OK';

  @override
  String get errorPrefix => 'エラー';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => 'タスク完了';

  @override
  String get taskFailed => 'タスク失敗';

  @override
  String get noOutput => '(出力なし)';

  @override
  String get unknownError => '不明なエラー';

  @override
  String get languageInstruction => '日本語で返信してください。';

  @override
  String get language => '言語';

  @override
  String get apiEndpoint => 'API エンドポイント';

  @override
  String get apiKey => 'API キー';

  @override
  String get defaultModel => 'デフォルトモデル';

  @override
  String get save => '保存';

  @override
  String get proxyHost => 'プロキシホスト';

  @override
  String get proxyPort => 'プロキシポート';

  @override
  String get saveSuccess => '保存しました';

  @override
  String get history => '履歴';

  @override
  String get searchPlugins => 'プラグインを検索...';

  @override
  String get autoExecute => '自動';

  @override
  String get manualExecute => '手動';

  @override
  String get copied => 'コピーしました';

  @override
  String get copy => 'コピー';

  @override
  String get close => '閉じる';

  @override
  String get cancel => 'キャンセル';

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
}
