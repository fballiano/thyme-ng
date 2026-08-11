import Foundation
import Testing
@testable import ThymeNG

@MainActor
@Suite("Preferences")
struct PreferencesTests {
    private func makeDefaults() -> UserDefaults {
        let name = "thyme-ng.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("The defaults match the original app, plus the session limit")
    func defaultValues() {
        let preferences = Preferences(defaults: makeDefaults())

        #expect(preferences.pauseOnSleep)
        #expect(preferences.pauseOnScreensaver)
        #expect(!preferences.askForTagOnFinish)
        #expect(preferences.showNotifications)
        #expect(preferences.maxStoredSessions == 10)
    }

    @Test("A change is written to the store")
    func writesThrough() {
        let defaults = makeDefaults()
        let preferences = Preferences(defaults: defaults)

        preferences.pauseOnSleep = false
        preferences.maxStoredSessions = 42

        #expect(defaults.bool(forKey: Preferences.Key.pauseOnSleep) == false)
        #expect(defaults.integer(forKey: Preferences.Key.maxStoredSessions) == 42)

        // A new instance reads the same values back.
        let reloaded = Preferences(defaults: defaults)
        #expect(!reloaded.pauseOnSleep)
        #expect(reloaded.maxStoredSessions == 42)
    }

    @Test("The limit switch turns the pruning on and off")
    func limitSwitch() {
        let preferences = Preferences(defaults: makeDefaults())

        #expect(preferences.limitsStoredSessions)

        preferences.limitsStoredSessions = false
        #expect(preferences.maxStoredSessions == Preferences.unlimited)

        preferences.limitsStoredSessions = true
        #expect(preferences.maxStoredSessions == Preferences.defaultSessionLimit)
    }

    @Test("A negative limit becomes zero")
    func clampsNegative() {
        let preferences = Preferences(defaults: makeDefaults())

        preferences.maxStoredSessions = -5

        #expect(preferences.maxStoredSessions == 0)
    }
}
