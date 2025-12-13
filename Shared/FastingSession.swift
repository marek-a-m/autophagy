import Foundation

struct FastingSession: Codable, Identifiable, Equatable {
    let id: UUID
    let startDate: Date
    let endDate: Date

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var reachedAutophagy: Bool {
        duration >= AutophagyConstants.autophagyThreshold
    }

    var autophagyDuration: TimeInterval? {
        guard reachedAutophagy else { return nil }
        return duration - AutophagyConstants.autophagyThreshold
    }

    init(id: UUID = UUID(), startDate: Date, endDate: Date) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
    }
}

class FastingHistoryManager: ObservableObject {
    static let shared = FastingHistoryManager()

    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let historyKey = "fastingSessionsHistory"
    private let localHistoryKey = "localFastingSessionsHistory"

    @Published var sessions: [FastingSession] = []

    private init() {
        loadSessions()

        // Listen for iCloud changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidUpdate),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )

        // Sync with iCloud
        iCloudStore.synchronize()
    }

    @objc private func iCloudDidUpdate(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadSessions()
        }
    }

    private func loadSessions() {
        // Try iCloud first
        if let data = iCloudStore.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([FastingSession].self, from: data) {
            sessions = decoded.sorted { $0.startDate > $1.startDate }
            // Sync to local storage as backup
            saveToLocal(sessions)
            return
        }

        // Fall back to local storage
        if let data = UserDefaults.shared.data(forKey: localHistoryKey),
           let decoded = try? JSONDecoder().decode([FastingSession].self, from: data) {
            sessions = decoded.sorted { $0.startDate > $1.startDate }
            // Try to push to iCloud
            saveSessions()
        }
    }

    private func saveSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }

        // Save to iCloud
        iCloudStore.set(data, forKey: historyKey)
        iCloudStore.synchronize()

        // Save locally as backup
        saveToLocal(sessions)
    }

    private func saveToLocal(_ sessions: [FastingSession]) {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.shared.set(data, forKey: localHistoryKey)
    }

    func addSession(_ session: FastingSession) {
        sessions.insert(session, at: 0)
        saveSessions()
    }

    func deleteSession(_ session: FastingSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    func deleteSession(at indexSet: IndexSet) {
        sessions.remove(atOffsets: indexSet)
        saveSessions()
    }

    // Statistics
    var totalFasts: Int {
        sessions.count
    }

    var totalFastingTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var totalAutophagyTime: TimeInterval {
        sessions.compactMap { $0.autophagyDuration }.reduce(0, +)
    }

    var averageFastDuration: TimeInterval? {
        guard !sessions.isEmpty else { return nil }
        return totalFastingTime / Double(sessions.count)
    }

    var longestFast: FastingSession? {
        sessions.max { $0.duration < $1.duration }
    }

    var autophagySuccessRate: Double {
        guard !sessions.isEmpty else { return 0 }
        let autophagyCount = sessions.filter { $0.reachedAutophagy }.count
        return Double(autophagyCount) / Double(sessions.count)
    }
}
