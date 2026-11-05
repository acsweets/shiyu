use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;

/// Flutter 显示偏好随设置导入和导出，核心不据此改变计时规则。
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct DisplaySettings {
    pub locale: Option<String>,
    pub onboarding_completed: Option<bool>,
    pub metric_order: Vec<String>,
    pub enabled_metrics: Vec<String>,
}

const METRICS: [&str; 7] = [
    "work",
    "today_salary",
    "holiday",
    "life",
    "retirement",
    "month_salary",
    "payday",
];

impl Default for DisplaySettings {
    fn default() -> Self {
        Self {
            locale: None,
            onboarding_completed: None,
            metric_order: METRICS.map(String::from).to_vec(),
            enabled_metrics: METRICS[..5].iter().map(|id| (*id).into()).collect(),
        }
    }
}

impl DisplaySettings {
    pub(crate) fn valid_locale(&self) -> bool {
        self.locale.as_deref().is_none_or(|locale| {
            ["zh", "zh-Hant", "en", "ja", "ko", "es", "de", "fr"].contains(&locale)
        })
    }

    pub(crate) fn valid_metrics(&self) -> bool {
        self.metric_order.len() == METRICS.len()
            && valid_ids(&self.metric_order)
            && valid_ids(&self.enabled_metrics)
    }
}

fn valid_ids(ids: &[String]) -> bool {
    ids.iter()
        .map(String::as_str)
        .all(|id| METRICS.contains(&id))
        && ids.iter().collect::<BTreeSet<_>>().len() == ids.len()
}
