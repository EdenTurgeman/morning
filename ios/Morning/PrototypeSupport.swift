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

@MainActor
final class PrototypeHaptics {
    static let shared = PrototypeHaptics()

    private var engine: CHHapticEngine?
    private var players: [String: any CHHapticPatternPlayer] = [:]

    private init() {
        prepare()
    }

    func prewarm() {
        try? engine?.start()
    }

    func rep(treatment: DawnTreatment) {
        play(key: "rep-\(treatment.rawValue)", beats: shaped(HapticVocabulary.rep, for: treatment))
    }

    func threshold(treatment: DawnTreatment) {
        play(key: "threshold-\(treatment.rawValue)", beats: shaped(HapticVocabulary.threshold, for: treatment))
    }

    func confirm(treatment: DawnTreatment) {
        play(key: "confirm-\(treatment.rawValue)", beats: shaped(HapticVocabulary.logged, for: treatment))
    }

    func reveal(treatment: DawnTreatment) {
        play(key: "reveal-\(treatment.rawValue)", beats: shaped(HapticVocabulary.reveal, for: treatment))
    }

    func zero(treatment: DawnTreatment) {
        play(key: "zero-\(treatment.rawValue)", beats: shaped(HapticVocabulary.zero, for: treatment))
    }

    func countdown(second: Int, treatment: DawnTreatment) {
        play(
            key: "countdown-\(second)-\(treatment.rawValue)",
            beats: shaped(HapticVocabulary.countdown(second: second), for: treatment)
        )
    }

    /// The three W1 treatments differ in feel, not in vocabulary: the same
    /// events, tilted in sharpness. Precise is crisper, Tactile is softer and
    /// more physical, Atmospheric sits between them. The product meaning of
    /// every pattern is identical across the three.
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

    private func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak self] in
                Task { @MainActor in
                    self?.prepare()
                }
            }
            engine.stoppedHandler = { [weak self] _ in
                Task { @MainActor in
                    self?.engine = nil
                    self?.players.removeAll()
                }
            }
            try engine.start()
            self.engine = engine
            players.removeAll()
        } catch {
            engine = nil
            players.removeAll()
        }
    }

    private func play(key: String, beats: [HapticBeat], retry: Bool = true) {
        let events = beats.map(\.event)
        guard let engine else {
            prepare()
            if retry {
                play(key: key, beats: beats, retry: false)
            }
            return
        }

        do {
            try engine.start()
            let player: any CHHapticPatternPlayer
            if let prepared = players[key] {
                player = prepared
            } else {
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let prepared = try engine.makePlayer(with: pattern)
                players[key] = prepared
                player = prepared
            }
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            prepare()
            if retry {
                play(key: key, beats: beats, retry: false)
            }
        }
    }
}
