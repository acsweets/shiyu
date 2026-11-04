// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Time Remaining';

  @override
  String get tagline => 'Prenez le temps de vivre.';

  @override
  String get initializationNotice =>
      'La base de l’application est prête. Les fonctions de temps et de salaire sont en cours de développement.';
}
