import SwiftUI
import WidgetKit

struct RetirementEntry: TimelineEntry {
    /// 系统时间线条目的创建时刻。
    let date: Date
    /// Rust 的状态与数值，不由 Swift 计算日期差。
    let snapshot: WidgetSnapshot?
}

struct WidgetSnapshot: Decodable {
    /// 下次日历或退休边界。
    let next_change_at_millis: Int64
    /// 用户配置的显式时区。
    let time_zone: String
    /// 当前退休指标。
    let retirement: Retirement

    struct Retirement: Decodable {
        /// 未配置、计时中或已退休。
        let status: String
        /// Rust 返回的日历剩余天数。
        let remaining_days: Int64
    }
}

struct WidgetReply: Decodable {
    /// 核心是否成功计算。
    let ok: Bool
    /// 无效设置时不存在快照。
    let snapshot: WidgetSnapshot?
}

struct RetirementProvider: TimelineProvider {
    func placeholder(in context: Context) -> RetirementEntry { RetirementEntry(date: Date(), snapshot: nil) }

    func getSnapshot(in context: Context, completion: @escaping (RetirementEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RetirementEntry>) -> Void) {
        let entry = load()
        let next = entry.snapshot.map { Date(timeIntervalSince1970: Double($0.next_change_at_millis) / 1000) }
            ?? entry.date.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(max(next, entry.date.addingTimeInterval(60)))))
    }

    // 扩展进程直接调用独立 Rust 静态库，主应用退出也可以重新计算。
    private func load() -> RetirementEntry {
        let now = Date()
        do {
            let settings = try SharedWidgetStore.read() ?? defaultSettings()
            let json = computeSnapshot(settingsJson: settings, holidayJson: "{}", nowMillis: Int64(now.timeIntervalSince1970 * 1000))
            let reply = try JSONDecoder().decode(WidgetReply.self, from: Data(json.utf8))
            return RetirementEntry(date: now, snapshot: reply.ok ? reply.snapshot : nil)
        } catch { return RetirementEntry(date: now, snapshot: nil) }
    }
}

struct RetirementWidgetView: View {
    /// 当前系统时间线条目。
    let entry: RetirementEntry
    private var chinese: Bool { Locale.preferredLanguages.first?.hasPrefix("zh") == true }
    private var value: String {
        guard let state = entry.snapshot?.retirement else { return chinese ? "打开时余完成设置" : "Open Shiyu to set up" }
        switch state.status {
        case "active": return chinese ? "还剩 \(state.remaining_days) 天" : "\(state.remaining_days) days left"
        case "retired": return chinese ? "已退休" : "Retired"
        default: return chinese ? "请设置退休日期" : "Choose a retirement date"
        }
    }
    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(chinese ? "退休倒计时" : "Retirement", systemImage: "hourglass")
                .font(.caption).foregroundColor(.secondary)
            Text(value).font(.title2.bold()).minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            if let zone = entry.snapshot?.time_zone { Text(zone).font(.caption2).foregroundColor(.secondary) }
            Text(entry.date, style: .time).font(.caption2).foregroundColor(.secondary)
        }.widgetURL(URL(string: "shiyu://settings"))
    }
    var body: some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(Color(red: 0.94, green: 0.97, blue: 0.95), for: .widget)
        } else {
            content.padding().background(Color(red: 0.94, green: 0.97, blue: 0.95))
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
        .description("使用本地设置显示退休剩余天数。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
