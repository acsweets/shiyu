use crate::contract::{HolidayData, SCHEMA_VERSION, Settings};
use jiff::civil::Date;

/// 覆盖优先级：个人日期 > 自定义假期 > 地区日期覆盖 > 每周工作日。
pub fn workday(settings: &Settings, holidays: &HolidayData, date: Date) -> (bool, &'static str) {
    let key = date.to_string();
    let covered = holidays.schema_version == SCHEMA_VERSION
        && holidays.region == settings.region
        && holidays.years.contains(&date.year());
    let status = if covered {
        "available"
    } else {
        "weekly_fallback"
    };
    if let Some(value) = settings.date_overrides.get(&key) {
        return (*value, status);
    }
    for period in &settings.holidays {
        if period.start <= key && key <= period.end {
            return (false, status);
        }
    }
    if covered && let Some(value) = holidays.date_overrides.get(&key) {
        return (*value, status);
    }
    (
        settings
            .schedule
            .workdays
            .contains(&(date.weekday().to_monday_one_offset() as u8)),
        status,
    )
}
