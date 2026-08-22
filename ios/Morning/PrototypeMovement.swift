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
            .opacity(0.13)

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
                .font(TypeScale.microLabel)
                .tracking(1.6)
                .foregroundStyle(Ink.tertiary)
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
            let renderer = FigureRenderer(
                pose: pose,
                limbColor: accent,
                bodyColor: .white.opacity(0.82),
                size: size
            )
            renderer.draw(into: &context)
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 14)
        .allowsHitTesting(false)
    }

    /// The pose coordinates are unchanged from the stroke version — only the
    /// rendering gained mass. Each one interpolates between an honest start and
    /// finish position for the real movement.
    private var pose: FigurePose {
        switch movement {
        case .overheadPress: overheadPress
        case .pushUp: pushUp
        case .lateralRaise: lateralRaise
        case .floorFly: floorFly
        case .row: row
        case .curl: curl
        }
    }

    private var overheadPress: FigurePose {
        let hand = interpolated(from: (0.36, 0.30), to: (0.43, 0.09))
        let elbow = interpolated(from: (0.34, 0.50), to: (0.43, 0.24))
        return FigurePose(
            head: (0.5, 0.22),
            neck: (0.5, 0.33),
            hip: (0.5, 0.66),
            arms: [
                [(0.44, 0.39), elbow, hand],
                [(0.56, 0.39), mirrored(elbow), mirrored(hand)],
            ],
            legs: [
                [(0.465, 0.68), (0.455, 0.79), (0.450, 0.90)],
                [(0.535, 0.68), (0.545, 0.79), (0.550, 0.90)],
            ],
            dumbbells: [hand, mirrored(hand)]
        )
    }

    private var pushUp: FigurePose {
        // The body drops toward the floor and presses back up; the hands stay put.
        let drop = phase * 0.12
        return FigurePose(
            head: (0.24, 0.40 + drop),
            neck: (0.34, 0.44 + drop),
            hip: (0.62, 0.52 + drop * 0.7),
            arms: [
                [(0.34, 0.45 + drop), (0.40, 0.60 + drop * 0.4), (0.31, 0.76)],
            ],
            legs: [
                [(0.62, 0.53 + drop * 0.7), (0.75, 0.64 + drop * 0.4), (0.86, 0.76)],
            ],
            ground: FigureGround(fromX: 0.16, toX: 0.94, y: 0.80)
        )
    }

    private var lateralRaise: FigurePose {
        let hand = interpolated(from: (0.42, 0.62), to: (0.20, 0.40))
        let elbow = interpolated(from: (0.43, 0.51), to: (0.32, 0.40))
        return FigurePose(
            head: (0.5, 0.21),
            neck: (0.5, 0.32),
            hip: (0.5, 0.64),
            arms: [
                [(0.44, 0.37), elbow, hand],
                [(0.56, 0.37), mirrored(elbow), mirrored(hand)],
            ],
            legs: [
                [(0.465, 0.66), (0.455, 0.78), (0.450, 0.90)],
                [(0.535, 0.66), (0.545, 0.78), (0.550, 0.90)],
            ],
            dumbbells: [hand, mirrored(hand)]
        )
    }

    private var floorFly: FigurePose {
        // Lying down: the arms open wide and close above the chest.
        let hand = interpolated(from: (0.16, 0.44), to: (0.44, 0.22))
        let elbow = interpolated(from: (0.28, 0.48), to: (0.44, 0.36))
        return FigurePose(
            head: (0.5, 0.22),
            neck: (0.5, 0.33),
            hip: (0.5, 0.70),
            arms: [
                [(0.45, 0.39), elbow, hand],
                [(0.55, 0.39), mirrored(elbow), mirrored(hand)],
            ],
            legs: [
                [(0.470, 0.72), (0.458, 0.82), (0.452, 0.90)],
                [(0.530, 0.72), (0.542, 0.82), (0.548, 0.90)],
            ],
            dumbbells: [hand, mirrored(hand)],
            ground: FigureGround(fromX: 0.10, toX: 0.90, y: 0.92)
        )
    }

    private var row: FigurePose {
        // Hinged at the hip, torso near horizontal, elbow driving back.
        let hand = interpolated(from: (0.40, 0.74), to: (0.58, 0.56))
        let elbow = interpolated(from: (0.44, 0.62), to: (0.56, 0.44))
        return FigurePose(
            head: (0.24, 0.36),
            neck: (0.34, 0.42),
            hip: (0.64, 0.54),
            arms: [
                [(0.38, 0.45), elbow, hand],
            ],
            legs: [
                [(0.622, 0.56), (0.608, 0.74), (0.622, 0.90)],
                [(0.678, 0.56), (0.692, 0.74), (0.706, 0.90)],
            ],
            dumbbells: [hand]
        )
    }

    private var curl: FigurePose {
        let hand = interpolated(from: (0.37, 0.66), to: (0.42, 0.40))
        let elbow = interpolated(from: (0.39, 0.53), to: (0.40, 0.54))
        return FigurePose(
            head: (0.5, 0.21),
            neck: (0.5, 0.32),
            hip: (0.5, 0.64),
            arms: [
                [(0.44, 0.37), elbow, hand],
                [(0.56, 0.37), mirrored(elbow), mirrored(hand)],
            ],
            legs: [
                [(0.465, 0.66), (0.455, 0.78), (0.450, 0.90)],
                [(0.535, 0.66), (0.545, 0.78), (0.550, 0.90)],
            ],
            dumbbells: [hand, mirrored(hand)]
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
}
