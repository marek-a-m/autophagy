import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var fastingManager: FastingManager

    var body: some View {
        VStack(spacing: 8) {
            statusIndicator

            timerDisplay

            Spacer()

            actionButton
        }
        .padding(.vertical, 8)
    }

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            if fastingManager.state.autophagyStarted {
                Image(systemName: "flame.fill")
                    .foregroundColor(.green)
                Text("Autophagy")
                    .foregroundColor(.green)
            } else if fastingManager.state.isFasting {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                Text("Fasting")
                    .foregroundColor(.orange)
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                Text("Not Fasting")
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption2)
    }

    private var timerDisplay: some View {
        VStack(spacing: 4) {
            if fastingManager.state.isFasting {
                Text(fastingManager.displayedDuration.formatted)
                    .font(.system(size: 32, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)

                if let timeUntil = fastingManager.state.timeUntilAutophagy {
                    Text("Autophagy in \(timeUntil.shortFormatted)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else if let autophagyDuration = fastingManager.state.autophagyDuration {
                    Text("Active: \(autophagyDuration.shortFormatted)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            } else {
                Text("00:00:00")
                    .font(.system(size: 32, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))

                if let lastDuration = fastingManager.state.lastFastingDuration {
                    Text("Last: \(lastDuration.shortFormatted)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var actionButton: some View {
        Button(action: {
            fastingManager.toggleFasting()
            WatchConnectivityManager.shared.sendState(fastingManager.state)
        }) {
            HStack(spacing: 6) {
                Image(systemName: fastingManager.state.isFasting ? "stop.fill" : "play.fill")
                Text(fastingManager.state.isFasting ? "End" : "Start")
            }
            .font(.body)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(fastingManager.state.isFasting ? Color.red : Color.green)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WatchContentView()
        .environmentObject(FastingManager.shared)
}
