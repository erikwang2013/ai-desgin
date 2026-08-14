// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get about => '关于';

  @override
  String get aboutDescription1 =>
      'AI Design是一个支持 Windows 和 macOS 的桌面应用，通过内置 Claude Code CLI 实现 AI 驱动的多模型调度，自动生成控制脚本并操作各类设计软件。';

  @override
  String get aboutDescription2 => '覆盖 六大设计领域：Web 设计、广告设计、工业设计、3D 设计、建筑设计、装修设计。';

  @override
  String get aboutDeveloper => '开发者：erik';

  @override
  String get aboutPackageName => '应用包名称：Ai Desgin';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get agentBackend => 'Agent 后端';

  @override
  String get agentBackendDesc => '选择用于生成脚本的 Agent CLI';

  @override
  String get all => '全部';

  @override
  String get apiEndpoint => 'API 端点';

  @override
  String get apiKey => 'API 密钥';

  @override
  String get appTitle => 'AI Design';

  @override
  String get autoExecute => '自动执行';

  @override
  String available(Object count) {
    return '可安装 ($count)';
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
  String get cancel => '取消';

  @override
  String get categoryAd => '广告设计';

  @override
  String get categoryArch => '建筑设计';

  @override
  String get categoryIndustrial => '工业设计';

  @override
  String get categoryInterior => '装修设计';

  @override
  String get categoryThreeD => '3D 设计';

  @override
  String get categoryWeb => 'Web 设计';

  @override
  String get claudeInstallFailed => '安装失败，请检查 npm 环境';

  @override
  String get claudeUpToDate => '已是最新版本';

  @override
  String get claudeVersion => 'Claude Code 版本';

  @override
  String get close => '关闭';

  @override
  String get comingSoon => '即将推出';

  @override
  String get completed => '已完成';

  @override
  String get connected => '已连接';

  @override
  String get copied => '已复制';

  @override
  String get copy => '复制';

  @override
  String get defaultModel => '默认模型';

  @override
  String get delete => '删除';

  @override
  String get deleteAll => '全部删除';

  @override
  String deleteAllConfirm(Object count) {
    return '确定删除全部 $count 个会话？';
  }

  @override
  String get deleteConfirm => '确定删除该会话？';

  @override
  String deleteSelected(Object count) {
    return '删除所选 ($count)';
  }

  @override
  String get designDomains => '设计领域';

  @override
  String get disconnected => '未连接';

  @override
  String get done => '完成';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get errorPrefix => '错误';

  @override
  String get hintText => '描述你想要的设计操作...';

  @override
  String get history => '历史';

  @override
  String get historyList => '历史会话';

  @override
  String get inProgress => '进行中';

  @override
  String get install => '安装';

  @override
  String get installClaude => '安装 Claude Code 2.1.143';

  @override
  String get installPlugin => '安装插件';

  @override
  String installSuccess(Object name) {
    return '$name 安装成功';
  }

  @override
  String installed(Object count) {
    return '已安装 ($count)';
  }

  @override
  String get installedPlugins => '已安装插件';

  @override
  String get installingClaude => '正在安装…';

  @override
  String get language => '语言';

  @override
  String get languageInstruction => '请使用中文回复。';

  @override
  String get manage => '管理';

  @override
  String get manualExecute => '手动执行';

  @override
  String get rustConnected => 'Rust 内核已连接 · 注册表来自 Rust';

  @override
  String get rustDisconnected => 'Rust 内核未连接 · 使用 Dart 内置注册表';

  @override
  String get modelConfig => '模型配置';

  @override
  String get modelConfigDesc => '管理 API endpoint 和密钥';

  @override
  String get navigation => '导航';

  @override
  String get noHistory => '暂无历史会话';

  @override
  String get noHistoryHint => '完成任务后会话将显示在这里';

  @override
  String get noOutput => '(无输出)';

  @override
  String get noTasks => '暂无任务';

  @override
  String get noTasksHint => '在对话面板中输入设计需求，任务将显示在这里';

  @override
  String get ok => '确定';

  @override
  String get pluginMarket => '插件市场';

  @override
  String get pluginMarketDesc => '浏览和安装插件';

  @override
  String get proxyHost => '代理主机';

  @override
  String get proxyPort => '代理端口';

  @override
  String get proxySettings => '代理设置';

  @override
  String get proxySettingsDesc => '配置网络代理';

  @override
  String get retry => '重试';

  @override
  String get save => '保存';

  @override
  String get saveSuccess => '保存成功';

  @override
  String get searchPlugins => '搜索插件...';

  @override
  String get settings => '设置';

  @override
  String get tabChat => '对话';

  @override
  String get tabHistory => '历史';

  @override
  String get tabPlugins => '插件';

  @override
  String get tabTasks => '任务';

  @override
  String get targetSoftware => '目标软件：';

  @override
  String get taskCompleted => '任务完成';

  @override
  String get taskFailed => '任务失败';

  @override
  String get taskList => '任务列表';

  @override
  String tasksCount(Object count) {
    return '$count 个任务';
  }

  @override
  String get uninstall => '卸载';

  @override
  String uninstallSuccess(Object name) {
    return '$name 已卸载';
  }

  @override
  String get unknownError => '未知错误';
}
