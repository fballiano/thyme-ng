#!/usr/bin/env swift
//
// Draws the thyme-ng application icon and writes every size the asset catalog
// needs.
//
//   swift Tools/make-icon.swift
//
// The glyph is the "stopwatch" icon from Tabler Icons, MIT licensed,
// Copyright (c) 2020-2026 Paweł Kuna. See https://tabler.io/icons.
// Its 24 x 24 outline path is redrawn here with Core Graphics, in white, on a
// green squircle.
//
// The menu bar draws the same path from
// Sources/ThymeNG/Views/StopwatchGlyph.swift. This script runs on its own,
// outside the application, so it cannot import that file. Change the two
// together.

import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: "Resources/Assets.xcassets/AppIcon.appiconset")

/// The Tabler "stopwatch" outline, in its own 24 x 24 coordinate space.
/// The y axis points down, as in SVG.
func tablerStopwatchPath() -> NSBezierPath {
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

/// Draws the icon into a bitmap of the given pixel size.
func drawIcon(pixels: Int) -> NSBitmapImageRep {
    let size = CGFloat(pixels)

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Cannot create the bitmap")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // The macOS icon grid leaves a margin around the shape.
    let inset = size * 0.086
    let plate = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = plate.width * 0.2237
    let plateShape = NSBezierPath(roundedRect: plate, xRadius: radius, yRadius: radius)

    // Background: a herb green gradient.
    let gradient = NSGradient(
        starting: NSColor(srgbRed: 0.42, green: 0.73, blue: 0.35, alpha: 1),
        ending: NSColor(srgbRed: 0.16, green: 0.45, blue: 0.24, alpha: 1)
    )
    gradient?.draw(in: plateShape, angle: -90)

    // A thin light rim, so the shape reads on a dark desktop.
    NSColor.white.withAlphaComponent(0.18).setStroke()
    plateShape.lineWidth = size * 0.006
    plateShape.stroke()

    // The glyph, scaled from its 24 x 24 box into the middle of the plate.
    let glyphSide = plate.width * 0.60
    let scale = glyphSide / 24

    var transform = AffineTransform()
    transform.translate(
        x: plate.midX - glyphSide / 2,
        y: plate.midY + glyphSide / 2
    )
    transform.scale(x: scale, y: -scale) // SVG counts y downwards.

    let glyph = tablerStopwatchPath()
    glyph.transform(using: transform)
    // The stroke width Tabler ships. It matches `StopwatchGlyph.strokeWidth`,
    // which the menu bar uses.
    glyph.lineWidth = 2 * scale
    glyph.lineCapStyle = .round // stroke-linecap="round"
    glyph.lineJoinStyle = .round // stroke-linejoin="round"

    NSColor.white.setStroke()
    glyph.stroke()

    NSGraphicsContext.restoreGraphicsState()

    return rep
}

func write(pixels: Int, to name: String) {
    let rep = drawIcon(pixels: pixels)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Cannot encode \(name)")
    }

    let url = outputDirectory.appendingPathComponent(name)
    try! data.write(to: url)
    print("wrote \(name) (\(pixels)x\(pixels))")
}

try! FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for pixels in sizes {
    write(pixels: pixels, to: "icon_\(pixels).png")
}
