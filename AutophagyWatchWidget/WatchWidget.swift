import WidgetKit
import SwiftUI

struct WatchFastingEntry: TimelineEntry {
    let date: Date
    let state: FastingState
}

struct WatchFastingTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchFastingEntry {
        WatchFastingEntry(date: Date(), state: FastingState(isFasting: true, fastingStartDate: Date().addingTimeInterval(-3600 * 8)))
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchFastingEntry) -> Void) {
        let state = FastingState.load()
        completion(WatchFastingEntry(date: Date(), state: state))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchFastingEntry>) -> Void) {
        let state = FastingState.load()
        let currentDate = Date()

        var entries: [WatchFastingEntry] = []

        // Update every minute
        for minuteOffset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            entries.append(WatchFastingEntry(date: entryDate, state: state))
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WatchWidgetEntryView: View {
    var entry: WatchFastingEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            WatchCircularView(state: entry.state, currentDate: entry.date)
        case .accessoryRectangular:
            WatchRectangularView(state: entry.state, currentDate: entry.date)
        case .accessoryInline:
            WatchInlineView(state: entry.state, currentDate: entry.date)
        case .accessoryCorner:
            WatchCornerView(state: entry.state, currentDate: entry.date)
        default:
            WatchCircularView(state: entry.state, currentDate: entry.date)
        }
    }
}

struct WatchCircularView: View {
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
        if state.isFasting {
            Gauge(value: progress) {
                Image(systemName: autophagyActive ? "flame.fill" : "timer")
                    .foregroundColor(autophagyActive ? .green : .orange)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(autophagyActive ? .green : .orange)
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "fork.knife")
                    .font(.title2)
            }
        }
    }
}

struct WatchRectangularView: View {
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
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: autophagyActive ? "flame.fill" : "timer")
                    .foregroundColor(autophagyActive ? .green : .orange)
                Text(state.isFasting ? (autophagyActive ? "Autophagy" : "Fasting") : "Not Fasting")
                    .font(.headline)
            }

            if state.isFasting {
                Text(duration.compactFormatted)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                Gauge(value: progress) { }
                    .gaugeStyle(.accessoryLinear)
                    .tint(autophagyActive ? .green : .orange)
            } else if let lastDuration = state.lastFastingDuration {
                Text("Last: \(lastDuration.shortFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WatchInlineView: View {
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
        if state.isFasting {
            HStack(spacing: 4) {
                Image(systemName: autophagyActive ? "flame.fill" : "timer")
                Text(duration.shortFormatted)
            }
        } else {
            Text("Not Fasting")
        }
    }
}

struct WatchCornerView: View {
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
        if state.isFasting {
            Text(duration.shortFormatted)
                .font(.system(size: 14, weight: .medium))
                .widgetCurvesContent()
                .widgetLabel {
                    Gauge(value: progress) {
                        Text(autophagyActive ? "A" : "F")
                    }
                    .gaugeStyle(.accessoryLinear)
                    .tint(autophagyActive ? .green : .orange)
                }
        } else {
            Image(systemName: "fork.knife")
                .font(.title3)
                .widgetLabel {
                    Text("Not Fasting")
                }
        }
    }
}

struct AutophagyWatchWidget: Widget {
    let kind: String = "AutophagyWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchFastingTimelineProvider()) { entry in
            WatchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fasting Timer")
        .description("Track your fasting and autophagy.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

#Preview(as: .accessoryCircular) {
    AutophagyWatchWidget()
} timeline: {
    WatchFastingEntry(date: .now, state: FastingState(isFasting: true, fastingStartDate: Date().addingTimeInterval(-3600 * 8)))
}
