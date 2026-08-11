import AppKit
import SwiftUI

/// Shows `TagPromptView` in its own small window.
///
/// The app has no ordinary windows, so it drives this one through AppKit. That
/// keeps the prompt reachable from a global hot key and from AppleScript, not
/// only from the menu.
@MainActor
final class TagPromptController: NSObject {
    private var window: NSWindow?
    private var pendingSubmit: ((String) -> Void)?

    /// Shows the prompt. If one is already open, the earlier session is stored
    /// without a tag first.
    func present(duration: TimeInterval, onSubmit: @escaping (String) -> Void) {
        resolvePending(with: "")

        pendingSubmit = onSubmit

        let view = TagPromptView(duration: duration) { [weak self] tag in
            self?.resolvePending(with: tag)
        }

        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "thyme-ng"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.delegate = self
        window.center()

        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func resolvePending(with tag: String) {
        guard let submit = pendingSubmit else { return }

        pendingSubmit = nil
        dismiss()
        submit(tag)
    }

    private func dismiss() {
        guard let window else { return }

        self.window = nil
        window.delegate = nil
        window.close()
    }
}

extension TagPromptController: NSWindowDelegate {
    /// The user closed the window with the red button: store it without a tag.
    func windowWillClose(_ notification: Notification) {
        window = nil

        let submit = pendingSubmit
        pendingSubmit = nil
        submit?("")
    }
}
