import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../platform/widgets/widget_bridge.dart';
import '../../desktop_stickers/data/sticker_palette.dart';
import 'settings_store.dart';

/// 原生主屏幕小组件和手机设置页共用的外观。
class MobileAppearance {
  const MobileAppearance({
    this.palette = StickerPalette.macaron,
    this.titleVisible = true,
    this.titleSize = 16,
  });

  static const double minTitleSize = 10;
  static const double maxTitleSize = 24;

  /// 小组件整张卡片的配色。
  final StickerPalette palette;

  /// 是否在小组件中显示倒计时标题。
  final bool titleVisible;

  /// 标题字号，倒计时使用固定的数字样式。
  final double titleSize;

  MobileAppearance copyWith({
    StickerPalette? palette,
    bool? titleVisible,
    double? titleSize,
  }) => MobileAppearance(
    palette: palette ?? this.palette,
    titleVisible: titleVisible ?? this.titleVisible,
    titleSize: titleSize ?? this.titleSize,
  );

  static MobileAppearance fromJson(Map<String, dynamic> json) {
    final Object? size = json['titleSize'];
    return MobileAppearance(
      palette: StickerPalette.fromId(json['palette']),
      titleVisible: json['titleVisible'] != false,
      titleSize: size is num && size.isFinite
          ? size.clamp(minTitleSize, maxTitleSize).toDouble()
          : 16,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'palette': palette.name,
    'titleVisible': titleVisible,
    'titleSize': titleSize,
  };
}

/// 小组件外观通过原生共享存储读写，并兼容上一版应用内偏好。
class MobileAppearanceStore {
  const MobileAppearanceStore(this.bridge);

  /// 按平台读写私有共享文件并请求系统刷新。
  final WidgetBridge bridge;

  Future<MobileAppearance> read() async {
    if (!bridge.supported) return const MobileAppearance();
    final String? shared = await bridge.readAppearance();
    if (shared != null) return _decode(shared);
    final Directory directory = await getApplicationSupportDirectory();
    final LocalSettingsStore legacy = LocalSettingsStore(
      Directory('${directory.path}/shiyu/mobile'),
    );
    final String? previous = await legacy.read();
    if (previous == null) return const MobileAppearance();
    final MobileAppearance migrated = _decode(previous);
    await write(migrated);
    return migrated;
  }

  Future<void> write(MobileAppearance value) =>
      bridge.writeAppearance(jsonEncode(value.toJson()));

  MobileAppearance _decode(String raw) =>
      MobileAppearance.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
