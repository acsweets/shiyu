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

  @override
  String get retirementTitle => 'Compte à rebours avant la retraite';

  @override
  String get retired => 'À la retraite';

  @override
  String get daysRemaining => 'jours restants';

  @override
  String get chooseRetirement => 'Choisir la date de retraite';

  @override
  String get configure => 'Configurer';

  @override
  String get hideWindow => 'Masquer la fenêtre';

  @override
  String get timeZoneLabel => 'Fuseau horaire IANA';

  @override
  String get saveSettings => 'Enregistrer le fuseau';

  @override
  String get clearTarget => 'Effacer la date';

  @override
  String get addWidget => 'Ajouter un widget d’accueil';

  @override
  String get widgetInstructions =>
      'Appuyez longuement sur l’écran d’accueil et ajoutez le widget de retraite Shiyu.';

  @override
  String get settingsError =>
      'Vérifiez la date, le fuseau horaire et le stockage partagé, puis réessayez.';

  @override
  String get calendarFallback =>
      'Les jours fériés ne sont pas encore connectés ; les jours travaillés hebdomadaires configurés sont utilisés.';

  @override
  String get currentSlice =>
      'Le compte à rebours avant la retraite est disponible. Les autres indicateurs seront ajoutés ultérieurement.';
}
