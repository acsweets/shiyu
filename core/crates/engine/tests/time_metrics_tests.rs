use jiff::Timestamp;
use serde::Deserialize;
use serde_json::{Value, json};
use shiyu_core::compute_snapshot;
use std::collections::BTreeMap;

#[derive(Deserialize)]
struct Scenario {
    name: String,
    settings: Option<Value>,
    holiday_data: Option<Value>,
    cases: Vec<Case>,
}

#[derive(Deserialize)]
struct Case {
    now: String,
    expect: Value,
    times: BTreeMap<String, String>,
}

#[test]
fn golden_time_metrics_cover_state_and_target_boundaries() {
    let cases: Vec<Scenario> =
        serde_json::from_str(include_str!("../../../testdata/time_metric_cases.json")).unwrap();
    for scenario in cases {
        let settings = scenario.settings.unwrap_or(json!({})).to_string();
        let holidays = scenario.holiday_data.unwrap_or(json!({})).to_string();
        for case in scenario.cases {
            let label = format!("{} / {}", scenario.name, case.now);
            let now = millis(&case.now);
            let snapshot = snapshot(&settings, &holidays, now);
            assert_subset(&snapshot, &case.expect, &label);
            for (path, expected) in case.times {
                assert_eq!(
                    snapshot.pointer(&path).and_then(Value::as_i64),
                    Some(millis(&expected)),
                    "{label}{path}",
                );
            }
        }
    }
}

#[test]
fn days_lived_changes_at_local_midnight_and_keeps_countdown_optional() {
    let mut settings = json!({
        "time_zone": "America/New_York",
        "birth": {"date": "2024-02-28", "time": "17:00"},
        "display": {"life_mode": "elapsed_days", "hidden_metric_titles": ["life", "custom/reading"]}
    });
    let before = snapshot(&settings.to_string(), "{}", millis("2024-03-01T04:59:59Z"));
    let after = snapshot(&settings.to_string(), "{}", millis("2024-03-01T05:00:00Z"));
    assert_eq!(before["life"]["elapsed_days"], 1);
    assert_eq!(
        before["next_change_at_millis"],
        millis("2024-03-01T05:00:00Z")
    );
    assert_eq!(after["life"]["elapsed_days"], 2);
    assert_eq!(after["life"]["status"], "elapsed");
    assert!(after["life"]["target_millis"].is_null());
    assert_eq!(
        after["hidden_metric_titles"],
        json!(["life", "custom/reading"])
    );
    let before_birth = snapshot(&settings.to_string(), "{}", millis("2024-02-01T12:00:00Z"));
    assert_eq!(before_birth["life"]["elapsed_days"], 0);
    settings["display"]["life_mode"] = json!("countdown");
    let countdown = snapshot(&settings.to_string(), "{}", millis("2024-03-01T05:00:00Z"));
    assert_eq!(countdown["life"]["status"], "active");
    assert!(countdown["life"].get("elapsed_days").is_none());
    settings["birth"] = Value::Null;
    settings["display"]["life_mode"] = json!("elapsed_days");
    let missing = snapshot(&settings.to_string(), "{}", millis("2024-03-01T05:00:00Z"));
    assert_eq!(missing["life"]["status"], "elapsed");
    assert!(missing["life"].get("elapsed_days").is_none());
}

#[test]
fn snapshots_are_deterministic_and_have_a_future_transition() {
    let calendars = [
        json!({}),
        json!({
            "time_zone":"America/New_York",
            "birth":{"date":"1996-02-29","life_expectancy_years":"30.7"},
            "retirement_date":"2027-01-04",
            "payday":{"rule":"twice_monthly","days":[1,31],"adjustment":"previous_workday"},
            "date_overrides":{"2026-11-01":true,"2026-11-02":false}
        }),
        json!({"schedule":{"workdays":[]}}),
        json!({"schedule":{"workdays":[1,2,3,4,5,6,7]}, "weekly_rest_as_holiday":false}),
    ];
    for settings in calendars {
        let settings = settings.to_string();
        let initial = millis("2026-10-26T00:00:00Z");
        for hour in 0..(18 * 24) {
            let now = initial + hour * 3_600_000 + 125;
            let current = snapshot(&settings, "{}", now);
            assert_eq!(current, snapshot(&settings, "{}", now));
            let next = current["next_change_at_millis"].as_i64().unwrap();
            assert!(next > now, "{current}");
            for key in ["life", "work", "retirement", "payday", "holiday"] {
                let metric = &current[key];
                let seconds = metric["remaining_seconds"].as_i64().unwrap();
                let days = metric["remaining_days"].as_i64().unwrap();
                assert!(seconds >= 0 && days >= 0, "{key}: {metric}");
                if let Some(target) = metric["target_millis"].as_i64()
                    && target > now
                {
                    assert_eq!(seconds, (target - now + 999) / 1000);
                    assert!(next <= target);
                } else {
                    assert_eq!(seconds, 0);
                }
            }
        }
    }
}

fn snapshot(settings: &str, holidays: &str, now: i64) -> Value {
    let reply: Value = serde_json::from_str(&compute_snapshot(settings, holidays, now)).unwrap();
    assert_eq!(reply["ok"], true, "{reply}");
    reply["snapshot"].clone()
}

fn millis(time: &str) -> i64 {
    time.parse::<Timestamp>().unwrap().as_millisecond()
}

fn assert_subset(actual: &Value, expected: &Value, label: &str) {
    if let Some(fields) = expected.as_object() {
        for (key, value) in fields {
            let path = format!("{label}/{key}");
            assert_subset(
                actual.get(key).unwrap_or_else(|| panic!("{path} 缺失")),
                value,
                &path,
            );
        }
    } else {
        assert_eq!(actual, expected, "{label}");
    }
}
