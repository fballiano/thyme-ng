import AppKit
import Foundation

/// Watches sleep, wake, the screensaver and the lock screen.
///
/// The lock screen names are the same private notification names the original
/// app used. They are not in a public header, so they stay as string literals.
@MainActor
final class SystemEvents {
    private var tokens: [NSObjectProtocol] = []

    private let onSleep: @MainActor () -> Void
    private let onWake: @MainActor () -> Void
    private let onScreenLock: @MainActor () -> Void
    private let onScreenUnlock: @MainActor () -> Void

    init(
        onSleep: @escaping @MainActor () -> Void,
        onWake: @escaping @MainActor () -> Void,
        onScreenLock: @escaping @MainActor () -> Void,
        onScreenUnlock: @escaping @MainActor () -> Void
    ) {
        self.onSleep = onSleep
        self.onWake = onWake
        self.onScreenLock = onScreenLock
        self.onScreenUnlock = onScreenUnlock
    }

    /// Starts to listen. Call it once.
    func start() {
        guard tokens.isEmpty else { return }

        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.willSleepNotification) { [weak self] in self?.onSleep() }
        observe(workspace, NSWorkspace.didWakeNotification) { [weak self] in self?.onWake() }

        let distributed = DistributedNotificationCenter.default()
        for name in ["com.apple.screensaver.didstart", "com.apple.screenIsLocked"] {
            observe(distributed, Notification.Name(name)) { [weak self] in self?.onScreenLock() }
        }
        for name in ["com.apple.screensaver.didstop", "com.apple.screenIsUnlocked"] {
            observe(distributed, Notification.Name(name)) { [weak self] in self?.onScreenUnlock() }
        }
    }

    /// Stops listening.
    func stop() {
        for token in tokens {
            NotificationCenter.default.removeObserver(token)
            DistributedNotificationCenter.default().removeObserver(token)
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        tokens.removeAll()
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: Notification.Name,
        _ handler: @escaping @MainActor () -> Void
    ) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { handler() }
        }
        tokens.append(token)
    }
}
