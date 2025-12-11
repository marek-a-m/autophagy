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

    func startFasting() {
        state = FastingState(
            isFasting: true,
            fastingStartDate: Date(),
            lastFastingDuration: state.lastFastingDuration
        )
        setupTimer()
    }

    func stopFasting() {
        let duration = state.currentFastingDuration
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
