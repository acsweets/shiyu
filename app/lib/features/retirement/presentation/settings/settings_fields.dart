import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

class SettingsInput extends StatelessWidget {
  const SettingsInput({
    required this.label,
    required this.value,
    required this.changed,
    this.hint,
    this.error,
    this.secret = false,
    this.keyboard,
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String>? changed;
  final String? hint;
  final String? error;
  final bool secret;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: value,
      enabled: changed != null,
      onChanged: changed,
      obscureText: secret,
      enableSuggestions: !secret,
      autocorrect: false,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        errorMaxLines: 3,
      ),
    ),
  );
}

class SettingsChoice extends StatelessWidget {
  const SettingsChoice({
    required this.label,
    required this.selected,
    required this.options,
    required this.changed,
    this.error,
    super.key,
  });

  final String label;
  final String selected;
  final Map<String, String> options;
  final ValueChanged<String>? changed;
  final String? error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: options.containsKey(selected)
          ? selected
          : options.keys.first,
      isExpanded: true,
      items: <DropdownMenuItem<String>>[
        for (final MapEntry<String, String> option in options.entries)
          DropdownMenuItem<String>(
            value: option.key,
            child: Text(option.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: changed == null ? null : _choose,
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        errorMaxLines: 3,
      ),
    ),
  );

  void _choose(String? value) {
    if (value != null) changed?.call(value);
  }
}

class SettingsDate extends StatelessWidget {
  const SettingsDate({
    required this.label,
    required this.value,
    required this.changed,
    this.error,
    this.clearable = true,
    super.key,
  });

  final String label;
  final String? value;
  final ValueChanged<String?>? changed;
  final String? error;
  final bool clearable;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, errorText: error),
        child: Wrap(
          spacing: 6,
          children: <Widget>[
            TextButton.icon(
              onPressed: changed == null ? null : () => _choose(context),
              icon: const Icon(Icons.calendar_today_outlined, size: 17),
              label: Text(value ?? strings.mobileNotSet),
            ),
            if (clearable && value != null)
              TextButton(
                onPressed: changed == null ? null : () => changed!(null),
                child: Text(strings.clearTarget),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(value ?? '') ?? DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (date != null && context.mounted) {
      changed?.call(date.toIso8601String().split('T').first);
    }
  }
}

/// 手机作息直接选时间，存储格式与现有文本表单一致。
class SettingsTime extends StatelessWidget {
  const SettingsTime({
    required this.label,
    required this.value,
    required this.changed,
    this.error,
    super.key,
  });

  /// 时间字段的用途。
  final String label;

  /// 共享设置使用的 24 小时时间。
  final String value;

  /// 选择后交给编辑器保存草稿。
  final ValueChanged<String>? changed;

  /// 共享核心返回的校验提示。
  final String? error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, errorText: error),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: changed == null ? null : () => _pick(context),
          icon: const Icon(Icons.schedule_rounded, size: 18),
          label: Text(value),
        ),
      ),
    ),
  );

  Future<void> _pick(BuildContext context) async {
    final DateTime? parsed = DateTime.tryParse('2000-01-01T$value');
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: parsed == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(parsed),
    );
    if (time != null && context.mounted) {
      changed?.call('${_twoDigits(time.hour)}:${_twoDigits(time.minute)}');
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
