import Foundation
import WatchConnectivity

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
        guard let data = applicationContext["state"] as? Data,
              let state = try? JSONDecoder().decode(FastingState.self, from: data) else { return }

        Task { @MainActor in
            FastingManager.shared.updateFromWatch(state)
        }
    }
}
