#!/usr/bin/env swift

import AppKit
import Foundation

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let packagingDir = repoRoot.appendingPathComponent("Packaging", isDirectory: true)
let iconsetDir = packagingDir.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icnsURL = packagingDir.appendingPathComponent("AppIcon.icns")
let previewURL = packagingDir.appendingPathComponent("AppIcon-preview.png")

let iconDefinitions: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

try? FileManager.default.removeItem(at: iconsetDir)
try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

for (name, size) in iconDefinitions {
    let pngData = try renderIcon(size: size)
    try pngData.write(to: iconsetDir.appendingPathComponent(name))
}

try renderIcon(size: 1024).write(to: previewURL)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "generate-icon", code: Int(process.terminationStatus))
}

print("Generated \(icnsURL.path)")

func renderIcon(size: CGFloat) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "generate-icon", code: 1)
    }

    guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "generate-icon", code: 2)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    let cgContext = graphicsContext.cgContext
    cgContext.setAllowsAntialiasing(true)
    cgContext.setShouldAntialias(true)

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    cgContext.clear(rect)

    drawBase(in: rect, context: cgContext)
    drawPaperStack(in: rect, context: cgContext)
    drawMarkdownGlyph(in: rect, context: cgContext)
    drawTextLines(in: rect, context: cgContext)
    drawHighlight(in: rect, context: cgContext)

    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "generate-icon", code: 3)
    }

    return png
}

func drawBase(in rect: CGRect, context: CGContext) {
    let canvas = roundedRect(in: rect.insetBy(dx: rect.width * 0.018, dy: rect.height * 0.018), radius: rect.width * 0.23)
    context.saveGState()
    canvas.addClip()

    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            color(0.09, 0.20, 0.30).cgColor,
            color(0.20, 0.37, 0.45).cgColor,
            color(0.89, 0.56, 0.28).cgColor,
            color(0.79, 0.28, 0.22).cgColor
        ] as CFArray,
        locations: [0.0, 0.33, 0.72, 1.0]
    )!

    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.minX, y: rect.maxY),
        end: CGPoint(x: rect.maxX, y: rect.minY),
        options: []
    )

    let topGlow = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            color(0.99, 0.90, 0.62, alpha: 0.85).cgColor,
            color(0.99, 0.90, 0.62, alpha: 0.0).cgColor
        ] as CFArray,
        locations: [0.0, 1.0]
    )!

    context.drawRadialGradient(
        topGlow,
        startCenter: CGPoint(x: rect.width * 0.24, y: rect.height * 0.82),
        startRadius: 0,
        endCenter: CGPoint(x: rect.width * 0.24, y: rect.height * 0.82),
        endRadius: rect.width * 0.48,
        options: []
    )

    let bottomGlow = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            color(0.90, 0.37, 0.31, alpha: 0.0).cgColor,
            color(0.07, 0.12, 0.19, alpha: 0.30).cgColor
        ] as CFArray,
        locations: [0.0, 1.0]
    )!

    context.drawRadialGradient(
        bottomGlow,
        startCenter: CGPoint(x: rect.width * 0.78, y: rect.height * 0.15),
        startRadius: 0,
        endCenter: CGPoint(x: rect.width * 0.78, y: rect.height * 0.15),
        endRadius: rect.width * 0.46,
        options: []
    )

    context.restoreGState()

    context.saveGState()
    context.setShadow(offset: .zero, blur: rect.width * 0.04, color: color(0.04, 0.08, 0.12, alpha: 0.32).cgColor)
    color(1.0, 1.0, 1.0, alpha: 0.08).setStroke()
    canvas.lineWidth = max(1, rect.width * 0.012)
    canvas.stroke()
    context.restoreGState()
}

