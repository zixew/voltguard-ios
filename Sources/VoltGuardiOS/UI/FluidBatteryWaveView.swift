import SwiftUI

public struct FluidBatteryWaveView: View {
    public let percentage: Int
    public let isCharging: Bool
    public let accentColor: Color
    @State private var phase: CGFloat = 0

    public init(percentage: Int, isCharging: Bool, accentColor: Color) {
        self.percentage = max(0, min(100, percentage))
        self.isCharging = isCharging
        self.accentColor = accentColor
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1.5)
                )

            GeometryReader { geo in
                let fillHeight = geo.size.height * CGFloat(percentage) / 100.0

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ZStack {
                        WaveShape(phase: phase, amplitude: 5)
                            .fill(accentColor.opacity(0.4))
                            .frame(height: 14)
                            .offset(y: -7)

                        WaveShape(phase: phase + .pi, amplitude: 4)
                            .fill(accentColor)
                            .frame(height: 14)
                            .offset(y: -7)

                        Rectangle()
                            .fill(accentColor)
                            .frame(height: fillHeight)
                    }
                    .frame(height: fillHeight)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    if isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text("\(percentage)%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text(isCharging ? "Charging" : "On Battery")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(width: 140, height: 180)
        .onAppear {
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

private struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let mid = height / 2

        path.move(to: CGPoint(x: 0, y: mid))
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 2 + phase)
            let y = mid + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}
