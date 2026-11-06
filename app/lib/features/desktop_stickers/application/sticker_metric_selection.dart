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

  /// 今日已赚和生命指标的稳定标识。
  static const String todaySalaryId = 'today_salary';
  static const String lifeId = 'life';

  /// 在倒计时和完整设置中共用同一开关的指标。
  static const List<String> sharedVisibilityIds = <String>[
    todaySalaryId,
    lifeId,
  ];

  static const List<String> _standardOrder = <String>[
    'work',
    todaySalaryId,
    'month_salary',
    'payday',
    'holiday',
    'retirement',
    lifeId,
  ];

  /// 完整设置保存的启用项，旧设置使用迷你浮窗默认项。
  List<String> get enabledMetrics =>
      _list(controller.displaySettings['enabled_metrics']) ??
      defaultMetricOrder.take(5).toList();

  Iterable<String> get enabledSharedMetrics =>
      sharedVisibilityIds.where(enabledMetrics.contains);

  List<String> get ids {
    final List<String> enabled = enabledMetrics;
    if (layout.preview) {
      return <String>[
        ...layout.enabled,
        ...sharedVisibilityIds.where(enabled.contains),
      ];
    }
    final Map<String, dynamic> display = controller.displaySettings;
    final List<String> order =
        _list(display['metric_order']) ?? defaultMetricOrder;
    // 单独切换共用开关时，标准和展开保留其余默认指标。
    final bool custom =
        display['metrics_customized'] == true ||
        !listEquals(order, defaultMetricOrder) ||
        !listEquals(
          enabled.where(_otherMetric).toList(),
          defaultMetricOrder.take(5).where(_otherMetric).toList(),
        );
    final List<String> defaults = !custom && layout.mode != StickerMode.mini
        ? <String>[
            for (final String id in _standardOrder)
              if (_otherMetric(id) || enabled.contains(id)) id,
          ]
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

  static bool _otherMetric(String id) => !sharedVisibilityIds.contains(id);

  List<String>? _list(Object? value) =>
      (value as List<Object?>?)?.cast<String>();
}
