import AppKit
import SwiftUI

enum ClaudeIcon {
    static let color = Color(red: 1.0, green: 0.5, blue: 0.0) // #FF8000

    // SVG path from the official Claude Code logo (viewBox 0 0 24 24)
    static func logoPath(in rect: CGRect) -> Path {
        let sx = rect.width / 24.0
        let sy = rect.height / 24.0

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * sx, y: y * sy)
        }

        var path = Path()

        // Outer shape
        path.move(to: pt(20.998, 10.949))
        path.addLine(to: pt(24, 10.949))
        path.addLine(to: pt(24, 14.051))
        path.addLine(to: pt(21, 14.051))
        path.addLine(to: pt(21, 17.079))
        path.addLine(to: pt(19.513, 17.079))
        path.addLine(to: pt(19.513, 20))
        path.addLine(to: pt(18, 20))
        path.addLine(to: pt(18, 17.079))
        path.addLine(to: pt(16.513, 17.079))
        path.addLine(to: pt(16.513, 20))
        path.addLine(to: pt(15, 20))
        path.addLine(to: pt(15, 17.079))
        path.addLine(to: pt(9, 17.079))
        path.addLine(to: pt(9, 20))
        path.addLine(to: pt(7.488, 20))
        path.addLine(to: pt(7.488, 17.079))
        path.addLine(to: pt(6, 17.079))
        path.addLine(to: pt(6, 20))
        path.addLine(to: pt(4.487, 20))
        path.addLine(to: pt(4.487, 17.079))
        path.addLine(to: pt(3, 17.079))
        path.addLine(to: pt(3, 14.05))
        path.addLine(to: pt(0, 14.05))
        path.addLine(to: pt(0, 10.95))
        path.addLine(to: pt(3, 10.95))
        path.addLine(to: pt(3, 5))
        path.addLine(to: pt(20.998, 5))
        path.closeSubpath()

        // Left eye (even-odd hole)
        path.move(to: pt(6, 10.949))
        path.addLine(to: pt(7.488, 10.949))
        path.addLine(to: pt(7.488, 8.102))
        path.addLine(to: pt(6, 8.102))
        path.closeSubpath()

        // Right eye (even-odd hole)
        path.move(to: pt(16.51, 10.949))
        path.addLine(to: pt(18, 10.949))
        path.addLine(to: pt(18, 8.102))
        path.addLine(to: pt(16.51, 8.102))
        path.closeSubpath()

        return path
    }

    static func menuBarImage(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        // Flip Y for NSImage coordinate system
        ctx.saveGState()
        ctx.translateBy(x: 0, y: size)
        ctx.scaleBy(x: 1, y: -1)

        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let path = logoPath(in: rect)

        ctx.setFillColor(NSColor.black.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath(using: .evenOdd)

        ctx.restoreGState()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}

struct ClaudeMascotView: View {
    let size: CGFloat
    var color: Color = ClaudeIcon.color

    var body: some View {
        ClaudeIcon.logoPath(in: CGRect(x: 0, y: 0, width: size, height: size))
            .fill(color, style: FillStyle(eoFill: true))
            .frame(width: size, height: size)
    }
}
