use jiff::Timestamp;
use serde::Deserialize;
use serde_json::{Value, json};
use shiyu_core::{compute_snapshot, compute_timeline, update_custom_countdown, validate_settings};

#[derive(Deserialize)]
struct Scenario {
    name: String,
    settings: Value,
    holiday_data: Option<Value>,
    cases: Vec<Case>,
}

#[derive(Deserialize)]
struct Case {
    now: String,
    expect: Value,
}

#[test]
fn salary_golden_cases_cover_calendar_boundaries_and_truncation() {
    let scenarios: Vec<Scenario> =
        serde_json::from_str(include_str!("../../../testdata/salary_cases.json")).unwrap();
    for scenario in scenarios {
        let holidays = scenario.holiday_data.unwrap_or(json!({})).to_string();
        for case in scenario.cases {
            let result = snapshot(&scenario.settings, &holidays, millis(&case.now));
            for (key, expected) in case.expect.as_object().unwrap() {
                assert_eq!(
                    &result["salary"][key], expected,
                    "{} / {} / {key}",
                    scenario.name, case.now
                );
            }
        }
    }
}

#[test]
fn salary_does_not_expose_hidden_amounts_or_echo_invalid_input() {
    let config = json!({"salary":{"gross_monthly":"43210987.65", "net_monthly":"34567890.12"}});
    let now = millis("2026-01-31T00:00:00Z");
    let result = compute_snapshot(&config.to_string(), "{}", now);
    assert!(!result.contains("43210987") && !result.contains("34567890"));
    let salary = &decode(&result)["snapshot"]["salary"];
    assert_eq!(salary["hidden"], true);
    assert_eq!(salary["today_earned"], "****");
    assert_eq!(salary["month_earned"], "****");
    let unconfigured = snapshot(&json!({}), "{}", now);
    assert_eq!(unconfigured["salary"]["status"], "unconfigured");
    assert!(unconfigured["salary"]["month_earned"].is_null());
    for (input, code) in [
        (json!({"gross_monthly":"private-input"}), "invalid_amount"),
        (json!({"gross_monthly":"-1"}), "invalid_amount"),
        (
            json!({"gross_monthly":"100","basis":"net"}),
            "net_salary_required",
        ),
        (
            json!({"gross_monthly":"100","precision":1}),
            "invalid_precision",
        ),
    ] {
        let result = validate_settings(&json!({"salary":input}).to_string());
        assert!(!result.contains("private-input"));
        assert_eq!(decode(&result)["errors"][0]["code"], code);
    }
}

#[test]
fn salary_progress_matches_exact_ratio_and_pauses_during_lunch() {
    let config = json!({
        "time_zone":"UTC",
        "hide_amount":false,
        "salary":{"gross_monthly":"1234.5678","precision":4},
        "schedule":{"workdays":[]},
        "date_overrides":{"2026-01-05":true}
    });
    let start = millis("2026-01-05T09:00:00Z");
    for minute in -1_i64..=541 {
        let elapsed = minute.clamp(0, 180) + (minute - 240).clamp(0, 300);
        let scaled = 12_345_678 * elapsed / 480;
        let expected = format!("{}.{:04}", scaled / 10_000, scaled % 10_000);
        let result = snapshot(&config, "{}", start + minute * 60_000);
        assert_eq!(result["salary"]["today_earned"], expected);
        assert_eq!(result["salary"]["month_earned"], expected);
    }
}

