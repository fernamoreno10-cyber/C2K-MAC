import Testing
import Foundation
@testable import KeyboardCleanerLib

@Suite("AppStateTests")
struct AppStateTests {

    @Test func test_formattedTime_twoMinutes() {
        let state = AppState(defaults: makeDefaults())
        state.timeRemaining = 120
        #expect(state.formattedTime() == "2:00")
    }

    @Test func test_formattedTime_oneMinuteThirty() {
        let state = AppState(defaults: makeDefaults())
        state.timeRemaining = 90
        #expect(state.formattedTime() == "1:30")
    }

    @Test func test_formattedTime_zero() {
        let state = AppState(defaults: makeDefaults())
        state.timeRemaining = 0
        #expect(state.formattedTime() == "0:00")
    }

    @Test func test_duration_defaultIs120WhenNoValue() {
        let defaults = makeDefaults()
        defaults.removeObject(forKey: "cleanDuration")
        let state = AppState(defaults: defaults)
        #expect(state.duration == 120)
    }

    @Test func test_duration_persistsToUserDefaults() {
        let defaults = makeDefaults()
        let state = AppState(defaults: defaults)
        state.duration = 300
        #expect(defaults.integer(forKey: "cleanDuration") == 300)
    }

    @Test func test_duration_readsFromUserDefaults() {
        let defaults = makeDefaults()
        defaults.set(180, forKey: "cleanDuration")
        let state = AppState(defaults: defaults)
        #expect(state.duration == 180)
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: UUID().uuidString)!
    }
}
