use crate::{
    calendar::Calendar,
    contract::{HolidayData, SCHEMA_VERSION, Settings},
    metrics::{self, Clock},
    validation::{error, parse_settings},
};
use jiff::{Timestamp, civil::Date, tz::TimeZone};
use serde::Serialize;
use serde_json::json;

pub(crate) type SnapshotError = (&'static str, &'static str);

pub fn default_settings() -> String {
    serde_json::to_string(&Settings::default()).expect("固定默认结构可序列化")
}

pub fn validate_settings(settings_json: &str) -> String {
    match parse_settings(settings_json) {
        Ok(settings) => json!({"ok":true,"settings":settings,"errors":[]}).to_string(),
        Err(errors) => json!({"ok":false,"errors":errors}).to_string(),
    }
}

pub(crate) fn error_reply((field, code): SnapshotError) -> String {
    json!({"ok":false,"errors":[error(field,code)]}).to_string()
}

/// 所有时间由调用端显式传入，UI、原生小组件不会复制日历规则。
pub fn compute_snapshot(settings_json: &str, holiday_json: &str, now_millis: i64) -> String {
    let result = SnapshotContext::new(settings_json, holiday_json).and_then(|context| {
        let snapshot = context.compute(now_millis)?;
        Ok(serde_json::to_string(&SnapshotReply {
            ok: true,
            snapshot,
            errors: [],
        })
        .expect("快照可以序列化"))
    });
    result.unwrap_or_else(error_reply)
}

#[derive(Serialize)]
struct SnapshotReply<'a> {
    ok: bool,
    snapshot: Snapshot<'a>,
    errors: [(); 0],
}

#[derive(Serialize)]
pub(crate) struct Snapshot<'a> {
    schema_version: u32,
    computed_at_millis: i64,
    local_date: String,
    time_zone: &'a str,
    is_workday: bool,
    calendar_status: &'static str,
    next_change_at_millis: i64,
    unavailable_metrics: [&'static str; 0],
    #[serde(flatten)]
    metrics: metrics::Metrics<'a>,
}

/// 时间线中的所有采样共用同一份校验后的输入与工作日历。
pub(crate) struct SnapshotContext {
    settings: Settings,
    calendar: Calendar,
    zone: TimeZone,
}

impl SnapshotContext {
    pub(crate) fn new(settings_json: &str, holiday_json: &str) -> Result<Self, SnapshotError> {
        let settings =
            parse_settings(settings_json).map_err(|_| ("settings", "invalid_settings"))?;
        let holidays: HolidayData =
            serde_json::from_str(holiday_json).map_err(|_| ("holiday_data", "invalid_json"))?;
        if holidays.schema_version != 0 && holidays.schema_version != SCHEMA_VERSION {
            return Err(("holiday_data", "unsupported_version"));
        }
        if holidays
            .date_overrides
            .keys()
            .any(|date| date.parse::<Date>().is_err())
        {
            return Err(("holiday_data", "invalid_date"));
        }
        let zone =
            TimeZone::get(&settings.time_zone).map_err(|_| ("time_zone", "invalid_time_zone"))?;
        let calendar = Calendar::new(&settings, &holidays);
        Ok(Self {
            settings,
            calendar,
            zone,
        })
    }

    pub(crate) fn compute(&self, now_millis: i64) -> Result<Snapshot<'_>, SnapshotError> {
        let timestamp =
            Timestamp::from_millisecond(now_millis).map_err(|_| ("now", "invalid_timestamp"))?;
        let clock = Clock(timestamp.to_zoned(self.zone.clone()));
        let date = clock.date();
        let next_midnight = clock.next_day_boundary().ok_or(("now", "out_of_range"))?;
        let (metrics, next_change_at_millis) =
            metrics::compute(&self.settings, &self.calendar, &clock, next_midnight);
        Ok(Snapshot {
            schema_version: SCHEMA_VERSION,
            computed_at_millis: now_millis,
            local_date: date.to_string(),
            time_zone: &self.settings.time_zone,
            is_workday: self.calendar.is_workday(date),
            calendar_status: self.calendar.status(date),
            next_change_at_millis,
            unavailable_metrics: [],
            metrics,
        })
    }
}
