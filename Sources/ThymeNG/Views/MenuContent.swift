import SwiftUI

/// The menu that drops down from the menu bar.
///
/// The order matches the original app: the three commands, the saved sessions
/// with `Export…` and `Clear`, then the application items.
struct MenuContent: View {
    let model: AppModel

    var body: some View {
        Button(model.primaryCommandTitle) { model.toggle() }

        Button("Restart") { model.restart() }
            .disabled(model.stopwatch.isStopped)

        Button("Finish") { model.finish() }
            .disabled(model.stopwatch.isStopped)

        if !model.sessions.isEmpty {
            Divider()

            ForEach(model.sessions) { session in
                Text(session.menuText)
            }

            Button("Export…") { model.export() }
            Button("Clear") { model.clearSessions() }
        }

        if let storeError = model.storeError {
            Divider()
            Text("Database error: \(storeError)")
        }

        Divider()

        Button("Preferences…") { model.showSettings() }
            .keyboardShortcut(",", modifiers: .command)

        Button("About thyme-ng") { model.showAbout() }

        Divider()

        Button("Quit thyme-ng") { model.quit() }
            .keyboardShortcut("q", modifiers: .command)
    }
}
