// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'AI Design';

  @override
  String get designDomains => '디자인 분야';

  @override
  String get navigation => '내비게이션';

  @override
  String get tabChat => '채팅';

  @override
  String get tabTasks => '작업';

  @override
  String get tabPlugins => '플러그인';

  @override
  String get settings => '설정';

  @override
  String get targetSoftware => '대상 소프트웨어:';

  @override
  String get hintText => '원하는 디자인 작업을 설명하세요...';

  @override
  String get modelConfig => '모델 구성';

  @override
  String get modelConfigDesc => 'API 엔드포인트 및 키 관리';

  @override
  String get pluginMarket => '플러그인 마켓';

  @override
  String get pluginMarketDesc => '플러그인 탐색 및 설치';

  @override
  String get proxySettings => '프록시 설정';

  @override
  String get proxySettingsDesc => '네트워크 프록시 구성';

  @override
  String get about => '정보';

  @override
  String aboutVersion(Object version) {
    return 'AI Design v$version';
  }

  @override
  String get comingSoon => '곧 출시';

  @override
  String get aboutDescription1 => 'AI 기반 디자인 소프트웨어 자동화 도구.';

  @override
  String get aboutDescription2 =>
      '6개 디자인 분야와 47개 이상의 주요 디자인 소프트웨어를 위한 AI 스크립트 생성 및 실행.';

  @override
  String get installedPlugins => '설치된 플러그인';

  @override
  String get installPlugin => '플러그인 설치';

  @override
  String get connected => '연결됨';

  @override
  String get disconnected => '연결 안 됨';

  @override
  String get all => '전체';

  @override
  String get inProgress => '진행 중';

  @override
  String get completed => '완료됨';

  @override
  String get taskList => '작업 목록';

  @override
  String get noTasks => '작업 없음';

  @override
  String get noTasksHint => '채팅 패널에 디자인 요구사항을 입력하면 작업이 여기에 표시됩니다.';

  @override
  String installed(Object count) {
    return '설치됨 ($count)';
  }

  @override
  String available(Object count) {
    return '설치 가능 ($count)';
  }

  @override
  String get install => '설치';

  @override
  String get uninstall => '제거';

  @override
  String installSuccess(Object name) {
    return '$name 설치 성공';
  }

  @override
  String uninstallSuccess(Object name) {
    return '$name 제거됨';
  }

  @override
  String get ok => '확인';

  @override
  String get errorPrefix => '오류';

  @override
  String get echoPrefix => 'Echo';

  @override
  String get taskCompleted => '작업 완료';

  @override
  String get taskFailed => '작업 실패';

  @override
  String get noOutput => '(출력 없음)';

  @override
  String get unknownError => '알 수 없는 오류';

  @override
  String get languageInstruction => '한국어로 답변해 주세요.';
}
