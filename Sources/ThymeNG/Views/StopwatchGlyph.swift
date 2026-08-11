import AppKit

/// The "stopwatch" outline from Tabler Icons, MIT licensed, Copyright (c)
/// 2020-2026 Paweł Kuna. See https://tabler.io/icons.
///
/// The menu bar used the SF Symbol "stopwatch" before. The application icon
/// cannot use an SF Symbol, because Apple does not allow it, so the two icons
/// were different drawings of the same thing. Both now come from here.
///
/// `Tools/make-icon.swift` holds the same path for the application icon. That
/// script runs on its own, outside the application, so it cannot import this
/// file. Change the two together.
@MainActor
enum StopwatchGlyph {
    /// Tabler draws on a 24 x 24 grid, with the y axis pointing down.
    static let grid: CGFloat = 24

    /// The stroke width Tabler ships. The grid is drawn into a 20 point box, so
    /// the line is 1.67 points on screen. A lighter value looks thin next to the
    /// other menu bar icons.
    static let strokeWidth: CGFloat = 2

    /// The image for the menu bar. It is a template, so the menu bar colours it
    /// itself: it follows light and dark, and it inverts while the menu is open.
    ///
    /// The drawing fills 18.5 of the 24 units, so a 20 point box gives a glyph
    /// of about 15 points. That is the height of the SF Symbol it replaces.
    static let menuBar: NSImage = image(side: 20)

    /// The outline in its own 24 x 24 space.
    static func outline() -> NSBezierPath {
        let path = NSBezierPath()

        // <path d="M5 13a7 7 0 1 0 14 0a7 7 0 0 0 -14 0" /> — the dial.
        path.appendOval(in: NSRect(x: 5, y: 6, width: 14, height: 14))

        // <path d="M14.5 10.5l-2.5 2.5" /> — the hand.
        path.move(to: NSPoint(x: 14.5, y: 10.5))
        path.line(to: NSPoint(x: 12, y: 13))

        // <path d="M17 8l1 -1" /> — the side button.
        path.move(to: NSPoint(x: 17, y: 8))
        path.line(to: NSPoint(x: 18, y: 7))

        // <path d="M14 3h-4" /> — the crown on top.
        path.move(to: NSPoint(x: 14, y: 3))
        path.line(to: NSPoint(x: 10, y: 3))

        return path
    }

    private static func image(side: CGFloat) -> NSImage {
        // `flipped: true` points the y axis down, as SVG does, so the path
        // needs no mirroring.
        let image = NSImage(size: NSSize(width: side, height: side), flipped: true) { _ in
            let scale = side / grid

            let glyph = outline()
            var transform = AffineTransform()
            transform.scale(scale)
            glyph.transform(using: transform)

            glyph.lineWidth = strokeWidth * scale
            glyph.lineCapStyle = .round // stroke-linecap="round"
            glyph.lineJoinStyle = .round // stroke-linejoin="round"

            // A template image only keeps its shape. The colour comes from the
            // menu bar.
            NSColor.black.setStroke()
            glyph.stroke()

            return true
        }

        image.isTemplate = true
        return image
    }
}