func drawPaperStack(in rect: CGRect, context: CGContext) {
    let shadowRect = CGRect(
        x: rect.width * 0.23,
        y: rect.height * 0.13,
        width: rect.width * 0.54,
        height: rect.height * 0.10
    )
    let shadowPath = NSBezierPath(ovalIn: shadowRect)
    color(0.05, 0.10, 0.14, alpha: 0.18).setFill()
    shadowPath.fill()

    drawSheet(
        in: rect,
        frame: CGRect(x: rect.width * 0.21, y: rect.height * 0.19, width: rect.width * 0.51, height: rect.height * 0.60),
        angle: -10,
        fill: color(0.98, 0.94, 0.86, alpha: 0.56),
        shadowAlpha: 0.0,
        showFold: false,
        context: context
    )

    drawSheet(
        in: rect,
        frame: CGRect(x: rect.width * 0.28, y: rect.height * 0.18, width: rect.width * 0.50, height: rect.height * 0.62),
        angle: 5,
        fill: color(0.99, 0.98, 0.95),
        shadowAlpha: 0.22,
        showFold: true,
        context: context
    )
}

func drawSheet(
    in rect: CGRect,
    frame: CGRect,
    angle: CGFloat,
    fill: NSColor,
    shadowAlpha: CGFloat,
    showFold: Bool,
    context: CGContext
) {
    let transform = rotationTransform(angle: angle, around: CGPoint(x: frame.midX, y: frame.midY))

    let path = roundedRect(in: frame, radius: rect.width * 0.05)
    path.transform(using: transform)

    context.saveGState()
    if shadowAlpha > 0 {
        context.setShadow(
            offset: CGSize(width: 0, height: -rect.height * 0.015),
            blur: rect.width * 0.045,
            color: color(0.02, 0.07, 0.12, alpha: shadowAlpha).cgColor
        )
    }
    fill.setFill()
    path.fill()
    context.restoreGState()

    color(0.20, 0.24, 0.28, alpha: 0.08).setStroke()
    path.lineWidth = max(1, rect.width * 0.004)
    path.stroke()

    guard showFold else { return }

    let fold = NSBezierPath()
    let topRight = CGPoint(x: frame.maxX, y: frame.maxY)
    let inset = rect.width * 0.11
    fold.move(to: CGPoint(x: topRight.x - inset, y: topRight.y))
    fold.line(to: CGPoint(x: topRight.x, y: topRight.y))
    fold.line(to: CGPoint(x: topRight.x, y: topRight.y - inset))
    fold.close()
    fold.transform(using: transform)

    color(0.93, 0.91, 0.86).setFill()
    fold.fill()
    color(0.63, 0.62, 0.58, alpha: 0.22).setStroke()
    fold.lineWidth = max(1, rect.width * 0.003)
    fold.stroke()
}

