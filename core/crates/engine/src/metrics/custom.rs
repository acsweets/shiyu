use super::{Clock, Countdown};
use crate::contract::CustomCountdown;
use jiff::civil::DateTime;
use serde::Serialize;

/// 每项保留稳定 ID，设置界面可以检查已经到期或隐藏的项目。
#[derive(Serialize)]
pub(super) struct CustomMetric<'a> {
    id: &'a str,
    name: &'a str,
    enabled: bool,
    order: u32,
    #[serde(flatten)]
    pub(super) countdown: Countdown,
}

pub(super) fn compute<'a>(clock: &Clock, items: &'a [CustomCountdown]) -> Vec<CustomMetric<'a>> {
    let mut metrics: Vec<_> = items
        .iter()
        .enumerate()
        .map(|(index, item)| {
            let date_time: DateTime = item.target.parse().expect("目标时间已校验");
            let target = clock.resolve(date_time);
            let status = match target {
                Some(target) if target <= clock.millis() => "expired",
                Some(_) => "active",
                None => "out_of_range",
            };
            CustomMetric {
                id: &item.id,
                name: &item.name,
                enabled: item.enabled,
                order: item.order.unwrap_or(index as u32),
                countdown: clock.countdown(status, target),
            }
        })
        .collect();
    metrics.sort_by_key(|item| item.order);
    metrics
}
