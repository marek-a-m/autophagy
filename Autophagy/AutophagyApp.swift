import SwiftUI
import WidgetKit

@main
struct AutophagyApp: App {
    @StateObject private var fastingManager = FastingManager.shared
    @Environment(\.scenePhase) private var scenePhase
    private let connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fastingManager)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        fastingManager.refreshFromStorage()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
        }
    }
}
