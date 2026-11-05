import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_editor.dart';
import '../../data/settings_repository.dart';
import 'salary_settings.dart';
import 'settings_fields.dart';

class WorkSettings extends StatelessWidget {
  const WorkSettings({required this.editor, super.key});

  final SettingsEditor editor;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final SettingsValues schedule = editor.group('schedule');
    final List<Object?> workdays =
        schedule['workdays'] as List<Object?>? ?? <int>[1, 2, 3, 4, 5];
    final List<Object?>? lunch = schedule['lunch'] as List<Object?>?;
    final String? timeError = editor.issue('schedule') == null
        ? null
        : strings.invalidWorkHours;
    final String? lunchError = editor.issue('schedule.lunch') == null
        ? null
        : strings.invalidLunch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.workWeek, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 6,
          children: <Widget>[
            for (int day = 1; day <= 7; day++)
              FilterChip(
                label: Text(
                  DateFormat.E(strings.localeName)
                      .format(DateTime.utc(2026, 11, day + 1)),
                ),
                selected: workdays.contains(day),
                onSelected: editor.blocked
                    ? null
                    : (bool enabled) => _workday(day, enabled, workdays),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsInput(
          label: strings.workStart,
          value: schedule['start'] as String? ?? '09:00',
          changed: editor.blocked ? null : _start,
          hint: 'HH:mm',
          error: timeError,
        ),
        SettingsInput(
          label: strings.workEnd,
          value: schedule['end'] as String? ?? '18:00',
          changed: editor.blocked ? null : _end,
          hint: 'HH:mm',
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.lunchBreak),
          value: lunch != null,
          onChanged: editor.blocked ? null : _lunch,
        ),
        if (lunch != null) ...<Widget>[
          SettingsInput(
            label: strings.lunchStart,
            value: lunch[0] as String,
            changed: editor.blocked
                ? null
                : (String value) => _lunchTime(0, value),
            hint: 'HH:mm',
            error: lunchError,
          ),
          SettingsInput(
            label: strings.lunchEnd,
            value: lunch[1] as String,
            changed: editor.blocked
                ? null
                : (String value) => _lunchTime(1, value),
            hint: 'HH:mm',
          ),
        ],
        const Divider(height: 30),
        SalarySettings(editor: editor),
      ],
    );
  }

  void _workday(int day, bool enabled, List<Object?> current) {
    final Set<int> days = current.cast<int>().toSet();
    if (enabled) {
      days.add(day);
    } else {
      days.remove(day);
    }
    editor.changeGroup('schedule', 'workdays', days.toList()..sort());
  }

  void _start(String value) =>
      editor.changeGroup('schedule', 'start', value.trim());
  void _end(String value) =>
      editor.changeGroup('schedule', 'end', value.trim());
  void _lunch(bool value) => editor.changeGroup(
    'schedule',
    'lunch',
    value ? <String>['12:00', '13:00'] : null,
  );

  void _lunchTime(int index, String value) {
    final List<String> times =
        (editor.group('schedule')['lunch'] as List<Object?>)
            .cast<String>()
            .toList();
    times[index] = value.trim();
    editor.changeGroup('schedule', 'lunch', times);
  }
}
