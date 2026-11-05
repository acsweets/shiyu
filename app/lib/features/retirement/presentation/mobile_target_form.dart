import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../app/theme/settings_paper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/retirement_controller.dart';

/// 退休日期和时区作为同一表单保存，继续使用 Rust 校验和原生小组件刷新。
class MobileTargetForm extends StatefulWidget {
  const MobileTargetForm({required this.controller, super.key});

  /// 共享设置、错误状态及保存入口。
  final RetirementController controller;

  @override
  State<MobileTargetForm> createState() => _MobileTargetFormState();
}

class _MobileTargetFormState extends State<MobileTargetForm> {
  /// 未保存的时区输入，可在校验失败时直接修正。
  late final TextEditingController _zone;

  /// 日期草稿，清除或选择日期时不改动已保存设置。
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _date = DateTime.tryParse(widget.controller.retirementDate ?? '');
    _zone = TextEditingController(text: widget.controller.timeZone);
  }

  @override
  void dispose() {
    _zone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: widget.controller, builder: _buildForm);

  Widget _buildForm(BuildContext context, Widget? child) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool editable =
        !widget.controller.saving && !widget.controller.editingBlocked;
    final DateTime? date = _date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OutlinedButton(
          key: const ValueKey<String>('chooseDate'),
          onPressed: editable ? _chooseDate : null,
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.calendar_today_outlined,
                size: 19,
                color: SettingsPaper.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(strings.chooseRetirement),
                    const SizedBox(height: 4),
                    Text(
                      date == null
                          ? strings.mobileNotSet
                          : DateFormat.yMMMd(strings.localeName).format(date),
                      style: Theme.of(context).textTheme.bodySmall!
                          .copyWith(color: SettingsPaper.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
        if (date != null || widget.controller.retirementDate != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: editable && date != null ? _clearDate : null,
              child: Text(strings.clearTarget),
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _zone,
          enabled: editable,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: strings.timeZoneLabel,
            hintText: 'Asia/Shanghai',
            prefixIcon: const Icon(Icons.public_rounded, size: 19),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        if (widget.controller.problem != null) ...<Widget>[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              strings.settingsError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (widget.controller.canRestoreBackup)
          OutlinedButton(
            onPressed: widget.controller.saving ? null : _restoreBackup,
            child: Text(strings.restoreSettingsBackup),
          ),
        FilledButton(
          onPressed: editable ? _save : null,
          child: Text(strings.mobileSave),
        ),
      ],
    );
  }

  Future<void> _chooseDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  void _clearDate() => setState(() => _date = null);

  Future<void> _restoreBackup() async {
    final bool restored = await widget.controller.restoreBackup();
    if (!mounted || !restored) return;
    _zone.text = widget.controller.timeZone;
    setState(
      () => _date = DateTime.tryParse(widget.controller.retirementDate ?? ''),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final bool saved = await widget.controller.save(
      _date?.toIso8601String().split('T').first,
      _zone.text,
    );
    if (!mounted || !saved || widget.controller.problem != null) return;
    _zone.text = widget.controller.timeZone;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).mobileSaved)),
    );
  }
}
