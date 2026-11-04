use serde_json::{Value, json};
use shiyu_core::{compute_snapshot, default_settings, validate_settings};

fn compute(settings: Value, time: &str) -> Value {
    let now = time.parse::<jiff::Timestamp>().unwrap().as_millisecond();
    serde_json::from_str(&compute_snapshot(&settings.to_string(), "{}", now)).unwrap()
}

#[test]
fn defaults_are_valid_without_a_fabricated_target() {
    let defaults: Value = serde_json::from_str(&default_settings()).unwrap();
    assert!(defaults["retirement_date"].is_null());
    let validated: Value = serde_json::from_str(&validate_settings(&defaults.to_string())).unwrap();
    assert_eq!(validated["ok"], true);
    assert_eq!(
        compute(defaults, "2026-11-04T04:00:00Z")["snapshot"]["retirement"]["status"],
        "unconfigured"
    );
}

#[test]
fn retirement_is_calendar_based_across_both_dst_changes() {
    for (now, target, seconds) in [
        ("2026-11-01T04:00:00Z", "2026-11-02", 90000),
        ("2026-03-08T05:00:00Z", "2026-03-09", 82800),
    ] {
        let mut settings: Value = serde_json::from_str(&default_settings()).unwrap();
        settings["time_zone"] = json!("America/New_York");
        settings["retirement_date"] = json!(target);
        let result = compute(settings, now);
        assert_eq!(result["snapshot"]["retirement"]["remaining_days"], 1);
        assert_eq!(
            result["snapshot"]["retirement"]["remaining_seconds"],
            seconds
        );
    }
}

#[test]
fn target_day_is_retired_and_never_negative() {
    let mut settings: Value = serde_json::from_str(&default_settings()).unwrap();
    settings["retirement_date"] = json!("2026-11-04");
    let result = compute(settings, "2026-11-04T04:00:00Z");
    assert_eq!(result["snapshot"]["retirement"]["status"], "retired");
    assert_eq!(result["snapshot"]["retirement"]["remaining_seconds"], 0);
}

#[test]
fn validation_rejects_versions_unknown_fields_and_overnight_schedules() {
    for (key, value) in [
        ("schema_version", json!(9)),
        ("unknown", json!(true)),
        ("time_zone", json!("Unknown/Zone")),
        ("retirement_date", json!("2026-02-30")),
    ] {
        let mut settings: Value = serde_json::from_str(&default_settings()).unwrap();
        settings[key] = value;
        let response: Value =
            serde_json::from_str(&validate_settings(&settings.to_string())).unwrap();
        assert_eq!(response["ok"], false);
    }
    let response = validate_settings(
        r#"{"schedule":{"start":"22:00","end":"06:00"},"salary":{"gross_monthly":"private_value","net_monthly":null,"currency":"CNY","precision":2}}"#,
    );
    assert!(!response.contains("private_value"));
    assert!(response.contains("invalid_work_hours"));
}

#[test]
fn personal_date_overrides_win_and_missing_data_falls_back() {
    let mut settings: Value = serde_json::from_str(&default_settings()).unwrap();
    settings["date_overrides"] = json!({"2026-11-07":true});
    settings["holidays"] =
        json!([{"name":"合成测试假期","start":"2026-11-07","end":"2026-11-09","kind":"personal"}]);
    let now = "2026-11-07T00:00:00Z"
        .parse::<jiff::Timestamp>()
        .unwrap()
        .as_millisecond();
    let holiday = json!({"schema_version":1,"region":"CN","years":[2026],"date_overrides":{"2026-11-07":false}});
    let first: Value = serde_json::from_str(&compute_snapshot(
        &settings.to_string(),
        &holiday.to_string(),
        now,
    ))
    .unwrap();
    assert_eq!(first["snapshot"]["is_workday"], true);
    assert_eq!(first["snapshot"]["calendar_status"], "available");
    settings["date_overrides"] = json!({});
    let regional_workday = json!({"schema_version":1,"region":"CN","years":[2026],"date_overrides":{"2026-11-07":true}});
    let custom: Value = serde_json::from_str(&compute_snapshot(
        &settings.to_string(),
        &regional_workday.to_string(),
        now,
    ))
    .unwrap();
    assert_eq!(custom["snapshot"]["is_workday"], false);
    settings["holidays"] = json!([]);
    let regional: Value = serde_json::from_str(&compute_snapshot(
        &settings.to_string(),
        &regional_workday.to_string(),
        now,
    ))
    .unwrap();
    assert_eq!(regional["snapshot"]["is_workday"], true);
    let fallback = compute(settings, "2026-11-07T00:00:00Z");
    assert_eq!(fallback["snapshot"]["is_workday"], false);
    assert_eq!(fallback["snapshot"]["calendar_status"], "weekly_fallback");
}

#[test]
fn golden_contract_is_deterministic() {
    let cases: Value =
        serde_json::from_str(include_str!("../../../testdata/retirement_cases.json")).unwrap();
    for case in cases.as_array().unwrap() {
        let a = compute(case["settings"].clone(), case["now"].as_str().unwrap());
        let b = compute(case["settings"].clone(), case["now"].as_str().unwrap());
        assert_eq!(a, b);
        assert_eq!(a["snapshot"]["retirement"], case["expected_retirement"]);
    }
}

#[test]
fn calendar_handles_leap_day_month_end_and_all_weekdays() {
    let mut settings: Value = serde_json::from_str(&default_settings()).unwrap();
    settings["retirement_date"] = json!("2028-03-01");
    let leap = compute(settings.clone(), "2028-02-28T16:00:00Z");
    assert_eq!(leap["snapshot"]["local_date"], "2028-02-29");
    assert_eq!(leap["snapshot"]["retirement"]["remaining_days"], 1);
    assert_eq!(leap["snapshot"]["retirement"]["remaining_seconds"], 86400);
    settings["schedule"]["workdays"] = json!([1, 2, 3, 4, 5, 6, 7]);
    assert_eq!(
        compute(settings.clone(), "2026-11-07T00:00:00Z")["snapshot"]["is_workday"],
        true
    );
    settings["schedule"]["workdays"] = json!([]);
    assert_eq!(
        compute(settings, "2026-11-09T00:00:00Z")["snapshot"]["is_workday"],
        false
    );
}

#[test]
fn midnight_gap_and_payday_salary_constraints_are_rejected_before_saving() {
    let invalid = [
        json!({"time_zone":"Pacific/Apia","retirement_date":"2011-12-30"}),
        json!({"payday":{"rule":"twice_monthly","days":[15,15],"adjustment":"next_workday"}}),
        json!({"salary":{"gross_monthly":"10000.00","currency":"CNY","precision":2,"basis":"net"}}),
    ];
    for settings in invalid {
        let reply: Value = serde_json::from_str(&validate_settings(&settings.to_string())).unwrap();
        assert_eq!(reply["ok"], false);
    }
    let valid = json!({"payday":{"rule":"fixed_day","days":[31],"adjustment":"next_workday"}});
    let reply: Value = serde_json::from_str(&validate_settings(&valid.to_string())).unwrap();
    assert_eq!(reply["ok"], true);
}
