// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Time Remaining';

  @override
  String get tagline => 'Mehr Zeit fürs Leben.';

  @override
  String get initializationNotice =>
      'Die App-Grundlage ist bereit. Zeit- und Gehaltsfunktionen sind in Entwicklung.';
}
