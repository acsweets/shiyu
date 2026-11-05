import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../retirement/application/retirement_controller.dart';
import '../data/sticker_cat_pose.dart';
import '../data/sticker_character.dart';
import '../data/sticker_layout.dart';

/// 跨窗口只传输可见文本与外观信息，子窗无需加载 Rust。
class StickerGroupView {
  StickerGroupView(this.data);

  /// 可经平台消息传递的窗口视图快照。
  final Map<Object?, Object?> data;

  factory StickerGroupView.fromLayout(
    StickerLayout layout,
    RetirementController controller,
    int group,
    bool visible,
  ) {
    final StickerCatPose pose = StickerCatPose.values[group];
    final StickerCharacter? character = layout.characterOf(group);
    return StickerGroupView(<String, Object?>{
      'values': <String, String>{
        for (final String id in layout.members(group))
          id: _value(id, layout.preview, controller),
      },
      'titles': layout.showsTitle(group),
      'titleSize': layout.titleSize,
      'preview': layout.preview,
      'visible': visible,
      'background': layout.palette.backgroundFor(group).toARGB32(),
      'foreground': layout.palette.foreground.toARGB32(),
      'catAsset': pose.asset,
      'catBottomInset': pose.bottomInset,
      'character': character?.file.path,
      'characterBottomInset': character?.bottomInset,
      'assetRevision': layout.assetRevision,
      'initialBounds': StickerLayout.encodeBounds(
        layout.boundsOf(group) ?? layout.initialBounds(group),
      ),
    });
  }

  Map<String, String> get values {
    final Map<Object?, Object?> values =
        data['values'] as Map<Object?, Object?>;
    return <String, String>{
      for (final String id in StickerLayout.titles.keys)
        if (values[id] case final String text) id: text,
    };
  }

  bool get showsTitle => data['titles'] as bool;
  double get titleSize => (data['titleSize'] as int).toDouble();
  bool get preview => data['preview'] as bool;
  bool get visible => data['visible'] as bool;
  Color get background => Color(data['background'] as int);
  Color get foreground => Color(data['foreground'] as int);
  String get catAsset => data['catAsset'] as String;
  double get catBottomInset => data['catBottomInset'] as double;
  double? get characterBottomInset => data['characterBottomInset'] as double?;
  int get assetRevision => data['assetRevision'] as int;
  File? get character {
    final String? path = data['character'] as String?;
    return path == null ? null : File(path);
  }

  Rect get initialBounds => StickerLayout.decodeBounds(data['initialBounds'])!;

  static String _value(
    String id,
    bool preview,
    RetirementController controller,
  ) {
    if (preview) return StickerLayout.examples[id]!;
    if (id != 'retirement') return '待接入';
    final String? status = controller.snapshot?.status;
    if (status == 'retired') return '已退休';
    if (status != 'active') return '请设置退休日期';
    final Duration time = Duration(seconds: controller.snapshot!.seconds);
    return '${time.inDays}天 ${_two(time.inHours % 24)}小时 ${_two(time.inMinutes % 60)}分 ${_two(time.inSeconds % 60)}秒';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
