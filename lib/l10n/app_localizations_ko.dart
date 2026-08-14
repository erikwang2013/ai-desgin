// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get about => '정보';

  @override
  String get aboutDescription1 => 'AI 기반 디자인 소프트웨어 자동화 도구.';

  @override
  String get aboutDescription2 =>
      '6개 디자인 분야와 62개 이상의 주요 디자인 소프트웨어를 위한 AI 스크립트 생성 및 실행.';

  @override
  String get aboutDeveloper => '개발자: erik';

  @override
  String get aboutPackageName => '패키지 이름: Ai Desgin';

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
  String get all => '전체';

  @override
  String get apiEndpoint => 'API 엔드포인트';

  @override
  String get apiKey => 'API 키';

  @override
  String get appTitle => 'AI Design';

  @override
  String get autoExecute => '자동';

  @override
  String available(Object count) {
    return '설치 가능 ($count)';
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
  String get cancel => '취소';

  @override
  String get categoryAd => '광고 디자인';

  @override
  String get categoryArch => '건축';

  @override
  String get categoryIndustrial => '산업 디자인';

  @override
  String get categoryInterior => '인테리어 디자인';

  @override
  String get categoryThreeD => '3D 디자인';

  @override
  String get categoryWeb => '웹 디자인';

  @override
  String get claudeInstallFailed => 'Install failed, check npm environment';

  @override
  String get claudeUpToDate => 'Up to date';

  @override
  String get claudeVersion => 'Claude Code Version';

  @override
  String get close => '닫기';

  @override
  String get comingSoon => '곧 출시';

  @override
  String get completed => '완료됨';

  @override
  String get connected => '연결됨';

  @override
  String get copied => '복사됨';

  @override
  String get copy => '복사';

  @override
  String get defaultModel => '기본 모델';

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
  String get designDomains => '디자인 분야';

  @override
  String get disconnected => '연결 안 됨';

  @override
  String get done => 'Done';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get endpointUrl => '엔드포인트 URL';

  @override
  String get enterExportPath => '내보내기 경로 입력 (.zip)';

  @override
  String get enterPluginPackagePath => 'Enter plugin package (.zip) path';

  @override
  String get errorPrefix => '오류';

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
  String get hintText => '원하는 디자인 작업을 설명하세요...';

  @override
  String get history => '기록';

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
  String get inProgress => '진행 중';

  @override
  String get install => '설치';

  @override
  String get installClaude => 'Install Claude Code 2.1.143';

  @override
  String get installPlugin => '플러그인 설치';

  @override
  String installSuccess(Object name) {
    return '$name 설치 성공';
  }

  @override
  String installed(Object count) {
    return '설치됨 ($count)';
  }

  @override
  String get installedPlugins => '설치된 플러그인';

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
  String get language => '언어';

  @override
  String get languageInstruction => '한국어로 답변해 주세요.';

  @override
  String get manage => 'Manage';

  @override
  String get manualExecute => '수동';

  @override
  String get rustConnected => 'Rust core connected · registry from Rust';

  @override
  String get rustDisconnected =>
      'Rust core offline · using built-in Dart registry';

  @override
  String get modelConfig => '모델 구성';

  @override
  String get modelConfigDesc => 'API 엔드포인트 및 키 관리';

  @override
  String get navigation => '내비게이션';

  @override
  String get noHistory => 'No history';

  @override
  String get noHistoryHint => 'Completed sessions will appear here';

  @override
  String get historySearchHint => '기록 검색';

  @override
  String get searchNoResults => '일치하는 세션이 없습니다';

  @override
  String get deleteFailed => '삭제 실패';

  @override
  String get exportMarkdown => 'Markdown 내보내기';

  @override
  String get openFailed => '열기 실패';

  @override
  String get more => '더 보기';

  @override
  String get noOutput => '(출력 없음)';

  @override
  String get noPluginsToExport => 'No installed plugins to export';

  @override
  String get noTasks => '작업 없음';

  @override
  String get noTasksHint => '채팅 패널에 디자인 요구사항을 입력하면 작업이 여기에 표시됩니다.';

  @override
  String get ok => '확인';

  @override
  String get pluginMarket => '플러그인 마켓';

  @override
  String get pluginMarketDesc => '플러그인 탐색 및 설치';

  @override
  String get proxyHost => '프록시 호스트';

  @override
  String get proxyHostRequired => 'Proxy host is required when a port is set';

  @override
  String get proxyPort => '프록시 포트';

  @override
  String get proxySettings => '프록시 설정';

  @override
  String get proxySettingsDesc => '네트워크 프록시 구성';

  @override
  String get remoteConfigSaveFailed => 'Failed to save remote endpoint config';

  @override
  String get remoteConfigSaved => 'Remote endpoint config saved';

  @override
  String get remoteEndpoint => 'Remote Endpoint';

  @override
  String get retry => 'Retry';

  @override
  String get save => '저장';

  @override
  String get saveSuccess => '저장됨';

  @override
  String get searchPlugins => '플러그인 검색...';

  @override
  String get selectPluginToExport => 'Select plugin to export';

  @override
  String get settings => '설정';

  @override
  String get tabChat => '채팅';

  @override
  String get tabHistory => 'History';

  @override
  String get tabPlugins => '플러그인';

  @override
  String get tabTasks => '작업';

  @override
  String get targetSoftware => '대상 소프트웨어:';

  @override
  String get taskCompleted => '작업 완료';

  @override
  String get taskFailed => '작업 실패';

  @override
  String get taskList => '작업 목록';

  @override
  String tasksCount(Object count) {
    return '$count tasks';
  }

  @override
  String get uninstall => '제거';

  @override
  String uninstallSuccess(Object name) {
    return '$name 제거됨';
  }

  @override
  String get unknownError => '알 수 없는 오류';
}
