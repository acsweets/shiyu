use super::{Clock, Countdown, schedule::WorkSchedule};
use crate::calendar::Calendar;
use jiff::civil::Time;
use serde::Serialize;

#[derive(Serialize)]
pub(super) struct Work {
    #[serde(flatten)]
    pub(super) countdown: Countdown,
    target_kind: Option<&'static str>,
    #[serde(skip_serializing_if = "Option::is_none")]
    progress: Option<f64>,
    /// 工作中以“下班”为目标，状态可在此前进入午休。
    #[serde(skip)]
    pub(super) next_boundary: Option<i64>,
}

pub(super) fn compute(clock: &Clock, calendar: &Calendar, schedule: &WorkSchedule) -> Work {
    let date = clock.date();
    let now = clock.millis();
    let start = schedule.start;
    if !calendar.is_workday(date) {
        return make(
            clock,
            "rest_day",
            "work_start",
            next_start(clock, calendar, start),
            None,
        );
    }
    let bounds = schedule.bounds(clock, date);
    let (start_today, end_today) = (bounds.start, bounds.end);
    if start_today.is_some_and(|target| now < target) {
        return make(clock, "before_work", "work_start", start_today, None);
    }
    if end_today.is_none_or(|target| now >= target) {
        return make(
            clock,
            "after_work",
            "work_start",
            next_start(clock, calendar, start),
            None,
        );
    }
    let lunch = bounds.lunch;
    if let Some((from, to)) = lunch
        && from <= now
        && now < to
    {
        let mut work = make(clock, "lunch_break", "lunch_end", Some(to), None);
        work.progress = shift_progress(clock, start_today, end_today);
        return work;
    }
    let mut work = make(
        clock,
        "working",
        "work_end",
        end_today,
        lunch.map(|(from, _)| from).filter(|from| *from > now),
    );
    work.progress = shift_progress(clock, start_today, end_today);
    work
}

fn shift_progress(clock: &Clock, start: Option<i64>, end: Option<i64>) -> Option<f64> {
    let (start, end) = (start?, end?);
    (end > start).then(|| ((clock.millis() - start) as f64 / (end - start) as f64).clamp(0.0, 1.0))
}

fn next_start(clock: &Clock, calendar: &Calendar, start: Time) -> Option<i64> {
    let mut date = clock.date().tomorrow().ok()?;
    loop {
        let workday = calendar.next_workday(date)?;
        let target = clock.resolve(workday.to_datetime(start))?;
        if clock.target_date(target) == Some(workday) {
            return Some(target);
        }
        date = workday.tomorrow().ok()?;
    }
}

fn make(
    clock: &Clock,
    status: &'static str,
    kind: &'static str,
    target: Option<i64>,
    next_boundary: Option<i64>,
) -> Work {
    Work {
        countdown: clock.countdown(status, target),
        target_kind: target.map(|_| kind),
        progress: None,
        next_boundary: next_boundary.or(target),
    }
}
