import 'dart:io';

import 'package:flutter/material.dart';

import '../../retirement/application/retirement_controller.dart';
import '../data/sticker_layout.dart';

typedef StickerWindowResize = void Function(int group, int step);

class StickerSettings extends StatefulWidget {
  const StickerSettings({
    required this.layout,
    required this.controller,
    required this.resetWindowBounds,
    required this.resizeWindow,
    required this.windowFailed,
    super.key,
  });

  /// 画布外观配置。
  final StickerLayout layout;

  /// 真实退休设置。
  final RetirementController controller;

  /// 复位真实系统窗口的几何信息。
  final VoidCallback resetWindowBounds;

  /// 在设置内调整任意分组的窗口大小。
  final StickerWindowResize resizeWindow;

  /// 只在设置中提示子窗打开异常。
  final bool windowFailed;

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
    subtitle: id == widget.layout.main ? const Text('当前主倒计时') : null,
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
            if (widget.windowFailed) const Text('部分浮窗未能打开'),
            if (widget.layout.writeFailed) const Text('窗口布局未能保存'),
            const Text('窗口显示', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('主窗口关闭后，可从系统托盘或菜单栏打开设置。'),
            ...widget.layout.activeGroups.map(_windowVisibility),
            const Divider(),
            const Text('窗口分组', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('选择同一窗口即可合并。选择独立窗口可拆出。'),
            ...widget.layout.enabled.map(_assignment),
            const SizedBox(height: 8),
            ...widget.layout.activeGroups.map(_windowOptions),
            const Divider(),
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
                  onPressed: widget.resetWindowBounds,
                  child: const Text('复位窗口位置与大小'),
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
  String _groupName(int group) {
    final String members = widget.layout.members(group).map(_title).join('、');
    return '窗口 ${group + 1} · $members';
  }

  String _title(String id) => StickerLayout.titles[id]!;

  Widget _assignment(String id) {
    final int group = widget.layout.groupOf(id);
    final List<DropdownMenuItem<int>> options = <DropdownMenuItem<int>>[
      const DropdownMenuItem<int>(value: -1, child: Text('独立窗口')),
      for (final int candidate in widget.layout.activeGroups)
        if (candidate != group || widget.layout.members(group).length > 1)
          DropdownMenuItem<int>(
            value: candidate,
            child: Text(_groupName(candidate), overflow: TextOverflow.ellipsis),
          ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: _title(id)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isDense: true,
            isExpanded: true,
            value: widget.layout.members(group).length == 1 ? -1 : group,
            items: options,
            onChanged: (int? value) => _assign(id, value),
          ),
        ),
      ),
    );
  }

  void _assign(String id, int? value) {
    if (value != null) widget.layout.assign(id, value < 0 ? null : value);
  }

  Widget _windowVisibility(int group) => SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(group == widget.layout.mainGroup ? '显示主窗口' : '显示窗口'),
    subtitle: Text(_groupName(group)),
    value: widget.layout.showsGroup(group),
    onChanged: (bool value) => widget.layout.setGroupVisible(group, value),
  );

  Widget _windowOptions(int group) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('显示标题'),
        subtitle: Text(_groupName(group)),
        value: widget.layout.showsTitle(group),
        onChanged: (bool value) => widget.layout.setTitleVisible(group, value),
      ),
      Wrap(
        spacing: 8,
        children: <Widget>[
          OutlinedButton(
            onPressed: () => widget.resizeWindow(group, -1),
            child: const Text('缩小窗口'),
          ),
          OutlinedButton(
            onPressed: () => widget.resizeWindow(group, 1),
            child: const Text('放大窗口'),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ],
  );

  DropdownMenuItem<String> _mainItem(String id) => DropdownMenuItem<String>(
    value: id,
    child: Text(StickerLayout.titles[id]!),
  );
}
