// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get holidayData => 'Feiertagsdaten';

  @override
  String get holidayFallback =>
      'Daten für das aktuelle Jahr fehlen. Dein Wochenplan wird verwendet.';

  @override
  String get holidayChecking => 'Feiertagsdaten werden geprüft…';

  @override
  String get holidayCheck => 'Updates suchen';

  @override
  String get holidayImport => 'JSON importieren';

  @override
  String get holidayUpdated => 'Feiertagsdaten aktualisiert.';

  @override
  String get holidayLatest => 'Feiertagsdaten sind aktuell.';

  @override
  String get holidayRejected =>
      'Die Datei ist ungültig. Prüfe Version, Region, Jahre und Prüfsumme.';

  @override
  String get holidayFailed =>
      'Aktualisierung fehlgeschlagen. Gültige lokale Daten werden weiterverwendet.';

  @override
  String get restoreSettingsBackup => 'Sicherung wiederherstellen';

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

  @override
  String get mobileSettings => 'Einstellungen';

  @override
  String get mobileAppearance => 'Widget-Darstellung';

  @override
  String get mobileWidget => 'Startbildschirm-Widget';

  @override
  String get mobileShowTitle => 'Titel anzeigen';

  @override
  String get mobileTitleSize => 'Titelgröße';

  @override
  String get mobileMacaron => 'Macaron';

  @override
  String get mobileCool => 'Kühl';

  @override
  String get mobileSunset => 'Sonnenuntergang';

  @override
  String get mobileSave => 'Einstellungen speichern';

  @override
  String get mobileSaved => 'Einstellungen gespeichert';

  @override
  String get mobileAppearanceError =>
      'Darstellung konnte nicht gespeichert werden. Erneut versuchen.';

  @override
  String get mobileNotSet => 'Nicht festgelegt';
}
