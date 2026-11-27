import SwiftUI
import VoltGuardDomain

public extension View {
    @ViewBuilder
    func compatNumericTransition() -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.contentTransition(.numericText())
        } else {
            self
        }
    }

    @ViewBuilder
    func compatOnChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value, perform: action)
        }
    }
}

public extension Text {
    func compatTextColor(_ color: Color) -> Text {
        if #available(iOS 17.0, macOS 14.0, *) {
            return self.foregroundStyle(color)
        } else {
            return self.foregroundColor(color)
        }
    }
}

public enum BatteryVisualMode: Equatable {
    case charging
    case limitReached
    case thermalWarning
    case onBattery
}

public struct LiquidBatteryCellView: View {
    public let percentage: Int
    public let limitPercent: Int
    public let sailingDeltaPercent: Int?
    public let thermalLevel: iOSThermalLevel
    public let colorStyle: BatteryColorStyle
    public let mode: BatteryVisualMode
    public let palette: ThemePalette
    public let width: CGFloat
    public let height: CGFloat
    public let onLimitChange: ((Int) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDraggingLimit = false

    public init(
        percentage: Int,
        limitPercent: Int,
        sailingDeltaPercent: Int? = nil,
        thermalLevel: iOSThermalLevel = .nominal,
        colorStyle: BatteryColorStyle = .adaptiveSpectrum,
        mode: BatteryVisualMode,
        palette: ThemePalette,
        width: CGFloat = LiquidBatteryConstants.cellWidth,
        height: CGFloat = LiquidBatteryConstants.cellHeight,
        onLimitChange: ((Int) -> Void)? = nil
    ) {
        self.percentage = min(max(percentage, 0), 100)
        self.limitPercent = min(max(limitPercent, VoltGuardiOSLimits.minLimitPercent), VoltGuardiOSLimits.maxLimitPercent)
        self.sailingDeltaPercent = sailingDeltaPercent
        self.thermalLevel = thermalLevel
        self.colorStyle = colorStyle
        self.mode = mode
        self.palette = palette
        self.width = width
        self.height = height
        self.onLimitChange = onLimitChange
    }

    public var body: some View {
        let isActiveFlow = (mode == .charging)
        let shouldAnimate = !reduceMotion
        let interval = isActiveFlow ? MotionConstants.flowFrameInterval : LiquidBatteryConstants.calmFlowFrameInterval
        let cycleSeconds = isActiveFlow ? LiquidBatteryConstants.waveCycleSeconds : LiquidBatteryConstants.calmWaveCycleSeconds
        let amplitude: CGFloat = shouldAnimate ? (isActiveFlow ? LiquidBatteryConstants.waveAmplitude : LiquidBatteryConstants.calmWaveAmplitude) : 0
        let fillColors = resolvedGradientColors
        let fillColor = fillColors.first ?? palette.accent

        TimelineView(.animation(minimumInterval: interval, paused: !shouldAnimate)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let phase: Double = shouldAnimate
                ? (time.truncatingRemainder(dividingBy: cycleSeconds) / cycleSeconds) * (.pi * 2)
                : 0

            Canvas { graphics, size in
                drawCell(
                    graphics: &graphics,
                    size: size,
                    time: time,
                    phase: phase,
                    amplitude: amplitude,
                    isActiveFlow: isActiveFlow,
                    shouldAnimate: shouldAnimate,
                    fillColors: fillColors,
                    fillColor: fillColor
                )
            }
            .overlay(alignment: .center) {
                centerOverlay(time: time, shouldAnimate: shouldAnimate, fillColor: fillColor)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    guard let onLimitChange else { return }
                    isDraggingLimit = true
                    let normalized = 1.0 - min(max(value.location.y / height, 0), 1)
                    let newLimit = Int((normalized * 100.0).rounded())
                    onLimitChange(min(max(newLimit, VoltGuardiOSLimits.minLimitPercent), VoltGuardiOSLimits.maxLimitPercent))
                }
                .onEnded { _ in
                    isDraggingLimit = false
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(percentage)% / \(limitPercent)%"))
    }

    private func drawCell(
        graphics: inout GraphicsContext,
        size: CGSize,
        time: TimeInterval,
        phase: Double,
        amplitude: CGFloat,
        isActiveFlow: Bool,
        shouldAnimate: Bool,
        fillColors: [Color],
        fillColor: Color
    ) {
        let capHeight: CGFloat = 6
        let capWidth: CGFloat = size.width * 0.36
        let capRect = CGRect(x: (size.width - capWidth) / 2, y: 0, width: capWidth, height: capHeight)
        graphics.fill(Path(roundedRect: capRect, cornerRadius: 3), with: .color(palette.border))

        let bodyRect = CGRect(x: 2, y: capHeight + 2, width: size.width - 4, height: size.height - capHeight - 4)
        let bodyPath = Path(roundedRect: bodyRect, cornerRadius: 12)
        graphics.fill(bodyPath, with: .color(palette.background))

        graphics.drawLayer { layer in
            let innerRect = bodyRect.insetBy(dx: 3, dy: 3)
            layer.clip(to: Path(roundedRect: innerRect, cornerRadius: 9))
            drawWavesAndGate(
                layer: &layer,
                innerRect: innerRect,
                time: time,
                phase: phase,
                amplitude: amplitude,
                isActiveFlow: isActiveFlow,
                shouldAnimate: shouldAnimate,
                fillColors: fillColors,
                fillColor: fillColor
            )
        }

        let isHighlighted = shouldAnimate && (mode == .charging || mode == .limitReached)
        let pulseRate = mode == .charging ? 3.2 : 1.8
        let pulse: Double = isHighlighted ? (0.50 + 0.45 * (0.5 + 0.5 * sin(time * pulseRate))) : 0.0
        let rimColor: Color = isDraggingLimit ? palette.accent : (isHighlighted ? fillColor.opacity(pulse) : palette.border)
        graphics.stroke(bodyPath, with: .color(rimColor), lineWidth: (isDraggingLimit || isHighlighted) ? 2.0 : 1.5)
    }

    private func drawWavesAndGate(
        layer: inout GraphicsContext,
        innerRect: CGRect,
        time: TimeInterval,
        phase: Double,
        amplitude: CGFloat,
        isActiveFlow: Bool,
        shouldAnimate: Bool,
        fillColors: [Color],
        fillColor: Color
    ) {
        let levelFraction = CGFloat(percentage) / 100.0
        let surfaceY = innerRect.maxY - (innerRect.height * levelFraction)
        let stepCount = 28

        var backWave = Path()
        backWave.move(to: CGPoint(x: innerRect.minX, y: innerRect.maxY))
        backWave.addLine(to: CGPoint(x: innerRect.minX, y: surfaceY))
        for step in 0...stepCount {
            let t = CGFloat(step) / CGFloat(stepCount)
            let x = innerRect.minX + t * innerRect.width
            let yOffset = sin(Double(t) * .pi * 2 * LiquidBatteryConstants.waveCycles - phase * 0.8 + 1.2) * Double(amplitude * 0.82)
            backWave.addLine(to: CGPoint(x: x, y: surfaceY + CGFloat(yOffset) - 1.5))
        }
        backWave.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.maxY))
        backWave.closeSubpath()
        layer.fill(backWave, with: .color(fillColor.opacity(0.42)))

        var frontWave = Path()
        var crest = Path()
        frontWave.move(to: CGPoint(x: innerRect.minX, y: innerRect.maxY))
        for step in 0...stepCount {
            let t = CGFloat(step) / CGFloat(stepCount)
            let x = innerRect.minX + t * innerRect.width
            let yOffset = sin(Double(t) * .pi * 2 * LiquidBatteryConstants.waveCycles + phase) * Double(amplitude)
            let pt = CGPoint(x: x, y: surfaceY + CGFloat(yOffset))
            frontWave.addLine(to: pt)
            if step == 0 { crest.move(to: pt) } else { crest.addLine(to: pt) }
        }
        frontWave.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.maxY))
        frontWave.closeSubpath()

