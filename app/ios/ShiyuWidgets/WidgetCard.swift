import SwiftUI
import WidgetKit

struct ShiyuWidgetCard: View {
    let entry: ShiyuWidgetEntry
    var salary = false

    @Environment(\.widgetFamily) private var family
    private var compact: Bool { family == .systemSmall }
    private var appearance: WidgetAppearance { entry.appearance }

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
                    earnings
                } else if compact {
                    countdown(entry.metric)
                } else {
                    HStack(spacing: 6) {
                        countdown(.work)
                        countdown(.holiday)
                    }
                    HStack(spacing: 6) {
                        countdown(.payday)
                        countdown(.retirement)
                    }
                }
                if entry.snapshot != nil {
                    updated
                        .font(.system(size: 9, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundColor(appearance.colors.ink)
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(appearance.colors.surface))
            .padding(.top, 28)

            Image("widget_cat", bundle: .main)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 34)
                .accessibilityHidden(true)
        }
    }

    private var updated: Text {
        let age = Text(entry.date, style: .relative)
        return entry.chinese ? Text("\(age) 前更新") : Text("Updated \(age) ago")
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
        return line(label, size: compact ? 17 : 23, alwaysLabel: true) { Text(value).privacySensitive() }
    }

    private func countdown(_ metric: WidgetMetric) -> some View {
        let value = entry.snapshot?.countdown(metric)
        let title = metric.title(value, chinese: entry.chinese)
        return line(title, size: compact ? 24 : 16) { countdownValue(value) }
    }

    private func line<Content: View>(
        _ title: String, size: CGFloat, alwaysLabel: Bool = false, @ViewBuilder value: () -> Content
    ) -> some View {
        VStack(spacing: 2) {
            if alwaysLabel || appearance.titleVisible != false {
                Text(title)
                    .font(.system(size: CGFloat(min(compact && !salary ? 24 : 14, max(10, appearance.titleSize ?? 16))),
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
           value.remaining_seconds < 86_400, target > entry.date {
            Text(timerInterval: entry.date...target, pauseTime: target, countsDown: true)
        } else {
            Text(formattedCountdown(value))
        }
    }

    private func formattedCountdown(_ value: WidgetSnapshot.Countdown?) -> String {
        guard let value else { return entry.chinese ? "检查设置" : "Check settings" }
        switch value.status {
        case "retired": return entry.chinese ? "已退休" : "Retired"
        case "today": return entry.chinese ? "今天发薪" : "Payday today"
        case "unconfigured": return entry.chinese ? "未设置" : "Not set"
        default:
            guard value.target_millis != nil else { return entry.chinese ? "暂不可用" : "Unavailable" }
            let seconds = max(0, value.remaining_seconds)
            let clock = String(format: "%02lld:%02lld:%02lld",
                               seconds / 3_600 % 24, seconds / 60 % 60, seconds % 60)
            guard seconds >= 86_400 else { return clock }
            let locale = entry.locale.map { Locale(identifier: $0) } ?? .current
            let days = (seconds / 86_400).formatted(.number.locale(locale))
            return entry.chinese ? "\(days) 天 \(clock)" : "\(days)d \(clock)"
        }
    }
}
