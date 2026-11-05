import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/settings_repository.dart';
import 'settings_fields.dart';

typedef DatedItemSave = Future<bool> Function(SettingsValues value);

class DatedItemDialog extends StatefulWidget {
  const DatedItemDialog({
    required this.value,
    required this.submit,
    this.countdown = false,
    super.key,
  });

  final SettingsValues value;
  final DatedItemSave submit;
  final bool countdown;

  @override
  State<DatedItemDialog> createState() => _DatedItemDialogState();
}

class _DatedItemDialogState extends State<DatedItemDialog> {
  late String _name = widget.value['name'] as String? ?? '';
  late String? _start = widget.countdown
      ? _part(0)
      : widget.value['start'] as String?;
  late String? _end = widget.value['end'] as String?;
  late String _time = _part(1) ?? '09:00';
  late String _kind = widget.value['kind'] as String? ?? '';
  bool _busy = false;
  bool _invalid = false;

  String? _part(int index) {
    final List<String>? parts = (widget.value['target'] as String?)?.split('T');
    return parts != null && parts.length > index ? parts[index] : null;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.countdown ? strings.customCountdown : strings.customHolidays,
      ),
      scrollable: true,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SettingsInput(
              label: strings.itemName,
              value: _name,
              changed: _changeName,
            ),
            SettingsDate(
              label: widget.countdown
                  ? strings.dateLabel
                  : strings.holidayStart,
              value: _start,
              changed: _changeStart,
              clearable: false,
            ),
            if (widget.countdown)
              SettingsInput(
                label: strings.targetTime,
                value: _time,
                changed: _changeTime,
                hint: 'HH:mm:ss',
              )
            else ...<Widget>[
              SettingsDate(
                label: strings.holidayEnd,
                value: _end,
                changed: _changeEnd,
                clearable: false,
              ),
              SettingsInput(
                label: strings.holidayKind,
                value: _kind,
                changed: _changeKind,
              ),
            ],
            if (_invalid)
              Text(
                widget.countdown
                    ? strings.invalidCountdown
                    : strings.invalidHoliday,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : Navigator.of(context).pop,
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(strings.mobileSave),
        ),
      ],
    );
  }

  void _changeName(String value) => _name = value;
  void _changeStart(String? value) => setState(() => _start = value);
  void _changeEnd(String? value) => setState(() => _end = value);
  void _changeTime(String value) => _time = value;
  void _changeKind(String value) => _kind = value;

  Future<void> _submit() async {
    final String name = _name.trim();
    final String? start = _start;
    final String? end = _end;
    final String time = _time.trim();
    if (name.isEmpty ||
        start == null ||
        (widget.countdown &&
            !RegExp(r'^\d{2}:\d{2}(:\d{2})?$').hasMatch(time)) ||
        (!widget.countdown &&
            (end == null ||
                start.compareTo(end) > 0 ||
                _kind.trim().isEmpty))) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _busy = true);
    final SettingsValues candidate = widget.countdown
        ? <String, dynamic>{
            ...widget.value,
            'id':
                widget.value['id'] ??
                'countdown-${DateTime.now().microsecondsSinceEpoch}',
            'name': name,
            'target': '${start}T$time',
          }
        : <String, dynamic>{
            'name': name,
            'start': start,
            'end': end,
            'kind': _kind.trim(),
          };
    bool saved = false;
    try {
      saved = await widget.submit(candidate);
    } catch (_) {
      // 保留输入，用户可继续编辑。
    }
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _invalid = true;
      });
    }
  }
}
