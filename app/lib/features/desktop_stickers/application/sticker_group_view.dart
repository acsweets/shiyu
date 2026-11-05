import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../retirement/application/retirement_controller.dart';
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
  ) => StickerGroupView(<String, Object?>{
    'values': <String, String>{
      for (final String id in layout.members(group))
        id: _value(id, layout.preview, controller),
    },
    'titles': layout.showsTitle(group),
    'preview': layout.preview,
    'visible': visible,
    if (group == layout.mainGroup) 'character': layout.character?.path,
    if (group == layout.mainGroup) 'assetRevision': layout.assetRevision,
    'initialBounds': StickerLayout.encodeBounds(
      layout.boundsOf(group) ?? layout.initialBounds(group),
    ),
  });

  Map<String, String> get values =>
      (data['values'] as Map<Object?, Object?>).cast<String, String>();
  bool get showsTitle => data['titles'] as bool;
  bool get preview => data['preview'] as bool;
  bool get visible => data['visible'] as bool;
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
