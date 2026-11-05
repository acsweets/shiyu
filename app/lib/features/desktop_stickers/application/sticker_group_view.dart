import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../retirement/application/retirement_controller.dart';
import '../../retirement/presentation/metrics/snapshot_metrics.dart';
import '../data/sticker_cat_pose.dart';
import '../data/sticker_character.dart';
import '../data/sticker_layout.dart';
import '../data/sticker_mode.dart';
import 'sticker_metric_selection.dart';

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
    final SnapshotMetrics metrics = SnapshotMetrics(
      controller.snapshot,
      SnapshotMetrics.localizations(controller.preferredLocale),
    );
    final List<String> ids = StickerMetricSelection(
      layout,
      controller,
    ).group(group);
    return StickerGroupView(<String, Object?>{
      'metrics': <String, MetricFields>{
        for (final String id in ids)
          id: layout.preview
              ? <Object?, Object?>{
                  'title': StickerLayout.titles[id],
                  'value': StickerLayout.examples[id],
                }
              : metrics.read(id, coreFailed: controller.problem == 'core'),
      },
      'mode': layout.mode.name,
      'emptyLabel': metrics.strings.noVisibleMetrics,
      'fallback':
          !layout.preview &&
              controller.snapshot?.calendarStatus == 'weekly_fallback'
          ? metrics.strings.holidayFallback
          : null,
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
        layout.boundsOf(group) ??
            (layout.preview
                ? layout.initialBounds(group)
                : layout.modeBounds(group, ids.length)),
      ),
    });
  }

  Map<String, MetricFields> get metrics =>
      (data['metrics'] as Map<Object?, Object?>).cast<String, MetricFields>();

  Map<String, String> get values => <String, String>{
    for (final MapEntry<String, MetricFields> item in metrics.entries)
      item.key: item.value['value'] as String,
  };

  String label(String id) =>
      metrics[id]?['title'] as String? ?? StickerLayout.titles[id] ?? id;
  String get emptyLabel => data['emptyLabel'] as String;
  String? get fallback => data['fallback'] as String?;
  StickerMode get mode => StickerMode.read(data['mode']);

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
}
