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
    if (constraints.maxWidth < 682) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[controls, const SizedBox(height: 28), preview],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: controls),
        const SizedBox(width: 28),
        SizedBox(width: 282, child: preview),
      ],
    );
  }

  Widget _controls() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Text('浮窗配色', style: TextStyle(fontSize: 17)),
      const SizedBox(height: 8),
      const Text(
        '为桌面上的浮窗选择一套颜色。',
        style: TextStyle(color: SettingsPaper.muted),
      ),
      const SizedBox(height: 18),
      LayoutBuilder(builder: _paletteGrid),
      const SizedBox(height: 26),
      const Divider(height: 1),
      const SizedBox(height: 16),
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

  /// 统一各色卡宽度，小窗口换行时保留相同间距。
  Widget _paletteGrid(BuildContext context, BoxConstraints constraints) {
    const double gap = 14;
    final int columns = switch (constraints.maxWidth) {
      >= 372 => 3,
      >= 242 => 2,
      _ => 1,
    };
    final double width = (constraints.maxWidth - (columns - 1) * gap) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: <Widget>[
        for (final StickerPalette palette in StickerPalette.values)
          SizedBox(width: width, child: _colorCard(palette)),
      ],
    );
  }

  Widget _colorCard(StickerPalette palette) {
    final bool selected = session.state.palette == palette;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        style:
            OutlinedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              backgroundColor: SettingsPaper.surface,
            ).copyWith(
              side: WidgetStateProperty.resolveWith<BorderSide>(
                (Set<WidgetState> states) => _cardBorder(selected, states),
              ),
            ),
        onPressed: () => session.change(
          StickerSetting.palette,
          <String, Object?>{'value': palette.name},
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    palette.label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 16,
                  child: selected
                      ? const Icon(
                          Icons.check,
                          size: 15,
                          color: SettingsPaper.accent,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 22,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: palette.swatches.map(_swatch).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BorderSide _cardBorder(bool selected, Set<WidgetState> states) {
    final bool focused = states.contains(WidgetState.focused);
    return BorderSide(
      color: selected || focused ? SettingsPaper.accent : SettingsPaper.line,
      width: focused ? 2 : 1,
    );
  }

  Widget _swatch(Color color) => Expanded(child: ColoredBox(color: color));

  void _setSize(double size) => session.change(
    StickerSetting.titleSize,
    <String, Object?>{'value': size.round()},
  );

  Widget _preview() => DecoratedBox(
    decoration: BoxDecoration(
      color: SettingsPaper.surface,
      border: Border.all(color: SettingsPaper.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('浮窗预览', style: TextStyle(fontSize: 17)),
          const SizedBox(height: 8),
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
