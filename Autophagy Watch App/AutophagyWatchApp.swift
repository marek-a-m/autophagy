import SwiftUI

@main
struct AutophagyWatchApp: App {
    @StateObject private var fastingManager = FastingManager.shared
    private let connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(fastingManager)
        }
    }
}
