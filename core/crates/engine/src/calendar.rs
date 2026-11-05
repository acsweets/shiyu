use crate::contract::{HolidayData, SCHEMA_VERSION, Settings};
use jiff::civil::Date;
use std::{
    collections::{BTreeMap, BTreeSet},
    ops::Bound::{Excluded, Included, Unbounded},
};

/// 日期的最终判定来源，用于区分每周休息和显式休息。
#[derive(Clone, Copy)]
enum Day {
    Work,
    WeeklyRest,
    ExplicitRest,
}

/// 时间指标共享工作日优先级；稀疏覆盖和长假不必逐日扫描。
pub(crate) struct Calendar {
    /// 合并地区和个人覆盖之前的分层数据。
    personal: BTreeMap<Date, bool>,
    regional: BTreeMap<Date, bool>,
    /// 排序合并后的自定义假期，端点均包含。
    holidays: Vec<(Date, Date)>,
    /// 地区数据实际覆盖的年份。
    years: BTreeSet<i16>,
    /// ISO 星期编号。
    workdays: Vec<u8>,
    /// 覆盖进入和退出的日期。
    changes: BTreeSet<Date>,
}

impl Calendar {
    pub(crate) fn new(settings: &Settings, holidays: &HolidayData) -> Self {
        let years: BTreeSet<_> =
            if holidays.schema_version == SCHEMA_VERSION && holidays.region == settings.region {
                holidays.years.iter().copied().collect()
            } else {
                BTreeSet::new()
            };
        let personal = parse_overrides(&settings.date_overrides);
        let mut regional = parse_overrides(&holidays.date_overrides);
        regional.retain(|date, _| years.contains(&date.year()));
        let holidays = merge_holidays(settings);
        let mut changes = BTreeSet::new();
        for date in personal.keys().chain(regional.keys()) {
            changes.insert(*date);
            changes.extend(date.tomorrow().ok());
        }
        for &(start, end) in &holidays {
            changes.insert(start);
            changes.extend(end.tomorrow().ok());
        }
        Self {
            personal,
            regional,
            holidays,
            years,
            workdays: settings.schedule.workdays.clone(),
            changes,
        }
    }

    /// 个人日期 > 自定义假期 > 地区日期 > 工作周。
    fn day(&self, date: Date) -> Day {
        if let Some(&working) = self.personal.get(&date) {
            return override_day(working);
        }
        let index = self.holidays.partition_point(|&(start, _)| start <= date);
        if index > 0 && date <= self.holidays[index - 1].1 {
            return Day::ExplicitRest;
        }
        if let Some(&working) = self.regional.get(&date) {
            return override_day(working);
        }
        if self
            .workdays
            .contains(&(date.weekday().to_monday_one_offset() as u8))
        {
            Day::Work
        } else {
            Day::WeeklyRest
        }
    }

    pub(crate) fn is_workday(&self, date: Date) -> bool {
        matches!(self.day(date), Day::Work)
    }

    pub(crate) fn status(&self, date: Date) -> &'static str {
        if self.years.contains(&date.year()) {
            "available"
        } else {
            "weekly_fallback"
        }
    }

    pub(crate) fn next_workday(&self, date: Date) -> Option<Date> {
        self.find(date, true, |day| matches!(day, Day::Work))
    }

    pub(crate) fn previous_workday(&self, date: Date) -> Option<Date> {
        self.find(date, false, |day| matches!(day, Day::Work))
    }

    pub(crate) fn next_rest(&self, date: Date, include_weekly: bool) -> Option<Date> {
        self.find(date, true, |day| match day {
            Day::ExplicitRest => true,
            Day::WeeklyRest => include_weekly,
            Day::Work => false,
        })
    }

    /// 固定覆盖状态的一段最多检查一周；整周无匹配就跳到下一段。
    fn find(&self, mut date: Date, forward: bool, matches: impl Fn(Day) -> bool) -> Option<Date> {
        loop {
            let boundary = if forward {
                self.changes
                    .range((Excluded(date), Unbounded))
                    .next()
                    .copied()
            } else {
                self.changes
                    .range((Unbounded, Included(date)))
                    .next_back()
                    .and_then(|date| date.yesterday().ok())
            };
            for _ in 0..7 {
                if matches(self.day(date)) {
                    return Some(date);
                }
                date = if forward {
                    date.tomorrow()
                } else {
                    date.yesterday()
                }
                .ok()?;
                if Some(date) == boundary {
                    break;
                }
            }
            date = boundary?;
        }
    }
}

fn override_day(working: bool) -> Day {
    if working {
        Day::Work
    } else {
        Day::ExplicitRest
    }
}

fn parse_overrides(overrides: &BTreeMap<String, bool>) -> BTreeMap<Date, bool> {
    overrides
        .iter()
        .map(|(date, &working)| (date.parse().expect("日期已校验"), working))
        .collect()
}

fn merge_holidays(settings: &Settings) -> Vec<(Date, Date)> {
    let mut ranges: Vec<(Date, Date)> = settings
        .holidays
        .iter()
        .map(|range| {
            (
                range.start.parse().expect("开始日期已校验"),
                range.end.parse().expect("结束日期已校验"),
            )
        })
        .collect();
    ranges.sort_unstable();
    let mut merged: Vec<(Date, Date)> = Vec::new();
    for (start, end) in ranges {
        if let Some(last) = merged.last_mut()
            && start <= last.1.tomorrow().unwrap_or(Date::MAX)
        {
            last.1 = last.1.max(end);
        } else {
            merged.push((start, end));
        }
    }
    merged
}
