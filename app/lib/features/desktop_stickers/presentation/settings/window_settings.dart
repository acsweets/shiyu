import 'package:flutter/material.dart';

import '../../application/sticker_group_view.dart';
import '../../application/sticker_settings_state.dart';
import '../../data/sticker_layout.dart';
import 'desktop_behavior_settings.dart';
import 'settings_controls.dart';

class WindowSettings extends StatelessWidget {
  const WindowSettings({required this.session, super.key});

  /// 由主引擎同步到桌面的窗口配置。
  final StickerSettingsSession session;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (final int group in session.state.groups) ...<Widget>[
        _window(context, group),
        const Divider(height: 25),
      ],
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _confirmReset(context),
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('重置窗口位置和大小'),
        ),
      ),
      const Divider(height: 30),
      DesktopBehaviorSettings(session: session),
    ],
  );

  Widget _window(BuildContext context, int group) {
    final StickerGroupView window = session.state.window(group);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PaperSettingRow(
          title: session.state.groupLabel(group),
          detail: session.state.members(group),
          control: _switch(
            '显示窗口',
            window.visible,
            StickerSetting.groupVisible,
            group,
          ),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _switch(
              '显示标题',
              window.showsTitle,
              StickerSetting.titleVisible,
              group,
            ),
            OutlinedButton(
              onPressed: () => _resize(group, -1),
              child: const Text('缩小'),
            ),
            OutlinedButton(
              onPressed: () => _resize(group, 1),
              child: const Text('放大'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final String id in window.values.keys) _timer(context, id, group),
      ],
    );
  }

  Widget _switch(String label, bool value, StickerSetting action, int group) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: const TextStyle(color: SettingsPaper.muted)),
          const SizedBox(width: 8),
          Semantics(
            label: '$label · ${session.state.groupLabel(group)}',
            child: Switch(
              value: value,
              onChanged: (bool next) => session.change(
                action,
                <String, Object?>{'group': group, 'value': next},
              ),
            ),
          ),
        ],
      );

  Widget _timer(BuildContext context, String id, int group) {
    final String title = session.state.window(group).label(id);
    final List<int> targets = session.state.groups
        .where((int target) => target != group)
        .toList();
    final List<Widget> destinations = <Widget>[
      for (final int target in targets)
        PaperOption(
          label: session.state.groupLabel(target),
          detail: session.state.members(target),
          autofocus: target == targets.first,
          onSelect: () => _move(context, id, target),
        ),
      if (session.state.window(group).values.length > 1 &&
          session.state.groups.length < StickerLayout.titles.length)
        PaperOption(
          label: '新的独立窗口',
          autofocus: targets.isEmpty,
          onSelect: () => _move(context, id, null),
        ),
    ];
    if (destinations.isEmpty) return const SizedBox.shrink();
    return PaperSettingRow(
      title: title,
      control: PaperMenu(
        label: '移到…',
        tooltip: '移动$title',
        items: destinations,
      ),
    );
  }

  void _resize(int group, int step) => session.change(
    StickerSetting.resize,
    <String, Object?>{'group': group, 'step': step},
  );

  Future<void> _move(BuildContext context, String id, int? target) async {
    final StickerSettingsReply reply = await session.send(
      StickerSetting.move,
      <String, Object?>{'id': id, 'target': target},
    );
    if (!context.mounted || reply.message == null) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(reply.message!),
        behavior: SnackBarBehavior.floating,
        action: reply.canUndo
            ? SnackBarAction(label: '撤销', onPressed: _undo)
            : null,
      ),
    );
  }

  void _undo() => session.change(StickerSetting.undoMove);

  Future<void> _confirmReset(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: _resetDialog,
    );
    if (confirmed == true) session.change(StickerSetting.resetBounds);
  }

  Widget _resetDialog(BuildContext context) => AlertDialog(
    title: const Text('重置窗口位置和大小？'),
    content: const Text('浮窗将回到默认位置和大小。倒计时分组和显示设置会保留。'),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('重置'),
      ),
    ],
  );
}
