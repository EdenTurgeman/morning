import CoreHaptics
import SwiftUI

struct SetFixture {
    let exercise: String
    let sub: String?
    let meta: String
    let target: String
    let cues: [String]
    let initialReps: Int
    let previous: Int?
    let previousKg: Double?
    let straightIntoNext: Bool
    let intense: Bool

    static func fixture(for scenario: SetScenario) -> SetFixture {
        switch scenario {
        case .firstRun:
            SetFixture(
                exercise: "Push-up",
                sub: "feet elevated",
                meta: "bodyweight · set 1 of 3",
                target: "8–15 reps",
                cues: [
                    "3s down · 1s PAUSE at the bottom · fast up",
                    "Elbows 45° from your torso, glutes squeezed",
                    "Go to failure, or one rep short",
                ],
                initialReps: 10,
                previous: nil,
                previousKg: nil,
                straightIntoNext: false,
                intense: false
            )
        case .loadedFirstRun:
            SetFixture(
                exercise: "Overhead press",
                sub: "standing, strict",
                meta: "7.5 kg · set 1 of 3",
                target: "8–15 reps",
                cues: [
                    "Ribs down. No leg drive, no leaning back",
                    "Start at ear height, finish biceps by your ears",
                ],
                initialReps: 12,
                previous: nil,
                previousKg: nil,
                straightIntoNext: false,
                intense: false
            )
        case .comparable:
            SetFixture(
                exercise: "Overhead press",
                sub: "standing, strict",
                meta: "7.5 kg · set 2 of 3 · superset 1 of 2",
                target: "8–15 reps",
                cues: [
                    "Ribs down. No leg drive, no leaning back",
                    "Start at ear height, finish biceps by your ears",
                ],
                initialReps: 13,
                previous: 13,
                previousKg: nil,
                straightIntoNext: true,
                intense: false
            )
        case .beating:
            SetFixture(
                exercise: "Overhead press",
                sub: "standing, strict",
                meta: "7.5 kg · set 2 of 3 · superset 1 of 2",
                target: "8–15 reps",
                cues: [
                    "Ribs down. No leg drive, no leaning back",
                    "Start at ear height, finish biceps by your ears",
                ],
                initialReps: 14,
                previous: 13,
                previousKg: nil,
                straightIntoNext: true,
                intense: false
            )
        case .changedWeight:
            SetFixture(
                exercise: "Floor fly",
                sub: "lying on your back",
                meta: "6.25 kg · set 1 of 2",
                target: "15–25 reps",
                cues: [
                    "Elbows slightly bent and locked there — a fly, not a press",
                    "Lower until your triceps touch the floor · 1s PAUSE in the stretch",
                    "Past 25 clean reps? Slow the lowering to 4s. Go to failure",
                ],
                initialReps: 12,
                previous: 18,
                previousKg: 5,
                straightIntoNext: false,
                intense: false
            )
        case .superset:
            SetFixture(
                exercise: "Bent-over row",
                sub: nil,
                meta: "7.5 kg · set 1 of 2 · superset 1 of 2",
                target: "15–20 reps",
                cues: [
                    "Hinge to 45°, flat back",
                    "Pull to your hips and squeeze",
                    "Shoulder insurance — don't skip it",
                ],
                initialReps: 17,
                previous: 17,
                previousKg: nil,
                straightIntoNext: true,
                intense: false
            )
        case .supersetSecond:
            SetFixture(
                exercise: "Curl",
                sub: nil,
                meta: "7.5 kg · set 1 of 3 · superset 2 of 2",
                target: "10–18 reps",
                cues: [
                    "3 seconds lowering",
                    "FULL arm extension at the bottom of every rep",
                    "That bottom inch is the whole exercise",
                ],
                initialReps: 14,
                previous: 14,
                previousKg: nil,
                straightIntoNext: false,
                intense: false
            )
        case .myo:
            SetFixture(
                exercise: "Lateral raise",
                sub: "myo-reps",
                meta: "5 kg · set 1 of 3",
                target: "all-out to failure",
                cues: [
                    "Set 1 is all-out. Then 20s rest, 4–5 reps, repeat",
                    "Stop when you can't get 4 clean reps",
                    "The 20-second rest IS the mechanism — don't stretch it",
                ],
                initialReps: 12,
                previous: 14,
                previousKg: nil,
                straightIntoNext: false,
                intense: true
            )
        case .myoSecond:
            SetFixture(
                exercise: "Lateral raise",
                sub: "myo-reps",
                meta: "5 kg · set 2 of 3",
                target: "4–5 reps",
                cues: [
                    "Set 1 is all-out. Then 20s rest, 4–5 reps, repeat",
                    "Stop when you can't get 4 clean reps",
                    "The 20-second rest IS the mechanism — don't stretch it",
                ],
                initialReps: 5,
                previous: 5,
                previousKg: nil,
                straightIntoNext: false,
                intense: true
            )
        case .longContent:
            SetFixture(
                exercise: "Push-up",
                sub: "deficit — hands on books",
                meta: "bodyweight · set 3 of 3",
                target: "8–15 reps",
                cues: [
                    "Hands on books or blocks, chest sinking below them",
                    "3s down · 1s PAUSE at the bottom · fast up",
                    "Too easy → elevate your feet as well. Go to failure",
                    "Set the dumbbells while you do this",
                ],
                initialReps: 15,
                previous: 15,
                previousKg: nil,
                straightIntoNext: false,
                intense: false
            )
        }
    }
}

