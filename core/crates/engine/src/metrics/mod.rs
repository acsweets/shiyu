mod clock;
mod holiday;
mod life;
mod payday;
mod work;

use crate::{calendar::Calendar, contract::Settings};
use jiff::civil::{Date, Time};
use serde::Serialize;

pub(crate) use clock::Clock;
use clock::{CalendarRemaining, Countdown};

#[derive(Serialize)]
pub(crate) struct Metrics {
    life: Countdown,
    work: work::Work,
    retirement: Countdown,
    payday: payday::PaydayMetric,
    holiday: holiday::HolidayMetric,
    calendar_remaining: CalendarBreakdown,
}

#[derive(Serialize)]
struct CalendarBreakdown {
    life: Option<CalendarRemaining>,
    retirement: Option<CalendarRemaining>,
}

/// 装配所有已实现时间指标，输出最近一个结构性状态变化时刻。
pub(crate) fn compute(
    settings: &Settings,
    calendar: &Calendar,
    clock: &Clock,
    next_midnight: i64,
) -> (Metrics, i64) {
    let life = life::compute(clock, settings.birth.as_ref());
    let work = work::compute(clock, calendar, &settings.schedule);
    let retirement = retirement(clock, settings.retirement_date.as_deref());
    let payday = payday::compute(clock, calendar, settings.payday.as_ref());
    let end: Time = settings.schedule.end.parse().expect("下班时间已校验");
    let holiday = holiday::compute(clock, calendar, settings.weekly_rest_as_holiday, end);
    let next_change = [
        life.target_millis,
        work.next_boundary,
        retirement.target_millis,
        payday.countdown.target_millis,
        holiday.countdown.target_millis,
    ]
    .into_iter()
    .flatten()
    .filter(|target| *target > clock.millis())
    .fold(next_midnight, i64::min);
    let calendar_remaining = CalendarBreakdown {
        life: clock.calendar_remaining(life.target_millis, false),
        retirement: clock.calendar_remaining(retirement.target_millis, true),
    };
    (
        Metrics {
            life,
            work,
            retirement,
            payday,
            holiday,
            calendar_remaining,
        },
        next_change,
    )
}

fn retirement(clock: &Clock, date: Option<&str>) -> Countdown {
    let Some(date) = date else {
        return clock.countdown("unconfigured", None);
    };
    let date: Date = date.parse().expect("退休日期已校验");
    let target = clock.retirement_target(date).expect("退休午夜已校验");
    let status = if target <= clock.millis() {
        "retired"
    } else {
        "active"
    };
    clock.countdown(status, Some(target))
}
