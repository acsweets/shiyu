import 'package:flutter/painting.dart';

/// 桌面浮窗配色，枚举名称用作本地布局的保存标识。
enum StickerPalette {
  macaron('马卡龙色系', Color(0xFF45363B), <Color>[
    Color(0xFFFFEBB4),
    Color(0xFFE8D9FA),
    Color(0xFFD8EBFA),
    Color(0xFFFADBD9),
  ]),
  cool('冷酷色系', Color(0xFFF0F5FF), <Color>[
    Color(0xFF242A3A),
    Color(0xFF33354E),
    Color(0xFF193B46),
    Color(0xFF443244),
  ]),
  sunset('日落暖调', Color(0xFF472B29), <Color>[
    Color(0xFFF4D0A3),
    Color(0xFFF1BCA4),
    Color(0xFFEDBAC2),
    Color(0xFFE4C1D4),
  ]);

  const StickerPalette(this.label, this.foreground, this.swatches);

  /// 设置色卡上的名称。
  final String label;

  /// 窗口标题、时间与设置图标的文字色。
  final Color foreground;

  /// 按窗口槽位排列的底色，也是设置色卡的预览。
  final List<Color> swatches;

  Color backgroundFor(int group) => swatches[group % swatches.length];

  /// 旧布局未记录配色时，继续使用默认马卡龙色系。
  static StickerPalette fromId(Object? id) => values.firstWhere(
    (StickerPalette palette) => palette.name == id,
    orElse: () => macaron,
  );
}
