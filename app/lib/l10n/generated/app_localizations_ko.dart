// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get mobileMacaronGlass => '마카롱 글라스';

  @override
  String get mobileCountdownSummary => '은퇴 날짜, 생년월일, 생애 표시 방식';

  @override
  String get mobileWorkSummary => '근무일, 근무 시간, 점심시간, 급여';

  @override
  String get mobileCalendarSummary => '급여일, 공휴일 지역, 예외 날짜';

  @override
  String get mobileTitlesSummary => '카운트다운별 제목 표시 설정';

  @override
  String get mobileWidgetSummary => '위젯 추가, 색상 및 글자 크기 변경';

  @override
  String get mobileGeneralSummary => '시간대, 금액 표시, 설정 백업';

  @override
  String get mobileSaving => '저장 중…';

  @override
  String get mobileDiscardChanges => '저장하지 않은 변경 사항을 버릴까요?';

  @override
  String get mobileDiscard => '변경 사항 버리기';

  @override
  String get metricTitleVisibility => '항목별 제목 표시';

  @override
  String get metricTitleVisibilityDetail => '제목을 꺼도 값은 표시됩니다. 플로팅 창과 위젯에는 제목을 한꺼번에 끄는 설정도 있습니다.';

  @override
  String get lifeDisplayMode => '생애 표시 방식';

  @override
  String get lifeElapsedTitle => '살아온 날 수';

  @override
  String lifeElapsedValue(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return '$daysString일';
  }

  @override
  String get desktopAppearance => '모양';

  @override
  String get desktopWindows => '창 관리';

  @override
  String get desktopCountdowns => '카운트다운';

  @override
  String get desktopCatAssets => '고양이 스티커';

  @override
  String get desktopAppearanceDescription => '언어, 색상, 글자 크기를 바꾸고 떠 있는 창을 미리 봅니다.';

  @override
  String get desktopWindowsDescription => '각 창의 내용을 확인하고 합치거나 나누고 표시를 조정합니다.';

  @override
  String get desktopCountdownsDescription => '바탕 화면에 표시할 카운트다운과 은퇴 날짜를 설정합니다.';

  @override
  String get desktopCatAssetsDescription => '창마다 고양이 스티커를 바꿉니다.';

  @override
  String get floatingMode => '창 모드';

  @override
  String get modeMini => '미니';

  @override
  String get modeStandard => '표준';

  @override
  String get modeExpanded => '확장';

  @override
  String get countdownExpired => '종료됨';

  @override
  String get holidayOngoing => '휴일 중';

  @override
  String get paydayToday => '오늘은 급여일';

  @override
  String get metricUnavailable => '사용할 수 없음';

  @override
  String get noVisibleMetrics => '모든 지표가 숨겨져 있습니다';

  @override
  String get untilWorkStart => '출근까지';

  @override
  String get untilWorkEnd => '퇴근까지';

  @override
  String get untilLunchEnd => '휴식 종료까지';

  @override
  String get addCountdown => '카운트다운 추가';

  @override
  String get addDateOverride => '날짜 설정 추가';

  @override
  String get addHoliday => '휴일 추가';

  @override
  String get appLanguage => '앱 언어';

  @override
  String get backStep => '이전';

  @override
  String get birthDate => '생년월일 (선택)';

  @override
  String get birthTime => '출생 시각 (선택)';

  @override
  String get businessSettings => '전체 설정';

  @override
  String get calendarSection => '날짜 및 휴일';

  @override
  String get currencyCode => '통화 코드';

  @override
  String get customCountdown => '사용자 지정 카운트다운';

  @override
  String get customHolidays => '사용자 지정 휴일';

  @override
  String get dateLabel => '날짜';

  @override
  String get dateOverrides => '날짜별 설정';

  @override
  String get dayType => '날짜 유형';

  @override
  String get disableAll => '모두 숨기기';

  @override
  String get displaySection => '플로팅 창';

  @override
  String get enableAll => '모두 표시';

  @override
  String get exportPrivacy => '내보내기에는 개인 정보와 급여가 포함됩니다. 안전한 위치를 선택하세요.';

  @override
  String get finishSetup => '설정 완료';

  @override
  String get fixedPayday => '매월 지정일';

  @override
  String get generalSection => '일반';

  @override
  String get grossMonthly => '세전 월급';

  @override
  String get hideSalary => '금액 숨기기';

  @override
  String get holidayEnd => '종료 날짜';

  @override
  String get holidayKind => '휴일 유형';

  @override
  String get holidayStart => '시작 날짜';

  @override
  String get invalidCountdown => '이름과 시각을 확인하세요. 새 목표는 미래여야 합니다.';

  @override
  String get invalidDraft => '표시된 항목을 확인하세요. 기존의 유효한 설정은 유지됩니다.';

  @override
  String get invalidHoliday => '이름과 유형을 입력하고 날짜 범위를 확인하세요.';

  @override
  String get invalidLifespan => '1~150년을 소수점 한 자리까지 입력하세요.';

  @override
  String get invalidLunch => '휴식 시간을 근무 시간 안에 설정하세요.';

  @override
  String get invalidPaydays => '1~31 사이의 서로 다른 날짜를 입력하세요.';

  @override
  String get invalidSalary => '0 이상의 유효한 금액을 입력하세요.';

  @override
  String get invalidValue => '입력값을 확인하세요.';

  @override
  String get invalidWorkHours => 'HH:mm 형식으로 같은 날의 시작보다 늦은 종료 시각을 입력하세요.';

  @override
  String get itemName => '이름';

  @override
  String get lastWorkday => '매월 마지막 근무일';

  @override
  String get lifeExpectancy => '기대 수명 (년)';

  @override
  String get lunchBreak => '점심 휴식';

  @override
  String get lunchEnd => '휴식 종료';

  @override
  String get lunchStart => '휴식 시작';

  @override
  String get metricHoliday => '다음 휴일까지';

  @override
  String get metricLife => '인생 카운트다운';

  @override
  String get metricMonthSalary => '이번 달 수입';

  @override
  String get metricPayday => '급여일까지';

  @override
  String get metricTodaySalary => '오늘 수입';

  @override
  String get metricWork => '근무 카운트다운';

  @override
  String get miniMetrics => '미니 창 지표';

  @override
  String get moveDown => '아래로 이동';

  @override
  String get moveUp => '위로 이동';

  @override
  String get netMonthly => '세후 월급 (선택)';

  @override
  String get netRequired => '세후로 전환하려면 세후 월급을 입력하세요.';

  @override
  String get nextStep => '계속';

  @override
  String get nextWorkday => '다음 근무일';

  @override
  String get noAdjustment => '날짜 유지';

  @override
  String get onboardingTitle => 'Shiyu 설정';

  @override
  String get paydayAdjustment => '급여일이 휴일일 때';

  @override
  String get paydayDate => '급여일';

  @override
  String get paydayRule => '급여 일정';

  @override
  String get peekSalary => '금액 잠시 보기';

  @override
  String get personalSection => '개인 정보';

  @override
  String get previewLive => '실제 데이터 미리 보기';

  @override
  String get previousWorkday => '이전 근무일';

  @override
  String get regionCN => '중국 본토';

  @override
  String get regionHK => '홍콩';

  @override
  String get regionJP => '일본';

  @override
  String get regionKR => '대한민국';

  @override
  String get regionLabel => '공휴일 지역';

  @override
  String get regionTW => '대만';

  @override
  String get regionUS => '미국';

  @override
  String get removeItem => '삭제';

  @override
  String get restDayLabel => '휴일';

  @override
  String get salaryBasis => '급여 기준';

  @override
  String get salaryPrecision => '소수 자릿수';

  @override
  String get settingsExport => '설정 내보내기';

  @override
  String get settingsExported => '설정을 내보냈습니다.';

  @override
  String get settingsFileInvalid => '파일을 사용할 수 없습니다. 크기, JSON 형식, 버전을 확인하세요.';

  @override
  String get settingsImport => '설정 가져오기';

  @override
  String get systemLanguage => '시스템 언어';

  @override
  String get targetTime => '목표 시각';

  @override
  String get twiceMonthly => '월 2회';

  @override
  String get weeklyRestHoliday => '주간 휴일을 휴식에 포함';

  @override
  String get workdayLabel => '근무일';

  @override
  String get workEnd => '퇴근 시각';

  @override
  String get workSection => '근무 및 급여';

  @override
  String get workStart => '출근 시각';

  @override
  String get workWeek => '근무 요일';

  @override
  String get holidayData => '공휴일 데이터';

  @override
  String get holidayFallback => '올해 데이터가 없어 설정한 주간 근무 일정으로 계산합니다.';

  @override
  String get holidayChecking => '공휴일 데이터 확인 중…';

  @override
  String get holidayCheck => '업데이트 확인';

  @override
  String get holidayImport => 'JSON 가져오기';

  @override
  String get holidayUpdated => '공휴일 데이터가 업데이트되었습니다.';

  @override
  String get holidayLatest => '공휴일 데이터가 최신입니다.';

  @override
  String get holidayRejected => '파일 검증에 실패했습니다. 버전, 지역, 연도, 체크섬을 확인하세요.';

  @override
  String get holidayFailed => '업데이트를 확인할 수 없습니다. 유효한 로컬 데이터를 사용합니다.';

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
  String get durationDays => '일';

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
  String get timeZoneSearch => '시간대 검색';

  @override
  String get timeZoneNoMatches => '일치하는 시간대가 없습니다';

  @override
  String get showTodayEarnings => '오늘 번 금액 표시';

  @override
  String get hideEarningsDetail => '오늘과 이번 달 금액을 ****로 가립니다.';

  @override
  String get saveSettings => '시간대 저장';

  @override
  String get clearTarget => '날짜 지우기';

  @override
  String get addWidget => '카운트다운 위젯 추가';

  @override
  String get addSalaryWidget => '급여 위젯 추가';

  @override
  String get widgetInstructions => '홈 화면을 길게 눌러 시유 위젯을 추가하세요. 편집을 지원하는 경우 카운트다운과 급여 지표를 최대 4개까지 선택할 수 있습니다. 따로 표시하려면 지표마다 위젯을 추가하세요.';

  @override
  String get widgetPinRequested => '추가를 요청했습니다. 홈 화면에서 확인하세요. 확인 창이 뜨지 않으면 빈 곳을 길게 눌러 위젯 → 시유(时余)를 선택하세요.';

  @override
  String get widgetPinManual => '홈 화면에서 요청을 받지 못했습니다. 빈 곳을 길게 눌러 위젯 → 시유(时余)를 선택하세요.';

  @override
  String get widgetOpenHome => '홈 화면으로 이동';

  @override
  String get refreshEarnings => '급여 새로고침';

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
