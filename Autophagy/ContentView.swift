import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @State private var showingHistory = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                VStack(spacing: 40) {
                    Spacer()

                    statusSection

                    timerSection

                    Spacer()

                    actionButton

                    if let lastDuration = fastingManager.state.lastFastingDuration, !fastingManager.state.isFasting {
                        lastFastSection(duration: lastDuration)
                    }

                    Spacer()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                NavigationStack {
                    HistoryView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    showingHistory = false
                                }
                            }
                        }
                }
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: fastingManager.state.autophagyStarted
                ? [Color.green.opacity(0.3), Color.black]
                : [Color.orange.opacity(0.3), Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var statusSection: some View {
        VStack(spacing: 8) {
            Text(fastingManager.state.isFasting ? "FASTING" : "EATING WINDOW")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            if fastingManager.state.autophagyStarted {
                Label("Autophagy Active", systemImage: "flame.fill")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            } else if fastingManager.state.isFasting {
                if let timeUntil = fastingManager.state.timeUntilAutophagy {
                    Text("Autophagy in \(timeUntil.shortFormatted)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    private var timerSection: some View {
        VStack(spacing: 16) {
            if fastingManager.state.isFasting {
                Text(fastingManager.displayedDuration.formatted)
                    .font(.system(size: 64, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)

                if fastingManager.state.autophagyStarted, let autophagyDuration = fastingManager.state.autophagyDuration {
                    VStack(spacing: 4) {
                        Text("Autophagy Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(autophagyDuration.formatted)
                            .font(.system(size: 24, weight: .light, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
            } else {
                Text("00:00:00")
                    .font(.system(size: 64, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }

    private var actionButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                fastingManager.toggleFasting()
                WatchConnectivityManager.shared.sendState(fastingManager.state)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: fastingManager.state.isFasting ? "stop.fill" : "play.fill")
                Text(fastingManager.state.isFasting ? "End Fast" : "Start Fast")
                    .fontWeight(.semibold)
            }
            .font(.title3)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(fastingManager.state.isFasting ? Color.red : Color.green)
            )
        }
        .padding(.horizontal, 32)
    }

    private func lastFastSection(duration: TimeInterval) -> some View {
        VStack(spacing: 4) {
            Text("Last Fast")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(duration.shortFormatted)
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FastingManager.shared)
}
