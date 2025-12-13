import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @State private var showingHistory = false
    @State private var showingStartFasting = false
    @State private var selectedStartTime = Date()

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
            .sheet(isPresented: $showingStartFasting) {
                StartFastingSheet(
                    selectedStartTime: $selectedStartTime,
                    onStart: {
                        fastingManager.startFasting(from: selectedStartTime)
                        WatchConnectivityManager.shared.sendState(fastingManager.state)
                        showingStartFasting = false
                    },
                    onCancel: {
                        showingStartFasting = false
                    }
                )
                .presentationDetents([.height(380)])
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
            if fastingManager.state.isFasting {
                withAnimation(.spring(response: 0.3)) {
                    fastingManager.stopFasting()
                    WatchConnectivityManager.shared.sendState(fastingManager.state)
                }
            } else {
                selectedStartTime = Date()
                showingStartFasting = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: fastingManager.state.isFasting ? "stop.fill" : "play.fill")
                Text(fastingManager.state.isFasting ? "End Fasting" : "Start Fasting")
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

struct StartFastingSheet: View {
    @Binding var selectedStartTime: Date
    let onStart: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundColor(.blue)
                Spacer()
                Text("Start Fasting")
                    .font(.headline)
                Spacer()
                // Invisible button for balance
                Button("Cancel") {}
                    .opacity(0)
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Text("When did you stop eating?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            DatePicker(
                "Start Time",
                selection: $selectedStartTime,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 180)

            Button(action: onStart) {
                Text("Start Fasting")
                    .fontWeight(.semibold)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                    )
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FastingManager.shared)
}
