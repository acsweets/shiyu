import AppIntents
import SwiftUI
import WidgetKit

private struct WidgetTimeline {
    let metric: WidgetMetric
    /// 由组件的 App Intent 配置传入。
    var additionalMetrics: [WidgetMetric] = []
    /// 既有中尺寸组件的默认布局开关。
    var useMediumPreset = true

    func placeholder() -> ShiyuWidgetEntry {
        ShiyuWidgetEntry(date: Date(), snapshot: nil, appearance: WidgetAppearance(),
                         locale: nil, metric: metric, additionalMetrics: additionalMetrics,
                         useMediumPreset: useMediumPreset)
    }

    func snapshot() -> ShiyuWidgetEntry {
        entry(Date(), WidgetInputs.load(), .load())
    }

    func make() -> Timeline<ShiyuWidgetEntry> {
        let now = Date()
        let appearance = WidgetAppearance.load()
        let input = WidgetInputs.load()
        let first = entry(now, input, appearance)
        let horizon = now.addingTimeInterval(first.hasEarnings ? 60 : 900)
        let boundary = first.snapshot.map {
            Date(timeIntervalSince1970: Double($0.next_change_at_millis) / 1000)
        }
        // 薪资只保留当前样本，隐藏金额变更后无需等预先生成的金额条目过期。
        if let boundary, boundary > now, boundary <= horizon {
            if first.hasEarnings { return Timeline(entries: [first], policy: .after(boundary)) }
            let changed = entry(boundary, input, appearance)
            let refresh = max(now.addingTimeInterval(60), boundary.addingTimeInterval(1))
            return Timeline(entries: [first, changed], policy: .after(refresh))
        }
        return Timeline(entries: [first], policy: .after(horizon))
    }

    private func entry(_ date: Date, _ input: WidgetInputs, _ appearance: WidgetAppearance) -> ShiyuWidgetEntry {
        ShiyuWidgetEntry(date: date, snapshot: input.snapshot(at: date),
                         appearance: appearance, locale: input.locale,
                         metric: metric, additionalMetrics: additionalMetrics,
                         useMediumPreset: useMediumPreset)
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
    case todaySalary = "today_salary"
    case monthSalary = "month_salary"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Widget metric"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .work: "Work", .holiday: "Holiday", .payday: "Payday", .retirement: "Retirement", .life: "Life",
        .todaySalary: "Earned today", .monthSalary: "Earned this month",
    ]

    var metric: WidgetMetric { WidgetMetric(rawValue: rawValue) ?? .retirement }
}

@available(iOS 17.0, *)
struct CountdownConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose what to display"
    static var description: IntentDescription = "Combine up to four countdown or earnings metrics."

    @Parameter(title: "Main metric", default: .retirement)
    var option: CountdownOption

    @Parameter(title: "Second metric")
    var second: CountdownOption?

    @Parameter(title: "Third metric")
    var third: CountdownOption?

    @Parameter(title: "Fourth metric")
    var fourth: CountdownOption?

    @Parameter(title: "Use medium preset for one countdown", default: true)
    var useMediumPreset: Bool
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
        configuredTimeline(configuration).snapshot()
    }

    func timeline(for configuration: CountdownConfiguration, in context: Context) async -> Timeline<ShiyuWidgetEntry> {
        configuredTimeline(configuration).make()
    }

    private func configuredTimeline(_ configuration: CountdownConfiguration) -> WidgetTimeline {
        let additional = [configuration.second, configuration.third, configuration.fourth]
        return WidgetTimeline(
            metric: configuration.option.metric,
            additionalMetrics: additional.compactMap { $0?.metric },
            useMediumPreset: configuration.useMediumPreset
        )
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
            .description("Combine countdowns and earnings in one card.")
            .supportedFamilies([.systemSmall, .systemMedium])
            .contentMarginsDisabled()
    }
}

/// 系统图库提供单项卡，既有倒计时组件保留原系统标识。
private struct ShiyuFixedCountdownWidget: Widget {
    let metric: WidgetMetric

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "ShiyuCountdown.\(metric.rawValue)",
            provider: ShiyuStaticProvider(timeline: WidgetTimeline(metric: metric, useMediumPreset: false))
        ) { entry in
            ShiyuWidgetCard(entry: entry)
        }
        .configurationDisplayName(metric.title(chinese: Locale.preferredLanguages.first?.hasPrefix("zh") == true))
        .description("One Shiyu metric.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct ShiyuEarningsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "ShiyuEarnings",
            provider: ShiyuStaticProvider(timeline: WidgetTimeline(
                metric: .todaySalary, additionalMetrics: [.monthSalary], useMediumPreset: false
            ))
        ) { entry in
            ShiyuWidgetCard(entry: entry)
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
        FixedEarningsWidgets().body
    }
}

/// 旧系统也能从图库添加单项薪资卡。
private struct FixedEarningsWidgets: WidgetBundle {
    var body: some Widget {
        ShiyuFixedCountdownWidget(metric: .todaySalary)
        ShiyuFixedCountdownWidget(metric: .monthSalary)
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
