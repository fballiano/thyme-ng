import AppKit
import Foundation
import KeyboardShortcuts
import Observation
import SwiftData
import UniformTypeIdentifiers

/// The one controller of the app.
///
/// Every way in — the menu, a global hot key, an AppleScript command, a
/// Shortcuts action — calls the same methods here, so each command has exactly
/// one code path.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    let stopwatch: Stopwatch
    let preferences: Preferences
    let loginItem: LoginItem

    /// The saved sessions, newest first. The menu reads this.
    private(set) var sessions: [Session] = []

    /// Set when the database could not be opened.
    private(set) var storeError: String?

    @ObservationIgnored private let store: SessionStore
    @ObservationIgnored private let tagPrompt = TagPromptController()
    @ObservationIgnored private let settingsWindow = SettingsWindowController()
    @ObservationIgnored private var systemEvents: SystemEvents?
    @ObservationIgnored private var didBootstrap = false

    /// `true` when the stopwatch was running before the Mac slept.
    @ObservationIgnored private var resumeAfterWake = false

    /// `true` when the stopwatch was running before the screen locked.
    @ObservationIgnored private var resumeAfterScreen = false

    init(store: SessionStore? = nil, preferences: Preferences? = nil) {
        self.stopwatch = Stopwatch()
        self.preferences = preferences ?? Preferences()
        self.loginItem = LoginItem()

        if let store {
            self.store = store
        } else {
            // The tests run inside the real app, so they must not touch the
            // live database.
            let inMemory = RuntimeEnvironment.isRunningTests
            do {
                self.store = SessionStore(container: try SessionStore.makeContainer(inMemory: inMemory))
            } catch {
                // Fall back to a throw-away store so the app still runs.
                self.store = SessionStore(
                    container: try! SessionStore.makeContainer(inMemory: true)
                )
                self.storeError = error.localizedDescription
            }
        }

        reloadSessions()
    }

    // MARK: - Launch

    /// Wires the hot keys and the system events.
    func bootstrap() {
        guard !didBootstrap, !RuntimeEnvironment.isRunningTests else { return }
        didBootstrap = true

        store.prune(keeping: preferences.maxStoredSessions)
        reloadSessions()

        applyDefaultLoginItem()
        registerHotKeys()
        registerSystemEvents()
        registerTerminationHandler()
    }

    /// Starts the app at login, once.
    ///
    /// The app has no dock icon and no window, so a user who does not find it
    /// after a restart thinks it is gone. The first launch therefore registers
    /// the login item. A later change by the user stays: the flag says that the
    /// default was applied, so the app never sets it again.
    private func applyDefaultLoginItem() {
        guard !preferences.appliedDefaultLoginItem else { return }

        if loginItem.isEnabled {
            preferences.appliedDefaultLoginItem = true
            return
        }

        loginItem.isEnabled = true

        // Only a registration that worked counts. A failure is tried again at
        // the next launch.
        preferences.appliedDefaultLoginItem = loginItem.isEnabled
    }

    /// Stores the running session when the app quits.
    ///
    /// The original app threw the running session away on quit. This keeps it.
    private func registerTerminationHandler() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                AppModel.shared.storeRunningSession()
            }
        }
    }

    private func storeRunningSession() {
        guard !stopwatch.isStopped else { return }

        let duration = stopwatch.stop()
        store.add(duration: duration, tag: "", keeping: preferences.maxStoredSessions)
    }

    private func registerHotKeys() {
        KeyboardShortcuts.onKeyDown(for: .toggle) { [weak self] in
            MainActor.assumeIsolated { self?.toggle() }
        }
        KeyboardShortcuts.onKeyDown(for: .restart) { [weak self] in
            MainActor.assumeIsolated { self?.restart() }
        }
        KeyboardShortcuts.onKeyDown(for: .finish) { [weak self] in
            MainActor.assumeIsolated { self?.finish() }
        }
    }

    private func registerSystemEvents() {
        let events = SystemEvents(
            onSleep: { [weak self] in self?.handleSleep() },
            onWake: { [weak self] in self?.handleWake() },
            onScreenLock: { [weak self] in self?.handleScreenLock() },
            onScreenUnlock: { [weak self] in self?.handleScreenUnlock() }
        )
        events.start()
        systemEvents = events
    }

    // MARK: - Commands

    func start() {
        guard !stopwatch.isRunning else { return }

        stopwatch.start()
    }

    func pause() {
        guard stopwatch.isRunning else { return }

        stopwatch.pause()
    }

    func toggle() {
        stopwatch.isRunning ? pause() : start()
    }

    /// Saves the running session and starts a new one.
    func restart() {
        guard !stopwatch.isStopped else { return }

        finish()
        start()
    }

    /// Saves the running session and returns the stopwatch to zero.
    func finish() {
        guard !stopwatch.isStopped else { return }

        let duration = stopwatch.stop()

        guard duration >= SessionStore.minimumDuration else { return }

        if preferences.askForTagOnFinish {
            askForTag(duration: duration)
        } else {
            save(duration: duration, tag: "")
        }
    }

    /// The title of the first menu command, as in the original app.
    var primaryCommandTitle: String {
        if stopwatch.isRunning { return "Pause" }
        if stopwatch.isPaused { return "Continue" }
        return "Start"
    }

    // MARK: - Sessions

    func clearSessions() {
        store.clear()
        reloadSessions()
    }

    func applySessionLimit() {
        store.prune(keeping: preferences.maxStoredSessions)
        reloadSessions()
    }

    private func save(duration: TimeInterval, tag: String) {
        store.add(duration: duration, tag: tag, keeping: preferences.maxStoredSessions)
        reloadSessions()
    }

    private func reloadSessions() {
        sessions = store.all()
    }

    private func askForTag(duration: TimeInterval) {
        tagPrompt.present(duration: duration) { [weak self] tag in
            self?.save(duration: duration, tag: tag)
        }
    }

    // MARK: - Export

    func export() {
        guard let data = try? store.exportData() else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = SessionStore.exportFileName()
        panel.title = "Export sessions"

        NSApp.activate()

        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Panels

    func showSettings() {
        settingsWindow.present(model: self)
    }

    func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Sleep and screen

    private func handleSleep() {
        guard preferences.pauseOnSleep else { return }

        resumeAfterWake = stopwatch.isRunning
        pause()
    }

    private func handleWake() {
        guard preferences.pauseOnSleep, resumeAfterWake else { return }

        resumeAfterWake = false
        start()
    }

    private func handleScreenLock() {
        guard preferences.pauseOnScreensaver else { return }

        resumeAfterScreen = stopwatch.isRunning
        pause()
    }

    private func handleScreenUnlock() {
        guard preferences.pauseOnScreensaver, resumeAfterScreen else { return }

        resumeAfterScreen = false
        start()
    }
}
