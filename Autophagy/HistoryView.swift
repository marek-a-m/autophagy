import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyManager = FastingHistoryManager.shared

    var body: some View {
        List {
            if !historyManager.sessions.isEmpty {
                statsSection
            }

            sessionsSection
        }
        .navigationTitle("History")
    }

    private var statsSection: some View {
        Section("Statistics") {
            StatRow(title: "Total Fasts", value: "\(historyManager.totalFasts)")

            StatRow(title: "Total Fasting Time", value: historyManager.totalFastingTime.shortFormatted)

            StatRow(title: "Total Autophagy Time", value: historyManager.totalAutophagyTime.shortFormatted)

            if let average = historyManager.averageFastDuration {
                StatRow(title: "Average Fast", value: average.shortFormatted)
            }

            if let longest = historyManager.longestFast {
                StatRow(title: "Longest Fast", value: longest.duration.shortFormatted)
            }

            StatRow(
                title: "Autophagy Success Rate",
                value: String(format: "%.0f%%", historyManager.autophagySuccessRate * 100)
            )
        }
    }

    private var sessionsSection: some View {
        Section("Sessions") {
            if historyManager.sessions.isEmpty {
                Text("No fasting sessions yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(historyManager.sessions) { session in
                    SessionRow(session: session)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                historyManager.deleteSession(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct SessionRow: View {
    let session: FastingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.startDate, style: .date)
                    .font(.headline)
                Spacer()
                if session.reachedAutophagy {
                    Label("Autophagy", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            HStack {
                Label(formatTime(session.startDate), systemImage: "play.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Label(formatTime(session.endDate), systemImage: "stop.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(session.duration.shortFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(session.reachedAutophagy ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
