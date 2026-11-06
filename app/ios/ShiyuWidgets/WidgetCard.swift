import AppIntents
import SwiftUI
import WidgetKit

struct ShiyuWidgetCard: View {
    let entry: ShiyuWidgetEntry
    var salary = false

    @Environment(\.widgetFamily) private var family
    private var compact: Bool { family == .systemSmall }
    private var appearance: WidgetAppearance { entry.appearance }

    /// 保留既有组件的默认布局，显式追加时只显示去重后的选择。
    private var countdowns: [WidgetMetric] {
        if entry.additionalMetrics.isEmpty {
            if compact { return [entry.metric] }
            return [.work, .holiday, .payday, entry.metric == .life ? .life : .retirement]
        }
        var selected = [entry.metric]
        for metric in entry.additionalMetrics where !selected.contains(metric) {
            selected.append(metric)
        }
        return selected
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            surface.containerBackground(Color.clear, for: .widget)
        } else {
            surface
        }
    }

    private var surface: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 4) {
                if salary {
                    if #available(iOS 17.0, *) {
                        earningsRefresh
                    }
                    earnings
                } else {
                    countdownGrid
                }
            }
            .foregroundColor(appearance.colors.ink)
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(cardBackground)
            .padding(.top, 28)

            Image("widget_cat", bundle: .main)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 34)
                .accessibilityHidden(true)
        }
    }

    @available(iOS 17.0, *)
    private var earningsRefresh: some View {
        Button(intent: RefreshEarningsIntent()) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(entry.chinese ? "刷新已赚" : "Refresh earnings"))
    }

    private var countdownGrid: some View {
        let metrics = countdowns
        let columns = compact && metrics.count <= 2 ? 1 : 2
        return ForEach(Array(stride(from: 0, to: metrics.count, by: columns)), id: \.self) { index in
            HStack(spacing: 6) {
                ForEach(metrics[index..<min(index + columns, metrics.count)], id: \.self) { metric in
                    countdown(metric, single: metrics.count == 1)
                }
            }
        }
    }

    @ViewBuilder private var cardBackground: some View {
        let card = RoundedRectangle(cornerRadius: 16)
        if let glass = appearance.glassGradient {
            card.fill(glass).overlay(card.strokeBorder(Color.white.opacity(0.83), lineWidth: 1))
        } else {
            card.fill(appearance.colors.surface)
        }
    }

    @ViewBuilder private var earnings: some View {
        if compact {
            VStack(spacing: 3) {
                earning(month: false)
                earning(month: true)
            }
        } else {
            HStack(spacing: 6) {
                earning(month: false)
                earning(month: true)
            }
        }
    }

    private func earning(month: Bool) -> some View {
        let label = month
            ? (entry.chinese ? "本月已赚" : "Earned this month")
            : (entry.chinese ? "今日已赚" : "Earned today")
        let value = entry.snapshot?.salary.amount(month: month, chinese: entry.chinese)
            ?? (entry.chinese ? "检查设置" : "Check settings")
        return line(label, id: month ? "month_salary" : "today_salary", size: compact ? 17 : 23, alwaysLabel: true) {
            Text(value).privacySensitive()
        }
    }

    private func countdown(_ metric: WidgetMetric, single: Bool) -> some View {
        let value = entry.snapshot?.countdown(metric)
        let title = metric.title(value, chinese: entry.chinese)
        let size: CGFloat = compact && single ? 24 : 16
        return line(title, id: metric.rawValue, size: size, largeTitle: compact && single) {
            countdownValue(value)
        }
    }

    private func line<Content: View>(
        _ title: String, id: String, size: CGFloat, alwaysLabel: Bool = false,
        largeTitle: Bool = false, @ViewBuilder value: () -> Content
    ) -> some View {
        VStack(spacing: 2) {
            if entry.snapshot?.hidden_metric_titles?.contains(id) != true &&
                (alwaysLabel || appearance.titleVisible != false) {
                Text(title)
                    .font(.system(size: CGFloat(min(largeTitle ? 24 : 14, max(10, appearance.titleSize ?? 16))),
                                  weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            value()
                .font(.system(size: size, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.45)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func countdownValue(_ value: WidgetSnapshot.Countdown?) -> some View {
        if #available(iOS 16.0, *),
           let value, let target = value.target, value.status != "today",
           value.remaining_seconds > 0, target > entry.date {
            Text(timerInterval: entry.date...target, pauseTime: target, countsDown: true)
        } else {
            Text(formattedCountdown(value))
        }
    }

    private func formattedCountdown(_ value: WidgetSnapshot.Countdown?) -> String {
        guard let value else { return entry.chinese ? "检查设置" : "Check settings" }
        let locale = entry.locale.map { Locale(identifier: $0) } ?? .current
        switch value.status {
        case "retired": return entry.chinese ? "已退休" : "Retired"
        case "exceeded": return entry.chinese ? "已结束" : "Ended"
        case "today": return entry.chinese ? "今天发薪" : "Payday today"
        case "unconfigured": return entry.chinese ? "未设置" : "Not set"
        case "elapsed":
            guard let days = value.elapsed_days else { return entry.chinese ? "未设置" : "Not set" }
            let number = days.formatted(.number.locale(locale))
            if entry.chinese { return "\(number) 天" }
            return days == 1 ? "\(number) day" : "\(number) days"
        default:
            guard value.target_millis != nil else { return entry.chinese ? "暂不可用" : "Unavailable" }
            let seconds = max(0, value.remaining_seconds)
            let clock = String(format: "%02lld:%02lld:%02lld",
                               seconds / 3_600 % 24, seconds / 60 % 60, seconds % 60)
            guard seconds >= 86_400 else { return clock }
            let days = (seconds / 86_400).formatted(.number.locale(locale))
            return entry.chinese ? "\(days) 天 \(clock)" : "\(days)d \(clock)"
        }
    }
}
