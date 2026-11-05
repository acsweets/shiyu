import SwiftUI
import WidgetKit

struct RetirementEntry: TimelineEntry {
    /// 系统时间线条目的起始时刻。
    let date: Date
    /// Rust 计算出的退休状态及时间。
    let snapshot: WidgetSnapshot?
    /// 从 App Group 读取的小组件外观。
    let appearance: WidgetAppearance
    var locale: String? = nil

    /// 退休的绝对时间由 Rust 按目标时区计算。
    var target: Date? {
        snapshot?.retirement.target_millis.map {
            Date(timeIntervalSince1970: Double($0) / 1000)
        }
    }
}

struct WidgetSnapshot: Decodable {
    /// 下次日历或退休边界。
    let next_change_at_millis: Int64
    /// 当前退休指标。
    let retirement: Retirement

    struct Retirement: Decodable {
        /// 未配置、计时中或已退休。
        let status: String
        /// Rust 返回的非负剩余秒数。
        let remaining_seconds: Int64
        /// Rust 返回的绝对目标时间。
        let target_millis: Int64?
    }
}

struct WidgetReply: Decodable {
    let ok: Bool
    let snapshot: WidgetSnapshot?
}

/// 正式 UniFFI 独立校验共享设置，缺失时回退且保持金额遮蔽。
private struct WidgetInputs {
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
        case "cool": return (color(0x242A3A), color(0xF0F5FF))
        case "sunset": return (color(0xF4D0A3), color(0x472B29))
        default: return (color(0xFFEBB4), color(0x45363B))
        }
    }

    private func color(_ rgb: UInt32) -> Color {
        Color(red: Double(rgb >> 16) / 255,
              green: Double(rgb >> 8 & 255) / 255,
              blue: Double(rgb & 255) / 255)
    }
}

struct RetirementProvider: TimelineProvider {
    func placeholder(in context: Context) -> RetirementEntry {
        RetirementEntry(date: Date(), snapshot: nil, appearance: WidgetAppearance())
    }

    func getSnapshot(in context: Context, completion: @escaping (RetirementEntry) -> Void) {
        completion(entry(at: Date(), input: .load(), appearance: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RetirementEntry>) -> Void) {
        let now = Date()
        let appearance = WidgetAppearance.load()
        let input = WidgetInputs.load()
        let current = entry(at: now, input: input, appearance: appearance)
        let interval = now.addingTimeInterval(1800)
        let boundary = current.snapshot.map {
            Date(timeIntervalSince1970: Double($0.next_change_at_millis) / 1000)
        } ?? interval
        let next = max(now.addingTimeInterval(60), min(boundary, interval))
        var entries = [current]
        if let target = current.target, target > now, target <= next {
            entries.append(entry(at: target, input: input, appearance: appearance))
        }
        completion(Timeline(entries: entries, policy: .after(next)))
    }

    /// 组件扩展直接调用 Rust，打开或关闭 Flutter 都不会改变时间线来源。
    private func entry(at date: Date, input: WidgetInputs, appearance: WidgetAppearance) -> RetirementEntry {
        RetirementEntry(date: date, snapshot: input.snapshot(at: date), appearance: appearance, locale: input.locale)
    }
}

struct RetirementWidgetView: View {
    /// 当前系统时间线条目。
    let entry: RetirementEntry

    private var chinese: Bool { (entry.locale ?? Locale.preferredLanguages.first)?.hasPrefix("zh") == true }

    private var value: String {
        guard let state = entry.snapshot?.retirement else {
            return chinese ? "设置退休日期" : "Set a retirement date"
        }
        switch state.status {
        case "active":
            let seconds = state.remaining_seconds
            let days = (seconds / 86_400).formatted()
            let clock = String(format: "%02lld:%02lld:%02lld",
                               seconds / 3_600 % 24, seconds / 60 % 60, seconds % 60)
            return chinese ? "\(days) 天 \(clock)" : "\(days)d \(clock)"
        case "retired": return chinese ? "已退休" : "Retired"
        default: return chinese ? "设置退休日期" : "Set a retirement date"
        }
    }

    @ViewBuilder
    private var countdown: some View {
        if #available(iOS 16.0, *),
           let target = entry.target,
           let retirement = entry.snapshot?.retirement,
           retirement.status == "active",
           retirement.remaining_seconds < 86_400,
           target > entry.date {
            // 最后一天交给系统计时，并在目标时刻停在零。
            Text(timerInterval: entry.date...target, pauseTime: target, countsDown: true)
        } else {
            Text(value)
        }
    }

    private var content: some View {
        let appearance = entry.appearance
        let colors = appearance.colors
        return ZStack(alignment: .top) {
            VStack(spacing: 5) {
                if appearance.titleVisible != false {
                    Text(chinese ? "退休倒计时" : "Retirement countdown")
                        .font(.system(size: CGFloat(min(24, max(10, appearance.titleSize ?? 16))), weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                countdown
                    .font(.system(size: 25, weight: .bold))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .foregroundColor(colors.ink)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 20).fill(colors.surface))
            .padding(.top, 43)

            Image("widget_cat", bundle: .main)
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 48)
                .accessibilityHidden(true)
        }
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(Color.clear, for: .widget)
        } else {
            content
        }
    }
}

@main
struct ShiyuRetirementWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ShiyuRetirement", provider: RetirementProvider()) { entry in
            RetirementWidgetView(entry: entry)
        }
        .configurationDisplayName("Shiyu · 退休倒计时")
        .description("在主屏幕查看退休倒计时。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
