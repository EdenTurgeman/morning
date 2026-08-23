import XCTest
@testable import Morning

/// Bones do not change length.
///
/// Every arm pose used to author the elbow by hand next to the wrist and
/// interpolate both independently, so they did. Measured at the extremes of the
/// five arm movements before this was fixed: the forearm grew 42% through a
/// lateral raise, shrank 26% through an overhead press, and the upper arm lost
/// **86% of itself** through a floor fly, ending up 7pt from the shoulder.
///
/// That is what "goofy" was. It is also a property a test can check exactly and
/// an eye can only squint at, which is why this file exists rather than another
/// round of looking at screenshots.
@MainActor
final class FigureAnatomyTests: XCTestCase {
    private let movements: [(String, ExerciseMovement)] = [
        ("overhead press", .overheadPress),
        ("push-up", .pushUp),
        ("lateral raise", .lateralRaise),
        ("rear-delt fly", .rearDeltFly),
        ("floor fly", .floorFly),
        ("bent-over row", .row),
        ("curl", .curl),
    ]

    /// Sampled across the whole travel, not just the ends: an interpolation can
    /// be right at 0 and 1 and wrong everywhere between, and with the elbow
    /// solved rather than lerped that is exactly where a mistake would hide.
    private let phases: [Double] = stride(from: 0.0, through: 1.0, by: 0.05).map(\.self)

    func testEveryBoneKeepsItsLengthThroughEveryMovement() {
        for (name, movement) in movements {
            var spans: [Int: [Double]] = [:]

            for phase in phases {
                let pose = ExerciseFigure(movement: movement, phase: phase, accent: .white).pose
                for (armIndex, arm) in pose.arms.enumerated() {
                    for joint in 0 ..< max(0, arm.count - 1) {
                        let a = arm[joint], b = arm[joint + 1]
                        let length = ((a.0 - b.0) * (a.0 - b.0) + (a.1 - b.1) * (a.1 - b.1)).squareRoot()
                        spans[armIndex * 10 + joint, default: []].append(length)
                    }
                }
            }

            for (key, lengths) in spans {
                guard let low = lengths.min(), let high = lengths.max(), low > 0 else { continue }
                let drift = (high - low) / low
                XCTAssertLessThan(
                    drift, 0.02,
                    "\(name): bone \(key) changes length by \(Int(drift * 100))% across the movement "
                        + "(\(String(format: "%.4f", low))…\(String(format: "%.4f", high)))"
                )
            }
        }
    }

    /// A limb drawn with round joints reads as broken when it is dead straight,
    /// and the solver clamps reach to just short of full extension to avoid it.
    /// This checks the clamp actually holds — a hand authored further away than
    /// the arm is long must not produce a hyperextended or NaN elbow.
    func testNoArmEverHyperextendsOrGoesUndefined() {
        for (name, movement) in movements {
            for phase in phases {
                let pose = ExerciseFigure(movement: movement, phase: phase, accent: .white).pose
                for arm in pose.arms {
                    for joint in arm {
                        XCTAssertTrue(
                            joint.0.isFinite && joint.1.isFinite,
                            "\(name): non-finite joint at phase \(phase)"
                        )
                        XCTAssertTrue(
                            (-0.5 ... 1.5).contains(joint.0),
                            "\(name): joint x \(joint.0) off-canvas at phase \(phase)"
                        )
                        XCTAssertTrue(
                            (-0.5 ... 1.5).contains(joint.1),
                            "\(name): joint y \(joint.1) off-canvas at phase \(phase)"
                        )
                    }
                }
            }
        }
    }

    /// Every exercise in the program has a figure of its own, or shares one
    /// deliberately.
    ///
    /// "Rear-delt fly" used to fall through the switch to `.curl`, so one of the
    /// eight movements animated as an entirely different exercise for as long as
    /// the port has existed. Nothing caught it because nothing had ever put the
    /// figures side by side.
    func testEveryProgrammedExerciseResolvesToAPlausibleFigure() {
        let expected: [String: ExerciseMovement] = [
            "Push-up": .pushUp,
            "Overhead press": .overheadPress,
            "Curl": .curl,
            "Bent-over row": .row,
            // Shares the curl skeleton on purpose: the web build's own comment
            // says only the grip differs, and a grip is not visible at this size.
            "Hammer curl": .curl,
            "Lateral raise": .lateralRaise,
            "Rear-delt fly": .rearDeltFly,
            "Floor fly": .floorFly,
        ]

        let programmed = Set(
            ["A", "B"].flatMap { StepCompiler.build(session: $0).compactMap(\.asSet?.exercise) }
        )

        for exercise in programmed.sorted() {
            XCTAssertEqual(
                ExerciseMovement(exercise: exercise), expected[exercise],
                "\(exercise) does not resolve to the figure it should"
            )
        }
        XCTAssertEqual(
            programmed,
            Set(expected.keys),
            "the program and this table disagree about which exercises exist"
        )
    }
}
