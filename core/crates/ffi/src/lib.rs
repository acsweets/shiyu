//! 原生小组件的 UniFFI 门面，与 Flutter 共享同一个计算核心。

uniffi::setup_scaffolding!();

/// 验证原生调用链，不访问网络、配置或个人数据。
#[uniffi::export]
pub fn bridge_probe(challenge: u32) -> String {
    shiyu_core::bridge_probe(challenge)
}

/// 生成初始配置，首次运行不设置任何虚构目标。
#[uniffi::export]
pub fn default_settings() -> String {
    shiyu_core::default_settings()
}

/// 校验配置并返回不含敏感原值的字段错误。
#[uniffi::export]
pub fn validate_settings(settings_json: String) -> String {
    shiyu_core::validate_settings(&settings_json)
}

/// 原生小组件独立计算快照，不依赖 Flutter 引擎。
#[uniffi::export]
pub fn compute_snapshot(settings_json: String, holiday_json: String, now_millis: i64) -> String {
    shiyu_core::compute_snapshot(&settings_json, &holiday_json, now_millis)
}

/// 原生宿主按固定起点和步长生成有界时间线。
#[uniffi::export]
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

/// 校验并返回内存中的自定义倒计时配置变更。
#[uniffi::export]
pub fn update_custom_countdown(
    settings_json: String,
    change_json: String,
    now_millis: i64,
) -> String {
    shiyu_core::update_custom_countdown(&settings_json, &change_json, now_millis)
}
