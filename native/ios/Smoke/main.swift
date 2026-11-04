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
