import AppKit
import Foundation

/// The AppleScript commands.
///
/// The suite code and the command codes are the same as the original app, so an
/// existing script keeps working after you change the application name:
///
///     tell application "thyme-ng" to start
///
/// The class names are exported to the Objective-C runtime, because the
/// scripting definition refers to them by name.

@objc(StartCommand)
final class StartCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.start() }
        return nil
    }
}

@objc(PauseCommand)
final class PauseCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.pause() }
        return nil
    }
}

@objc(StopCommand)
final class StopCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.finish() }
        return nil
    }
}

@objc(ToggleCommand)
final class ToggleCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.toggle() }
        return nil
    }
}

@objc(RestartCommand)
final class RestartCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.restart() }
        return nil
    }
}

/// Returns the elapsed time as `MM:SS` or `HH:MM:SS`.
@objc(ElapsedCommand)
final class ElapsedCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated {
            TimeFormatter.clock(AppModel.shared.stopwatch.currentElapsed)
        }
    }
}
