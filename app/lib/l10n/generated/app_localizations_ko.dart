// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get restoreSettingsBackup => '설정 백업 복원';

  @override
  String get appName => '시여';

  @override
  String get tagline => '시간을 느끼고, 일상을 소중히.';

  @override
  String get initializationNotice => '앱의 기반이 준비되었습니다. 시간 및 급여 기능을 개발 중입니다.';

  @override
  String get retirementTitle => '은퇴 카운트다운';

  @override
  String get retired => '은퇴 완료';

  @override
  String get daysRemaining => '일 후 은퇴';

  @override
  String get chooseRetirement => '은퇴 날짜 선택';

  @override
  String get configure => '설정';

  @override
  String get hideWindow => '창 숨기기';

  @override
  String get timeZoneLabel => 'IANA 시간대';

  @override
  String get saveSettings => '시간대 저장';

  @override
  String get clearTarget => '날짜 지우기';

  @override
  String get addWidget => '홈 화면 위젯 추가';

  @override
  String get widgetInstructions => '홈 화면을 길게 누른 후 Shiyu 은퇴 위젯을 추가하세요.';

  @override
  String get settingsError => '날짜, 시간대, 공유 저장소를 확인하고 다시 시도하세요.';

  @override
  String get calendarFallback => '공휴일 데이터가 아직 연결되지 않아 설정된 주간 근무일을 사용합니다.';

  @override
  String get currentSlice => '현재 은퇴 카운트다운을 지원합니다. 다른 지표는 후속 단계에서 제공됩니다.';

  @override
  String get mobileSettings => '설정';

  @override
  String get mobileAppearance => '위젯 모양';

  @override
  String get mobileWidget => '홈 화면 위젯';

  @override
  String get mobileShowTitle => '제목 표시';

  @override
  String get mobileTitleSize => '제목 글자 크기';

  @override
  String get mobileMacaron => '마카롱';

  @override
  String get mobileCool => '쿨';

  @override
  String get mobileSunset => '노을';

  @override
  String get mobileSave => '설정 저장';

  @override
  String get mobileSaved => '설정을 저장했습니다';

  @override
  String get mobileAppearanceError => '모양을 저장하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get mobileNotSet => '설정되지 않음';
}
