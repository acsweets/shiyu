use crate::snapshot::{SnapshotContext, SnapshotError, error_reply};

/// 限制单次调用的采样数量与响应体积。
const MAX_ENTRIES: i64 = 1440;
const MAX_RESPONSE_BYTES: usize = 8 * 1024 * 1024;

/// 从显式起点等间隔计算，整个批次共享配置且不读取系统时间。
pub fn compute_timeline(
    settings_json: &str,
    holiday_json: &str,
    start_millis: i64,
    step_seconds: i64,
    count: i64,
) -> String {
    timeline(
        settings_json,
        holiday_json,
        start_millis,
        step_seconds,
        count,
    )
    .unwrap_or_else(error_reply)
}

fn timeline(
    settings_json: &str,
    holiday_json: &str,
    start_millis: i64,
    step_seconds: i64,
    count: i64,
) -> Result<String, SnapshotError> {
    if !(1..=MAX_ENTRIES).contains(&count) {
        return Err(("count", "invalid_count"));
    }
    if step_seconds <= 0 {
        return Err(("step_seconds", "invalid_step"));
    }
    let step = step_seconds
        .checked_mul(1000)
        .ok_or(("timeline", "out_of_range"))?;
    let span = (count - 1)
        .checked_mul(step)
        .ok_or(("timeline", "out_of_range"))?;
    start_millis
        .checked_add(span)
        .ok_or(("timeline", "out_of_range"))?;
    let context = SnapshotContext::new(settings_json, holiday_json)?;
    let mut output = br#"{"ok":true,"snapshots":["#.to_vec();
    let suffix = br#"],"errors":[]}"#;
    for index in 0..count {
        if index > 0 {
            output.push(b',');
        }
        let snapshot = context.compute(start_millis + index * step)?;
        serde_json::to_writer(&mut output, &snapshot).expect("快照可以序列化到内存");
        if output.len() > MAX_RESPONSE_BYTES - suffix.len() {
            return Err(("timeline", "too_large"));
        }
    }
    output.extend(suffix);
    Ok(String::from_utf8(output).expect("JSON 编码为 UTF-8"))
}
