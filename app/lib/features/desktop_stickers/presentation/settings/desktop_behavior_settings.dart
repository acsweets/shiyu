import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../platform/desktop/desktop_options.dart';
import '../../application/sticker_settings_state.dart';
import 'settings_controls.dart';

class DesktopBehaviorSettings extends StatelessWidget {
  const DesktopBehaviorSettings({required this.session, super.key});

  final StickerSettingsSession session;

  @override
  Widget build(BuildContext context) {
    final StickerSettingsState state = session.state;
    final DesktopOptions options = state.desktop;
    final String modifier = Platform.isMacOS ? 'Cmd' : 'Ctrl';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '桌面行为',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        PaperSettingRow(
          title: '靠边吸附',
          detail: '拖动到显示器工作区边缘 12 像素以内时贴边',
          control: Switch(
            value: options.snap,
            onChanged: (bool value) => _change(context, 'snap', value),
          ),
        ),
        PaperSettingRow(
          title: '点击穿透',
          detail: '开启后可从托盘或菜单栏解除',
          control: Switch(
            value: options.clickThrough,
            onChanged: (bool value) => _change(context, 'clickThrough', value),
          ),
        ),
        PaperSettingRow(
          title: '覆盖全屏应用',
          detail: Platform.isMacOS ? '允许浮窗加入系统支持的全屏空间' : null,
          control: Switch(
            value: options.coverFullscreen,
            onChanged: (bool value) =>
                _change(context, 'coverFullscreen', value),
          ),
        ),
        PaperSettingRow(
          title: '登录时启动',
          detail: state.startupSupported ? null : '当前系统版本不提供应用内登录项管理',
          control: Switch(
            value: state.startupEnabled,
            onChanged: state.startupSupported
                ? (bool value) => _startup(context, value)
                : null,
          ),
        ),
        PaperSettingRow(
          title: '显示或隐藏浮窗',
          detail: state.visibilityShortcutOk
              ? '$modifier+Shift+T'
              : '$modifier+Shift+T 已被占用，可从托盘操作',
          control: const Icon(Icons.keyboard_outlined, size: 22),
        ),
        PaperSettingRow(
          title: '切换金额可见性',
          detail: state.amountShortcutOk ? null : '上次保存的快捷键当前不可用',
          control: _shortcuts(context, modifier, options.amountShortcut),
        ),
      ],
    );
  }

  Widget _shortcuts(BuildContext context, String modifier, String selected) =>
      PaperMenu(
        label: selected.isEmpty ? '未设置' : '$modifier+Shift+$selected',
        tooltip: '金额快捷键',
        items: <Widget>[
          PaperOption(
            label: '未设置',
            selected: selected.isEmpty,
            onSelect: () => _change(context, 'amountShortcut', ''),
          ),
          for (final int code in 'ABCDEFGHIJKLMNOPQRSUVWXYZ'.codeUnits)
            PaperOption(
              label: '$modifier+Shift+${String.fromCharCode(code)}',
              selected: selected == String.fromCharCode(code),
              onSelect: () =>
                  _change(context, 'amountShortcut', String.fromCharCode(code)),
            ),
        ],
      );

  Future<void> _change(BuildContext context, String key, Object value) => _send(
    context,
    StickerSetting.desktop,
    <String, Object?>{'key': key, 'value': value},
  );

  Future<void> _startup(BuildContext context, bool value) =>
      _send(context, StickerSetting.startup, <String, Object?>{'value': value});

  Future<void> _send(
    BuildContext context,
    StickerSetting action,
    Map<String, Object?> arguments,
  ) async {
    final StickerSettingsReply reply = await session.send(action, arguments);
    if (context.mounted && reply.message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(reply.message!)));
    }
  }
}
