/// 所有端使用统一默认配置。
pub fn default_settings() -> String {
    shiyu_core::default_settings()
}

/// 校验输入并规范化版本化设置。
pub fn validate_settings(settings_json: String) -> String {
    shiyu_core::validate_settings(&settings_json)
}

/// 计算退休与基础日历快照，时间始终显式传入。
pub fn compute_snapshot(settings_json: String, holiday_json: String, now_millis: i64) -> String {
    shiyu_core::compute_snapshot(&settings_json, &holiday_json, now_millis)
}

/// 批量计算固定起点、步长和数量的快照。
pub fn compute_timeline(
    settings_json: String,
    holiday_json: String,
    start_millis: i64,
    step_seconds: i64,
    count: i64,
) -> String {
    shiyu_core::compute_timeline(
        &settings_json,
        &holiday_json,
        start_millis,
        step_seconds,
        count,
    )
}

/// 校验创建、编辑或删除自定义倒计时，返回新的设置 JSON。
pub fn update_custom_countdown(
    settings_json: String,
    change_json: String,
    now_millis: i64,
) -> String {
    shiyu_core::update_custom_countdown(&settings_json, &change_json, now_millis)
}
