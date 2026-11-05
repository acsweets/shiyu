// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
