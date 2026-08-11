import SwiftUI

/// What the menu bar shows.
///
/// The stopwatch icon while the stopwatch is stopped, otherwise the running
/// time.
///
/// The icon is the same Tabler outline as the application icon, drawn as a
/// template image, so it follows the menu bar between light and dark and it
/// inverts while the menu is open.
///
/// The digits are monospaced, so the width does not jump every second. The
/// original app worked around that by fixing the status item to 46 or 72 points.
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        if model.stopwatch.isStopped {
            Image(nsImage: StopwatchGlyph.menuBar)
                .renderingMode(.template)
        } else {
            Text(TimeFormatter.clock(model.stopwatch.elapsed))
                .monospacedDigit()
        }
    }
}
