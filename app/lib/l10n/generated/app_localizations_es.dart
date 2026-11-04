// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Time Remaining';

  @override
  String get tagline => 'Haz tiempo para la vida.';

  @override
  String get initializationNotice =>
      'La base de la aplicación está lista. Las funciones de tiempo y salario están en desarrollo.';
}
