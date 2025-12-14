import SwiftUI
import WidgetKit

@main
struct AutophagyWatchApp: App {
    @StateObject private var fastingManager = FastingManager.shared
    @Environment(\.scenePhase) private var scenePhase
    private let connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(fastingManager)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
