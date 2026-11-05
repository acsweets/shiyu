import 'package:flutter/material.dart';

import '../../application/sticker_settings_state.dart';
import '../../data/sticker_layout.dart';
import '../../data/sticker_palette.dart';
import '../countdown_sticker.dart';
import 'settings_controls.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({required this.session, super.key});

  /// 实时读写外观设置。
  final StickerSettingsSession session;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _layout);

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final Widget controls = _controls();
    final Widget preview = _preview();
    if (constraints.maxWidth < 625) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[controls, const SizedBox(height: 22), preview],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: controls),
        const SizedBox(width: 24),
        SizedBox(width: 274, child: preview),
      ],
    );
  }

  Widget _controls() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text(
        '浮窗配色',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      const Text('为桌面上的浮窗选择一套颜色。'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: StickerPalette.values.map(_colorCard).toList(),
      ),
      const SizedBox(height: 20),
      const Divider(height: 1),
      const SizedBox(height: 12),
      PaperSettingRow(
        title: '提示文字大小',
        detail: '调整「距离下班」这类标题',
        control: Text(
          '${session.state.titleSize}',
          style: const TextStyle(
            color: SettingsPaper.accent,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Semantics(
        label: '提示文字大小',
        child: Slider(
          min: StickerLayout.minTitleSize.toDouble(),
          max: StickerLayout.maxTitleSize.toDouble(),
          divisions: StickerLayout.maxTitleSize - StickerLayout.minTitleSize,
          value: session.state.titleSize.toDouble(),
          label: '${session.state.titleSize}',
          onChanged: _setSize,
        ),
      ),
    ],
  );

  Widget _colorCard(StickerPalette palette) {
    final bool selected = session.state.palette == palette;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        style:
            OutlinedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              backgroundColor: selected
                  ? SettingsPaper.hover
                  : SettingsPaper.surface,
            ).copyWith(
              side: WidgetStatePropertyAll<BorderSide>(
                BorderSide(
                  color: selected ? SettingsPaper.accent : SettingsPaper.line,
                ),
              ),
            ),
        onPressed: () => session.change(
          StickerSetting.palette,
          <String, Object?>{'value': palette.name},
        ),
        child: SizedBox(
          width: 84,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      palette.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check,
                      size: 14,
                      color: SettingsPaper.accent,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 18,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: palette.swatches.map(_swatch).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _swatch(Color color) => Expanded(child: ColoredBox(color: color));

  void _setSize(double size) => session.change(
    StickerSetting.titleSize,
    <String, Object?>{'value': size.round()},
  );

  Widget _preview() => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFF5EDE1),
      border: Border.all(color: SettingsPaper.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('浮窗预览', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          const Text('当前主窗口', style: TextStyle(color: SettingsPaper.muted)),
          SizedBox(
            height:
                108 +
                session.state.window(session.state.mainGroup).values.length *
                    74,
            child: StickerGroupSurface(
              view: session.state.window(session.state.mainGroup),
              interactive: false,
            ),
          ),
        ],
      ),
    ),
  );
}
