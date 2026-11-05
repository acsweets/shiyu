use super::{Clock, Countdown};
use crate::calendar::Calendar;
use jiff::civil::{Date, Time};
use serde::Serialize;

#[derive(Serialize)]
pub(super) struct HolidayMetric {
    #[serde(flatten)]
    pub(super) countdown: Countdown,
    interval: Option<RestInterval>,
    next_interval: Option<RestInterval>,
}

/// 日期端点描述连续休息日，时刻端点描述用户实际看到的放假期间。
#[derive(Serialize)]
struct RestInterval {
    first_rest_date: Option<String>,
    last_rest_date: Option<String>,
    start_millis: Option<i64>,
    end_millis: Option<i64>,
}

pub(super) fn compute(
    clock: &Clock,
    calendar: &Calendar,
    include_weekly: bool,
    end: Time,
) -> HolidayMetric {
    let date = clock.date();
    let search_from = if calendar.is_workday(date) {
        date
    } else {
        calendar
            .previous_workday(date)
            .and_then(|day| day.tomorrow().ok())
            .unwrap_or(Date::MIN)
    };
    let Some((interval, following_workday)) =
        interval_at_or_after(clock, calendar, search_from, include_weekly, end)
    else {
        return HolidayMetric {
            countdown: clock.countdown("no_target", None),
            interval: None,
            next_interval: None,
        };
    };
    let active = interval
        .start_millis
        .is_none_or(|start| start <= clock.millis());
    let (status, target, next_interval) = if active {
        let next = following_workday.and_then(|date| {
            interval_at_or_after(clock, calendar, date, include_weekly, end).map(|(next, _)| next)
        });
        ("on_holiday", interval.end_millis, next)
    } else {
        ("upcoming", interval.start_millis, None)
    };
    HolidayMetric {
        countdown: clock.countdown(status, target),
        interval: Some(interval),
        next_interval,
    }
}

fn interval_at_or_after(
    clock: &Clock,
    calendar: &Calendar,
    date: Date,
    include_weekly: bool,
    end: Time,
) -> Option<(RestInterval, Option<Date>)> {
    // 关闭每周休息时，纯周休不入选；显式休假相连的休息日仍合成同一段。
    let seed = calendar.next_rest(date, include_weekly)?;
    let prior = calendar.previous_workday(seed);
    let following = calendar.next_workday(seed);
    let interval = RestInterval {
        first_rest_date: prior
            .and_then(|day| day.tomorrow().ok())
            .map(|day| day.to_string()),
        last_rest_date: following
            .and_then(|day| day.yesterday().ok())
            .map(|day| day.to_string()),
        start_millis: prior.and_then(|day| clock.resolve(day.to_datetime(end))),
        end_millis: following.and_then(|day| clock.resolve(day.at(0, 0, 0, 0))),
    };
    Some((interval, following))
}
