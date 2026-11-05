import 'package:flutter/material.dart';

import '../../application/sticker_settings_state.dart';
import 'appearance_settings.dart';
import 'asset_settings.dart';
import 'countdown_settings.dart';
import 'settings_controls.dart';
import 'window_settings.dart';

enum _SettingsPane {
  appearance('外观', '选择底色和字号，实时查看浮窗效果。', Icons.palette_outlined),
  windows('窗口管理', '查看每个窗口的内容，合并、拆分或调整显示。', Icons.dashboard_outlined),
  countdown('倒计时', '选择桌面上要显示的倒计时，配置退休日期。', Icons.timer_outlined),
  assets('猫猫素材', '每个窗口有自己的猫猫，可以分别替换。', Icons.pets_outlined);

  const _SettingsPane(this.label, this.detail, this.icon);

  /// 导航名称。
  final String label;

  /// 页面说明。
  final String detail;

  /// 与名称并列显示的线性图标。
  final IconData icon;
}

class StickerSettings extends StatefulWidget {
  const StickerSettings({required this.session, this.onClose, super.key});

  /// 连接主引擎的设置会话。
  final StickerSettingsSession session;

  /// 仅在同引擎预览时提供关闭动作。
  final VoidCallback? onClose;

  @override
  State<StickerSettings> createState() => _StickerSettingsState();
}

class _StickerSettingsState extends State<StickerSettings> {
  /// 当前导航项。
  _SettingsPane _pane = _SettingsPane.appearance;

  void _select(_SettingsPane pane) => setState(() => _pane = pane);

  @override
  Widget build(BuildContext context) => Theme(
    data: SettingsPaper.theme,
    child: ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: SettingsPaper.surface,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _sidebar(),
            const VerticalDivider(width: 1),
            Expanded(child: _content()),
          ],
        ),
      ),
    ),
  );

  Widget _sidebar() => Container(
    width: 164,
    padding: const EdgeInsets.fromLTRB(14, 28, 14, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 0, 24),
          child: Text(
            '设置',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
        ),
        ..._SettingsPane.values.map(_navigation),
      ],
    ),
  );

  Widget _navigation(_SettingsPane pane) {
    final bool selected = pane == _pane;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        selected: selected,
        child: TextButton(
          onPressed: () => _select(pane),
          style: TextButton.styleFrom(
            foregroundColor: selected
                ? SettingsPaper.accent
                : SettingsPaper.ink,
            backgroundColor: selected ? SettingsPaper.selection : null,
            minimumSize: const Size(double.infinity, 43),
            shape: RoundedRectangleBorder(borderRadius: SettingsPaper.corners),
            padding: const EdgeInsets.symmetric(horizontal: 11),
          ),
          child: Row(
            children: <Widget>[
              Icon(pane.icon, size: 19),
              const SizedBox(width: 9),
              Text(pane.label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(
          SettingsPaper.contentInset,
          26,
          SettingsPaper.contentInset,
          22,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _pane.label,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _pane.detail,
                    style: const TextStyle(color: SettingsPaper.muted),
                  ),
                ],
              ),
            ),
            if (widget.onClose != null)
              IconButton(
                tooltip: '关闭设置',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: AnimatedBuilder(animation: widget.session, builder: _body),
      ),
    ],
  );

  Widget _body(BuildContext context, Widget? child) {
    final StickerSettingsSession session = widget.session;
    final StickerSettingsState state = session.state;
    return SingleChildScrollView(
      key: PageStorageKey<_SettingsPane>(_pane),
      padding: const EdgeInsets.fromLTRB(
        SettingsPaper.contentInset,
        28,
        SettingsPaper.contentInset,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (state.windowFailed || state.writeFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.windowFailed ? '部分浮窗未能打开' : '窗口布局未能保存',
                style: const TextStyle(color: SettingsPaper.accent),
              ),
            ),
          switch (_pane) {
            _SettingsPane.appearance => AppearanceSettings(session: session),
            _SettingsPane.windows => WindowSettings(session: session),
            _SettingsPane.countdown => CountdownSettings(session: session),
            _SettingsPane.assets => AssetSettings(session: session),
          },
        ],
      ),
    );
  }
}
