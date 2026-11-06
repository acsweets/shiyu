mod clock;
mod custom;
mod holiday;
mod life;
mod payday;
mod salary;
mod schedule;
mod work;

use crate::{calendar::Calendar, contract::Settings};
use jiff::civil::Date;
use schedule::WorkSchedule;
use serde::Serialize;

pub(crate) use clock::Clock;
use clock::{CalendarRemaining, Countdown};

#[derive(Serialize)]
pub(crate) struct Metrics<'a> {
    life: life::LifeMetric,
    work: work::Work,
    retirement: Countdown,
    payday: payday::PaydayMetric,
    holiday: holiday::HolidayMetric,
    calendar_remaining: CalendarBreakdown,
    salary: salary::SalaryMetric<'a>,
    custom_countdowns: Vec<custom::CustomMetric<'a>>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    hidden_metric_titles: &'a Vec<String>,
}

#[derive(Serialize)]
struct CalendarBreakdown {
    life: Option<CalendarRemaining>,
    retirement: Option<CalendarRemaining>,
}

/// 装配所有已实现时间指标，输出最近一个结构性状态变化时刻。
pub(crate) fn compute<'a>(
    settings: &'a Settings,
    calendar: &Calendar,
    clock: &Clock,
    next_midnight: i64,
) -> (Metrics<'a>, i64) {
    let life = life::compute(clock, settings.birth.as_ref(), settings.display.life_mode);
    let schedule = WorkSchedule::new(&settings.schedule);
    let work = work::compute(clock, calendar, &schedule);
    let retirement = retirement(clock, settings.retirement_date.as_deref());
    let payday = payday::compute(clock, calendar, settings.payday.as_ref());
    let holiday = holiday::compute(
        clock,
        calendar,
        settings.weekly_rest_as_holiday,
        schedule.end,
    );
    let salary = salary::compute(clock, calendar, &schedule, settings);
    let custom_countdowns = custom::compute(clock, &settings.custom_countdowns);
    let next_change = [
        life.countdown.target_millis,
        work.next_boundary,
        retirement.target_millis,
        payday.countdown.target_millis,
        holiday.countdown.target_millis,
    ]
    .into_iter()
    .chain(
        custom_countdowns
            .iter()
            .map(|item| item.countdown.target_millis),
    )
    .flatten()
    .filter(|target| *target > clock.millis())
    .fold(next_midnight, i64::min);
    let calendar_remaining = CalendarBreakdown {
        life: clock.calendar_remaining(life.countdown.target_millis, false),
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
            salary,
            custom_countdowns,
            hidden_metric_titles: &settings.display.hidden_metric_titles,
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
