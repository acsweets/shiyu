import SwiftUI
import WidgetKit

enum WidgetMetric: String, CaseIterable {
    case work, holiday, payday, retirement, life

    func title(chinese: Bool) -> String {
        switch self {
        case .work: return chinese ? "上下班倒计时" : "Work countdown"
        case .holiday: return chinese ? "距离放假" : "Until the next break"
        case .payday: return chinese ? "距离发薪" : "Until payday"
        case .retirement: return chinese ? "退休倒计时" : "Retirement countdown"
        case .life: return chinese ? "静待百岁，好好生活" : "Life countdown"
        }
    }

    func title(_ value: WidgetSnapshot.Countdown?, chinese: Bool) -> String {
        if value?.status == "elapsed" {
            return chinese ? "已存在世界" : "Days lived"
        }
        switch value?.target_kind {
        case "work_start": return chinese ? "距离上班" : "Until work starts"
        case "work_end": return chinese ? "距离下班" : "Until work ends"
        case "lunch_end": return chinese ? "距离午休结束" : "Until lunch ends"
        default:
            if value?.status == "on_holiday" {
                return chinese ? "距离假期结束" : "Until break ends"
            }
            return title(chinese: chinese)
        }
    }
}

struct ShiyuWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let appearance: WidgetAppearance
    let locale: String?
    let metric: WidgetMetric
    /// 用户为当前实例追加的倒计时，空列表沿用旧版布局。
    let additionalMetrics: [WidgetMetric]

    var chinese: Bool {
        (locale ?? Locale.preferredLanguages.first)?.hasPrefix("zh") == true
    }
}

struct WidgetSnapshot: Decodable {
    let next_change_at_millis: Int64
    let work: Countdown
    let holiday: Countdown
    let payday: Countdown
    let retirement: Countdown
    let life: Countdown?
    let salary: Salary
    let hidden_metric_titles: [String]?

    struct Countdown: Decodable {
        let status: String
        let remaining_seconds: Int64
        let target_millis: Int64?
        let target_kind: String?
        let elapsed_days: Int?

        var target: Date? {
            target_millis.map { Date(timeIntervalSince1970: Double($0) / 1000) }
        }
    }

    struct Salary: Decodable {
        let hidden: Bool
        let currency: String
        let today_earned: String?
        let month_earned: String?

        func amount(month: Bool, chinese: Bool) -> String {
            if hidden { return "****" }
            guard let value = month ? month_earned : today_earned else {
                return chinese ? "未设置" : "Not set"
            }
            return "\(value) \(currency)"
        }
    }

    func countdown(_ metric: WidgetMetric) -> Countdown? {
        switch metric {
        case .work: return work
        case .holiday: return holiday
        case .payday: return payday
        case .retirement: return retirement
        case .life: return life
        }
    }
}

private struct WidgetReply: Decodable {
    let ok: Bool
    let snapshot: WidgetSnapshot?
}

/// 正式 UniFFI 独立校验共享设置，缺失时回退且保持金额遮蔽。
struct WidgetInputs {
    let settings: String
    let calendar: String
    let locale: String?

    static func load() -> WidgetInputs {
        let primary = checked(try? SharedWidgetStore.read())
        var values = primary ?? checked(try? SharedWidgetStore.readLastGoodSettings()) ?? [:]
        if primary == nil { values["hide_amount"] = true }
        let data = try? JSONSerialization.data(withJSONObject: values)
        let settings = data.flatMap { String(data: $0, encoding: .utf8) } ?? defaultSettings()
        let display = values["display"] as? [String: Any]
        let region = values["region"] as? String ?? "CN"
        return WidgetInputs(
            settings: settings, calendar: SharedWidgetStore.readCalendar(region: region) ?? "{}",
            locale: display?["locale"] as? String
        )
    }

    private static func checked(_ raw: String?) -> [String: Any]? {
        guard let raw,
              var candidate = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any] else {
            return nil
        }
        if candidate["schema_version"] as? Int == 0 { candidate["schema_version"] = 1 }
        guard let data = try? JSONSerialization.data(withJSONObject: candidate),
              let json = String(data: data, encoding: .utf8) else { return nil }
        let validated = validateSettings(settingsJson: json)
        guard let reply = (try? JSONSerialization.jsonObject(with: Data(validated.utf8))) as? [String: Any],
              reply["ok"] as? Bool == true else { return nil }
        return reply["settings"] as? [String: Any]
    }

    func snapshot(at date: Date) -> WidgetSnapshot? {
        let millis = Int64((date.timeIntervalSince1970 * 1000).rounded())
        let decoder = JSONDecoder()
        let json = computeSnapshot(settingsJson: settings, holidayJson: calendar, nowMillis: millis)
        let reply = try? decoder.decode(WidgetReply.self, from: Data(json.utf8))
        if reply?.ok == true { return reply?.snapshot }
        guard calendar != "{}" else { return nil }
        let fallback = computeSnapshot(settingsJson: settings, holidayJson: "{}", nowMillis: millis)
        let result = try? decoder.decode(WidgetReply.self, from: Data(fallback.utf8))
        return result?.ok == true ? result?.snapshot : nil
    }
}

struct WidgetAppearance: Decodable {
    /// 桌面同款色卡的标识。
    var palette: String?
    /// 标题显隐，旧版默认显示。
    var titleVisible: Bool?
    /// 标题字号，旧版默认 16。
    var titleSize: Double?

    static func load() -> WidgetAppearance {
        do {
            if let json = try SharedWidgetStore.readAppearance() {
                return try JSONDecoder().decode(Self.self, from: Data(json.utf8))
            }
        } catch {
            // 外观不可读时使用默认值，倒计时仍可独立计算。
        }
        return WidgetAppearance()
    }

    var colors: (surface: Color, ink: Color) {
        switch palette {
        case "macaronGlass": return (color(0xFFE9B2), color(0x382A36))
        case "cool": return (color(0x242A3A), color(0xF0F5FF))
        case "sunset": return (color(0xF4D0A3), color(0x472B29))
        default: return (color(0xFFEBB4), color(0x45363B))
        }
    }

    /// 玻璃色板的亮面从左上过渡到底色。
    var glassGradient: LinearGradient? {
        guard palette == "macaronGlass" else { return nil }
        return LinearGradient(
            stops: [
                .init(color: color(0xFFF7E2).opacity(0.94), location: 0),
                .init(color: colors.surface.opacity(0.86), location: 0.42),
                .init(color: colors.surface.opacity(0.74), location: 1),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private func color(_ rgb: UInt32) -> Color {
        Color(red: Double(rgb >> 16) / 255,
              green: Double(rgb >> 8 & 255) / 255,
              blue: Double(rgb & 255) / 255)
    }
}
