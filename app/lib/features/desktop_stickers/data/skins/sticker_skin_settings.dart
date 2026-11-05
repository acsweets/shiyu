import 'dart:ui';

enum StickerSkin { stationery, darkTech }

enum StickerTheme { light, dark, system }

enum StickerScale {
  small(16),
  medium(18),
  large(22);

  const StickerScale(this.valueSize);
  final double valueSize;
}

/// L1 标记独立于计时和布局数据。文字大小选择只作用于完整时间行。
class StickerSkinSettings {
  const StickerSkinSettings({
    this.skin = StickerSkin.stationery,
    this.theme = StickerTheme.light,
    this.opacity = 100,
    this.scale = StickerScale.medium,
    this.accent,
  });

  static const Set<int> accents = <int>{
    0xFFE7A976,
    0xFF91B6E0,
    0xFFB39AE2,
    0xFF83C4B0,
  };

  final StickerSkin skin;
  final StickerTheme theme;
  final int opacity;
  final StickerScale scale;
  final int? accent;

  factory StickerSkinSettings.read(Object? data) {
    if (data is! Map<Object?, Object?>) return const StickerSkinSettings();
    final Object? opacity = data['opacity'];
    final Object? accent = data['accent'];
    return StickerSkinSettings(
      skin: _named(StickerSkin.values, data['skin']),
      theme: _named(StickerTheme.values, data['theme']),
      opacity: opacity is int ? opacity.clamp(30, 100) : 100,
      scale: _named(
        StickerScale.values,
        data['scale'],
        fallback: StickerScale.medium,
      ),
      accent: accent is int && accents.contains(accent) ? accent : null,
    );
  }

  Map<String, Object?> get data => <String, Object?>{
    'skin': skin.name,
    'theme': theme.name,
    'opacity': opacity,
    'scale': scale.name,
    'accent': accent,
  };

  bool isDark(Brightness brightness) => switch (theme) {
    StickerTheme.light => false,
    StickerTheme.dark => true,
    StickerTheme.system => brightness == Brightness.dark,
  };

  static T _named<T extends Enum>(
    List<T> values,
    Object? name, {
    T? fallback,
  }) => values.firstWhere(
    (T item) => item.name == name,
    orElse: () => fallback ?? values.first,
  );
}
