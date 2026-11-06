import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/holiday_status.dart';
import '../../application/settings_editor.dart';
import '../../data/holiday_repository.dart';
import '../../data/settings_repository.dart';
import 'calendar_overrides.dart';
import '../holiday_panel.dart';
import 'settings_fields.dart';

class CalendarSettings extends StatelessWidget {
  const CalendarSettings({required this.editor, super.key});

  final SettingsEditor editor;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final SettingsValues payday = editor.group('payday');
    final String rule = payday['rule'] as String? ?? 'none';
    final List<Object?> days =
        payday['days'] as List<Object?>? ?? const <int>[];
    final HolidayStatus? holiday = editor.view.holiday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsChoice(
          label: strings.regionLabel,
          selected: editor.draft['region'] as String? ?? 'CN',
          options: <String, String>{
            'CN': strings.regionCN,
            'US': strings.regionUS,
            'JP': strings.regionJP,
            'KR': strings.regionKR,
            'HK': strings.regionHK,
            'TW': strings.regionTW,
          },
          changed: editor.blocked ? null : _region,
        ),
        SettingsChoice(
          label: strings.paydayRule,
          selected: rule,
          options: <String, String>{
            'none': strings.mobileNotSet,
            'fixed_day': strings.fixedPayday,
            'last_workday': strings.lastWorkday,
            'twice_monthly': strings.twiceMonthly,
          },
          changed: editor.blocked ? null : _rule,
        ),
        if (days.isNotEmpty)
          for (int index = 0; index < days.length; index++)
            SettingsInput(
              key: ValueKey<String>('$rule-$index'),
              label: '${strings.paydayDate} ${index + 1}',
              value: '${days[index]}',
              hint: '1–31',
              changed: editor.blocked
                  ? null
                  : (String value) => _day(index, value),
              keyboard: TextInputType.number,
              error: editor.issue('payday.days') == null
                  ? null
                  : strings.invalidPaydays,
            ),
        if (rule != 'none' && rule != 'last_workday')
          SettingsChoice(
            label: strings.paydayAdjustment,
            selected: payday['adjustment'] as String? ?? 'next_workday',
            options: <String, String>{
              'next_workday': strings.nextWorkday,
              'previous_workday': strings.previousWorkday,
              'none': strings.noAdjustment,
            },
            changed: editor.blocked ? null : _adjustment,
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.weeklyRestHoliday),
          value: editor.draft['weekly_rest_as_holiday'] != false,
          onChanged: editor.blocked ? null : _weekly,
        ),
        const Divider(height: 24),
        if (holiday != null) ...<Widget>[
          Text(
            strings.holidayData,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          HolidayPanel(
            status: holiday,
            check: _check,
            importPack: _import,
            enabled: editor.autosave || !editor.dirty,
          ),
          const Divider(height: 24),
        ],
        CalendarOverrides(editor: editor),
      ],
    );
  }

  Future<HolidayUpdate> _check() =>
      editor.updateCalendar(editor.access.checkHolidays);

  Future<HolidayUpdate> _import(String raw) =>
      editor.updateCalendar(() => editor.access.importHoliday!(raw));

  void _region(String value) => editor.change('region', value);
  void _weekly(bool value) => editor.change('weekly_rest_as_holiday', value);
  void _adjustment(String value) =>
      editor.changeGroup('payday', 'adjustment', value);

  void _rule(String value) {
    final List<int> days = switch (value) {
      'fixed_day' => <int>[15],
      'twice_monthly' => <int>[15, 30],
      _ => <int>[],
    };
    editor.change(
      'payday',
      value == 'none'
          ? null
          : <String, dynamic>{
              ...editor.group('payday'),
              'rule': value,
              'days': days,
            },
    );
  }

  void _day(int index, String value) {
    final List<int> days = (editor.group('payday')['days'] as List<Object?>)
        .cast<int>()
        .toList();
    days[index] = int.tryParse(value.trim()) ?? 0;
    editor.changeGroup('payday', 'days', days);
  }
}
