import Foundation
import Observation

/// The user settings, stored in `UserDefaults`.
@MainActor
@Observable
final class Preferences {
    enum Key {
        static let pauseOnSleep = "pauseOnSleep"
        static let pauseOnScreensaver = "pauseOnScreensaver"
        static let askForTagOnFinish = "askForTagOnFinish"
        static let showNotifications = "showNotifications"
        static let maxStoredSessions = "maxStoredSessions"
        static let appliedDefaultLoginItem = "appliedDefaultLoginItem"
    }

    /// The value of `maxStoredSessions` that means "keep every session".
    static let unlimited = 0

    /// The default value of `maxStoredSessions`.
    static let defaultSessionLimit = 10

    @ObservationIgnored
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Key.pauseOnSleep: true,
            Key.pauseOnScreensaver: true,
            Key.askForTagOnFinish: false,
            Key.showNotifications: true,
            Key.maxStoredSessions: Self.defaultSessionLimit,
            Key.appliedDefaultLoginItem: false,
        ])

        pauseOnSleep = defaults.bool(forKey: Key.pauseOnSleep)
        pauseOnScreensaver = defaults.bool(forKey: Key.pauseOnScreensaver)
        askForTagOnFinish = defaults.bool(forKey: Key.askForTagOnFinish)
        showNotifications = defaults.bool(forKey: Key.showNotifications)
        storedMaxSessions = max(0, defaults.integer(forKey: Key.maxStoredSessions))
        appliedDefaultLoginItem = defaults.bool(forKey: Key.appliedDefaultLoginItem)
    }

    /// Pause when the Mac goes to sleep, continue when it wakes.
    var pauseOnSleep: Bool {
        didSet { defaults.set(pauseOnSleep, forKey: Key.pauseOnSleep) }
    }

    /// Pause when the screensaver starts or the screen locks.
    var pauseOnScreensaver: Bool {
        didSet { defaults.set(pauseOnScreensaver, forKey: Key.pauseOnScreensaver) }
    }

    /// Ask for a tag each time a session finishes.
    var askForTagOnFinish: Bool {
        didSet { defaults.set(askForTagOnFinish, forKey: Key.askForTagOnFinish) }
    }

    /// Show a notification on start, pause and stop.
    var showNotifications: Bool {
        didSet { defaults.set(showNotifications, forKey: Key.showNotifications) }
    }

    /// `true` after the app has registered the login item once.
    ///
    /// The app starts at login by default, so the first launch registers the
    /// login item. This flag stops it from doing that a second time. Without it
    /// the app would switch the setting back on at every launch, and a user who
    /// turned it off could never keep it off.
    var appliedDefaultLoginItem: Bool {
        didSet { defaults.set(appliedDefaultLoginItem, forKey: Key.appliedDefaultLoginItem) }
    }

    /// The backing value. Never assign to a property inside its own `didSet`:
    /// the `@Observable` macro routes the assignment back through the setter,
    /// which recurses until the stack overflows.
    private var storedMaxSessions: Int {
        didSet { defaults.set(storedMaxSessions, forKey: Key.maxStoredSessions) }
    }

    /// How many sessions to keep. `0` keeps every session.
    var maxStoredSessions: Int {
        get { storedMaxSessions }
        set { storedMaxSessions = max(0, newValue) }
    }

    /// `true` when the app deletes old sessions.
    var limitsStoredSessions: Bool {
        get { maxStoredSessions != Self.unlimited }
        set { maxStoredSessions = newValue ? Self.defaultSessionLimit : Self.unlimited }
    }
}