struct RestFixture {
    let seconds: Int
    let nextExercise: String
    let nextSub: String?
    let nextMeta: String
    let question: String?
    let answer: String?
    let topic: String?

    static func fixture(for scenario: RestScenario) -> RestFixture {
        switch scenario {
        case .plain:
            RestFixture(
                seconds: 60,
                nextExercise: "Overhead press",
                nextSub: "standing, strict",
                nextMeta: "set 1 of 3 · 7.5 kg · 8–15 reps",
                question: nil,
                answer: nil,
                topic: nil
            )
        case .card:
            RestFixture(
                seconds: 60,
                nextExercise: "Overhead press",
                nextSub: "standing, strict",
                nextMeta: "set 1 of 3 · 7.5 kg · 8–15 reps",
                question: "Where does the biscuit and brioche character in Champagne come from?",
                answer: "Autolysis. The second fermentation happens inside the bottle, "
                    + "and the dead yeast cells then break down in contact with the wine under pressure. "
                    + "Tank-method wines finish their second fermentation in a pressurised tank "
                    + "with little lees contact, so they keep primary fruit and florals instead.",
                topic: "SPARKLING"
            )
        case .myo:
            RestFixture(
                seconds: 20,
                nextExercise: "Lateral raise",
                nextSub: "myo-reps",
                nextMeta: "set 2 of 3 · 5 kg · 4–5 reps",
                question: nil,
                answer: nil,
                topic: nil
            )
        }
    }
}

/// The lab's haptics. One engine — `Haptics` — with a per-treatment sharpness
/// tilt on top, because the three W1 treatments differ in FEEL, not in
/// vocabulary. Same events, same product meaning, tilted crisper for Precise
/// and softer for Tactile.
///
/// The real screens call `Haptics.shared` directly. This exists only so the
/// comparison treatments still feel different from each other.
@MainActor
final class PrototypeHaptics {
    static let shared = PrototypeHaptics()

    private init() {}

    func prewarm() {
        Haptics.shared.prewarm()
    }

    func rep(treatment: DawnTreatment) {
        play("rep", HapticVocabulary.rep, treatment)
    }

    func threshold(treatment: DawnTreatment) {
        play("threshold", HapticVocabulary.threshold, treatment)
    }

    func confirm(treatment: DawnTreatment) {
        play("confirm", HapticVocabulary.logged, treatment)
    }

    func reveal(treatment: DawnTreatment) {
        play("reveal", HapticVocabulary.reveal, treatment)
    }

    func zero(treatment: DawnTreatment) {
        play("zero", HapticVocabulary.zero, treatment)
    }

    func countdown(second: Int, treatment: DawnTreatment) {
        play("countdown-\(second)", HapticVocabulary.countdown(second: second), treatment)
    }

    private func play(_ key: String, _ beats: [HapticBeat], _ treatment: DawnTreatment) {
        Haptics.shared.play("\(key)-\(treatment.rawValue)", shaped(beats, for: treatment))
    }

    private func shaped(_ beats: [HapticBeat], for treatment: DawnTreatment) -> [HapticBeat] {
        let tilt: Float = switch treatment {
        case .atmospheric: 0
        case .precise: 0.18
        case .tactile: -0.16
        }
        guard tilt != 0 else { return beats }
        return beats.map {
            HapticBeat(
                time: $0.time,
                intensity: $0.intensity,
                sharpness: min(1, max(0, $0.sharpness + tilt)),
                duration: $0.duration
            )
        }
    }
}
