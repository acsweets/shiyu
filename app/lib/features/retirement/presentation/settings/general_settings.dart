import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/settings_editor.dart';
import '../../data/settings_repository.dart';
import 'app_language_setting.dart';
import 'settings_files.dart';
import 'settings_time_zone.dart';

class GeneralSettings extends StatefulWidget {
  const GeneralSettings({required this.editor, this.mobile = false, super.key});

  final SettingsEditor editor;

  /// 手机在设置首页选择语言，此处提供时区和存储操作。
  final bool mobile;

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  bool _busy = false;
  SettingsEditor get _editor => widget.editor;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool hide = _editor.draft['hide_amount'] != false;
    final bool canRun = !_busy && (!widget.mobile || !_editor.dirty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.mobile)
          SettingsTimeZone(
            value: _editor.draft['time_zone'] as String? ?? 'Asia/Shanghai',
            changed: _editor.blocked ? null : _timeZone,
            error: _editor.issue('time_zone') == null
                ? null
                : strings.invalidValue,
          )
        else
          AppLanguageChoice(
            locale: _editor.group('display')['locale'] as String?,
            changed: _editor.blocked ? null : _locale,
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.hideSalary),
          value: hide,
          onChanged: _editor.blocked ? null : _hideSalary,
        ),
        OutlinedButton(
          onPressed: canRun ? _peek : null,
          child: Text(strings.peekSalary),
        ),
        const Divider(height: 28),
        Text(strings.exportPrivacy),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            OutlinedButton(
              onPressed: canRun && !_editor.blocked ? _import : null,
              child: Text(strings.settingsImport),
            ),
            OutlinedButton(
              onPressed: canRun ? _export : null,
              child: Text(strings.settingsExport),
            ),
          ],
        ),
      ],
    );
  }

  void _locale(String? value) =>
      _editor.changeGroup('display', 'locale', value);

  void _hideSalary(bool value) => _editor.change('hide_amount', value);
  void _timeZone(String value) => _editor.change('time_zone', value);

  Future<void> _peek() async {
    if (!await _editor.flush() || !mounted) return;
    setState(() => _busy = true);
    try {
      final SettingsValues? salary = await _editor.access.peekSalary();
      if (!mounted || salary == null) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => _SalaryDialog(salary: salary),
      );
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context).invalidValue);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final String? raw = await pickSettingsFile();
      if (raw == null || !mounted) return;
      final bool saved = await _editor.reloadFromFile(raw);
      if (!mounted) return;
      final AppLocalizations strings = AppLocalizations.of(context);
      _message(saved ? strings.mobileSaved : strings.settingsFileInvalid);
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context).settingsFileInvalid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await _editor.flush();
      if (mounted && await exportSettingsFile(_editor.view.values) && mounted) {
        _message(AppLocalizations.of(context).settingsExported);
      }
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context).settingsFileInvalid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _SalaryDialog extends StatefulWidget {
  const _SalaryDialog({required this.salary});

  final SettingsValues salary;

  @override
  State<_SalaryDialog> createState() => _SalaryDialogState();
}

class _SalaryDialogState extends State<_SalaryDialog>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final SettingsValues salary = widget.salary;
    final String currency = salary['currency'] as String? ?? '';
    return AlertDialog(
      title: Text(strings.peekSalary),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.metricTodaySalary),
          Text('${salary['today_earned'] ?? strings.mobileNotSet} $currency'),
          const SizedBox(height: 12),
          Text(strings.metricMonthSalary),
          Text('${salary['month_earned'] ?? strings.mobileNotSet} $currency'),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
