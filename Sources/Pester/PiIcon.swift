import SwiftUI

enum PiIcon {
    static func logoPath(in rect: CGRect) -> Path {
        let sx = rect.width / 800
        let sy = rect.height / 800

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }

        var path = Path()

        path.move(to: point(165.29, 165.29))
        path.addLine(to: point(517.36, 165.29))
        path.addLine(to: point(517.36, 400))
        path.addLine(to: point(400, 400))
        path.addLine(to: point(400, 517.36))
        path.addLine(to: point(282.65, 517.36))
        path.addLine(to: point(282.65, 634.72))
        path.addLine(to: point(165.29, 634.72))
        path.closeSubpath()

        path.move(to: point(282.65, 282.65))
        path.addLine(to: point(282.65, 400))
        path.addLine(to: point(400, 400))
        path.addLine(to: point(400, 282.65))
        path.closeSubpath()

        path.move(to: point(517.36, 400))
        path.addLine(to: point(634.72, 400))
        path.addLine(to: point(634.72, 634.72))
        path.addLine(to: point(517.36, 634.72))
        path.closeSubpath()

        return path
    }
}

struct PiLogoView: View {
    let size: CGFloat

    var body: some View {
        PiIcon.logoPath(in: CGRect(x: 0, y: 0, width: size, height: size))
            .fill(.white, style: FillStyle(eoFill: true))
            .frame(width: size, height: size)
    }
}
