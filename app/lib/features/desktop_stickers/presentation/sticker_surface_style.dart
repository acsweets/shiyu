import 'package:flutter/material.dart';

import '../application/sticker_group_view.dart';
import '../data/skins/sticker_skin_settings.dart';

/// 将主题、色卡和模板转换为实际绘制令牌。
class StickerSurfaceStyle {
  StickerSurfaceStyle(StickerGroupView view, Brightness system)
    : this._(view.skin, view.background, view.foreground, system);

  StickerSurfaceStyle._(this.skin, this.base, this.ink, this.system);

  final StickerSkinSettings skin;
  final Color base;
  final Color ink;
  final Brightness system;

  bool get tech => skin.skin == StickerSkin.darkTech;
  bool get dark => skin.isDark(system);
  Color get fill => dark
      ? Color.alphaBlend(base.withValues(alpha: 0.13), const Color(0xFF171D2A))
      : base;
  Color get background => fill.withValues(alpha: skin.opacity / 100);
  Color get foreground => dark ? const Color(0xFFF3F5FC) : ink;
  Color get accent => skin.accent != null
      ? Color(skin.accent!)
      : (tech ? const Color(0xFF91B6E0) : foreground);
  Color get border => Color.alphaBlend(
    accent.withValues(alpha: 0.38),
    fill,
  ).withValues(alpha: skin.opacity / 100);
  double get radius => tech ? 9 : 18;
  double get inset => tech ? 14 : 8;
  double get valueSize => skin.scale.valueSize;
}
