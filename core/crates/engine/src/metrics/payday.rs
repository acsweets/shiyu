use super::{Clock, Countdown};
use crate::{
    calendar::Calendar,
    contract::{Payday, PaydayAdjustment, PaydayRule},
};
use jiff::civil::Date;
use serde::Serialize;

#[derive(Serialize)]
pub(super) struct PaydayMetric {
    #[serde(flatten)]
    pub(super) countdown: Countdown,
    target_date: Option<String>,
}

pub(super) fn compute(clock: &Clock, calendar: &Calendar, rule: Option<&Payday>) -> PaydayMetric {
    let date = rule.and_then(|rule| next_payday(calendar, clock.date(), rule));
    let target = date.and_then(|date| clock.resolve(date.at(0, 0, 0, 0)));
    let status = match (rule, date, target) {
        (None, _, _) => "unconfigured",
        (_, Some(date), Some(_)) if date == clock.date() => "today",
        (_, _, Some(_)) => "upcoming",
        _ => "no_target",
    };
    PaydayMetric {
        countdown: clock.countdown(status, target),
        target_date: date
            .filter(|_| target.is_some())
            .map(|date| date.to_string()),
    }
}

fn next_payday(calendar: &Calendar, today: Date, rule: &Payday) -> Option<Date> {
    if matches!(rule.rule, PaydayRule::LastWorkday) {
        let month = calendar.next_workday(today)?.last_of_month();
        return calendar.previous_workday(month);
    }
    match rule.adjustment {
        PaydayAdjustment::None => nominal(today, &rule.days, true),
        PaydayAdjustment::PreviousWorkday => {
            // 先找到今天及以后首个工作日，再找可能提前到该日或更晚的名义日期。
            let first_workday = calendar.next_workday(today)?;
            calendar.previous_workday(nominal(first_workday, &rule.days, true)?)
        }
        PaydayAdjustment::NextWorkday => {
            // 顺延是单调映射。今天及之前最近的名义日期足以覆盖所有跨月顺延。
            if let Some(past) = nominal(today, &rule.days, false) {
                let adjusted = calendar.next_workday(past)?;
                if adjusted >= today {
                    return Some(adjusted);
                }
            }
            calendar.next_workday(nominal(today, &rule.days, true)?)
        }
    }
}

/// 每月最多两个名义日期，短月夹到月底；min/max 自然去除同日目标。
fn nominal(date: Date, days: &[u8], forward: bool) -> Option<Date> {
    let in_month = |anchor: Date| {
        let dates = days.iter().filter_map(move |&day| {
            Date::new(
                anchor.year(),
                anchor.month(),
                (day as i8).min(anchor.days_in_month()),
            )
            .ok()
        });
        if forward {
            dates.filter(|candidate| *candidate >= anchor).min()
        } else {
            dates.filter(|candidate| *candidate <= anchor).max()
        }
    };
    in_month(date).or_else(|| {
        if forward {
            in_month(date.last_of_month().tomorrow().ok()?)
        } else {
            in_month(date.first_of_month().yesterday().ok()?)
        }
    })
}
