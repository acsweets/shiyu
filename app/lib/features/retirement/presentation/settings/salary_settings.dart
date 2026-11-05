import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_editor.dart';
import '../../data/settings_repository.dart';
import 'settings_fields.dart';

class SalarySettings extends StatelessWidget {
  const SalarySettings({required this.editor, super.key});

  final SettingsEditor editor;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final SettingsValues salary = editor.group('salary');
    final bool configured = salary.isNotEmpty && !editor.blocked;
    final bool hidden = editor.draft['hide_amount'] != false;
    final String? amountError = editor.issue('salary') == null
        ? null
        : strings.invalidSalary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsInput(
          label: strings.grossMonthly,
          value: salary['gross_monthly'] as String? ?? '',
          changed: editor.blocked ? null : _gross,
          secret: hidden,
          error: amountError,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        SettingsInput(
          label: strings.netMonthly,
          value: salary['net_monthly'] as String? ?? '',
          changed: configured ? _net : null,
          secret: hidden,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        SettingsChoice(
          label: strings.salaryBasis,
          selected: salary['basis'] as String? ?? 'gross',
          options: <String, String>{
            'gross': strings.grossMonthly,
            'net': strings.netMonthly,
          },
          changed: configured ? _basis : null,
          error: editor.issue('salary.basis') == null
              ? null
              : strings.netRequired,
        ),
        SettingsInput(
          label: strings.currencyCode,
          value: salary['currency'] as String? ?? '',
          changed: configured ? _currency : null,
          hint: 'CNY / USD / JPY',
          error: editor.issue('salary.currency') == null
              ? null
              : strings.invalidValue,
        ),
        SettingsChoice(
          label: strings.salaryPrecision,
          selected: '${salary['precision'] ?? 2}',
          options: const <String, String>{'2': '2', '3': '3', '4': '4'},
          changed: configured ? _precision : null,
        ),
      ],
    );
  }

  void _gross(String raw) {
    final String value = _amount(raw);
    editor.change(
      'salary',
      value.isEmpty
          ? null
          : <String, dynamic>{
              ...editor.group('salary'),
              'gross_monthly': value,
            },
    );
  }

  void _net(String raw) {
    final String value = _amount(raw);
    editor.changeGroup('salary', 'net_monthly', value.isEmpty ? null : value);
  }

  String _amount(String value) => value.trim().replaceAll(',', '.');
  void _basis(String value) => editor.changeGroup('salary', 'basis', value);
  void _precision(String value) =>
      editor.changeGroup('salary', 'precision', int.parse(value));

  void _currency(String value) => editor.changeGroup(
    'salary',
    'currency',
    value.trim().isEmpty ? null : value.trim().toUpperCase(),
  );
}
