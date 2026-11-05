import Foundation

// 在 Mac 上验证生成的 Swift 绑定实际调用同一个 Rust 核心。
precondition(bridgeProbe(challenge: 41) == "shiyu-core:42")
precondition(bridgeProbe(challenge: UInt32.max) == "shiyu-core:0")
print("Swift -> UniFFI -> shiyu_core: PASS")

// 与 Rust 黄金样例同一时刻，检查正式 JSON 契约的跨语言调用。
var settings = try JSONSerialization.jsonObject(with: Data(defaultSettings().utf8)) as! [String: Any]
settings["retirement_date"] = "2026-11-05"
let settingsJSON = String(data: try JSONSerialization.data(withJSONObject: settings), encoding: .utf8)!
let instant = ISO8601DateFormatter().date(from: "2026-11-04T04:00:00Z")!
let replyJSON = computeSnapshot(settingsJson: settingsJSON, holidayJson: "{}", nowMillis: Int64(instant.timeIntervalSince1970 * 1000))
let reply = try JSONSerialization.jsonObject(with: Data(replyJSON.utf8)) as! [String: Any]
let snapshot = reply["snapshot"] as! [String: Any]
let retirement = snapshot["retirement"] as! [String: Any]
precondition((retirement["remaining_days"] as? Int) == 1)
precondition((retirement["remaining_seconds"] as? Int) == 43200)
print("Swift retirement contract: PASS")

// 使用相同的午休时刻验证 Decimal 字符串、时间线和自定义倒计时。
let salarySettings = #"{"hide_amount":false,"salary":{"gross_monthly":"22000"}}"#
let command = #"{"action":"upsert","item":{"id":"launch","name":"产品上线","target":"2026-01-05T12:00:01"}}"#
let start: Int64 = 1_767_585_600_000
let updated = updateCustomCountdown(settingsJson: salarySettings, changeJson: command, nowMillis: start)
let updateReply = try JSONSerialization.jsonObject(with: Data(updated.utf8)) as! [String: Any]
precondition(updateReply["ok"] as? Bool == true)
let normalized = try JSONSerialization.data(withJSONObject: updateReply["settings"]!)
let batch = computeTimeline(
    settingsJson: String(decoding: normalized, as: UTF8.self),
    holidayJson: "{}",
    startMillis: start,
    stepSeconds: 1,
    count: 3
)
let timeline = try JSONSerialization.jsonObject(with: Data(batch.utf8)) as! [String: Any]
precondition(timeline["ok"] as? Bool == true)
let entries = timeline["snapshots"] as! [[String: Any]]
precondition(entries.count == 3)
let salary = entries[0]["salary"] as! [String: Any]
precondition(salary["today_earned"] as? String == "375.00")
precondition(salary["month_earned"] as? String == "2375.00")
let events = entries[1]["custom_countdowns"] as! [[String: Any]]
precondition(events[0]["status"] as? String == "expired")
precondition(events[0]["remaining_seconds"] as? Int == 0)
print("Swift salary and countdown timeline: PASS")
