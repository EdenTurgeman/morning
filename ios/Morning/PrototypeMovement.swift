import SwiftUI

struct ExerciseMotionBay: View {
    let treatment: DawnTreatment
    let exercise: String
    let accent: Color
    /// Freezes the animation at a phase, for review. `nil` in the app.
    var frozenPhase: Double?

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

            if let frozenPhase {
                ExerciseFigure(movement: movement, phase: frozenPhase, accent: accent)
            } else if reduceMotion {
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

/// Internal rather than private so `FigureAnatomyTests` can reach it.
///
/// The invariant it guards is worth the access: every bone in this figure has
/// to be the same length at every phase of every movement, and that is a
/// property a test can check exactly and an eye cannot.
enum ExerciseMovement {
    case overheadPress
    case pushUp
    case lateralRaise
    case rearDeltFly
    case floorFly
    case row
    case curl

    init(exercise: String) {
        switch exercise {
        case "Overhead press": self = .overheadPress
        case "Push-up": self = .pushUp
        case "Lateral raise": self = .lateralRaise
        // Was falling through to `.curl`, so one of the eight movements in the
        // program animated as an entirely different exercise. The web build has
        // always had its own figure for this one.
        case "Rear-delt fly": self = .rearDeltFly
        case "Floor fly": self = .floorFly
        case "Bent-over row": self = .row
        default: self = .curl
        }
    }
}

struct ExerciseFigure: View {
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
    var pose: FigurePose {
        switch movement {
        case .overheadPress: overheadPress
        case .pushUp: pushUp
        case .lateralRaise: lateralRaise
        case .rearDeltFly: rearDeltFly
        case .floorFly: floorFly
        case .row: row
        case .curl: curl
        }
    }

    // MARK: - Anatomy

    /// A human arm, in units of the figure's height. Fixed, because they are
    /// bones.
    private enum Arm {
        static let upper = 0.150
        static let fore = 0.140
    }

    /// Where the elbow has to be, given a shoulder and a hand.
    ///
    /// THE FIGURE USED TO BE MADE OF RUBBER. Every pose authored the elbow by
    /// hand next to the wrist and interpolated both independently, so the bones
    /// changed length through the movement. Measured across the five arm
    /// movements at the extremes of their travel: the forearm grew 42% through
    /// a lateral raise, shrank 26% through an overhead press, and the upper arm
    /// lost **86% of itself** through a floor fly — the elbow ended up 7pt from
    /// the shoulder, which is why that one looked worst.
    ///
    /// So the elbow is not authored any more. Two-bone inverse kinematics: the
    /// pose says where the hand goes, the bones are a fixed length, and this
    /// works out the only two places the elbow can be. `bend` picks which of
    /// the two — that is the difference between an elbow that flares out and
    /// one that tucks, and it is the one thing about an arm a viewer reads
    /// instantly.
    ///
    /// When the hand is further away than the arm is long, the reach is clamped
    /// just short of straight rather than allowed to hyperextend, because a
    /// locked-straight limb drawn with round joints reads as a broken one.
    /// A hand swinging on a fixed radius about a fixed elbow.
    ///
    /// For a curl, IK is the wrong tool and gives the wrong answer. A curl's
    /// elbow does not travel — it stays pinned at the ribs and only the forearm
    /// rotates — so solving the elbow from the hand makes it swing wide to
    /// accommodate a folded arm, and the figure ends up doing a chicken-wing.
    /// That is what the first pass rendered: at the top of the curl the hand
    /// was 0.03 from the shoulder against an arm 0.29 long, the solver clamped,
    /// and both elbows shot out sideways.
    ///
    /// So a curl is authored the other way round: elbow fixed, hand on the end
    /// of a forearm at an angle. The bone cannot change length because the
    /// length is the radius.
    private func swung(
        about pivot: (Double, Double),
        radius: Double,
        from startAngle: Double,
        to endAngle: Double,
        inward: Double
    ) -> (Double, Double) {
        let a = startAngle + (endAngle - startAngle) * phase
        return (pivot.0 + sin(a) * radius * inward, pivot.1 + cos(a) * radius)
    }

    /// Returns the WHOLE arm, hand included, because clamping only the elbow
    /// is not a fix.
    ///
    /// The first version returned just the elbow and left the authored hand
    /// where it was. When a pose reached further than an arm is long, the elbow
    /// was pulled back to full extension and the hand was not — so the drawn
    /// forearm stretched to cover the gap, by 19% on the overhead press and 31%
    /// on the push-up. `FigureAnatomyTests` caught both, which is the entire
    /// reason it exists: looking at the rendered figures, I had signed both off.
    ///
    /// So an over-reach pulls the hand in to where the arm can actually get to.
    /// The pose asks; the anatomy answers.
    private func arm(
        from shoulder: (Double, Double),
        to target: (Double, Double),
        bend: Double
    ) -> (elbow: (Double, Double), hand: (Double, Double)) {
        let dx = target.0 - shoulder.0
        let dy = target.1 - shoulder.1
        let span = max(0.0001, (dx * dx + dy * dy).squareRoot())
        let ux = dx / span
        let uy = dy / span

        // Just short of straight, because a limb drawn with round joints reads
        // as broken when it is dead straight. Also floored, so a hand folded
        // onto its own shoulder cannot invert the solve.
        let reach = min(
            max(span, abs(Arm.upper - Arm.fore) + 0.004),
            (Arm.upper + Arm.fore) * 0.995
        )
        let along = (Arm.upper * Arm.upper - Arm.fore * Arm.fore + reach * reach) / (2 * reach)
        let across = max(0, Arm.upper * Arm.upper - along * along).squareRoot()

        return (
            elbow: (
                shoulder.0 + ux * along - uy * across * bend,
                shoulder.1 + uy * along + ux * across * bend
            ),
            hand: (shoulder.0 + ux * reach, shoulder.1 + uy * reach)
        )
    }

    private var overheadPress: FigurePose {
        // Bottom: hands at chin height, just outside the shoulders. Top: locked
        // overhead and converged slightly, which is where the joint is stacked.
        let shoulder = (0.44, 0.39)
        let reachFor = interpolated(from: (0.35, 0.395), to: (0.462, 0.104))
        // Elbows flare out and down at the bottom of a press.
        let (elbow, hand) = arm(from: shoulder, to: reachFor, bend: 1)
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
        // Side view, facing left, hands pinned to the floor. The chest drops
        // and presses back up.
        //
        // The drop was 0.12 and the arm was authored straight through it, so
        // the upper arm lost 40% of its length on the way down and the two ends
        // of the movement were almost indistinguishable. It is 0.155 now — a
        // deficit push-up goes BELOW the hands, which is the whole point of the
        // books — and the elbow is solved, so the bend is real.
        let drop = phase * 0.155
        let shoulder = (0.34, 0.468 + drop)
        // Elbows track back toward the feet rather than flaring to the sides.
        let (elbow, hand) = arm(from: shoulder, to: (0.301, 0.737), bend: -1)
        return FigurePose(
            head: (0.235, 0.395 + drop),
            neck: (0.335, 0.437 + drop),
            hip: (0.62, 0.52 + drop * 0.62),
            arms: [
                [shoulder, elbow, hand],
            ],
            legs: [
                [(0.62, 0.53 + drop * 0.62), (0.75, 0.635 + drop * 0.34), (0.87, 0.745)],
            ],
            ground: FigureGround(fromX: 0.18, toX: 0.92, y: 0.795)
        )
    }

    private var lateralRaise: FigurePose {
        // Hands start at the thighs and finish at shoulder height, no higher —
        // the cue is "stop at shoulder height" and the figure should not
        // contradict the cue six lines below it.
        // The bottom has to be a HANGING arm. The first pass started the hand
        // at 0.60 — only 0.23 below a shoulder on a 0.29 arm — so the solver
        // had to fold it, and both arms rendered as a diamond at hip height.
        let shoulder = (0.44, 0.37)
        let reachFor = interpolated(from: (0.437, 0.648), to: (0.168, 0.386))
        // A lateral raise keeps a soft elbow that stays below the wrist.
        let (elbow, hand) = arm(from: shoulder, to: reachFor, bend: 1)
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

    /// Hinged forward, arms opening like a curtain.
    ///
    /// The hardest of the eight to draw, because the two things that identify
    /// it — the hinge and the arms opening WIDE — want opposite viewpoints. A
    /// side view shows the hinge and hides one arm behind the other; a front
    /// view shows both arms and loses the hinge entirely, at which point it is
    /// a lateral raise.
    ///
    /// So: front view, with the torso foreshortened. The head sits low and
    /// close to the shoulders, which is what a body bent toward you looks like,
    /// and the legs are short and angled back. It reads as hinged without
    /// giving up either arm, and it is unmistakably not the lateral raise
    /// standing upright two sets earlier.
    private var rearDeltFly: FigurePose {
        let shoulder = (0.44, 0.415)
        let reachFor = interpolated(from: (0.452, 0.692), to: (0.192, 0.553))
        let (elbow, hand) = arm(from: shoulder, to: reachFor, bend: 1)
        return FigurePose(
            head: (0.5, 0.30),
            neck: (0.5, 0.375),
            hip: (0.5, 0.665),
            arms: [
                [shoulder, elbow, hand],
                [(0.56, 0.415), mirrored(elbow), mirrored(hand)],
            ],
            legs: [
                [(0.468, 0.685), (0.452, 0.79), (0.446, 0.90)],
                [(0.532, 0.685), (0.548, 0.79), (0.554, 0.90)],
            ],
            dumbbells: [hand, mirrored(hand)]
        )
    }

    private var floorFly: FigurePose {
        // Seen from above, on your back. The arms open wide to the floor and
        // close above the chest; the cue is "elbows slightly bent and locked
        // there", so the bend never changes and only the arc does.
        let shoulder = (0.45, 0.39)
        let reachFor = interpolated(from: (0.182, 0.418), to: (0.432, 0.238))
        let (elbow, hand) = arm(from: shoulder, to: reachFor, bend: 1)
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
        // Hinged at the hip, torso near horizontal, the hand travelling from
        // hanging straight down to the ribs.
        let shoulder = (0.38, 0.45)
        let reachFor = interpolated(from: (0.385, 0.732), to: (0.475, 0.505))
        // The elbow drives BACKWARD past the torso, which is the whole point of
        // a row and the one thing that distinguishes it from a curl.
        let (elbow, hand) = arm(from: shoulder, to: reachFor, bend: -1)
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
        // Elbow pinned at the ribs, forearm rotating through about 150°. See
        // `swung(about:)` for why this one is not solved like the others.
        let elbow = (0.437, 0.518)
        let hand = swung(about: elbow, radius: Arm.fore, from: 0, to: 2.62, inward: -1)
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