#[test]
fn custom_updates_preserve_expired_items_and_stable_order() {
    let start = millis("2026-01-05T01:00:00Z");
    let target = "2026-01-05T09:00:01";
    let item = json!({"id":"launch","name":"产品上线","target":target,"order":1});
    let initial = json!({"custom_countdowns":[
        {"id":"later","name":"稍后","target":"2026-01-05T10:00:00","order":2},
        {"id":"legacy","name":"旧项目","target":"2026-01-01T09:00:00"}
    ]});
    let command = json!({"action":"upsert","item":item});
    let rejected =
        update_custom_countdown(&initial.to_string(), &command.to_string(), start + 1000);
    assert_eq!(decode(&rejected)["errors"][0]["code"], "target_not_future");
    assert!(!rejected.contains("产品上线"));
    let created = update(&initial, &command, start);
    let result = snapshot(&created, "{}", start);
    let entries = result["custom_countdowns"].as_array().unwrap();
    assert_eq!(
        entries
            .iter()
            .map(|entry| entry["id"].as_str().unwrap())
            .collect::<Vec<_>>(),
        ["legacy", "launch", "later"]
    );
    assert_eq!(entries[0]["enabled"], true);
    assert_eq!(entries[0]["status"], "expired");
    assert_eq!(entries[1]["remaining_seconds"], 1);
    assert_eq!(result["next_change_at_millis"], start + 1000);
    let mut edit = command;
    edit["item"]["enabled"] = json!(false);
    let updated = update(&created, &edit, start + 2000);
    let after = snapshot(&updated, "{}", start + 2000);
    assert_eq!(after["custom_countdowns"][1]["status"], "expired");
    assert_eq!(after["custom_countdowns"][1]["remaining_seconds"], 0);
    assert_eq!(after["custom_countdowns"][1]["enabled"], false);
    let removed = update(&updated, &json!({"action":"remove","id":"launch"}), start);
    let again = update(&removed, &json!({"action":"remove","id":"launch"}), start);
    assert_eq!(removed, again);
    assert_eq!(removed["custom_countdowns"].as_array().unwrap().len(), 2);
}

#[test]
fn timeline_matches_point_queries_and_caps_invalid_batches() {
    let start = millis("2026-01-05T01:00:00Z");
    let settings = json!({
        "salary":{"gross_monthly":"22000"},
        "custom_countdowns":[{"id":"launch","name":"产品上线","target":"2026-01-05T09:00:01"}]
    });
    let run = |now, step, count| {
        decode(&compute_timeline(
            &settings.to_string(),
            "{}",
            now,
            step,
            count,
        ))
    };
    let timeline = run(start, 1, 3);
    let rows = timeline["snapshots"].as_array().unwrap();
    for (index, row) in rows.iter().enumerate() {
        assert_eq!(row, &snapshot(&settings, "{}", start + index as i64 * 1000));
        assert_eq!(row["salary"]["month_earned"], "****");
        assert_eq!(
            row["custom_countdowns"][0]["status"],
            if index == 0 { "active" } else { "expired" }
        );
    }
    assert_eq!(run(start, 0, 1)["errors"][0]["code"], "invalid_step");
    assert_eq!(run(start, -1, 1)["errors"][0]["code"], "invalid_step");
    assert_eq!(run(start, i64::MAX, 1)["errors"][0]["code"], "out_of_range");
    assert_eq!(run(start, 1, -1)["errors"][0]["code"], "invalid_count");
    assert_eq!(run(start, 1, 0)["errors"][0]["code"], "invalid_count");
    assert_eq!(run(start, 1, 1441)["errors"][0]["code"], "invalid_count");
    assert_eq!(run(i64::MAX, 1, 2)["errors"][0]["code"], "out_of_range");
    let large = json!({"custom_countdowns":[{"id":"a","name":"x".repeat(90_000),"target":"2050-01-01T00:00:00"}]});
    let result = decode(&compute_timeline(&large.to_string(), "{}", start, 1, 100));
    assert_eq!(result["errors"][0]["code"], "too_large");
    assert!(result.get("snapshots").is_none());
}

fn update(settings: &Value, command: &Value, now: i64) -> Value {
    let result = decode(&update_custom_countdown(
        &settings.to_string(),
        &command.to_string(),
        now,
    ));
    assert_eq!(result["ok"], true, "{result}");
    result["settings"].clone()
}

fn snapshot(settings: &Value, holidays: &str, now: i64) -> Value {
    let result = decode(&compute_snapshot(&settings.to_string(), holidays, now));
    assert_eq!(result["ok"], true, "{result}");
    result["snapshot"].clone()
}

fn decode(raw: &str) -> Value {
    serde_json::from_str(raw).unwrap()
}

fn millis(time: &str) -> i64 {
    time.parse::<Timestamp>().unwrap().as_millisecond()
}
