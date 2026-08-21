import AppIntents
import Foundation

/// The Shortcuts and Spotlight actions.
///
/// App Intents are the modern equivalent of the AppleScript suite. Both are
/// present, and both call the same methods on `AppModel`.

struct StartTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Timer"
    static let description = IntentDescription("Starts the thyme-ng stopwatch, or continues it after a pause.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppModel.shared.start()
        return .result()
    }
}

struct PauseTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Pause Timer"
    static let description = IntentDescription("Pauses the thyme-ng stopwatch and keeps the elapsed time.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppModel.shared.pause()
        return .result()
    }
}

struct ToggleTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Timer"
    static let description = IntentDescription("Starts the thyme-ng stopwatch if it is stopped, pauses it if it runs.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppModel.shared.toggle()
        return .result()
    }
}

struct FinishTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Finish Timer"
    static let description = IntentDescription("Stores the running session and returns the stopwatch to zero.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppModel.shared.finish()
        return .result()
    }
}

struct ElapsedTimeIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Elapsed Time"
    static let description = IntentDescription("Returns the time on the thyme-ng stopwatch as text.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: TimeFormatter.clock(AppModel.shared.stopwatch.currentElapsed))
    }
}

struct ThymeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: ["Start \(.applicationName)"],
            shortTitle: "Start Timer",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: PauseTimerIntent(),
            phrases: ["Pause \(.applicationName)"],
            shortTitle: "Pause Timer",
            systemImageName: "pause.fill"
        )
        AppShortcut(
            intent: ToggleTimerIntent(),
            phrases: ["Toggle \(.applicationName)"],
            shortTitle: "Toggle Timer",
            systemImageName: "playpause.fill"
        )
        AppShortcut(
            intent: FinishTimerIntent(),
            phrases: ["Finish \(.applicationName)"],
            shortTitle: "Finish Timer",
            systemImageName: "stop.fill"
        )
    }
}
