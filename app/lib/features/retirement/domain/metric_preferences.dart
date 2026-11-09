/// 今日已赚在显示配置和快照中共用的标识。
const String todaySalaryId = 'today_salary';

/// 默认排序与核心的显示配置保持一致。
const List<String> defaultMetricOrder = <String>[
  'work',
  todaySalaryId,
  'holiday',
  'life',
  'retirement',
  'month_salary',
  'payday',
];

/// 兼容未保存显示偏好的旧配置。
List<String> enabledMetricIds(Map<String, dynamic> display) =>
    (display['enabled_metrics'] as List<Object?>?)?.cast<String>() ??
    defaultMetricOrder.take(5).toList();
