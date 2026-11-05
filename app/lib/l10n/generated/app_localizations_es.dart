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

  @override
  String get retirementTitle => 'Cuenta atrás para la jubilación';

  @override
  String get retired => 'Jubilado/a';

  @override
  String get daysRemaining => 'días restantes';

  @override
  String get chooseRetirement => 'Elegir fecha de jubilación';

  @override
  String get configure => 'Configurar';

  @override
  String get hideWindow => 'Ocultar ventana';

  @override
  String get timeZoneLabel => 'Zona horaria IANA';

  @override
  String get saveSettings => 'Guardar zona horaria';

  @override
  String get clearTarget => 'Borrar fecha';

  @override
  String get addWidget => 'Añadir widget de inicio';

  @override
  String get widgetInstructions =>
      'Mantén pulsada la pantalla de inicio y añade el widget de jubilación de Shiyu.';

  @override
  String get settingsError =>
      'Comprueba la fecha, la zona horaria y el almacenamiento compartido e inténtalo de nuevo.';

  @override
  String get calendarFallback =>
      'Los datos de festivos aún no están conectados; se usan los días laborables semanales configurados.';

  @override
  String get currentSlice =>
      'La cuenta atrás para la jubilación está disponible. Los demás indicadores llegarán en etapas posteriores.';

  @override
  String get mobileSettings => 'Ajustes';

  @override
  String get mobileAppearance => 'Apariencia';

  @override
  String get mobileWidget => 'Widget de pantalla de inicio';

  @override
  String get mobileShowCard => 'Mostrar tarjeta flotante';

  @override
  String get mobileShowTitle => 'Mostrar título';

  @override
  String get mobileTitleSize => 'Tamaño del título';

  @override
  String get mobileMacaron => 'Macaron';

  @override
  String get mobileCool => 'Frío';

  @override
  String get mobileSunset => 'Atardecer';

  @override
  String get mobileSave => 'Guardar ajustes';

  @override
  String get mobileSaved => 'Ajustes guardados';

  @override
  String get mobileAppearanceError =>
      'No se pudo guardar la apariencia. Inténtalo de nuevo.';

  @override
  String mobileCountdown(String days, String clock) {
    return '$days d $clock';
  }

  @override
  String get mobileCardHidden => 'Tarjeta flotante oculta';

  @override
  String get mobileResetPosition => 'Restablecer posición de la tarjeta';

  @override
  String get mobileNotSet => 'Sin configurar';
}
