use super::Clock;
use crate::contract::Schedule;
use jiff::civil::{Date, Time};

/// 上下班、午休和计薪共用的本地作息。
pub(super) struct WorkSchedule {
    /// 上下班的本地时钟。
    pub(super) start: Time,
    pub(super) end: Time,
    /// 可关闭的本地午休区间。
    lunch: Option<(Time, Time)>,
}

/// 同一天的绝对毫秒边界，保留夏令时造成的实际时长变化。
pub(super) struct WorkBounds {
    pub(super) start: Option<i64>,
    pub(super) end: Option<i64>,
    pub(super) lunch: Option<(i64, i64)>,
}

impl WorkSchedule {
    pub(super) fn new(schedule: &Schedule) -> Self {
        Self {
            start: schedule.start.parse().expect("上班时间已校验"),
            end: schedule.end.parse().expect("下班时间已校验"),
            lunch: schedule.lunch.as_ref().map(|[start, end]| {
                (
                    start.parse().expect("午休起点已校验"),
                    end.parse().expect("午休终点已校验"),
                )
            }),
        }
    }

    /// 依照核心的时区策略一次解析当天边界。
    pub(super) fn bounds(&self, clock: &Clock, date: Date) -> WorkBounds {
        let lunch = self.lunch.and_then(|(from, to)| {
            let from = clock.resolve(date.to_datetime(from))?;
            let to = clock.resolve(date.to_datetime(to))?;
            (from < to).then_some((from, to))
        });
        WorkBounds {
            start: clock.resolve(date.to_datetime(self.start)),
            end: clock.resolve(date.to_datetime(self.end)),
            lunch,
        }
    }
}

impl WorkBounds {
    /// 返回已工作毫秒、当日有效毫秒和当前是否计薪。
    pub(super) fn elapsed(&self, now: i64) -> Option<(u64, u64, bool)> {
        let (start, end) = (self.start?, self.end?);
        let mut total = end - start;
        let mut elapsed = (now.min(end) - start).max(0);
        let mut working = start <= now && now < end;
        if let Some((from, to)) = self.lunch {
            total -= to - from;
            elapsed -= (now.min(to) - from).max(0);
            working &= !(from <= now && now < to);
        }
        (total > 0).then_some((elapsed as u64, total as u64, working))
    }
}
