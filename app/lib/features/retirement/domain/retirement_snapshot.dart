class RetirementSnapshot {
  RetirementSnapshot.fromJson(Map<String, dynamic> json)
    : status = (json['retirement'] as Map<String, dynamic>)['status'] as String,
      days =
          (json['retirement'] as Map<String, dynamic>)['remaining_days'] as int,
      seconds =
          (json['retirement'] as Map<String, dynamic>)['remaining_seconds']
              as int,
      workday = json['is_workday'] as bool,
      data = Map<String, dynamic>.unmodifiable(json);

  /// Rust 给出的配置/计时/到期状态。
  final String status;

  /// Rust 按日历日期计算的剩余天数。
  final int days;

  /// Rust 按绝对时间计算的非负剩余秒数。
  final int seconds;

  /// 当前配置时区内是否为工作日。
  final bool workday;

  /// 完整核心结果，供后续指标与设置页直接呈现。
  final Map<String, dynamic> data;

  String get calendarStatus =>
      data['calendar_status'] as String? ?? 'weekly_fallback';
  int? get nextChangeAtMillis => data['next_change_at_millis'] as int?;

  /// 活跃倒计时和计薪中按秒更新，其它状态等待业务边界。
  bool get changesEverySecond {
    for (final String key in <String>[
      'life',
      'retirement',
      'work',
      'payday',
      'holiday',
    ]) {
      if (_counting(data[key])) return true;
    }
    final Object? custom = data['custom_countdowns'];
    if (custom is List<dynamic> && custom.any(_counting)) return true;
    final Object? salary = data['salary'];
    return salary is Map<String, dynamic> && salary['status'] == 'earning';
  }

  bool _counting(Object? value) =>
      value is Map<String, dynamic> &&
      value['enabled'] != false &&
      (value['remaining_seconds'] as int? ?? 0) > 0;
}
