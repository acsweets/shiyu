use crate::{
    contract::CustomCountdown,
    metrics::Clock,
    snapshot::{SnapshotError, error_reply},
    validation::{MAX_SETTINGS_BYTES, parse_settings, valid_countdown},
};
use jiff::{Timestamp, civil::DateTime, tz::TimeZone};
use serde::Deserialize;

#[derive(Deserialize)]
#[serde(tag = "action", rename_all = "snake_case", deny_unknown_fields)]
enum Change {
    Upsert { item: CustomCountdown },
    Remove { id: String },
}

/// 在内存中创建、编辑或删除，调用方决定是否持久化返回配置。
pub fn update_custom_countdown(settings_json: &str, change_json: &str, now_millis: i64) -> String {
    update(settings_json, change_json, now_millis).unwrap_or_else(error_reply)
}

fn update(
    settings_json: &str,
    change_json: &str,
    now_millis: i64,
) -> Result<String, SnapshotError> {
    if change_json.len() > MAX_SETTINGS_BYTES {
        return Err(("change", "too_large"));
    }
    let change: Change =
        serde_json::from_str(change_json).map_err(|_| ("change", "invalid_json"))?;
    let mut settings =
        parse_settings(settings_json).map_err(|_| ("settings", "invalid_settings"))?;
    let now = Timestamp::from_millisecond(now_millis).map_err(|_| ("now", "invalid_timestamp"))?;
    match change {
        Change::Remove { id } => {
            if id.is_empty() {
                return Err(("custom_countdown.id", "invalid_countdown"));
            }
            settings.custom_countdowns.retain(|item| item.id != id);
        }
        Change::Upsert { item } => {
            if !valid_countdown(&item) {
                return Err(("custom_countdown", "invalid_countdown"));
            }
            let zone = TimeZone::get(&settings.time_zone).expect("时区已校验");
            let clock = Clock(now.to_zoned(zone));
            let date_time: DateTime = item.target.parse().expect("目标时间已校验");
            let target = clock
                .resolve(date_time)
                .ok_or(("custom_countdown.target", "out_of_range"))?;
            if let Some(current) = settings
                .custom_countdowns
                .iter_mut()
                .find(|entry| entry.id == item.id)
            {
                *current = item;
            } else {
                if target <= now_millis {
                    return Err(("custom_countdown.target", "target_not_future"));
                }
                settings.custom_countdowns.push(item);
            }
        }
    }
    let settings = serde_json::to_string(&settings).expect("配置可以序列化");
    if settings.len() > MAX_SETTINGS_BYTES {
        return Err(("settings", "too_large"));
    }
    Ok(format!(
        r#"{{"ok":true,"settings":{settings},"errors":[]}}"#
    ))
}
