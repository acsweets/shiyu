// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addCountdown => 'Add countdown';

  @override
  String get addDateOverride => 'Override a date';

  @override
  String get addHoliday => 'Add holiday';

  @override
  String get appLanguage => 'Language';

  @override
  String get backStep => 'Back';

  @override
  String get birthDate => 'Date of birth (optional)';

  @override
  String get birthTime => 'Time of birth (optional)';

  @override
  String get businessSettings => 'Full settings';

  @override
  String get calendarSection => 'Dates and holidays';

  @override
  String get currencyCode => 'Currency code';

  @override
  String get customCountdown => 'Custom countdowns';

  @override
  String get customHolidays => 'Custom holidays';

  @override
  String get dateLabel => 'Date';

  @override
  String get dateOverrides => 'Date overrides';

  @override
  String get dayType => 'Day type';

  @override
  String get disableAll => 'Hide all';

  @override
  String get displaySection => 'Floating window';

  @override
  String get enableAll => 'Show all';

  @override
  String get exportPrivacy =>
      'Export includes your personal information and salary. Choose a location you trust.';

  @override
  String get finishSetup => 'Finish setup';

  @override
  String get fixedPayday => 'Fixed day each month';

  @override
  String get generalSection => 'General';

  @override
  String get grossMonthly => 'Gross monthly pay';

  @override
  String get hideSalary => 'Hide amounts';

  @override
  String get holidayEnd => 'End date';

  @override
  String get holidayKind => 'Holiday type';

  @override
  String get holidayStart => 'Start date';

  @override
  String get invalidCountdown =>
      'Check the name and time. A new countdown needs a future target.';

  @override
  String get invalidDraft =>
      'Check the fields below. Your previous valid settings are still saved.';

  @override
  String get invalidHoliday => 'Enter a name, type, and an ordered date range.';

  @override
  String get invalidLifespan =>
      'Enter 1–150 years, with at most one decimal place.';

  @override
  String get invalidLunch => 'Break times must fall within working hours.';

  @override
  String get invalidPaydays => 'Use distinct days between 1 and 31.';

  @override
  String get invalidSalary => 'Enter a valid nonnegative amount.';

  @override
  String get invalidValue => 'Check this value.';

  @override
  String get invalidWorkHours =>
      'Use HH:mm and an end time after the start time on the same day.';

  @override
  String get itemName => 'Name';

  @override
  String get lastWorkday => 'Last workday of the month';

  @override
  String get lifeExpectancy => 'Life expectancy (years)';

  @override
  String get lunchBreak => 'Lunch break';

  @override
  String get lunchEnd => 'Break ends';

  @override
  String get lunchStart => 'Break starts';

  @override
  String get metricHoliday => 'Time until the next break';

  @override
  String get metricLife => 'Life countdown';

  @override
  String get metricMonthSalary => 'Earned this month';

  @override
  String get metricPayday => 'Time until payday';

  @override
  String get metricTodaySalary => 'Earned today';

  @override
  String get metricWork => 'Work countdown';

  @override
  String get miniMetrics => 'Mini window metrics';

  @override
  String get moveDown => 'Move down';

  @override
  String get moveUp => 'Move up';

  @override
  String get netMonthly => 'Net monthly pay (optional)';

  @override
  String get netRequired => 'Enter net pay before choosing this option.';

  @override
  String get nextStep => 'Continue';

  @override
  String get nextWorkday => 'Next workday';

  @override
  String get noAdjustment => 'Keep the date';

  @override
  String get onboardingTitle => 'Set up Shiyu';

  @override
  String get paydayAdjustment => 'When payday falls on a rest day';

  @override
  String get paydayDate => 'Payday';

  @override
  String get paydayRule => 'Pay schedule';

  @override
  String get peekSalary => 'View amounts temporarily';

  @override
  String get personalSection => 'Personal information';

  @override
  String get previewLive => 'Live preview';

  @override
  String get previousWorkday => 'Previous workday';

  @override
  String get regionCN => 'Mainland China';

  @override
  String get regionHK => 'Hong Kong';

  @override
  String get regionJP => 'Japan';

  @override
  String get regionKR => 'South Korea';

  @override
  String get regionLabel => 'Holiday region';

  @override
  String get regionTW => 'Taiwan';

  @override
  String get regionUS => 'United States';

  @override
  String get removeItem => 'Remove';

  @override
  String get restDayLabel => 'Rest day';

  @override
  String get salaryBasis => 'Amount basis';

  @override
  String get salaryPrecision => 'Decimal places';

  @override
  String get settingsExport => 'Export settings';

  @override
  String get settingsExported => 'Settings exported.';

  @override
  String get settingsFileInvalid =>
      'Could not use this file. Check its size, JSON format, and version.';

  @override
  String get settingsImport => 'Import settings';

  @override
  String get systemLanguage => 'System language';

  @override
  String get targetTime => 'Target time';

  @override
  String get twiceMonthly => 'Twice a month';

  @override
  String get weeklyRestHoliday => 'Count weekly rest days as breaks';

  @override
  String get workdayLabel => 'Workday';

  @override
  String get workEnd => 'Work ends';

  @override
  String get workSection => 'Schedule and pay';

  @override
  String get workStart => 'Work starts';

  @override
  String get workWeek => 'Working days';

  @override
  String get holidayData => 'Holiday data';

  @override
  String get holidayFallback =>
      'Data for the current year is missing. Your weekly schedule is used.';

  @override
  String get holidayChecking => 'Checking holiday data…';

  @override
  String get holidayCheck => 'Check for updates';

  @override
  String get holidayImport => 'Import JSON';

  @override
  String get holidayUpdated => 'Holiday data updated.';

  @override
  String get holidayLatest => 'Holiday data is up to date.';

  @override
  String get holidayRejected =>
      'The holiday file failed validation. Check its version, region, years, and checksum.';

  @override
  String get holidayFailed =>
      'Could not check holiday updates. Valid local data is still used.';

  @override
  String get restoreSettingsBackup => 'Restore settings backup';

  @override
  String get appName => 'Time Remaining';

  @override
  String get tagline => 'Make time for life.';

  @override
  String get initializationNotice =>
      'The app foundation is ready. Time and salary features are under development.';

  @override
  String get retirementTitle => 'Retirement countdown';

  @override
  String get retired => 'Retired';

  @override
  String get daysRemaining => 'days remaining';

  @override
  String get chooseRetirement => 'Choose retirement date';

  @override
  String get configure => 'Configure';

  @override
  String get hideWindow => 'Hide window';

  @override
  String get timeZoneLabel => 'IANA time zone';

  @override
  String get saveSettings => 'Save time zone';

  @override
  String get clearTarget => 'Clear date';

  @override
  String get addWidget => 'Add home screen widget';

  @override
  String get widgetInstructions =>
      'Long-press your home screen and add the Shiyu retirement widget.';

  @override
  String get settingsError =>
      'Check the date, time zone, and shared storage permissions, then try again.';

  @override
  String get calendarFallback =>
      'Holiday data is not connected yet; the configured weekly workdays are used.';

  @override
  String get currentSlice =>
      'Retirement countdown is available. Other built-in metrics are planned for later nodes.';

  @override
  String get mobileSettings => 'Settings';

  @override
  String get mobileAppearance => 'Widget appearance';

  @override
  String get mobileWidget => 'Home screen widget';

  @override
  String get mobileShowTitle => 'Show title';

  @override
  String get mobileTitleSize => 'Title text size';

  @override
  String get mobileMacaron => 'Macaron';

  @override
  String get mobileCool => 'Cool';

  @override
  String get mobileSunset => 'Sunset';

  @override
  String get mobileSave => 'Save settings';

  @override
  String get mobileSaved => 'Settings saved';

  @override
  String get mobileAppearanceError => 'Couldn’t save appearance. Try again.';

  @override
  String get mobileNotSet => 'Not set';
}
