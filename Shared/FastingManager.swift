import Foundation
import Combine
import WidgetKit

@MainActor
class FastingManager: ObservableObject {
    static let shared = FastingManager()

    @Published var state: FastingState {
        didSet {
            state.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @Published var displayedDuration: TimeInterval = 0

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.state = FastingState.load()
        setupTimer()
    }

    private func setupTimer() {
        timer?.invalidate()

        if state.isFasting {
            updateDisplayedDuration()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.updateDisplayedDuration()
                }
            }
        } else {
            displayedDuration = 0
        }
    }

    private func updateDisplayedDuration() {
        if let duration = state.currentFastingDuration {
            displayedDuration = duration
        }
    }

    func startFasting(from startDate: Date = Date()) {
        state = FastingState(
            isFasting: true,
            fastingStartDate: startDate,
            lastFastingDuration: state.lastFastingDuration
        )
        setupTimer()
    }

    func stopFasting(at endDate: Date = Date()) {
        // Save session to history before clearing state
        if let startDate = state.fastingStartDate {
            let session = FastingSession(
                startDate: startDate,
                endDate: endDate
            )
            FastingHistoryManager.shared.addSession(session)
        }

        let duration = endDate.timeIntervalSince(state.fastingStartDate ?? endDate)
        state = FastingState(
            isFasting: false,
            fastingStartDate: nil,
            lastFastingDuration: duration
        )
        timer?.invalidate()
        timer = nil
        displayedDuration = 0
    }

    func toggleFasting() {
        if state.isFasting {
            stopFasting()
        } else {
            startFasting()
        }
    }

    func updateFromWatch(_ newState: FastingState) {
        state = newState
        setupTimer()
    }
}
