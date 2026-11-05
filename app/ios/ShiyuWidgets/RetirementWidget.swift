import AppIntents
import SwiftUI
import WidgetKit

private struct WidgetTimeline {
    let metric: WidgetMetric
    var salary = false

    func placeholder() -> ShiyuWidgetEntry {
        ShiyuWidgetEntry(date: Date(), snapshot: nil, appearance: WidgetAppearance(), locale: nil, metric: metric)
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
                         appearance: appearance, locale: input.locale, metric: metric)
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
    case work, holiday, payday, retirement

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Countdown"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .work: "Work", .holiday: "Holiday", .payday: "Payday", .retirement: "Retirement",
    ]

    var metric: WidgetMetric { WidgetMetric(rawValue: rawValue) ?? .retirement }
}

@available(iOS 17.0, *)
struct CountdownConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose a countdown"
    static var description: IntentDescription = "Select the main countdown for the small widget."

    @Parameter(title: "Countdown", default: .retirement)
    var option: CountdownOption
}

@available(iOS 17.0, *)
private struct CountdownIntentProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ShiyuWidgetEntry {
        WidgetTimeline(metric: .retirement).placeholder()
    }

    func snapshot(for configuration: CountdownConfiguration, in context: Context) async -> ShiyuWidgetEntry {
        WidgetTimeline(metric: configuration.option.metric).snapshot()
    }

    func timeline(for configuration: CountdownConfiguration, in context: Context) async -> Timeline<ShiyuWidgetEntry> {
        WidgetTimeline(metric: configuration.option.metric).make()
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
            .description("Work, holidays, payday, and retirement.")
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
    }
}

@main
struct ShiyuWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShiyuCountdownWidget()
        ShiyuEarningsWidget()
        ShiyuFixedCountdownWidget(metric: .work)
        ShiyuFixedCountdownWidget(metric: .holiday)
        ShiyuFixedCountdownWidget(metric: .payday)
    }
}
