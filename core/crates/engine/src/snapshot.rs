use crate::{
    calendar::Calendar,
    contract::{HolidayData, SCHEMA_VERSION, Settings},
    metrics::{self, Clock},
    validation::{error, parse_settings},
};
use jiff::{Timestamp, civil::Date, tz::TimeZone};
use serde::Serialize;
use serde_json::json;
use std::str::FromStr;

pub fn default_settings() -> String {
    serde_json::to_string(&Settings::default()).expect("固定默认结构可序列化")
}

pub fn validate_settings(settings_json: &str) -> String {
    match parse_settings(settings_json) {
        Ok(settings) => json!({"ok":true,"settings":settings,"errors":[]}).to_string(),
        Err(errors) => json!({"ok":false,"errors":errors}).to_string(),
    }
}

/// 所有时间由调用端显式传入，UI、原生小组件不会复制日历规则。
pub fn compute_snapshot(settings_json: &str, holiday_json: &str, now_millis: i64) -> String {
    match compute(settings_json, holiday_json, now_millis) {
        Ok(snapshot) => json!({"ok":true,"snapshot":snapshot,"errors":[]}).to_string(),
        Err((field, code)) => json!({"ok":false,"errors":[error(field,code)]}).to_string(),
    }
}

#[derive(Serialize)]
struct Snapshot {
    schema_version: u32,
    computed_at_millis: i64,
    local_date: String,
    time_zone: String,
    is_workday: bool,
    calendar_status: &'static str,
    next_change_at_millis: i64,
    unavailable_metrics: [&'static str; 1],
    #[serde(flatten)]
    metrics: metrics::Metrics,
}

fn compute(
    settings_json: &str,
    holiday_json: &str,
    now_millis: i64,
) -> Result<Snapshot, (&'static str, &'static str)> {
    let settings = parse_settings(settings_json).map_err(|_| ("settings", "invalid_settings"))?;
    let holidays: HolidayData =
        serde_json::from_str(holiday_json).map_err(|_| ("holiday_data", "invalid_json"))?;
    if holidays.schema_version != 0 && holidays.schema_version != SCHEMA_VERSION {
        return Err(("holiday_data", "unsupported_version"));
    }
    if holidays
        .date_overrides
        .keys()
        .any(|s| Date::from_str(s).is_err())
    {
        return Err(("holiday_data", "invalid_date"));
    }
    let zone =
        TimeZone::get(&settings.time_zone).map_err(|_| ("time_zone", "invalid_time_zone"))?;
    let timestamp =
        Timestamp::from_millisecond(now_millis).map_err(|_| ("now", "invalid_timestamp"))?;
    let clock = Clock(timestamp.to_zoned(zone));
    let date = clock.date();
    let calendar = Calendar::new(&settings, &holidays);
    let next_midnight = clock.next_day_boundary().ok_or(("now", "out_of_range"))?;
    let (metrics, next_change_at_millis) =
        metrics::compute(&settings, &calendar, &clock, next_midnight);
    Ok(Snapshot {
        schema_version: SCHEMA_VERSION,
        computed_at_millis: now_millis,
        local_date: date.to_string(),
        time_zone: settings.time_zone,
        is_workday: calendar.is_workday(date),
        calendar_status: calendar.status(date),
        next_change_at_millis,
        unavailable_metrics: ["salary"],
        metrics,
    })
}
