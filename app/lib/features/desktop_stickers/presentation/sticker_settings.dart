import 'dart:io';

import 'package:flutter/material.dart';

import '../../retirement/application/retirement_controller.dart';
import '../data/sticker_layout.dart';

class StickerSettings extends StatefulWidget {
  const StickerSettings({
    required this.layout,
    required this.controller,
    super.key,
  });

  /// 画布外观配置。
  final StickerLayout layout;

  /// 真实退休设置。
  final RetirementController controller;
  @override
  State<StickerSettings> createState() => _StickerSettingsState();
}

class _StickerSettingsState extends State<StickerSettings> {
  /// 正在编辑的显式时区。
  late final TextEditingController _zone;

  /// 保存或资源操作的反馈。
  String? _message;
  @override
  void initState() {
    super.initState();
    _zone = TextEditingController(text: widget.controller.timeZone);
  }

  @override
  void dispose() {
    _zone.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(widget.controller.retirementDate ?? '') ??
          DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (date != null) await _save(date.toIso8601String().split('T').first);
  }

  Future<void> _save(String? date) async {
    final bool saved = await widget.controller.save(date, _zone.text);
    if (mounted) {
      setState(() => _message = saved ? '已保存真实设置' : '保存失败，请检查日期、时区或存储状态');
    }
  }

  Future<void> _saveZone() => _save(widget.controller.retirementDate);
  Future<void> _clearDate() => _save(null);
  void _selectMain(String? id) {
    if (id != null) widget.layout.setMain(id);
  }

  Widget _metric(String id) => CheckboxListTile(
    dense: true,
    title: Text(StickerLayout.titles[id]!),
    subtitle: id == widget.layout.main ? const Text('主贴纸保持开启') : null,
    value: widget.layout.enabled.contains(id),
    onChanged: id == widget.layout.main
        ? null
        : (bool? value) => widget.layout.toggle(id, value ?? false),
  );

  Future<void> _openAssets() async {
    try {
      final Directory? folder = widget.layout.directory;
      if (folder == null) return;
      await folder.create(recursive: true);
      await Process.run(Platform.isWindows ? 'explorer.exe' : 'open', <String>[
        folder.path,
      ]);
      if (mounted) {
        setState(() => _message = '将透明角色图命名为 character.png 放入此文件夹，再点“重新载入猫猫”。');
      }
    } catch (_) {
      if (mounted) setState(() => _message = '无法打开素材目录');
    }
  }

  Future<void> _reloadAssets() async {
    await widget.layout.reloadCharacter();
    if (mounted) setState(() => _message = '已请求重新载入；缺失或损坏的图片会使用内置猫猫。');
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: widget.layout, builder: _content);
  Widget _content(BuildContext context, Widget? child) => AlertDialog(
    backgroundColor: const Color(0xFFFFFBF4),
    title: const Text('猫猫贴纸设置'),
    content: SizedBox(
      width: 390,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('效果预览'),
              subtitle: const Text('预览使用固定示例时间，不写入个人配置'),
              value: widget.layout.preview,
              onChanged: widget.layout.setPreview,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: widget.layout.main,
              decoration: const InputDecoration(
                labelText: '主倒计时',
                border: OutlineInputBorder(),
              ),
              items: StickerLayout.titles.keys.map(_mainItem).toList(),
              onChanged: _selectMain,
            ),
            ...StickerLayout.titles.keys.map(_metric),
            const Divider(),
            const Text(
              '真实退休倒计时',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.controller.retirementDate ?? '尚未配置退休日期'),
            Wrap(
              spacing: 8,
              children: <Widget>[
                TextButton(
                  onPressed: widget.controller.editingBlocked
                      ? null
                      : _chooseDate,
                  child: const Text('选择日期'),
                ),
                TextButton(
                  onPressed: widget.controller.editingBlocked
                      ? null
                      : _clearDate,
                  child: const Text('清除日期'),
                ),
              ],
            ),
            TextField(
              controller: _zone,
              decoration: const InputDecoration(labelText: 'IANA 时区'),
            ),
            TextButton(
              onPressed: widget.controller.editingBlocked ? null : _saveZone,
              child: const Text('保存时区'),
            ),
            const Text(
              '关闭效果预览后，退休指标使用真实 Rust 快照，其余指标显示待接入。',
              style: TextStyle(fontSize: 12),
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: widget.layout.reset,
                  child: const Text('恢复默认排布'),
                ),
                OutlinedButton(
                  onPressed: _openAssets,
                  child: const Text('打开素材目录'),
                ),
                OutlinedButton(
                  onPressed: _reloadAssets,
                  child: const Text('重新载入猫猫'),
                ),
              ],
            ),
            SelectableText(
              widget.layout.directory?.path ?? '',
              style: const TextStyle(fontSize: 11),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_message!),
              ),
          ],
        ),
      ),
    ),
    actions: <Widget>[TextButton(onPressed: _close, child: const Text('完成'))],
  );
  DropdownMenuItem<String> _mainItem(String id) => DropdownMenuItem<String>(
    value: id,
    child: Text(StickerLayout.titles[id]!),
  );
}
