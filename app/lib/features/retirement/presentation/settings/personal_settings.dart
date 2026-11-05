import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_editor.dart';
import '../../data/settings_repository.dart';
import 'settings_fields.dart';

class PersonalSettings extends StatelessWidget {
  const PersonalSettings({required this.editor, super.key});

  final SettingsEditor editor;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final SettingsValues birth = editor.group('birth');
    final bool birthSet = birth['date'] != null && !editor.blocked;
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
        SettingsDate(
          label: strings.chooseRetirement,
          value: editor.draft['retirement_date'] as String?,
          changed: editor.blocked ? null : _retirement,
          error: editor.issue('retirement_date') == null
              ? null
              : strings.invalidValue,
        ),
        SettingsInput(
          label: strings.timeZoneLabel,
          value: editor.draft['time_zone'] as String? ?? 'Asia/Shanghai',
          hint: 'Asia/Shanghai',
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

  void _lifespan(String value) => editor.changeGroup(
    'birth',
    'life_expectancy_years',
    value.trim().replaceAll(',', '.'),
  );

  void _retirement(String? value) => editor.change('retirement_date', value);
  void _zone(String value) => editor.change('time_zone', value.trim());
}
