import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../retirement/application/holiday_status.dart';
import '../../../retirement/data/holiday_repository.dart';
import '../../../retirement/presentation/holiday_panel.dart';
import '../../application/sticker_settings_state.dart';
import '../../data/sticker_layout.dart';
import 'settings_controls.dart';

class CountdownSettings extends StatefulWidget {
  const CountdownSettings({required this.session, super.key});

  /// 主倒计时和业务设置的读写入口。
  final StickerSettingsSession session;

  @override
  State<CountdownSettings> createState() => _CountdownSettingsState();
}

class _CountdownSettingsState extends State<CountdownSettings> {
  /// 用户正在填写的时区，保存后交给 Rust 校验。
  late final TextEditingController _zone;

  /// 保存前暂存在设置页中的日期。
  String? _date;

  /// 请求过程中避免重复提交。
  bool _saving = false;

  StickerSettingsSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _date = _session.state.retirementDate;
    _zone = TextEditingController(text: _session.state.timeZone);
  }

  @override
  void dispose() {
    _zone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StickerSettingsState state = _session.state;
    final HolidayStatus? holidayStatus = state.holidayStatus;
    final bool editable = !state.editingBlocked && !_saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PaperSettingRow(
          title: '主倒计时',
          detail: '设置入口位于主倒计时所在的浮窗',
          control: PaperMenu(
            label: StickerLayout.titles[state.main]!,
            tooltip: '选择主倒计时',
            items: StickerLayout.titles.keys.map(_mainOption).toList(),
          ),
        ),
        const Divider(height: 24),
        const Text('启用倒计时', style: TextStyle(fontWeight: FontWeight.w700)),
        ...StickerLayout.titles.keys.map(_toggle),
        const Divider(height: 25),
        PaperSettingRow(
          title: '暂停刷新',
          detail: '恢复时按当前时间重新计算倒计时',
          control: Switch(value: state.paused, onChanged: _togglePause),
        ),
        const Divider(height: 25),
        PaperSettingRow(
          title: '示例数据',
          detail: '开启后显示示例时间。关闭后，退休倒计时使用真实设置。',
          control: Switch(value: state.preview, onChanged: _togglePreview),
        ),
        const Divider(height: 25),
        const Text(
          '退休设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        PaperSettingRow(
          title: '退休日期',
          detail: _date ?? '尚未设置',
          control: Wrap(
            spacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: editable ? _chooseDate : null,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: const Text('选择日期'),
              ),
              if (_date != null)
                TextButton(
                  onPressed: editable ? _clearDate : null,
                  child: const Text('清除'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 300,
          child: TextField(
            controller: _zone,
            enabled: editable,
            decoration: const InputDecoration(
              labelText: 'IANA 时区',
              hintText: 'Asia/Shanghai',
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (state.editingBlocked) const Text('无法读取当前设置。原配置已保留，编辑暂不可用。'),
        if (state.canRestore)
          OutlinedButton(
            onPressed: _saving ? null : _restoreBackup,
            child: const Text('恢复备份'),
          ),
        FilledButton(
          onPressed: editable ? _save : null,
          child: Text(_saving ? '正在保存…' : '保存退休设置'),
        ),
        if (holidayStatus != null) ...<Widget>[
          const Divider(height: 25),
          Text(
            AppLocalizations.of(context).holidayData,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          HolidayPanel(
            status: holidayStatus,
            check: _checkCalendar,
            importPack: _importCalendar,
          ),
        ],
      ],
    );
  }

  Widget _mainOption(String id) => PaperOption(
    label: StickerLayout.titles[id]!,
    selected: id == _session.state.main,
    autofocus: id == _session.state.main,
    onSelect: () =>
        _session.change(StickerSetting.main, <String, Object?>{'value': id}),
  );

  Widget _toggle(String id) {
    final String title = StickerLayout.titles[id]!;
    final bool main = id == _session.state.main;
    return PaperSettingRow(
      title: title,
      detail: main ? '当前主倒计时' : null,
      control: Semantics(
        label: '启用$title',
        child: Switch(
          value: _session.state.enabled.contains(id),
          onChanged: main
              ? null
              : (bool value) => _session.change(
                  StickerSetting.enabled,
                  <String, Object?>{'id': id, 'value': value},
                ),
        ),
      ),
    );
  }

  void _togglePreview(bool value) => _session.change(
    StickerSetting.preview,
    <String, Object?>{'value': value},
  );

  void _togglePause(bool value) =>
      _session.change(StickerSetting.pause, <String, Object?>{'value': value});

  Future<HolidayUpdate> _checkCalendar() async {
    final StickerSettingsReply reply = await _session.send(
      StickerSetting.holidayCheck,
    );
    return HolidayUpdate.values.byName(reply.message!);
  }

  Future<HolidayUpdate> _importCalendar(String raw) async {
    final StickerSettingsReply reply = await _session.send(
      StickerSetting.holidayImport,
      <String, Object?>{'raw': raw},
    );
    return HolidayUpdate.values.byName(reply.message!);
  }

  Future<void> _chooseDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date ?? '') ?? DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (mounted && date != null) {
      setState(() => _date = date.toIso8601String().split('T').first);
    }
  }

  void _clearDate() => setState(() => _date = null);

  Future<void> _save() => _submit(StickerSetting.retirement, <String, Object?>{
    'date': _date,
    'zone': _zone.text,
  });

  Future<void> _restoreBackup() =>
      _submit(StickerSetting.restoreBackup, const <String, Object?>{});

  Future<void> _submit(
    StickerSetting action,
    Map<String, Object?> arguments,
  ) async {
    setState(() => _saving = true);
    try {
      final StickerSettingsReply reply = await _session.send(action, arguments);
      if (mounted && action == StickerSetting.restoreBackup) {
        _date = reply.state.retirementDate;
        _zone.text = reply.state.timeZone;
      }
      if (mounted && reply.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reply.message!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