        let gradient = Gradient(colors: [
            (fillColors.first ?? fillColor).opacity(0.96),
            (fillColors.last ?? fillColor).opacity(0.74)
        ])
        layer.fill(
            frontWave,
            with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: innerRect.midX, y: surfaceY),
                endPoint: CGPoint(x: innerRect.midX, y: innerRect.maxY)
            )
        )
        layer.stroke(crest, with: .color(Color.white.opacity(0.45)), lineWidth: 1.3)

        if shouldAnimate && isActiveFlow {
            let pCount = 8
            for idx in 0..<pCount {
                let speed = 0.38 + Double(idx % 3) * 0.11
                let progress = ((time * speed) + Double(idx) / Double(pCount)).truncatingRemainder(dividingBy: 1.0)
                let directed = 1.0 - progress
                let baseX: CGFloat = 0.16 + 0.68 * CGFloat((idx * 37 + 13) % 11) / 10.0
                let wobble = CGFloat(sin(progress * .pi * 2.4 + Double(idx) * 1.3)) * 3.2
                let px = innerRect.minX + innerRect.width * baseX + wobble
                let py = surfaceY + (innerRect.maxY - surfaceY) * CGFloat(directed)
                if py >= surfaceY + 2 && py <= innerRect.maxY - 2 {
                    let radius: CGFloat = 1.6 + CGFloat(idx % 3) * 0.75
                    let fade = min(min(progress * 4.0, (1.0 - progress) * 3.5), 1.0)
                    let rect = CGRect(x: px - radius, y: py - radius, width: radius * 2, height: radius * 2)
                    layer.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.55 * fade)))
                }
            }
        }

        let limitFraction = CGFloat(limitPercent) / 100.0
        let limitY = innerRect.maxY - (innerRect.height * limitFraction)
        if let delta = sailingDeltaPercent, delta > 0 {
            let floorFraction = CGFloat(max(limitPercent - delta, 20)) / 100.0
            let floorY = innerRect.maxY - (innerRect.height * floorFraction)
            let band = CGRect(x: innerRect.minX, y: limitY, width: innerRect.width, height: max(floorY - limitY, 0))
            layer.fill(Path(band), with: .color(palette.primaryText.opacity(0.12)))
        }

        var gate = Path()
        gate.move(to: CGPoint(x: innerRect.minX, y: limitY))
        gate.addLine(to: CGPoint(x: innerRect.maxX, y: limitY))
        layer.stroke(
            gate,
            with: .color(isDraggingLimit ? palette.primaryText : palette.primaryText.opacity(0.75)),
            style: StrokeStyle(lineWidth: isDraggingLimit ? 2 : 1.5, dash: [4, 3])
        )
        if limitPercent < VoltGuardiOSLimits.maxLimitPercent {
            let tag = Text("\(limitPercent)%")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .compatTextColor(palette.primaryText.opacity(0.85))
            layer.draw(tag, at: CGPoint(x: innerRect.maxX - 13, y: max(limitY - 7, innerRect.minY + 6)))
        }
    }

    @ViewBuilder
    private func centerOverlay(time: TimeInterval, shouldAnimate: Bool, fillColor: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(percentage)%")
                .font(.system(size: width * 0.25, weight: .bold, design: .rounded))
                .monospacedDigit()
                .compatNumericTransition()
                .foregroundStyle(palette.primaryText)
                .shadow(color: palette.background.opacity(0.6), radius: 2, y: 1)

            if mode == .charging {
                let iconPulse: Double = shouldAnimate ? (0.72 + 0.28 * (0.5 + 0.5 * sin(time * 4.0))) : 1.0
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(palette.primaryText.opacity(iconPulse))
                    .shadow(color: fillColor.opacity(shouldAnimate ? 0.7 : 0), radius: 3)
            } else if mode == .limitReached {
                let shieldPulse: Double = shouldAnimate ? (0.68 + 0.32 * (0.5 + 0.5 * sin(time * 2.2))) : 0.9
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.primaryText.opacity(shieldPulse))
                    .shadow(color: fillColor.opacity(shouldAnimate ? 0.6 : 0), radius: 3)
            } else if mode == .thermalWarning {
                Image(systemName: "thermometer.sun.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "#F87171"))
            }
        }
    }

    private var resolvedGradientColors: [Color] {
        if mode == .thermalWarning {
            return [Color(hex: "#EF4444"), Color(hex: "#B91C1C")]
        }
        switch colorStyle {
        case .themeAccent:
            let base = percentage <= VoltGuardiOSLimits.lowBatteryAlertThresholdPercent ? palette.danger : (percentage < 50 ? palette.warning : palette.accent)
            return [base, base.opacity(0.75)]
        case .thermalReactive:
            switch thermalLevel {
            case .critical: return [Color(hex: "#F97316"), Color(hex: "#EF4444")]
            case .serious: return [Color(hex: "#FBBF24"), Color(hex: "#F59E0B")]
            case .fair: return [Color(hex: "#34D399"), Color(hex: "#10B981")]
            case .nominal: return [Color(hex: "#38BDF8"), Color(hex: "#0EA5E9")]
            }
        case .adaptiveSpectrum:
            if percentage <= VoltGuardiOSLimits.lowBatteryAlertThresholdPercent {
                return [Color(hex: "#F87171"), Color(hex: "#EF4444")]
            }
            if percentage < 50 {
                return [Color(hex: "#FBBF24"), Color(hex: "#F59E0B")]
            }
            if mode == .limitReached {
                return [Color(hex: "#10B981"), Color(hex: "#06B6D4")]
            }
            if percentage >= 80 {
                return [Color(hex: "#34D399"), Color(hex: "#10B981")]
            }
            return [Color(hex: "#38BDF8"), Color(hex: "#0EA5E9")]
        }
    }
}
