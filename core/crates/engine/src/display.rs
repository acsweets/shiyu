use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;

/// 显示偏好随设置导入和导出。
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct DisplaySettings {
    pub locale: Option<String>,
    pub onboarding_completed: Option<bool>,
    pub metric_order: Vec<String>,
    pub enabled_metrics: Vec<String>,
    pub metrics_customized: bool,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub hidden_metric_titles: Vec<String>,
    #[serde(skip_serializing_if = "LifeMode::is_default")]
    pub life_mode: LifeMode,
}

/// 生命指标可以显示剩余时间，或从出生日期起经过的日历天数。
#[derive(Clone, Copy, Debug, Default, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum LifeMode {
    #[default]
    Countdown,
    ElapsedDays,
}

impl LifeMode {
    fn is_default(&self) -> bool {
        matches!(self, Self::Countdown)
    }
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
            metrics_customized: false,
            hidden_metric_titles: vec![],
            life_mode: LifeMode::default(),
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

    pub(crate) fn valid_hidden_titles(&self) -> bool {
        self.hidden_metric_titles.iter().all(|id| {
            METRICS.contains(&id.as_str())
                || id.strip_prefix("custom/").is_some_and(|id| !id.is_empty())
        }) && self
            .hidden_metric_titles
            .iter()
            .collect::<BTreeSet<_>>()
            .len()
            == self.hidden_metric_titles.len()
    }
}

fn valid_ids(ids: &[String]) -> bool {
    ids.iter()
        .map(String::as_str)
        .all(|id| METRICS.contains(&id))
        && ids.iter().collect::<BTreeSet<_>>().len() == ids.len()
}
