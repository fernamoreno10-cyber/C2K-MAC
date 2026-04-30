import Combine
import Foundation

public class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public var isLocked: Bool = false
    @Published public var timeRemaining: Int = 0
    public var onUnlock: (() -> Void)?

    private let defaults: UserDefaults
    private var timerCancellable: AnyCancellable?

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var duration: Int {
        get {
            let v = defaults.integer(forKey: "cleanDuration")
            return v == 0 ? 120 : v
        }
        set { defaults.set(newValue, forKey: "cleanDuration") }
    }

    @Published public var isEmergency: Bool = false

    public func startCleaning(overrideDuration: Int? = nil) {
        guard !isLocked else { return }
        isEmergency = overrideDuration != nil
        timeRemaining = overrideDuration ?? duration
        isLocked = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stopCleaning()
                }
            }
    }

    public func stopCleaning() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isLocked = false
        isEmergency = false
        onUnlock?()
    }

    public func formattedTime() -> String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }
}
