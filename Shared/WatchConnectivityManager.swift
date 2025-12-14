import Foundation
import WatchConnectivity
import WidgetKit

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendState(_ state: FastingState) {
        guard WCSession.default.activationState == .activated else { return }

        guard let data = try? JSONEncoder().encode(state) else { return }
        let message = ["state": data]

        #if os(iOS)
        if WCSession.default.isWatchAppInstalled {
            try? WCSession.default.updateApplicationContext(message)
            // Also send complication update for immediate widget refresh
            if WCSession.default.isComplicationEnabled {
                WCSession.default.transferCurrentComplicationUserInfo(message)
            }
        }
        #else
        if WCSession.default.isCompanionAppInstalled {
            try? WCSession.default.updateApplicationContext(message)
        }
        #endif
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleReceivedState(applicationContext)
    }

    #if os(watchOS)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleReceivedState(userInfo)
        // Immediately reload widget when receiving complication update from iPhone
        WidgetCenter.shared.reloadAllTimelines()
    }
    #endif

    private func handleReceivedState(_ data: [String: Any]) {
        guard let data = data["state"] as? Data,
              let state = try? JSONDecoder().decode(FastingState.self, from: data) else { return }

        Task { @MainActor in
            FastingManager.shared.updateFromWatch(state)
        }
    }
}
