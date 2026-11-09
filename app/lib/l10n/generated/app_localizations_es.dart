// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get mobileMacaronGlass => 'Cristal macaron';

  @override
  String get mobileCountdownSummary => 'Jubilación, nacimiento y modo de vida';

  @override
  String get mobileWorkSummary => 'Días laborables, horarios, descanso y sueldo';

  @override
  String get mobileCalendarSummary => 'Días de pago, festivos y excepciones';

  @override
  String get mobileTitlesSummary => 'Muestra u oculta el título de cada cuenta atrás';

  @override
  String get mobileWidgetSummary => 'Añade widgets y cambia los colores o el texto';

  @override
  String get mobileGeneralSummary => 'Zona horaria, visibilidad de importes y copias';

  @override
  String get mobileSaving => 'Guardando…';

  @override
  String get mobileDiscardChanges => '¿Descartar los cambios sin guardar?';

  @override
  String get mobileDiscard => 'Descartar cambios';

  @override
  String get metricTitleVisibility => 'Títulos por indicador';

  @override
  String get metricTitleVisibilityDetail => 'Si ocultas un título, el valor sigue visible. Las ventanas flotantes y los widgets también tienen un interruptor general de títulos.';

  @override
  String get lifeDisplayMode => 'Modo de visualización de vida';

  @override
  String get lifeElapsedTitle => 'Días vividos';

  @override
  String lifeElapsedValue(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString días',
      one: '$daysString día',
    );
    return '$_temp0';
  }

  @override
  String get desktopAppearance => 'Apariencia';

  @override
  String get desktopWindows => 'Ventanas';

  @override
  String get desktopCountdowns => 'Cuentas regresivas';

  @override
  String get desktopCatAssets => 'Pegatinas de gato';

  @override
  String get desktopAppearanceDescription => 'Cambia el idioma, los colores o el tamaño del texto y previsualiza la ventana flotante.';

  @override
  String get desktopWindowsDescription => 'Revisa el contenido de cada ventana y agrúpalo, sepáralo o ajusta su vista.';

  @override
  String get desktopCountdownsDescription => 'Elige las cuentas regresivas del escritorio y fija la fecha de jubilación.';

  @override
  String get desktopCatAssetsDescription => 'Cambia la pegatina de gato de cada ventana.';

  @override
  String get floatingMode => 'Modo de ventana';

  @override
  String get modeMini => 'Mini';

  @override
  String get modeStandard => 'Estándar';

  @override
  String get modeExpanded => 'Ampliado';

  @override
  String get countdownExpired => 'Finalizado';

  @override
  String get holidayOngoing => 'En descanso';

  @override
  String get paydayToday => 'Hoy es día de cobro';

  @override
  String get metricUnavailable => 'No disponible';

  @override
  String get noVisibleMetrics => 'Todos los indicadores están ocultos';

  @override
  String get untilWorkStart => 'Hasta el inicio de la jornada';

  @override
  String get untilWorkEnd => 'Hasta el fin de la jornada';

  @override
  String get untilLunchEnd => 'Hasta el fin de la pausa';

  @override
  String get addCountdown => 'Añadir cuenta atrás';

  @override
  String get addDateOverride => 'Cambiar un día';

  @override
  String get addHoliday => 'Añadir festivo';

  @override
  String get appLanguage => 'Idioma';

  @override
  String get backStep => 'Atrás';

  @override
  String get birthDate => 'Fecha de nacimiento (opcional)';

  @override
  String get birthTime => 'Hora de nacimiento (opcional)';

  @override
  String get businessSettings => 'Ajustes completos';

  @override
  String get calendarSection => 'Fechas y festivos';

  @override
  String get currencyCode => 'Código de moneda';

  @override
  String get customCountdown => 'Cuentas atrás personalizadas';

  @override
  String get customHolidays => 'Festivos personalizados';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get dateOverrides => 'Excepciones por fecha';

  @override
  String get dayType => 'Tipo de día';

  @override
  String get disableAll => 'Ocultar todo';

  @override
  String get displaySection => 'Ventana flotante';

  @override
  String get enableAll => 'Mostrar todo';

  @override
  String get exportPrivacy => 'La exportación incluye datos personales y el sueldo. Elige una ubicación segura.';

  @override
  String get finishSetup => 'Finalizar configuración';

  @override
  String get fixedPayday => 'Día fijo del mes';

  @override
  String get generalSection => 'General';

  @override
  String get grossMonthly => 'Sueldo bruto mensual';

  @override
  String get hideSalary => 'Ocultar importes';

  @override
  String get holidayEnd => 'Fecha de fin';

  @override
  String get holidayKind => 'Tipo de festivo';

  @override
  String get holidayStart => 'Fecha de inicio';

  @override
  String get invalidCountdown => 'Comprueba el nombre y la hora. El nuevo objetivo debe ser futuro.';

  @override
  String get invalidDraft => 'Revisa los campos. Tus últimos ajustes válidos se conservan.';

  @override
  String get invalidHoliday => 'Indica un nombre, un tipo y un intervalo válido.';

  @override
  String get invalidLifespan => 'Introduce 1–150 años con un decimal como máximo.';

  @override
  String get invalidLunch => 'La pausa debe estar dentro del horario laboral.';

  @override
  String get invalidPaydays => 'Usa días distintos entre 1 y 31.';

  @override
  String get invalidSalary => 'Introduce un importe válido no negativo.';

  @override
  String get invalidValue => 'Revisa el valor.';

  @override
  String get invalidWorkHours => 'Usa HH:mm y una hora de fin posterior al inicio el mismo día.';

  @override
  String get itemName => 'Nombre';

  @override
  String get lastWorkday => 'Último día laborable del mes';

  @override
  String get lifeExpectancy => 'Esperanza de vida (años)';

  @override
  String get lunchBreak => 'Pausa para comer';

  @override
  String get lunchEnd => 'Fin de la pausa';

  @override
  String get lunchStart => 'Inicio de la pausa';

  @override
  String get metricHoliday => 'Hasta el próximo descanso';

  @override
  String get metricLife => 'Cuenta atrás vital';

  @override
  String get metricMonthSalary => 'Ganado este mes';

  @override
  String get metricPayday => 'Hasta el día de cobro';

  @override
  String get metricTodaySalary => 'Ganado hoy';

  @override
  String get metricWork => 'Cuenta atrás laboral';

  @override
  String get miniMetrics => 'Indicadores de la ventana mini';

  @override
  String get moveDown => 'Bajar';

  @override
  String get moveUp => 'Subir';

  @override
  String get netMonthly => 'Sueldo neto mensual (opcional)';

  @override
  String get netRequired => 'Introduce el sueldo neto antes de elegir esta opción.';

  @override
  String get nextStep => 'Continuar';

  @override
  String get nextWorkday => 'Siguiente día laborable';

  @override
  String get noAdjustment => 'Mantener la fecha';

  @override
  String get onboardingTitle => 'Configurar Shiyu';

  @override
  String get paydayAdjustment => 'Si el día de cobro no es laborable';

  @override
  String get paydayDate => 'Día de cobro';

  @override
  String get paydayRule => 'Calendario de pagos';

  @override
  String get peekSalary => 'Ver importes temporalmente';

  @override
  String get personalSection => 'Datos personales';

  @override
  String get previewLive => 'Vista previa con datos reales';

  @override
  String get previousWorkday => 'Día laborable anterior';

  @override
  String get regionCN => 'China continental';

  @override
  String get regionHK => 'Hong Kong';

  @override
  String get regionJP => 'Japón';

  @override
  String get regionKR => 'Corea del Sur';

  @override
  String get regionLabel => 'Región de festivos';

  @override
  String get regionTW => 'Taiwán';

  @override
  String get regionUS => 'Estados Unidos';

  @override
  String get removeItem => 'Eliminar';

  @override
  String get restDayLabel => 'Día de descanso';

  @override
  String get salaryBasis => 'Base del importe';

  @override
  String get salaryPrecision => 'Decimales';

  @override
  String get settingsExport => 'Exportar ajustes';

  @override
  String get settingsExported => 'Ajustes exportados.';

  @override
  String get settingsFileInvalid => 'No se pudo usar el archivo. Revisa el tamaño, formato JSON y versión.';

  @override
  String get settingsImport => 'Importar ajustes';

  @override
  String get systemLanguage => 'Idioma del sistema';

  @override
  String get targetTime => 'Hora objetivo';

  @override
  String get twiceMonthly => 'Dos veces al mes';

  @override
  String get weeklyRestHoliday => 'Incluir descansos semanales';

  @override
  String get workdayLabel => 'Día laborable';

  @override
  String get workEnd => 'Fin de la jornada';

  @override
  String get workSection => 'Horario y sueldo';

  @override
  String get workStart => 'Inicio de la jornada';

  @override
  String get workWeek => 'Días laborables';

  @override
  String get holidayData => 'Datos festivos';

  @override
  String get holidayFallback => 'Faltan los datos de este año. Se usará tu horario semanal.';

  @override
  String get holidayChecking => 'Comprobando los festivos…';

  @override
  String get holidayCheck => 'Buscar actualizaciones';

  @override
  String get holidayImport => 'Importar JSON';

  @override
  String get holidayUpdated => 'Datos festivos actualizados.';

  @override
  String get holidayLatest => 'Los datos festivos están al día.';

  @override
  String get holidayRejected => 'El archivo no es válido. Comprueba la versión, región, años y suma de verificación.';

  @override
  String get holidayFailed => 'No se pudo comprobar la actualización. Se mantienen los datos locales válidos.';

  @override
  String get restoreSettingsBackup => 'Restaurar copia de seguridad';

  @override
  String get appName => 'Time Remaining';

  @override
  String get tagline => 'Haz tiempo para la vida.';

  @override
  String get initializationNotice => 'La base de la aplicación está lista. Las funciones de tiempo y salario están en desarrollo.';

  @override
  String get retirementTitle => 'Cuenta atrás para la jubilación';

  @override
  String get retired => 'Jubilado/a';

  @override
  String get durationDays => 'd';

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
  String get timeZoneSearch => 'Buscar zonas horarias';

  @override
  String get timeZoneNoMatches => 'No hay zonas horarias que coincidan';

  @override
  String get showTodayEarnings => 'Mostrar lo ganado hoy';

  @override
  String get hideEarningsDetail => 'Oculta los importes de hoy y de este mes con ****.';

  @override
  String get saveSettings => 'Guardar zona horaria';

  @override
  String get clearTarget => 'Borrar fecha';

  @override
  String get addWidget => 'Añadir cuenta regresiva';

  @override
  String get addSalaryWidget => 'Añadir widget de ingresos';

  @override
  String get widgetInstructions => 'Mantén pulsada la pantalla de inicio para añadir un widget de Shiyu. Si se puede editar, elige de uno a cuatro indicadores de cuenta regresiva o ingresos. Añade un widget por indicador para verlos por separado.';

  @override
  String get widgetPinRequested => 'Solicitud enviada. Confírmala en la pantalla de inicio. Si no aparece el aviso, mantén pulsado un espacio vacío y elige Widgets → Shiyu (时余).';

  @override
  String get widgetPinManual => 'La pantalla de inicio no aceptó la solicitud. Mantén pulsado un espacio vacío y elige Widgets → Shiyu (时余).';

  @override
  String get widgetOpenHome => 'Ir a la pantalla de inicio';

  @override
  String get refreshEarnings => 'Actualizar ingresos';

  @override
  String get settingsError => 'Comprueba la fecha, la zona horaria y el almacenamiento compartido e inténtalo de nuevo.';

  @override
  String get calendarFallback => 'Los datos de festivos aún no están conectados; se usan los días laborables semanales configurados.';

  @override
  String get currentSlice => 'La cuenta atrás para la jubilación está disponible. Los demás indicadores llegarán en etapas posteriores.';

  @override
  String get mobileSettings => 'Ajustes';

  @override
  String get mobileAppearance => 'Apariencia del widget';

  @override
  String get mobileWidget => 'Widget de pantalla de inicio';

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
  String get mobileAppearanceError => 'No se pudo guardar la apariencia. Inténtalo de nuevo.';

  @override
  String get mobileNotSet => 'Sin configurar';
}
