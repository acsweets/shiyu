// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Time Remaining';

  @override
  String get tagline => 'Make time for life.';

  @override
  String get initializationNotice =>
      'The app foundation is ready. Time and salary features are under development.';
}
