import SwiftUI

/// What the menu bar shows.
///
/// An SF Symbol while the stopwatch is stopped, otherwise the running time.
///
/// SF Symbols is the icon system built into macOS. The symbol renders as a
/// template, so it follows the menu bar between light and dark, and it follows
/// the weight and the size the user chose for the menu bar.
///
/// The digits are monospaced, so the width does not jump every second. The
/// original app worked around that by fixing the status item to 46 or 72 points.
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        if model.stopwatch.isStopped {
            Image(systemName: "stopwatch")
        } else {
            Text(TimeFormatter.clock(model.stopwatch.elapsed))
                .monospacedDigit()
        }
    }
}
