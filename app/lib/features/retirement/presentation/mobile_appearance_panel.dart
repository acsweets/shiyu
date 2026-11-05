import 'package:flutter/material.dart';

import '../../../app/theme/settings_paper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../desktop_stickers/data/sticker_palette.dart';
import '../data/mobile_appearance.dart';

typedef MobileAppearanceChanged = void Function(MobileAppearance appearance);

/// 配色和标题可独立修改，不会写入共享倒计时数据。
class MobileAppearancePanel extends StatefulWidget {
  const MobileAppearancePanel({
    required this.appearance,
    required this.onChanged,
    super.key,
  });

  /// 小组件的已选外观。
  final MobileAppearance appearance;

  /// 选项实时应用，滑块在完成拖动时保存。
  final MobileAppearanceChanged onChanged;

  @override
  State<MobileAppearancePanel> createState() => _MobileAppearancePanelState();
}

class _MobileAppearancePanelState extends State<MobileAppearancePanel> {
  /// 拖动时用于更新滑块和字号读数。
  double? _draftTitleSize;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final MobileAppearance appearance = widget.appearance;
    final double titleSize = _draftTitleSize ?? appearance.titleSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.mobileShowTitle),
          value: appearance.titleVisible,
          onChanged: _setTitleVisible,
        ),
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${strings.mobileTitleSize} · ${titleSize.round()}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Slider(
          value: titleSize,
          min: MobileAppearance.minTitleSize,
          max: MobileAppearance.maxTitleSize,
          divisions: 14,
          label: titleSize.round().toString(),
          onChanged: appearance.titleVisible ? _previewSize : null,
          onChangeEnd: _setTitleSize,
        ),
        const SizedBox(height: 8),
        for (final StickerPalette palette in StickerPalette.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PaletteChoice(
              palette: palette,
              label: _paletteLabel(strings, palette),
              selected: appearance.palette == palette,
              onPressed: () => _setPalette(palette),
            ),
          ),
      ],
    );
  }

  void _setTitleVisible(bool value) =>
      widget.onChanged(widget.appearance.copyWith(titleVisible: value));

  void _previewSize(double value) => setState(() => _draftTitleSize = value);

  void _setTitleSize(double value) {
    widget.onChanged(widget.appearance.copyWith(titleSize: value));
    setState(() => _draftTitleSize = null);
  }

  void _setPalette(StickerPalette palette) =>
      widget.onChanged(widget.appearance.copyWith(palette: palette));

  String _paletteLabel(AppLocalizations strings, StickerPalette palette) =>
      switch (palette) {
        StickerPalette.macaron => strings.mobileMacaron,
        StickerPalette.cool => strings.mobileCool,
        StickerPalette.sunset => strings.mobileSunset,
      };
}

class _PaletteChoice extends StatelessWidget {
  const _PaletteChoice({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  /// 与桌面浮窗共用色卡。
  final StickerPalette palette;

  /// 选项的本地化名称。
  final String label;

  /// 选中时显示陶土色描边和对勾。
  final bool selected;

  /// 点击整张色卡即可应用。
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      side: BorderSide(
        color: selected ? SettingsPaper.accent : SettingsPaper.line,
      ),
      borderRadius: BorderRadius.circular(14),
    );
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? SettingsPaper.selection : SettingsPaper.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: SettingsPaper.accent,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    for (final Color color in palette.swatches)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            height: 13,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
