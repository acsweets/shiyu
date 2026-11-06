import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../retirement/presentation/settings/app_language_setting.dart';
import '../../application/sticker_settings_state.dart';
import 'appearance_settings.dart';
import 'asset_settings.dart';
import 'countdown_settings.dart';
import 'settings_controls.dart';
import 'window_settings.dart';

enum _SettingsPane {
  appearance(Icons.palette_outlined),
  windows(Icons.dashboard_outlined),
  countdown(Icons.timer_outlined),
  assets(Icons.pets_outlined);

  const _SettingsPane(this.icon);

  /// 与名称并列显示的线性图标。
  final IconData icon;

  String label(AppLocalizations strings) => switch (this) {
    appearance => strings.desktopAppearance,
    windows => strings.desktopWindows,
    countdown => strings.desktopCountdowns,
    assets => strings.desktopCatAssets,
  };

  String detail(AppLocalizations strings) => switch (this) {
    appearance => strings.desktopAppearanceDescription,
    windows => strings.desktopWindowsDescription,
    countdown => strings.desktopCountdownsDescription,
    assets => strings.desktopCatAssetsDescription,
  };
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
            _sidebar(AppLocalizations.of(context)),
            const VerticalDivider(width: 1),
            Expanded(child: _content(AppLocalizations.of(context))),
          ],
        ),
      ),
    ),
  );

  Widget _sidebar(AppLocalizations strings) => Container(
    width: 164,
    padding: const EdgeInsets.fromLTRB(14, 28, 14, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 0, 24),
          child: Text(
            strings.mobileSettings,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
        ),
        for (final _SettingsPane pane in _SettingsPane.values)
          _navigation(pane, strings),
      ],
    ),
  );

  Widget _navigation(_SettingsPane pane, AppLocalizations strings) {
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
              Expanded(
                child: Text(
                  pane.label(strings),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(AppLocalizations strings) => Column(
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
                    _pane.label(strings),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _pane.detail(strings),
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
          if (_pane == _SettingsPane.appearance) ...<Widget>[
            AppLanguageSetting(
              locale: state.preferredLocale,
              save: state.editingBlocked ? null : _saveLanguage,
            ),
            const SizedBox(height: 24),
          ],
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

  Future<bool> _saveLanguage(String? locale) async {
    final StickerSettingsReply reply = await widget.session.send(
      StickerSetting.language,
      <String, Object?>{'value': locale},
    );
    return reply.state.business?.saved == true;
  }
}
