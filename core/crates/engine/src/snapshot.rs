use crate::{
    calendar,
    contract::{HolidayData, SCHEMA_VERSION, Settings},
    validation::{error, parse_settings},
};
use jiff::{Timestamp, civil::Date, tz::TimeZone};
use serde_json::{Value, json};
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

fn compute(
    settings_json: &str,
    holiday_json: &str,
    now_millis: i64,
) -> Result<Value, (&'static str, &'static str)> {
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
    let now = Timestamp::from_millisecond(now_millis)
        .map_err(|_| ("now", "invalid_timestamp"))?
        .to_zoned(zone.clone());
    let date = now.date();
    let (is_workday, calendar_status) = calendar::workday(&settings, &holidays, date);
    let tomorrow = date
        .checked_add(jiff::Span::new().days(1))
        .map_err(|_| ("now", "out_of_range"))?;
    let next_midnight = zone
        .to_ambiguous_zoned(tomorrow.at(0, 0, 0, 0))
        .unambiguous()
        .map_err(|_| ("now", "ambiguous_local_time"))?
        .timestamp()
        .as_millisecond();
    let retirement = if let Some(value) = &settings.retirement_date {
        let target_date = Date::from_str(value).map_err(|_| ("retirement_date", "invalid_date"))?;
        let target = zone
            .to_ambiguous_zoned(target_date.at(0, 0, 0, 0))
            .unambiguous()
            .map_err(|_| ("retirement_date", "ambiguous_local_time"))?
            .timestamp()
            .as_millisecond();
        let seconds = ((target - now_millis).max(0) + 999) / 1000;
        let days = date
            .until(target_date)
            .map_err(|_| ("retirement_date", "out_of_range"))?
            .get_days()
            .max(0);
        json!({"status":if target<=now_millis {"retired"} else {"active"},"target_millis":target,"remaining_seconds":seconds,"remaining_days":days})
    } else {
        json!({"status":"unconfigured","target_millis":null,"remaining_seconds":0,"remaining_days":0})
    };
    let next_change = retirement["target_millis"]
        .as_i64()
        .filter(|t| *t > now_millis)
        .map_or(next_midnight, |t| t.min(next_midnight));
    Ok(
        json!({"schema_version":SCHEMA_VERSION,"computed_at_millis":now_millis,"local_date":date.to_string(),"time_zone":settings.time_zone,"is_workday":is_workday,"calendar_status":calendar_status,"next_change_at_millis":next_change,"retirement":retirement,"unavailable_metrics":["life","work","salary","payday","holiday"]}),
    )
}
