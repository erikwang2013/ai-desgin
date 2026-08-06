// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => '设计领域';

  @override
  String get navigation => '导航';

  @override
  String get tabChat => '对话';

  @override
  String get tabTasks => '任务';

  @override
  String get tabPlugins => '插件';

  @override
  String get settings => '设置';

  @override
  String get targetSoftware => '目标软件：';

  @override
  String get hintText => '描述你想要的设计操作...';

  @override
  String get modelConfig => '模型配置';

  @override
  String get modelConfigDesc => '管理 API endpoint 和密钥';

  @override
  String get pluginMarket => '插件市场';

  @override
  String get pluginMarketDesc => '浏览和安装插件';

  @override
  String get proxySettings => '代理设置';

  @override
  String get proxySettingsDesc => '配置网络代理';

  @override
  String get about => '关于';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => '即将推出';

  @override
  String get aboutDescription1 => '一款 AI 驱动的设计软件自动化工具。';

  @override
  String get aboutDescription2 => '覆盖 6 大设计领域、62 款主流设计软件的 AI 驱动脚本生成与执行。';

  @override
  String get installedPlugins => '已安装插件';

  @override
  String get installPlugin => '安装插件';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '未连接';

  @override
  String get all => '全部';

  @override
  String get inProgress => '进行中';

  @override
  String get completed => '已完成';

  @override
  String get taskList => '任务列表';

  @override
  String get noTasks => '暂无任务';

  @override
  String get noTasksHint => '在对话面板中输入设计需求，任务将显示在这里';

  @override
  String installed(Object count) {
    return '已安装 ($count)';
  }

  @override
  String available(Object count) {
    return '可安装 ($count)';
  }

  @override
  String get install => '安装';

  @override
  String get uninstall => '卸载';

  @override
  String installSuccess(Object name) {
    return '$name 安装成功';
  }

  @override
  String uninstallSuccess(Object name) {
    return '$name 已卸载';
  }

  @override
  String get ok => '确定';

  @override
  String get errorPrefix => '错误';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => '任务完成';

  @override
  String get taskFailed => '任务失败';

  @override
  String get noOutput => '(无输出)';

  @override
  String get unknownError => '未知错误';

  @override
  String get languageInstruction => '请使用中文回复。';

  @override
  String get language => '语言';

  @override
  String get apiEndpoint => 'API 端点';

  @override
  String get apiKey => 'API 密钥';

  @override
  String get defaultModel => '默认模型';

  @override
  String get save => '保存';

  @override
  String get proxyHost => '代理主机';

  @override
  String get proxyPort => '代理端口';

  @override
  String get saveSuccess => '保存成功';

  @override
  String get history => '历史';

  @override
  String get searchPlugins => '搜索插件...';

  @override
  String get autoExecute => '自动执行';

  @override
  String get manualExecute => '手动执行';

  @override
  String get copied => '已复制';

  @override
  String get copy => '复制';

  @override
  String get close => '关闭';

  @override
  String get cancel => '取消';
}
