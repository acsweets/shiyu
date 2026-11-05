use jiff::{
    RoundMode, Span, Timestamp, Unit, Zoned, ZonedDifference,
    civil::{Date, DateTime},
    tz::AmbiguousOffset,
};
use serde::Serialize;

/// 统一使用同一绝对时钟生成目标与展示字段。
pub(crate) struct Clock(pub(crate) Zoned);

#[derive(Serialize)]
pub(super) struct Countdown {
    status: &'static str,
    pub(super) target_millis: Option<i64>,
    remaining_seconds: i64,
    remaining_days: i32,
}

#[derive(Default, Serialize)]
pub(crate) struct CalendarRemaining {
    years: i16,
    months: i32,
    days: i32,
    hours: i32,
    minutes: i64,
    seconds: i64,
}

impl Clock {
    pub(crate) fn millis(&self) -> i64 {
        self.0.timestamp().as_millisecond()
    }

    pub(crate) fn date(&self) -> Date {
        self.0.date()
    }

    /// 重叠取第一次出现，跳时收敛到转场时刻，保持同日边界的顺序。
    pub(crate) fn resolve(&self, local: DateTime) -> Option<i64> {
        let zone = self.0.time_zone();
        let time = zone.to_ambiguous_timestamp(local);
        let timestamp = if matches!(time.offset(), AmbiguousOffset::Gap { .. }) {
            let earlier = time.earlier().ok()?;
            zone.following(earlier).next()?.timestamp()
        } else {
            time.compatible().ok()?
        };
        Some(timestamp.as_millisecond() + i64::from(timestamp.subsec_nanosecond() % 1_000_000 > 0))
    }

    /// 日历午夜若重复，第一次已过去时使用仍在未来的那次。
    pub(crate) fn next_day_boundary(&self) -> Option<i64> {
        let mut date = self.date().tomorrow().ok()?;
        loop {
            let local = date.at(0, 0, 0, 0);
            let first = self.resolve(local)?;
            if first > self.millis() {
                return Some(first);
            }
            let later = self
                .0
                .time_zone()
                .to_ambiguous_timestamp(local)
                .later()
                .ok()?
                .as_millisecond();
            if later > self.millis() {
                return Some(later);
            }
            date = date.tomorrow().ok()?;
        }
    }

    /// 严格保留 v1 对用户输入退休午夜的校验规则。
    pub(super) fn retirement_target(&self, date: Date) -> Option<i64> {
        self.0
            .time_zone()
            .to_ambiguous_timestamp(date.at(0, 0, 0, 0))
            .unambiguous()
            .ok()
            .map(Timestamp::as_millisecond)
    }

    pub(super) fn countdown(&self, status: &'static str, target: Option<i64>) -> Countdown {
        let millis = target.unwrap_or(self.millis());
        let remaining_seconds = ((millis - self.millis()).max(0) + 999) / 1000;
        let remaining_days = self
            .zoned(millis)
            .and_then(|target| self.date().until(target.date()).ok())
            .map_or(0, |span| span.get_days().max(0));
        Countdown {
            status,
            target_millis: target,
            remaining_seconds,
            remaining_days,
        }
    }

    /// 一次生成公历拆分供视图格式化。生命的月余量折回日历天。
    pub(crate) fn calendar_remaining(
        &self,
        target: Option<i64>,
        include_months: bool,
    ) -> Option<CalendarRemaining> {
        let target = self.zoned(target?)?;
        if target <= self.0 {
            return Some(CalendarRemaining::default());
        }
        let span = rounded_difference(&self.0, &target, Unit::Year)?;
        let years = span.get_years();
        let remainder = if include_months {
            span
        } else {
            let anniversary = self.0.checked_add(Span::new().years(years)).ok()?;
            rounded_difference(&anniversary, &target, Unit::Day)?
        };
        Some(CalendarRemaining {
            years,
            months: remainder.get_months(),
            days: remainder.get_days(),
            hours: remainder.get_hours(),
            minutes: remainder.get_minutes(),
            seconds: remainder.get_seconds(),
        })
    }

    pub(super) fn target_date(&self, millis: i64) -> Option<Date> {
        Some(self.zoned(millis)?.date())
    }

    fn zoned(&self, millis: i64) -> Option<Zoned> {
        Some(
            Timestamp::from_millisecond(millis)
                .ok()?
                .to_zoned(self.0.time_zone().clone()),
        )
    }
}

fn rounded_difference(from: &Zoned, to: &Zoned, largest: Unit) -> Option<Span> {
    from.until(
        ZonedDifference::new(to)
            .largest(largest)
            .smallest(Unit::Second)
            .mode(RoundMode::Ceil),
    )
    .ok()
}