func drawMarkdownGlyph(in rect: CGRect, context: CGContext) {
    let pageRect = CGRect(x: rect.width * 0.28, y: rect.height * 0.18, width: rect.width * 0.50, height: rect.height * 0.62)
    let transform = rotationTransform(angle: 5, around: CGPoint(x: pageRect.midX, y: pageRect.midY))

    let glyphBox = CGRect(
        x: pageRect.minX + pageRect.width * 0.15,
        y: pageRect.maxY - pageRect.height * 0.39,
        width: pageRect.width * 0.42,
        height: pageRect.height * 0.24
    )

    let symbolColor = color(0.95, 0.49, 0.24)
    let symbolShadow = color(0.46, 0.17, 0.12, alpha: 0.16)

    let barWidth = glyphBox.width * 0.14
    let verticalHeight = glyphBox.height
    let horizontalHeight = glyphBox.height * 0.15
    let firstX = glyphBox.minX + glyphBox.width * 0.18
    let secondX = glyphBox.minX + glyphBox.width * 0.56
    let upperY = glyphBox.minY + glyphBox.height * 0.60
    let lowerY = glyphBox.minY + glyphBox.height * 0.27

    let bars = [
        CGRect(x: firstX, y: glyphBox.minY, width: barWidth, height: verticalHeight),
        CGRect(x: secondX, y: glyphBox.minY, width: barWidth, height: verticalHeight),
        CGRect(x: glyphBox.minX, y: upperY, width: glyphBox.width, height: horizontalHeight),
        CGRect(x: glyphBox.minX + glyphBox.width * 0.02, y: lowerY, width: glyphBox.width * 0.96, height: horizontalHeight)
    ]

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -rect.height * 0.004), blur: rect.width * 0.015, color: symbolShadow.cgColor)
    symbolColor.setFill()
    for bar in bars {
        let path = roundedRect(in: bar, radius: bar.height * 0.45)
        path.transform(using: transform)
        path.fill()
    }
    context.restoreGState()

    let accent = roundedRect(
        in: CGRect(
            x: pageRect.minX + pageRect.width * 0.14,
            y: pageRect.minY + pageRect.height * 0.15,
            width: pageRect.width * 0.30,
            height: pageRect.height * 0.055
        ),
        radius: rect.width * 0.015
    )
    accent.transform(using: transform)
    color(0.13, 0.29, 0.39, alpha: 0.92).setFill()
    accent.fill()

    let underline = roundedRect(
        in: CGRect(
            x: pageRect.minX + pageRect.width * 0.14,
            y: pageRect.minY + pageRect.height * 0.11,
            width: pageRect.width * 0.58,
            height: pageRect.height * 0.028
        ),
        radius: rect.width * 0.012
    )
    underline.transform(using: transform)
    color(0.91, 0.56, 0.24, alpha: 0.78).setFill()
    underline.fill()
}

func drawTextLines(in rect: CGRect, context: CGContext) {
    let pageRect = CGRect(x: rect.width * 0.28, y: rect.height * 0.18, width: rect.width * 0.50, height: rect.height * 0.62)
    let transform = rotationTransform(angle: 5, around: CGPoint(x: pageRect.midX, y: pageRect.midY))

    let lines: [(CGFloat, CGFloat, CGFloat, NSColor)] = [
        (0.54, 0.18, 0.48, color(0.19, 0.33, 0.42, alpha: 0.22)),
        (0.47, 0.18, 0.56, color(0.19, 0.33, 0.42, alpha: 0.22)),
        (0.40, 0.18, 0.50, color(0.19, 0.33, 0.42, alpha: 0.22)),
        (0.33, 0.18, 0.60, color(0.19, 0.33, 0.42, alpha: 0.22))
    ]

    for (yFactor, xFactor, widthFactor, lineColor) in lines {
        let line = roundedRect(
            in: CGRect(
                x: pageRect.minX + pageRect.width * xFactor,
                y: pageRect.minY + pageRect.height * yFactor,
                width: pageRect.width * widthFactor,
                height: pageRect.height * 0.032
            ),
            radius: rect.width * 0.012
        )
        line.transform(using: transform)
        lineColor.setFill()
        line.fill()
    }
}

func drawHighlight(in rect: CGRect, context: CGContext) {
    let shine = roundedRect(
        in: CGRect(
            x: rect.width * 0.14,
            y: rect.height * 0.78,
            width: rect.width * 0.34,
            height: rect.height * 0.07
        ),
        radius: rect.width * 0.035
    )
    let transform = rotationTransform(angle: -18, around: CGPoint(x: rect.midX, y: rect.midY))
    shine.transform(using: transform)

    context.saveGState()
    color(1.0, 1.0, 1.0, alpha: 0.10).setFill()
    shine.fill()
    context.restoreGState()
}

func roundedRect(in rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1.0) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func rotationTransform(angle: CGFloat, around center: CGPoint) -> AffineTransform {
    var transform = AffineTransform()
    transform.translate(x: center.x, y: center.y)
    transform.rotate(byDegrees: angle)
    transform.translate(x: -center.x, y: -center.y)
    return transform
}
