class RetirementSnapshot {
  RetirementSnapshot.fromJson(Map<String, dynamic> json)
    : status = (json['retirement'] as Map<String, dynamic>)['status'] as String,
      days =
          (json['retirement'] as Map<String, dynamic>)['remaining_days'] as int,
      seconds =
          (json['retirement'] as Map<String, dynamic>)['remaining_seconds']
              as int,
      workday = json['is_workday'] as bool;

  /// Rust 给出的配置/计时/到期状态。
  final String status;

  /// Rust 按日历日期计算的剩余天数。
  final int days;

  /// Rust 按绝对时间计算的非负剩余秒数。
  final int seconds;

  /// 当前配置时区内是否为工作日。
  final bool workday;
}
