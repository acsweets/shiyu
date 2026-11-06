import AppIntents
import SwiftUI
import WidgetKit

private struct WidgetTimeline {
    let metric: WidgetMetric
    /// 由组件的 App Intent 配置传入。
    var additionalMetrics: [WidgetMetric] = []
    var salary = false

    func placeholder() -> ShiyuWidgetEntry {
        ShiyuWidgetEntry(date: Date(), snapshot: nil, appearance: WidgetAppearance(),
                         locale: nil, metric: metric, additionalMetrics: additionalMetrics)
    }

    func snapshot() -> ShiyuWidgetEntry {
        entry(Date(), WidgetInputs.load(), .load())
    }

    func make() -> Timeline<ShiyuWidgetEntry> {
        let now = Date()
        let appearance = WidgetAppearance.load()
        let input = WidgetInputs.load()
        let first = entry(now, input, appearance)
        let horizon = now.addingTimeInterval(salary ? 60 : 900)
        let boundary = first.snapshot.map {
            Date(timeIntervalSince1970: Double($0.next_change_at_millis) / 1000)
        }
        // 薪资只保留当前样本，隐藏金额变更后无需等预先生成的金额条目过期。
        if !salary, let boundary, boundary > now, boundary <= horizon {
            let changed = entry(boundary, input, appearance)
            let refresh = max(now.addingTimeInterval(60), boundary.addingTimeInterval(1))
            return Timeline(entries: [first, changed], policy: .after(refresh))
        }
        return Timeline(entries: [first], policy: .after(horizon))
    }

    private func entry(_ date: Date, _ input: WidgetInputs, _ appearance: WidgetAppearance) -> ShiyuWidgetEntry {
        ShiyuWidgetEntry(date: date, snapshot: input.snapshot(at: date),
                         appearance: appearance, locale: input.locale,
                         metric: metric, additionalMetrics: additionalMetrics)
    }
}

private struct ShiyuStaticProvider: TimelineProvider {
    let timeline: WidgetTimeline

    func placeholder(in context: Context) -> ShiyuWidgetEntry { timeline.placeholder() }

    func getSnapshot(in context: Context, completion: @escaping (ShiyuWidgetEntry) -> Void) {
        completion(timeline.snapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiyuWidgetEntry>) -> Void) {
        completion(timeline.make())
    }
}

@available(iOS 17.0, *)
enum CountdownOption: String, AppEnum {
    case work, holiday, payday, retirement, life

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Countdown"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .work: "Work", .holiday: "Holiday", .payday: "Payday", .retirement: "Retirement", .life: "Life",
    ]

    var metric: WidgetMetric { WidgetMetric(rawValue: rawValue) ?? .retirement }
}

@available(iOS 17.0, *)
struct CountdownConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose a countdown"
    static var description: IntentDescription = "Choose a main countdown and up to three additional countdowns."

    @Parameter(title: "Countdown", default: .retirement)
    var option: CountdownOption

    @Parameter(title: "Second countdown")
    var second: CountdownOption?

    @Parameter(title: "Third countdown")
    var third: CountdownOption?

    @Parameter(title: "Fourth countdown")
    var fourth: CountdownOption?

    fileprivate var timeline: WidgetTimeline {
        WidgetTimeline(metric: option.metric, additionalMetrics: [second, third, fourth].compactMap { $0?.metric })
    }
}

/// 用户交互完成后，WidgetKit 重新生成时间线并从 Rust 读取当前金额。
@available(iOS 17.0, *)
struct RefreshEarningsIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh earnings"

    func perform() async throws -> some IntentResult {
        .result()
    }
}

@available(iOS 17.0, *)
private struct CountdownIntentProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ShiyuWidgetEntry {
        WidgetTimeline(metric: .retirement).placeholder()
    }

    func snapshot(for configuration: CountdownConfiguration, in context: Context) async -> ShiyuWidgetEntry {
        configuration.timeline.snapshot()
    }

    func timeline(for configuration: CountdownConfiguration, in context: Context) async -> Timeline<ShiyuWidgetEntry> {
        configuration.timeline.make()
    }
}

private struct ShiyuCountdownWidget: Widget {
    let kind = "ShiyuRetirement"

    func configuration() -> some WidgetConfiguration {
        if #available(iOS 17.0, *) {
            return AppIntentConfiguration(
                kind: kind, intent: CountdownConfiguration.self, provider: CountdownIntentProvider()
            ) { entry in
                ShiyuWidgetCard(entry: entry)
            }
        } else {
            return StaticConfiguration(kind: kind, provider: ShiyuStaticProvider(timeline: WidgetTimeline(metric: .retirement))) {
                ShiyuWidgetCard(entry: $0)
            }
        }
    }

    var body: some WidgetConfiguration {
        configuration()
            .configurationDisplayName("时余 · Countdown")
            .description("Work, holidays, payday, retirement, and life.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// 在 iOS 15 和 16 上可直接添加对应的固定主指标，也保留已有退休组件。
private struct ShiyuFixedCountdownWidget: Widget {
    let metric: WidgetMetric

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "ShiyuCountdown.\(metric.rawValue)",
            provider: ShiyuStaticProvider(timeline: WidgetTimeline(metric: metric))
        ) { entry in
            ShiyuWidgetCard(entry: entry)
        }
        .configurationDisplayName(metric.title(chinese: Locale.preferredLanguages.first?.hasPrefix("zh") == true))
        .description("Shiyu countdown")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct ShiyuEarningsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "ShiyuEarnings",
            provider: ShiyuStaticProvider(timeline: WidgetTimeline(metric: .retirement, salary: true))
        ) { entry in
            ShiyuWidgetCard(entry: entry, salary: true)
        }
        .configurationDisplayName("时余 · Earnings")
        .description("Earnings today and this month.")
        .supportedFamilies([.systemSmall, .systemMedium])
            .contentMarginsDisabled()
    }
}

@main
struct ShiyuWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShiyuCountdownWidget()
        ShiyuEarningsWidget()
        FixedCountdownWidgets().body
    }
}

/// 固定指标组件保持独立的展示顺序。
private struct FixedCountdownWidgets: WidgetBundle {
    var body: some Widget {
        ShiyuFixedCountdownWidget(metric: .work)
        ShiyuFixedCountdownWidget(metric: .holiday)
        ShiyuFixedCountdownWidget(metric: .payday)
        ShiyuFixedCountdownWidget(metric: .life)
    }
}
