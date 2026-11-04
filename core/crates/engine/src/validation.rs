use crate::contract::{FieldError, PaydayRule, SCHEMA_VERSION, SalaryBasis, Settings};
use jiff::{
    civil::{Date, DateTime, Time},
    tz::TimeZone,
};
use rust_decimal::Decimal;
use std::{collections::BTreeSet, str::FromStr};

pub fn error(field: &str, code: &str) -> FieldError {
    FieldError {
        field: field.into(),
        code: code.into(),
    }
}

/// 校验字段而不泄漏个人原始值；拒绝未来 schema 和未知字段。
pub fn parse_settings(json: &str) -> Result<Settings, Vec<FieldError>> {
    if json.len() > 131_072 {
        return Err(vec![error("settings", "too_large")]);
    }
    let settings: Settings =
        serde_json::from_str(json).map_err(|_| vec![error("settings", "invalid_json")])?;
    let mut errors = vec![];
    if settings.schema_version != SCHEMA_VERSION {
        errors.push(error("schema_version", "unsupported_version"));
    }
    if TimeZone::get(&settings.time_zone).is_err() {
        errors.push(error("time_zone", "invalid_time_zone"));
    }
    if !["CN", "US", "JP", "KR", "HK", "TW"].contains(&settings.region.as_str()) {
        errors.push(error("region", "unsupported_region"));
    }
    if let Some(date) = &settings.retirement_date {
        match Date::from_str(date) {
            Err(_) => errors.push(error("retirement_date", "invalid_date")),
            Ok(date) => {
                if let Ok(zone) = TimeZone::get(&settings.time_zone)
                    && zone
                        .to_ambiguous_zoned(date.at(0, 0, 0, 0))
                        .unambiguous()
                        .is_err()
                {
                    errors.push(error("retirement_date", "ambiguous_local_time"));
                }
            }
        }
    }
    let schedule = &settings.schedule;
    if schedule.workdays.iter().any(|d| !(1..=7).contains(d))
        || schedule.workdays.iter().collect::<BTreeSet<_>>().len() != schedule.workdays.len()
    {
        errors.push(error("schedule.workdays", "invalid_workdays"));
    }
    match (
        Time::from_str(&schedule.start),
        Time::from_str(&schedule.end),
    ) {
        (Ok(start), Ok(end)) if start < end => {
            if let Some(lunch) = &schedule.lunch {
                match (Time::from_str(&lunch[0]), Time::from_str(&lunch[1])) {
                    (Ok(a), Ok(b)) if start <= a && a < b && b <= end => {}
                    _ => errors.push(error("schedule.lunch", "invalid_lunch")),
                }
            }
        }
        _ => errors.push(error("schedule", "invalid_work_hours")),
    }
    if let Some(birth) = &settings.birth {
        if Date::from_str(&birth.date).is_err() {
            errors.push(error("birth.date", "invalid_date"));
        }
        if birth
            .time
            .as_ref()
            .is_some_and(|s| Time::from_str(s).is_err())
        {
            errors.push(error("birth.time", "invalid_time"));
        }
        match Decimal::from_str(&birth.life_expectancy_years) {
            Ok(years)
                if years >= Decimal::ONE
                    && years <= Decimal::from(150)
                    && years.normalize().scale() <= 1 => {}
            _ => errors.push(error("birth.life_expectancy_years", "invalid_lifespan")),
        }
    }
    if let Some(salary) = &settings.salary {
        for value in std::iter::once(&salary.gross_monthly).chain(salary.net_monthly.iter()) {
            if Decimal::from_str(value).map_or(true, |d| d < Decimal::ZERO) {
                errors.push(error("salary", "invalid_amount"));
            }
        }
        if !(2..=4).contains(&salary.precision) {
            errors.push(error("salary.precision", "invalid_precision"));
        }
        if salary.currency.len() != 3 || !salary.currency.bytes().all(|c| c.is_ascii_uppercase()) {
            errors.push(error("salary.currency", "invalid_currency"));
        }
        if matches!(salary.basis, SalaryBasis::Net) && salary.net_monthly.is_none() {
            errors.push(error("salary.basis", "net_salary_required"));
        }
    }
    if let Some(payday) = &settings.payday {
        let count = match payday.rule {
            PaydayRule::FixedDay => 1,
            PaydayRule::LastWorkday => 0,
            PaydayRule::TwiceMonthly => 2,
        };
        if payday.days.len() != count
            || payday.days.iter().any(|day| !(1..=31).contains(day))
            || payday.days.iter().collect::<BTreeSet<_>>().len() != count
        {
            errors.push(error("payday.days", "invalid_paydays"));
        }
    }
    if settings
        .date_overrides
        .keys()
        .any(|d| Date::from_str(d).is_err())
    {
        errors.push(error("date_overrides", "invalid_date"));
    }
    for holiday in &settings.holidays {
        match (Date::from_str(&holiday.start), Date::from_str(&holiday.end)) {
            (Ok(a), Ok(b)) if a <= b && !holiday.name.trim().is_empty() => {}
            _ => errors.push(error("holidays", "invalid_holiday")),
        }
    }
    let mut ids = BTreeSet::new();
    for item in &settings.custom_countdowns {
        if item.id.is_empty()
            || !ids.insert(&item.id)
            || item.name.trim().is_empty()
            || DateTime::from_str(&item.target).is_err()
        {
            errors.push(error("custom_countdowns", "invalid_countdown"));
        }
    }
    if errors.is_empty() {
        Ok(settings)
    } else {
        Err(errors)
    }
}
