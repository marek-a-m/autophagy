import Foundation

struct FastingState: Codable, Equatable {
    var isFasting: Bool
    var fastingStartDate: Date?
    var lastFastingDuration: TimeInterval?

    init(isFasting: Bool = false, fastingStartDate: Date? = nil, lastFastingDuration: TimeInterval? = nil) {
        self.isFasting = isFasting
        self.fastingStartDate = fastingStartDate
        self.lastFastingDuration = lastFastingDuration
    }

    var currentFastingDuration: TimeInterval? {
        guard isFasting, let startDate = fastingStartDate else { return nil }
        return Date().timeIntervalSince(startDate)
    }

    var autophagyStarted: Bool {
        guard let duration = currentFastingDuration else { return false }
        return duration >= AutophagyConstants.autophagyThreshold
    }

    var timeUntilAutophagy: TimeInterval? {
        guard let duration = currentFastingDuration else { return nil }
        let remaining = AutophagyConstants.autophagyThreshold - duration
        return remaining > 0 ? remaining : nil
    }

    var autophagyDuration: TimeInterval? {
        guard let duration = currentFastingDuration, autophagyStarted else { return nil }
        return duration - AutophagyConstants.autophagyThreshold
    }
}

enum AutophagyConstants {
    static let autophagyThreshold: TimeInterval = 16 * 60 * 60 // 16 hours
    static let appGroupIdentifier = "group.cloud.buggygames.autophagy.app"
    static let fastingStateKey = "fastingState"
}

extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: AutophagyConstants.appGroupIdentifier) ?? .standard
    }
}

extension FastingState {
    static func load() -> FastingState {
        guard let data = UserDefaults.shared.data(forKey: AutophagyConstants.fastingStateKey),
              let state = try? JSONDecoder().decode(FastingState.self, from: data) else {
            return FastingState()
        }
        return state
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.shared.set(data, forKey: AutophagyConstants.fastingStateKey)
    }
}

extension TimeInterval {
    var formatted: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var shortFormatted: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
}
