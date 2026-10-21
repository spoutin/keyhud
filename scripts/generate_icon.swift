import Foundation
import AppKit
import CoreGraphics

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // 1. Draw Squircle Background
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    path.addClip()

    // Background Gradient (Dark Theme: #18191d to #2a2e37)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let startColor = NSColor(red: 0.165, green: 0.18, blue: 0.216, alpha: 1.0).cgColor // #2a2e37
    let endColor = NSColor(red: 0.094, green: 0.098, blue: 0.114, alpha: 1.0).cgColor   // #18191d
    let colors = [startColor, endColor] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
    
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

    // Subtle inner border
    NSColor.white.withAlphaComponent(0.12).setStroke()
    path.lineWidth = size * 0.015
    path.stroke()

    // 2. Draw '⌘' inside a circle (Mimicking command.circle.fill)
    let symbolColor = NSColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0) // Cyan #00d9ff

    // Shadow for glow effect
    let shadow = NSShadow()
    shadow.shadowColor = symbolColor.withAlphaComponent(0.6)
    shadow.shadowBlurRadius = size * 0.1
    shadow.shadowOffset = NSSize(width: 0, height: -(size * 0.02))
    shadow.set()

    // Circle
    let circlePadding = size * 0.15
    let circleRect = rect.insetBy(dx: circlePadding, dy: circlePadding)
    let circlePath = NSBezierPath(ovalIn: circleRect)
    symbolColor.setStroke()
    circlePath.lineWidth = size * 0.06
    circlePath.stroke()

    // Command Symbol '⌘'
    let cmdString = "⌘" as NSString
    let fontSize = size * 0.45
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: symbolColor,
        .paragraphStyle: paragraphStyle
    ]

    let textSize = cmdString.size(withAttributes: attributes)
    let textRect = NSRect(
        x: (size - textSize.width) / 2.0,
        y: ((size - textSize.height) / 2.0) - (size * 0.02), // slight optical baseline adjustment
        width: textSize.width,
        height: textSize.height
    )

    cmdString.draw(in: textRect, withAttributes: attributes)

    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("Failed to generate PNG for \(path)")
        return
    }
    try? pngData.write(to: URL(fileURLWithPath: path))
}

let iconsetPath = "/tmp/AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true, attributes: nil)

let sizes = [
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

for (filename, points) in sizes {
    let img = drawIcon(size: CGFloat(points))
    savePNG(image: img, path: "\(iconsetPath)/\(filename)")
    print("Generated \(filename)")
}

print("Running iconutil...")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath, "-o", "/tmp/AppIcon.icns"]
try? task.run()
task.waitUntilExit()

if task.terminationStatus == 0 {
    print("Successfully generated /tmp/AppIcon.icns")
} else {
    print("Failed to run iconutil")
}
