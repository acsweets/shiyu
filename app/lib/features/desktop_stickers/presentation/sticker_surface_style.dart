import 'package:flutter/material.dart';

import '../application/sticker_group_view.dart';
import '../data/skins/sticker_skin_settings.dart';
import '../data/sticker_palette.dart';

/// 将主题、色卡和模板转换为实际绘制令牌。
class StickerSurfaceStyle {
  StickerSurfaceStyle(StickerGroupView view, Brightness system)
    : this._(view.skin, view.palette, view.background, view.foreground, system);

  StickerSurfaceStyle._(
    this.skin,
    this.palette,
    this.base,
    this.ink,
    this.system,
  );

  final StickerSkinSettings skin;

  /// 决定使用纯色卡面或玻璃渐变。
  final StickerPalette palette;
  final Color base;
  final Color ink;
  final Brightness system;

  bool get tech => skin.skin == StickerSkin.darkTech;
  bool get dark => skin.isDark(system);
  Color get fill => dark
      ? Color.alphaBlend(base.withValues(alpha: 0.13), const Color(0xFF171D2A))
      : base;
  double get _opacity => skin.opacity / 100;
  Color get foreground => dark ? const Color(0xFFF3F5FC) : ink;
  Color get accent => skin.accent != null
      ? Color(skin.accent!)
      : (tech ? const Color(0xFF91B6E0) : foreground);
  Color get border => palette.isGlass
      ? Colors.white.withValues(alpha: (dark ? 0.42 : 0.83) * _opacity)
      : Color.alphaBlend(
          accent.withValues(alpha: 0.38),
          fill,
        ).withValues(alpha: _opacity);

  /// 背景透明度只影响底板和描边，文字仍以原有对比度绘制。
  BoxDecoration get decoration => BoxDecoration(
    color: palette.isGlass ? null : fill.withValues(alpha: _opacity),
    gradient: palette.glassGradient(fill, opacity: _opacity, dark: dark),
    border: Border.all(color: border),
    borderRadius: BorderRadius.circular(radius),
  );
  double get radius => tech ? 9 : 18;
  double get inset => tech ? 14 : 8;
  double get valueSize => skin.scale.valueSize;
}
