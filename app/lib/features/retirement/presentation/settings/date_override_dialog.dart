import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import 'settings_fields.dart';

typedef DateOverrideValue = ({String date, bool working});

class DateOverrideDialog extends StatefulWidget {
  const DateOverrideDialog({this.date, this.working = false, super.key});

  final String? date;
  final bool working;

  @override
  State<DateOverrideDialog> createState() => _DateOverrideDialogState();
}

class _DateOverrideDialogState extends State<DateOverrideDialog> {
  late String? _date = widget.date;
  late bool _working = widget.working;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.dateOverrides),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SettingsDate(
            label: strings.dateLabel,
            value: _date,
            changed: _changeDate,
            clearable: false,
          ),
          SettingsChoice(
            label: strings.dayType,
            selected: _working ? 'work' : 'rest',
            options: <String, String>{
              'work': strings.workdayLabel,
              'rest': strings.restDayLabel,
            },
            changed: _changeType,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _date == null ? null : _confirm,
          child: Text(strings.mobileSave),
        ),
      ],
    );
  }

  void _changeDate(String? value) => setState(() => _date = value);
  void _changeType(String value) => setState(() => _working = value == 'work');
  void _confirm() =>
      Navigator.of(context).pop((date: _date!, working: _working));
}
