import WidgetKit
import SwiftUI

struct FastingEntry: TimelineEntry {
    let date: Date
    let state: FastingState
}

struct FastingTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastingEntry {
        FastingEntry(date: Date(), state: FastingState(isFasting: true, fastingStartDate: Date().addingTimeInterval(-3600 * 8)))
    }

    func getSnapshot(in context: Context, completion: @escaping (FastingEntry) -> Void) {
        let state = FastingState.load()
        completion(FastingEntry(date: Date(), state: state))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingEntry>) -> Void) {
        let state = FastingState.load()
        let currentDate = Date()

        var entries: [FastingEntry] = []

        // Update every minute for accurate timer display
        for minuteOffset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            entries.append(FastingEntry(date: entryDate, state: state))
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct AutophagyWidgetEntryView: View {
    var entry: FastingEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(state: entry.state, currentDate: entry.date)
        case .systemMedium:
            MediumWidgetView(state: entry.state, currentDate: entry.date)
        case .accessoryCircular:
            CircularWidgetView(state: entry.state, currentDate: entry.date)
        case .accessoryRectangular:
            RectangularWidgetView(state: entry.state, currentDate: entry.date)
        default:
            SmallWidgetView(state: entry.state, currentDate: entry.date)
        }
    }
}

struct SmallWidgetView: View {
    let state: FastingState
    let currentDate: Date

    private var duration: TimeInterval {
        guard state.isFasting, let startDate = state.fastingStartDate else { return 0 }
        return currentDate.timeIntervalSince(startDate)
    }

    private var autophagyActive: Bool {
        duration >= AutophagyConstants.autophagyThreshold
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: autophagyActive ? "flame.fill" : "timer")
                    .foregroundColor(autophagyActive ? .green : .orange)
                Spacer()
            }

            Spacer()

            if state.isFasting {
                Text(duration.compactFormatted)
                    .font(.system(size: 36, weight: .medium, design: .monospaced))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Text(autophagyActive ? "Autophagy" : "Fasting")
                    .font(.caption)
                    .foregroundColor(autophagyActive ? .green : .orange)
            } else {
                Text("Not Fasting")
                    .font(.headline)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundColor(.secondary)

                if let lastDuration = state.lastFastingDuration {
                    Text("Last: \(lastDuration.shortFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct MediumWidgetView: View {
    let state: FastingState
    let currentDate: Date

    private var duration: TimeInterval {
        guard state.isFasting, let startDate = state.fastingStartDate else { return 0 }
        return currentDate.timeIntervalSince(startDate)
    }

    private var autophagyActive: Bool {
        duration >= AutophagyConstants.autophagyThreshold
    }

    private var progress: Double {
        min(duration / AutophagyConstants.autophagyThreshold, 1.0)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: autophagyActive ? "flame.fill" : "timer")
                        .foregroundColor(autophagyActive ? .green : .orange)
                    Text(state.isFasting ? (autophagyActive ? "Autophagy" : "Fasting") : "Not Fasting")
                        .font(.headline)
                        .foregroundColor(autophagyActive ? .green : (state.isFasting ? .orange : .secondary))
                }

                if state.isFasting {
                    Text(duration.compactFormatted)
                        .font(.system(size: 36, weight: .medium, design: .monospaced))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                } else if let lastDuration = state.lastFastingDuration {
                    Text("Last: \(lastDuration.shortFormatted)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if state.isFasting {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(autophagyActive ? Color.green : Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 16, weight: .bold))
                        if !autophagyActive {
                            let remaining = AutophagyConstants.autophagyThreshold - duration
                            Text(remaining.shortFormatted)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 70, height: 70)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct CircularWidgetView: View {
    let state: FastingState
    let currentDate: Date

    private var duration: TimeInterval {
        guard state.isFasting, let startDate = state.fastingStartDate else { return 0 }
        return currentDate.timeIntervalSince(startDate)
    }

    private var autophagyActive: Bool {
        duration >= AutophagyConstants.autophagyThreshold
    }

    private var progress: Double {
        min(duration / AutophagyConstants.autophagyThreshold, 1.0)
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            if state.isFasting {
                Gauge(value: progress) {
                    Image(systemName: autophagyActive ? "flame.fill" : "timer")
                }
                .gaugeStyle(.accessoryCircular)
                .tint(autophagyActive ? .green : .orange)
            } else {
                Image(systemName: "moon.zzz")
                    .font(.title2)
            }
        }
    }
}

struct RectangularWidgetView: View {
    let state: FastingState
    let currentDate: Date

    private var duration: TimeInterval {
        guard state.isFasting, let startDate = state.fastingStartDate else { return 0 }
        return currentDate.timeIntervalSince(startDate)
    }

    private var autophagyActive: Bool {
        duration >= AutophagyConstants.autophagyThreshold
    }

    private var progress: Double {
        min(duration / AutophagyConstants.autophagyThreshold, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: autophagyActive ? "flame.fill" : "timer")
                Text(state.isFasting ? (autophagyActive ? "Autophagy" : "Fasting") : "Not Fasting")
                    .font(.headline)
            }

            if state.isFasting {
                Text(duration.compactFormatted)
                    .font(.system(.body, design: .monospaced))

                Gauge(value: progress) { }
                    .gaugeStyle(.accessoryLinear)
                    .tint(autophagyActive ? .green : .orange)
            }
        }
    }
}

struct AutophagyWidget: Widget {
    let kind: String = "AutophagyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingTimelineProvider()) { entry in
            AutophagyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fasting Timer")
        .description("Track your fasting progress and autophagy status.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    AutophagyWidget()
} timeline: {
    FastingEntry(date: .now, state: FastingState(isFasting: true, fastingStartDate: Date().addingTimeInterval(-3600 * 8)))
    FastingEntry(date: .now, state: FastingState(isFasting: true, fastingStartDate: Date().addingTimeInterval(-3600 * 18)))
}
