use super::{Clock, Countdown};
use crate::{contract::Birth, display::LifeMode};
use jiff::{
    Span,
    civil::{Date, Time},
};
use rust_decimal::{Decimal, prelude::ToPrimitive};
use serde::Serialize;

#[derive(Serialize)]
pub(super) struct LifeMetric {
    #[serde(flatten)]
    pub(super) countdown: Countdown,
    #[serde(skip_serializing_if = "Option::is_none")]
    elapsed_days: Option<i32>,
}

pub(super) fn compute(clock: &Clock, birth: Option<&Birth>, mode: LifeMode) -> LifeMetric {
    match mode {
        LifeMode::Countdown => LifeMetric {
            countdown: countdown(clock, birth),
            elapsed_days: None,
        },
        LifeMode::ElapsedDays => LifeMetric {
            countdown: clock.countdown("elapsed", None),
            elapsed_days: birth.map(|birth| {
                let date: Date = birth.date.parse().expect("出生日期已校验");
                date.until(clock.date())
                    .expect("日历日期有效")
                    .get_days()
                    .max(0)
            }),
        },
    }
}

fn countdown(clock: &Clock, birth: Option<&Birth>) -> Countdown {
    let Some(birth) = birth else {
        return clock.countdown("unconfigured", None);
    };
    let target = target(clock, birth);
    let status = match target {
        Some(target) if target <= clock.millis() => "exceeded",
        Some(_) => "active",
        None => "out_of_range",
    };
    clock.countdown(status, target)
}

fn target(clock: &Clock, birth: &Birth) -> Option<i64> {
    let date: Date = birth.date.parse().expect("出生日期已校验");
    let time: Time = birth
        .time
        .as_ref()
        .map_or(Time::MIN, |time| time.parse().expect("出生时间已校验"));
    let years: Decimal = birth.life_expectancy_years.parse().expect("寿命已校验");
    let tenths = (years * Decimal::from(10)).to_i32()?;
    let whole = tenths / 10;
    let anniversary = date.checked_add(Span::new().years(whole)).ok()?;
    let fraction = tenths % 10;
    let mut local = anniversary.to_datetime(time);
    if fraction != 0 {
        // 用相邻两次生日之间的公历日数折算小数，保持同一个出生时刻。
        let next = date.checked_add(Span::new().years(whole + 1)).ok()?;
        let days = anniversary.until(next).ok()?.get_days();
        let seconds = i64::from(days * fraction) * 8640;
        local = local.checked_add(Span::new().seconds(seconds)).ok()?;
    }
    clock.resolve(local)
}
