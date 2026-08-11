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
    @ObservationIgnored private let notifier = Notifier()
    @ObservationIgnored private let tagPrompt = TagPromptController()
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

    /// Wires the hot keys, the system events and the notifications.
    func bootstrap() {
        guard !didBootstrap, !RuntimeEnvironment.isRunningTests else { return }
        didBootstrap = true

        store.prune(keeping: preferences.maxStoredSessions)
        reloadSessions()

        notifier.prepare()
        registerHotKeys()
        registerSystemEvents()
        registerTerminationHandler()
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
            MainActor.assumeIsolated { self?.toggle(notify: true) }
        }
        KeyboardShortcuts.onKeyDown(for: .restart) { [weak self] in
            MainActor.assumeIsolated { self?.restart(notify: true) }
        }
        KeyboardShortcuts.onKeyDown(for: .finish) { [weak self] in
            MainActor.assumeIsolated { self?.finish(notify: true) }
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

    func start(notify: Bool = false) {
        guard !stopwatch.isRunning else { return }

        stopwatch.start()

        if notify {
            notifier.post("Started", enabled: preferences.showNotifications)
        }
    }

    func pause(notify: Bool = false) {
        guard stopwatch.isRunning else { return }

        stopwatch.pause()

        if notify {
            notifier.post("Paused at \(TimeFormatter.clock(stopwatch.elapsed))",
                          enabled: preferences.showNotifications)
        }
    }

    func toggle(notify: Bool = false) {
        stopwatch.isRunning ? pause(notify: notify) : start(notify: notify)
    }

    /// Saves the running session and starts a new one.
    func restart(notify: Bool = false) {
        guard !stopwatch.isStopped else { return }

        finish(notify: notify)
        start(notify: notify)
    }

    /// Saves the running session and returns the stopwatch to zero.
    func finish(notify: Bool = false) {
        guard !stopwatch.isStopped else { return }

        let duration = stopwatch.stop()

        if notify {
            notifier.post("Stopped at \(TimeFormatter.clock(duration))",
                          enabled: preferences.showNotifications)
        }

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
