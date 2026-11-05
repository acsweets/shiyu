import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

import '../../desktop_stickers/data/sticker_palette.dart';
import 'settings_store.dart';

/// 手机端外观和位置独立于 Rust 与小组件使用的设置。
class MobileAppearance {
  const MobileAppearance({
    this.palette = StickerPalette.macaron,
    this.cardVisible = true,
    this.titleVisible = true,
    this.titleSize = 16,
    this.position = defaultPosition,
  });

  static const Alignment defaultPosition = Alignment(0, -0.26);
  static const double minTitleSize = 10;
  static const double maxTitleSize = 24;

  /// 整块浮窗的底色。
  final StickerPalette palette;

  /// 首页是否显示浮窗。
  final bool cardVisible;

  /// 是否在倒计时上方显示标题。
  final bool titleVisible;

  /// 标题的字号，不影响倒计时数字。
  final double titleSize;

  /// 在可拖动范围内的相对位置，旋转屏幕时仍可见。
  final Alignment position;

  MobileAppearance copyWith({
    StickerPalette? palette,
    bool? cardVisible,
    bool? titleVisible,
    double? titleSize,
    Alignment? position,
  }) => MobileAppearance(
    palette: palette ?? this.palette,
    cardVisible: cardVisible ?? this.cardVisible,
    titleVisible: titleVisible ?? this.titleVisible,
    titleSize: titleSize ?? this.titleSize,
    position: position ?? this.position,
  );

  static MobileAppearance fromJson(Map<String, dynamic> json) {
    return MobileAppearance(
      palette: StickerPalette.fromId(json['palette']),
      cardVisible: json['cardVisible'] != false,
      titleVisible: json['titleVisible'] != false,
      titleSize: _readNumber(json['titleSize'], 16, minTitleSize, maxTitleSize),
      position: Alignment(
        _readNumber(json['x'], defaultPosition.x, -1, 1),
        _readNumber(json['y'], defaultPosition.y, -1, 1),
      ),
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'palette': palette.name,
    'cardVisible': cardVisible,
    'titleVisible': titleVisible,
    'titleSize': titleSize,
    'x': position.x,
    'y': position.y,
  };

  static double _readNumber(
    Object? value,
    double fallback,
    double min,
    double max,
  ) {
    return value is num && value.isFinite
        ? value.clamp(min, max).toDouble()
        : fallback;
  }
}

/// 外观只写到本应用私有目录，沿用现有的原子文件替换。
class MobileAppearanceStore {
  const MobileAppearanceStore();

  Future<MobileAppearance> read() async {
    try {
      final LocalSettingsStore store = await _store();
      final String? content = await store.read();
      if (content != null) {
        return MobileAppearance.fromJson(
          jsonDecode(content) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // 外观文件缺失或损坏时使用默认值，不影响倒计时设置。
    }
    return const MobileAppearance();
  }

  Future<void> write(MobileAppearance value) async {
    final LocalSettingsStore store = await _store();
    await store.write(jsonEncode(value.toJson()));
  }

  Future<LocalSettingsStore> _store() async {
    final Directory directory = await getApplicationSupportDirectory();
    return LocalSettingsStore(Directory('${directory.path}/shiyu/mobile'));
  }
}
