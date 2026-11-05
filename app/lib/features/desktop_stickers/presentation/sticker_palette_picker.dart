import 'package:flutter/material.dart';

import '../data/sticker_palette.dart';

/// 展示各套配色的窗口底色，使用同一个选择切换所有浮窗。
class StickerPalettePicker extends StatelessWidget {
  const StickerPalettePicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// 当前选中的全局配色。
  final StickerPalette selected;

  /// 点击色卡后应用并保存配色。
  final ValueChanged<StickerPalette> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: StickerPalette.values.map(_choice).toList(),
  );

  Widget _choice(StickerPalette palette) => ChoiceChip(
    selected: selected == palette,
    showCheckmark: false,
    onSelected: (bool value) => _select(palette, value),
    label: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(palette.label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            width: 64,
            height: 13,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: palette.swatches.map(_swatch).toList(),
            ),
          ),
        ),
      ],
    ),
  );

  void _select(StickerPalette palette, bool value) {
    if (value) onSelected(palette);
  }

  Widget _swatch(Color color) => Expanded(child: ColoredBox(color: color));
}
