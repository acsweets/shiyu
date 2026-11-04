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

  @override
  String get retirementTitle => 'Countdown bis zur Rente';

  @override
  String get retired => 'Im Ruhestand';

  @override
  String get daysRemaining => 'Tage verbleibend';

  @override
  String get chooseRetirement => 'Rentendatum wählen';

  @override
  String get configure => 'Einstellungen';

  @override
  String get hideWindow => 'Fenster ausblenden';

  @override
  String get timeZoneLabel => 'IANA-Zeitzone';

  @override
  String get saveSettings => 'Zeitzone speichern';

  @override
  String get clearTarget => 'Datum löschen';

  @override
  String get addWidget => 'Startbildschirm-Widget hinzufügen';

  @override
  String get widgetInstructions =>
      'Halte den Startbildschirm gedrückt und füge das Shiyu-Renten-Widget hinzu.';

  @override
  String get settingsError =>
      'Prüfe Datum, Zeitzone und gemeinsamen Speicher und versuche es erneut.';

  @override
  String get calendarFallback =>
      'Feiertagsdaten sind noch nicht verbunden; die eingestellten wöchentlichen Arbeitstage werden verwendet.';

  @override
  String get currentSlice =>
      'Der Renten-Countdown ist verfügbar. Weitere Kennzahlen folgen in späteren Schritten.';
}
