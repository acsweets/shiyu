import 'package:flutter/foundation.dart';

import '../../retirement/application/retirement_controller.dart';
import '../../retirement/presentation/metrics/snapshot_metrics.dart';
import '../../retirement/presentation/settings/display_settings.dart';
import '../data/sticker_layout.dart';
import '../data/sticker_mode.dart';

/// 把显示偏好和分组组合，窗口仅接收自己的指标。
class StickerMetricSelection {
  StickerMetricSelection(this.layout, this.controller);

  final StickerLayout layout;
  final RetirementController controller;

  static const List<String> _standardOrder = <String>[
    'work',
    'today_salary',
    'month_salary',
    'payday',
    'holiday',
    'retirement',
    'life',
  ];

  List<String> get ids {
    if (layout.preview) return layout.enabled.toList();
    final Map<String, dynamic> display = controller.displaySettings;
    final List<String> order =
        _list(display['metric_order']) ?? defaultMetricOrder;
    final List<String> enabled =
        _list(display['enabled_metrics']) ??
        defaultMetricOrder.take(5).toList();
    final bool custom =
        display['metrics_customized'] == true ||
        !listEquals(order, defaultMetricOrder) ||
        !listEquals(enabled, defaultMetricOrder.take(5).toList());
    final List<String> defaults = !custom && layout.mode != StickerMode.mini
        ? _standardOrder
        : order.where(enabled.contains).toList();
    final List<Object?> raw =
        controller.snapshot?.data['custom_countdowns'] as List<Object?>? ??
        const <Object?>[];
    return <String>[
      for (final String id in defaults)
        if (!StickerLayout.titles.containsKey(id) ||
            layout.enabled.contains(id))
          id,
      for (final MetricFields item in raw.whereType<MetricFields>())
        if (item['enabled'] != false) 'custom/${item['id']}',
    ];
  }

  List<String> group(int slot) =>
      ids.where((String id) => layout.groupOf(id) == slot).toList();

  Set<int> get activeGroups => <int>{
    layout.mainGroup,
    ...ids.map(layout.groupOf),
  };

  bool get hasVisibleMetrics =>
      ids.any((String id) => layout.showsGroup(layout.groupOf(id)));

  List<String>? _list(Object? value) =>
      (value as List<Object?>?)?.cast<String>();
}
