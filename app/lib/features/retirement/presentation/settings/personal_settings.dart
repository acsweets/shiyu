import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_editor.dart';
import '../../data/settings_repository.dart';
import 'settings_fields.dart';
import 'settings_time_zone.dart';

class PersonalSettings extends StatelessWidget {
  const PersonalSettings({
    required this.editor,
    this.showTimeZone = true,
    super.key,
  });

  final SettingsEditor editor;

  /// 手机分类页将时区放在通用设置。
  final bool showTimeZone;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final SettingsValues birth = editor.group('birth');
    final bool birthSet = birth['date'] != null && !editor.blocked;
    final String mode =
        editor.group('display')['life_mode'] as String? ?? 'countdown';
    return Column(
      children: <Widget>[
        SettingsDate(
          label: strings.birthDate,
          value: birth['date'] as String?,
          changed: editor.blocked ? null : _birthDate,
          error: editor.issue('birth.date') == null
              ? null
              : strings.invalidValue,
        ),
        SettingsChoice(
          label: strings.lifeDisplayMode,
          selected: mode,
          options: <String, String>{
            'countdown': strings.metricLife,
            'elapsed_days': strings.lifeElapsedTitle,
          },
          changed: editor.blocked ? null : _lifeMode,
        ),
        if (showTimeZone || (birthSet && mode == 'countdown')) ...<Widget>[
          SettingsInput(
            label: strings.birthTime,
            value: birth['time'] as String? ?? '',
            hint: 'HH:mm',
            changed: birthSet ? _birthTime : null,
            error: editor.issue('birth.time') == null
                ? null
                : strings.invalidValue,
          ),
          SettingsInput(
            label: strings.lifeExpectancy,
            value: birth['life_expectancy_years'] as String? ?? '100',
            hint: '1–150',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            changed: birthSet ? _lifespan : null,
            error: editor.issue('birth.life_expectancy_years') == null
                ? null
                : strings.invalidLifespan,
          ),
        ],
        SettingsDate(
          label: strings.chooseRetirement,
          value: editor.draft['retirement_date'] as String?,
          changed: editor.blocked ? null : _retirement,
          error: editor.issue('retirement_date') == null
              ? null
              : strings.invalidValue,
        ),
        if (showTimeZone)
          SettingsTimeZone(
            value: editor.draft['time_zone'] as String? ?? 'Asia/Shanghai',
            changed: editor.blocked ? null : _zone,
            error: editor.issue('time_zone') == null
                ? null
                : strings.invalidValue,
          ),
      ],
    );
  }

  void _birthDate(String? value) {
    if (value == null) {
      editor.change('birth', null);
    } else {
      editor.changeGroup('birth', 'date', value);
    }
  }

  void _birthTime(String value) => editor.changeGroup(
    'birth',
    'time',
    value.trim().isEmpty ? null : value.trim(),
  );

  /// 切换生命指标的显示方式，保留出生时间和预期寿命。
  void _lifeMode(String value) =>
      editor.changeGroup('display', 'life_mode', value);

  void _lifespan(String value) => editor.changeGroup(
    'birth',
    'life_expectancy_years',
    value.trim().replaceAll(',', '.'),
  );

  void _retirement(String? value) => editor.change('retirement_date', value);
  void _zone(String value) => editor.change('time_zone', value);
}
