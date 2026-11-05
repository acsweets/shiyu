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

  @override
  String get mobileSettings => 'Réglages';

  @override
  String get mobileAppearance => 'Apparence';

  @override
  String get mobileWidget => 'Widget d’écran d’accueil';

  @override
  String get mobileShowCard => 'Afficher la carte flottante';

  @override
  String get mobileShowTitle => 'Afficher le titre';

  @override
  String get mobileTitleSize => 'Taille du titre';

  @override
  String get mobileMacaron => 'Macaron';

  @override
  String get mobileCool => 'Froid';

  @override
  String get mobileSunset => 'Coucher de soleil';

  @override
  String get mobileSave => 'Enregistrer les réglages';

  @override
  String get mobileSaved => 'Réglages enregistrés';

  @override
  String get mobileAppearanceError =>
      'Impossible d’enregistrer l’apparence. Réessayez.';

  @override
  String mobileCountdown(String days, String clock) {
    return '$days j $clock';
  }

  @override
  String get mobileCardHidden => 'Carte flottante masquée';

  @override
  String get mobileResetPosition => 'Réinitialiser la position de la carte';

  @override
  String get mobileNotSet => 'Non défini';
}
