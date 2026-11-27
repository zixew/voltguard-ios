import SwiftUI

public struct BrandLogoView: View {
    public let size: CGFloat
    public let accentColor: Color

    public init(size: CGFloat = 28, accentColor: Color = Color(hex: ThemeHexConstants.obsidianSlate.accent)) {
        self.size = size
        self.accentColor = accentColor
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(Color(hex: ThemeHexConstants.obsidianSlate.background))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(Color(hex: ThemeHexConstants.obsidianSlate.border), lineWidth: max(1, size * 0.04))
                )

            ShieldShape()
                .stroke(Color(hex: ThemeHexConstants.obsidianSlate.primaryText).opacity(0.9), lineWidth: max(1.2, size * 0.06))
                .frame(width: size * 0.56, height: size * 0.62)

            Circle()
                .trim(from: 0.12, to: 0.88)
                .stroke(accentColor, style: StrokeStyle(lineWidth: max(1.5, size * 0.085), lineCap: .round))
                .rotationEffect(.degrees(90))
                .frame(width: size * 0.34, height: size * 0.34)

            BoltCutShape()
                .fill(accentColor)
                .frame(width: size * 0.18, height: size * 0.26)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.18))
        path.addLine(to: CGPoint(x: w, y: h * 0.54))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 0.94, y: h * 0.86))
        path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.54), control: CGPoint(x: w * 0.06, y: h * 0.86))
        path.addLine(to: CGPoint(x: 0, y: h * 0.18))
        path.closeSubpath()
        return path
    }
}

private struct BoltCutShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.62, y: 0))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.48, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.36, y: h))
        path.addLine(to: CGPoint(x: w * 0.86, y: h * 0.44))
        path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.44))
        path.closeSubpath()
        return path
    }
}
