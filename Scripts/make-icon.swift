// Renders the app icon: the menu bar symbol on a white rounded square, at every size macOS wants.
// Run with `make icon`. Output goes to Resources/Assets.xcassets/AppIcon.appiconset.
import AppKit

let symbolName = "text.viewfinder"
let outputDirectory = URL(fileURLWithPath: "Resources/Assets.xcassets/AppIcon.appiconset")

struct Slot {
    let size: Int
    let scale: Int
    var pixels: Int { size * scale }
    var filename: String { scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@\(scale)x.png" }
}

let slots = [16, 32, 128, 256, 512].flatMap { [Slot(size: $0, scale: 1), Slot(size: $0, scale: 2)] }

func render(pixels: Int) -> Data {
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
    ), let context = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("Could not create bitmap for \(pixels)px")
    }
    rep.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    defer { NSGraphicsContext.restoreGraphicsState() }

    let canvas = CGFloat(pixels)

    // Apple's macOS template: an 824pt rounded square centred on a 1024pt canvas.
    let inset = canvas * (100.0 / 1024.0)
    let square = NSRect(x: inset, y: inset, width: canvas - 2 * inset, height: canvas - 2 * inset)
    let radius = square.width * (185.0 / 824.0)
    let plate = NSBezierPath(roundedRect: square, xRadius: radius, yRadius: radius)
    NSColor.white.setFill()
    plate.fill()

    // Hairline edge so the white plate still reads on a white Finder window.
    NSColor(white: 0.82, alpha: 1).setStroke()
    plate.lineWidth = max(1, canvas / 256)
    plate.addClip()
    plate.stroke()

    let configuration = NSImage.SymbolConfiguration(pointSize: square.width * 0.5, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.black]))
    guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
        .withSymbolConfiguration(configuration) else {
        fatalError("Missing SF Symbol \(symbolName)")
    }

    let target = square.width * 0.58
    let scale = target / max(symbol.size.width, symbol.size.height)
    let drawn = NSSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
    let origin = NSPoint(x: square.midX - drawn.width / 2, y: square.midY - drawn.height / 2)
    symbol.draw(
        in: NSRect(origin: origin, size: drawn),
        from: .zero,
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )

    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode PNG for \(pixels)px")
    }
    return png
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

var rendered: [Int: Data] = [:]
var images: [[String: String]] = []
for slot in slots {
    let data = rendered[slot.pixels] ?? render(pixels: slot.pixels)
    rendered[slot.pixels] = data
    try data.write(to: outputDirectory.appendingPathComponent(slot.filename))
    images.append(["filename": slot.filename, "idiom": "mac", "scale": "\(slot.scale)x", "size": "\(slot.size)x\(slot.size)"])
    print("wrote \(slot.filename) (\(slot.pixels)px)")
}

let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: outputDirectory.appendingPathComponent("Contents.json"))
print("wrote Contents.json")
