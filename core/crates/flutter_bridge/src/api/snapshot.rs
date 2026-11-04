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
