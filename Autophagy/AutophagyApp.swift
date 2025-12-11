import SwiftUI

@main
struct AutophagyApp: App {
    @StateObject private var fastingManager = FastingManager.shared
    private let connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fastingManager)
        }
    }
}
