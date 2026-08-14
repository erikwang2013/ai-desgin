// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get about => 'について';

  @override
  String get aboutDescription1 => 'AI駆動のデザインソフトウェア自動化ツール。';

  @override
  String get aboutDescription2 =>
      '6つのデザイン分野、62以上の主要デザインソフトウェアに対応するAIスクリプト生成と実行。';

  @override
  String get aboutDeveloper => '開発者: erik';

  @override
  String get aboutPackageName => 'パッケージ名：Ai Desgin';

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
  String get all => 'すべて';

  @override
  String get apiEndpoint => 'API エンドポイント';

  @override
  String get apiKey => 'API キー';

  @override
  String get appTitle => 'AI Design';

  @override
  String get artifacts => 'アーティファクト';

  @override
  String get autoExecute => '自動';

  @override
  String available(Object count) {
    return 'インストール可能 ($count)';
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
  String get cancel => 'キャンセル';

  @override
  String get categoryAd => '広告デザイン';

  @override
  String get categoryArch => '建築';

  @override
  String get categoryIndustrial => 'インダストリアルデザイン';

  @override
  String get categoryInterior => 'インテリアデザイン';

  @override
  String get categoryThreeD => '3Dデザイン';

  @override
  String get categoryWeb => 'ウェブデザイン';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get close => '閉じる';

  @override
  String get comingSoon => '近日公開';

  @override
  String get completed => '完了';

  @override
  String get connected => '接続済み';

  @override
  String get copied => 'コピーしました';

  @override
  String get copy => 'コピー';

  @override
  String get defaultModel => 'デフォルトモデル';

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
  String get designDomains => 'デザイン分野';

  @override
  String get disconnected => '未接続';

  @override
  String get done => 'Done';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get endpointUrl => 'エンドポイントURL';

  @override
  String get enterExportPath => 'エクスポート先パスを入力 (.zip)';

  @override
  String get enterPluginPackagePath => 'Enter plugin package (.zip) path';

  @override
  String get errorPrefix => 'エラー';

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
  String get hintText => '実行したいデザイン操作を説明してください...';

  @override
  String get history => '履歴';

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
  String get inProgress => '進行中';

  @override
  String get install => 'インストール';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installPlugin => 'プラグインをインストール';

  @override
  String installSuccess(Object name) {
    return '$name インストール成功';
  }

  @override
  String installed(Object count) {
    return 'インストール済み ($count)';
  }

  @override
  String get installedPlugins => 'インストール済みプラグイン';

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
  String get language => '言語';

  @override
  String get languageInstruction => '日本語で返信してください。';

  @override
  String get manage => 'Manage';

  @override
  String get manualExecute => '手動';

  @override
  String get rustConnected => 'Rust core connected · registry from Rust';

  @override
  String get rustDisconnected =>
      'Rust core offline · using built-in Dart registry';

  @override
  String get modelConfig => 'モデル設定';

  @override
  String get modelConfigDesc => 'APIエンドポイントとキーを管理';

  @override
  String get navigation => 'ナビゲーション';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get historySearchHint => '履歴を検索';

  @override
  String get searchNoResults => '一致するセッションがありません';

  @override
  String get deleteFailed => '削除に失敗しました';

  @override
  String get exportMarkdown => 'Markdown でエクスポート';

  @override
  String get openDirectory => 'フォルダを開く';

  @override
  String get openFailed => '開けませんでした';

  @override
  String get openFile => 'ファイルを開く';

  @override
  String get more => 'その他';

  @override
  String get noOutput => '(出力なし)';

  @override
  String get noPluginsToExport => 'No installed plugins to export';

  @override
  String get noTasks => 'タスクなし';

  @override
  String get noTasksHint => 'チャットパネルにデザイン要件を入力すると、タスクがここに表示されます。';

  @override
  String get ok => 'OK';

  @override
  String get pluginMarket => 'プラグインマーケット';

  @override
  String get pluginMarketDesc => 'プラグインの参照とインストール';

  @override
  String get proxyHost => 'プロキシホスト';

  @override
  String get proxyHostRequired => 'Proxy host is required when a port is set';

  @override
  String get proxyPort => 'プロキシポート';

  @override
  String get proxySettings => 'プロキシ設定';

  @override
  String get proxySettingsDesc => 'ネットワークプロキシを設定';

  @override
  String get refreshConnectionStatus => '接続状態を更新';

  @override
  String get remoteConfigSaveFailed => 'Failed to save remote endpoint config';

  @override
  String get remoteConfigSaved => 'Remote endpoint config saved';

  @override
  String get remoteEndpoint => 'Remote Endpoint';

  @override
  String get retry => 'Retry';

  @override
  String get save => '保存';

  @override
  String get saveSuccess => '保存しました';

  @override
  String get searchPlugins => 'プラグインを検索...';

  @override
  String get selectPluginToExport => 'Select plugin to export';

  @override
  String get settings => '設定';

  @override
  String get stop => '停止';

  @override
  String get tabChat => 'チャット';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlugins => 'プラグイン';

  @override
  String get tabTasks => 'タスク';

  @override
  String get targetSoftware => '対象ソフトウェア：';

  @override
  String get taskCompleted => 'タスク完了';

  @override
  String get taskFailed => 'タスク失敗';

  @override
  String get taskList => 'タスク一覧';

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get uninstall => 'アンインストール';

  @override
  String uninstallSuccess(Object name) {
    return '$name アンインストール済み';
  }

  @override
  String get unknownError => '不明なエラー';
}
