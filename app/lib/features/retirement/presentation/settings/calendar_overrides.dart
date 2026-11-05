import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_editor.dart';
import '../../data/settings_repository.dart';
import 'date_override_dialog.dart';
import 'dated_item_dialog.dart';

class CalendarOverrides extends StatelessWidget {
  const CalendarOverrides({required this.editor, super.key});

  final SettingsEditor editor;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final SettingsValues dates = editor.group('date_overrides');
    final List<String> sortedDates = dates.keys.toList()..sort();
    final List<SettingsValues> holidays = _holidays();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          strings.dateOverrides,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final String date in sortedDates)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(date),
            subtitle: Text(
              dates[date] == true ? strings.workdayLabel : strings.restDayLabel,
            ),
            onTap: editor.blocked ? null : () => _editDate(context, date),
            trailing: IconButton(
              tooltip: strings.removeItem,
              onPressed: editor.blocked ? null : () => _removeDate(date),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          onPressed: editor.blocked ? null : () => _editDate(context, null),
          label: Text(strings.addDateOverride),
        ),
        const SizedBox(height: 20),
        Text(
          strings.customHolidays,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (int index = 0; index < holidays.length; index++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(holidays[index]['name'] as String),
            subtitle: Text(
              '${holidays[index]['start']} – ${holidays[index]['end']}',
            ),
            onTap: editor.blocked ? null : () => _editHoliday(context, index),
            trailing: IconButton(
              tooltip: strings.removeItem,
              onPressed: editor.blocked ? null : () => _removeHoliday(index),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          onPressed: editor.blocked ? null : () => _editHoliday(context, null),
          label: Text(strings.addHoliday),
        ),
      ],
    );
  }

  Future<void> _editDate(BuildContext context, String? date) async {
    final DateOverrideValue? result = await showDialog<DateOverrideValue>(
      context: context,
      builder: (BuildContext context) => DateOverrideDialog(
        date: date,
        working: editor.group('date_overrides')[date] == true,
      ),
    );
    if (!context.mounted || result == null) return;
    final SettingsValues dates = <String, dynamic>{
      ...editor.group('date_overrides'),
    };
    dates.remove(date);
    dates[result.date] = result.working;
    editor.change('date_overrides', dates);
  }

  void _removeDate(String date) => editor.change(
    'date_overrides',
    <String, dynamic>{...editor.group('date_overrides')}..remove(date),
  );

  List<SettingsValues> _holidays() =>
      ((editor.draft['holidays'] as List<Object?>?) ?? const <Object?>[])
          .map(SettingsEditor.object)
          .toList();

  Future<void> _editHoliday(BuildContext context, int? index) async {
    if (!await editor.flush() || !context.mounted) return;
    final List<SettingsValues> items = _holidays();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DatedItemDialog(
        value: index == null ? <String, dynamic>{} : items[index],
        submit: (SettingsValues value) async {
          final List<SettingsValues> candidate = <SettingsValues>[...items];
          if (index == null) {
            candidate.add(value);
          } else {
            candidate[index] = value;
          }
          editor.change('holidays', candidate);
          return editor.flush();
        },
      ),
    );
  }

  void _removeHoliday(int index) =>
      editor.change('holidays', _holidays()..removeAt(index));
}
