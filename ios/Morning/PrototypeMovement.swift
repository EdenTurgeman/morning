import SwiftUI

struct ExerciseMotionBay: View {
    let treatment: DawnTreatment
    let exercise: String
    let accent: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var movement: ExerciseMovement {
        ExerciseMovement(exercise: exercise)
    }

    var body: some View {
        ZStack {
            baySurface

            ExerciseFigure(
                movement: movement,
                phase: 0,
                accent: accent
            )
            .opacity(0.18)

            if reduceMotion {
                ExerciseFigure(
                    movement: movement,
                    phase: 1,
                    accent: accent
                )
            } else {
                TimelineView(.animation(minimumInterval: 1 / 60)) { timeline in
                    ExerciseFigure(
                        movement: movement,
                        phase: motionPhase(at: timeline.date),
                        accent: accent
                    )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: treatment == .precise ? 1 : 0.75)
        }
        .overlay(alignment: .topLeading) {
            Text("MOVEMENT")
                .font(.caption2.weight(.semibold))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.58))
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(exercise) movement")
        .accessibilityValue(reduceMotion ? "Start and finish positions" : "Repeating demonstration")
    }

    @ViewBuilder
    private var baySurface: some View {
        switch treatment {
        case .atmospheric:
            LinearGradient(
                colors: [Color.black.opacity(0.26), Color.black.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .precise:
            Color.black.opacity(0.36)
                .overlay(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(accent.opacity(0.26))
                        .frame(width: 34, height: 1)
                }
        case .tactile:
            LinearGradient(
                colors: [Color.white.opacity(0.09), Color.black.opacity(0.32)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var cornerRadius: Double {
        switch treatment {
        case .atmospheric: 22
        case .precise: 12
        case .tactile: 26
        }
    }

    private var borderColor: Color {
        switch treatment {
        case .atmospheric: .white.opacity(0.1)
        case .precise: accent.opacity(0.3)
        case .tactile: .white.opacity(0.14)
        }
    }

    private func motionPhase(at date: Date) -> Double {
        let cycle = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: 3.2) / 3.2
        return 0.5 - 0.5 * cos(cycle * 2 * .pi)
    }
}

private enum ExerciseMovement {
    case overheadPress
    case pushUp
    case lateralRaise
    case floorFly
    case row
    case curl

    init(exercise: String) {
        switch exercise {
        case "Overhead press": self = .overheadPress
        case "Push-up": self = .pushUp
        case "Lateral raise": self = .lateralRaise
        case "Floor fly": self = .floorFly
        case "Bent-over row": self = .row
        default: self = .curl
        }
    }
}

private struct ExerciseFigure: View {
    let movement: ExerciseMovement
    let phase: Double
    let accent: Color

    var body: some View {
        Canvas { context, size in
            switch movement {
            case .overheadPress:
                drawOverheadPress(context: &context, size: size)
            case .pushUp:
                drawPushUp(context: &context, size: size)
            case .lateralRaise:
                drawLateralRaise(context: &context, size: size)
            case .floorFly:
                drawFloorFly(context: &context, size: size)
            case .row:
                drawRow(context: &context, size: size)
            case .curl:
                drawCurl(context: &context, size: size)
            }
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 14)
        .allowsHitTesting(false)
    }

    private var bodyColor: Color {
        .white.opacity(0.74)
    }

    private func drawOverheadPress(context: inout GraphicsContext, size: CGSize) {
        let shoulderY = 0.4
        drawHead(context: &context, size: size, center: point(0.5, 0.25, in: size))
        stroke([(0.5, 0.34), (0.5, 0.69)], color: bodyColor, context: &context, size: size)
        stroke([(0.38, 0.82), (0.5, 0.69), (0.62, 0.82)], color: bodyColor, context: &context, size: size)

        let leftElbow = interpolated(from: (0.36, 0.51), to: (0.43, 0.23))
        let leftHand = interpolated(from: (0.36, 0.3), to: (0.43, 0.08))
        let rightElbow = mirrored(leftElbow)
        let rightHand = mirrored(leftHand)
        stroke([(0.5, shoulderY), leftElbow, leftHand], color: accent, context: &context, size: size)
        stroke([(0.5, shoulderY), rightElbow, rightHand], color: accent, context: &context, size: size)
        drawDumbbell(at: leftHand, context: &context, size: size)
        drawDumbbell(at: rightHand, context: &context, size: size)
    }

    private func drawPushUp(context: inout GraphicsContext, size: CGSize) {
        let bodyY = 0.43 + phase * 0.13
        let shoulder = (0.34, bodyY)
        let ankle = (0.78, bodyY + 0.05)
        stroke([shoulder, ankle], color: bodyColor, context: &context, size: size)
        drawHead(context: &context, size: size, center: point(0.25, bodyY - 0.02, in: size))

        let elbow = (0.4, 0.7 - phase * 0.03)
        let hand = (0.3, 0.76)
        stroke([shoulder, elbow, hand], color: accent, context: &context, size: size)
        stroke([(0.66, bodyY + 0.04), (0.82, 0.76)], color: bodyColor, context: &context, size: size)
        stroke([(0.27, 0.78), (0.34, 0.78)], color: accent.opacity(0.8), context: &context, size: size)
        stroke([(0.28, 0.81), (0.35, 0.81)], color: accent.opacity(0.6), context: &context, size: size)
    }

    private func drawLateralRaise(context: inout GraphicsContext, size: CGSize) {
        drawHead(context: &context, size: size, center: point(0.5, 0.23, in: size))
        stroke([(0.5, 0.32), (0.5, 0.67)], color: bodyColor, context: &context, size: size)
        stroke([(0.38, 0.82), (0.5, 0.67), (0.62, 0.82)], color: bodyColor, context: &context, size: size)

        let leftElbow = interpolated(from: (0.43, 0.57), to: (0.31, 0.39))
        let leftHand = interpolated(from: (0.46, 0.73), to: (0.14, 0.4))
        let rightElbow = mirrored(leftElbow)
        let rightHand = mirrored(leftHand)
        stroke([(0.5, 0.38), leftElbow, leftHand], color: accent, context: &context, size: size)
        stroke([(0.5, 0.38), rightElbow, rightHand], color: accent, context: &context, size: size)
        drawDumbbell(at: leftHand, context: &context, size: size)
        drawDumbbell(at: rightHand, context: &context, size: size)
    }

    private func drawFloorFly(context: inout GraphicsContext, size: CGSize) {
        drawHead(context: &context, size: size, center: point(0.5, 0.24, in: size))
        stroke([(0.5, 0.32), (0.5, 0.77)], color: bodyColor, context: &context, size: size)
        stroke([(0.43, 0.78), (0.57, 0.78)], color: bodyColor, context: &context, size: size)

        let leftElbow = interpolated(from: (0.29, 0.49), to: (0.43, 0.36))
        let leftHand = interpolated(from: (0.12, 0.5), to: (0.45, 0.22))
        let rightElbow = mirrored(leftElbow)
        let rightHand = mirrored(leftHand)
        stroke([(0.5, 0.39), leftElbow, leftHand], color: accent, context: &context, size: size)
        stroke([(0.5, 0.39), rightElbow, rightHand], color: accent, context: &context, size: size)
        drawDumbbell(at: leftHand, context: &context, size: size)
        drawDumbbell(at: rightHand, context: &context, size: size)
    }

    private func drawRow(context: inout GraphicsContext, size: CGSize) {
        drawHead(context: &context, size: size, center: point(0.31, 0.34, in: size))
        stroke([(0.35, 0.39), (0.65, 0.55)], color: bodyColor, context: &context, size: size)
        stroke([(0.65, 0.55), (0.52, 0.82), (0.73, 0.82)], color: bodyColor, context: &context, size: size)

        let elbow = interpolated(from: (0.48, 0.65), to: (0.54, 0.45))
        let hand = interpolated(from: (0.43, 0.78), to: (0.65, 0.58))
        stroke([(0.43, 0.45), elbow, hand], color: accent, context: &context, size: size)
        drawDumbbell(at: hand, context: &context, size: size)
    }

    private func drawCurl(context: inout GraphicsContext, size: CGSize) {
        drawHead(context: &context, size: size, center: point(0.5, 0.23, in: size))
        stroke([(0.5, 0.32), (0.5, 0.68)], color: bodyColor, context: &context, size: size)
        stroke([(0.38, 0.82), (0.5, 0.68), (0.62, 0.82)], color: bodyColor, context: &context, size: size)

        let leftHand = interpolated(from: (0.36, 0.72), to: (0.39, 0.38))
        let rightHand = mirrored(leftHand)
        stroke([(0.44, 0.38), (0.36, 0.55), leftHand], color: accent, context: &context, size: size)
        stroke([(0.56, 0.38), (0.64, 0.55), rightHand], color: accent, context: &context, size: size)
        drawDumbbell(at: leftHand, context: &context, size: size)
        drawDumbbell(at: rightHand, context: &context, size: size)
    }

    private func drawHead(context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        let diameter = min(size.width, size.height) * 0.09
        let rect = CGRect(
            x: center.x - diameter / 2,
            y: center.y - diameter / 2,
            width: diameter,
            height: diameter
        )
        context.stroke(
            Path(ellipseIn: rect),
            with: .color(bodyColor),
            style: StrokeStyle(lineWidth: 4)
        )
    }

    private func drawDumbbell(
        at location: (Double, Double),
        context: inout GraphicsContext,
        size: CGSize
    ) {
        stroke(
            [(location.0 - 0.035, location.1), (location.0 + 0.035, location.1)],
            color: .white.opacity(0.86),
            lineWidth: 5,
            context: &context,
            size: size
        )
    }

    private func stroke(
        _ coordinates: [(Double, Double)],
        color: Color,
        lineWidth: Double = 5,
        context: inout GraphicsContext,
        size: CGSize
    ) {
        guard let first = coordinates.first else { return }
        var path = Path()
        path.move(to: point(first.0, first.1, in: size))
        for coordinate in coordinates.dropFirst() {
            path.addLine(to: point(coordinate.0, coordinate.1, in: size))
        }
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
    }

    private func interpolated(
        from start: (Double, Double),
        to end: (Double, Double)
    ) -> (Double, Double) {
        (
            start.0 + (end.0 - start.0) * phase,
            start.1 + (end.1 - start.1) * phase
        )
    }

    private func mirrored(_ point: (Double, Double)) -> (Double, Double) {
        (1 - point.0, point.1)
    }

    private func point(_ x: Double, _ y: Double, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * x, y: size.height * y)
    }
}
