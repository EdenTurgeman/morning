import CoreHaptics
import SwiftUI

extension Color {
    static let morningSuccess = Color(red: 0.2, green: 0.83, blue: 0.6)
}

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
                question: "Malolactic conversion always softens acidity. So why does it not always taste buttery?",
                answer: "It converts sharp malic acid into softer lactic acid, raising pH. "
                    + "Diacetyl — the buttery compound — is only a by-product: the bacteria can metabolise it further, "
                    + "lees stirring disperses it, and blending dilutes it. "
                    + "Chablis routinely goes through MLF without tasting of butter.",
                topic: "WINEMAKING"
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

struct DawnPalette {
    let progress: Double

    var accent: Color {
        interpolate(stops: accentStops)
    }

    var zenith: Color {
        let progressValue = min(1, max(0, progress))
        return Color(
            red: 0.015 + progressValue * 0.025,
            green: 0.02 + progressValue * 0.018,
            blue: 0.055 + progressValue * 0.018
        )
    }

    var middle: Color {
        accent.opacity(0.35)
    }

    var horizon: Color {
        accent
    }

    private var accentStops: [(Double, Color)] {
        [
            (0, Color(red: 0x6F / 255.0, green: 0x80 / 255.0, blue: 0xE0 / 255.0)),
            (0.26, Color(red: 0xA9 / 255.0, green: 0x74 / 255.0, blue: 0xE3 / 255.0)),
            (0.5, Color(red: 0xED / 255.0, green: 0x6B / 255.0, blue: 0xAF / 255.0)),
            (0.74, Color(red: 0xFF / 255.0, green: 0x82 / 255.0, blue: 0x71 / 255.0)),
            (1, Color(red: 0xFF / 255.0, green: 0xB4 / 255.0, blue: 0x40 / 255.0)),
        ]
    }

    private func interpolate(stops: [(Double, Color)]) -> Color {
        let progressValue = min(1, max(0, progress))
        for index in 1 ..< stops.count where progressValue <= stops[index].0 {
            let lower = stops[index - 1]
            let upper = stops[index]
            let local = (progressValue - lower.0) / (upper.0 - lower.0)
            return lower.1.mix(with: upper.1, by: local, in: .perceptual)
        }
        return stops.last?.1 ?? .white
    }
}

@MainActor
final class PrototypeHaptics {
    static let shared = PrototypeHaptics()

    private var engine: CHHapticEngine?

    private init() {
        prepare()
    }

    func rep() {
        play([
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.32),
                    .init(parameterID: .hapticSharpness, value: 0.68),
                ],
                relativeTime: 0
            ),
        ])
    }

    func threshold() {
        play([
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.48),
                    .init(parameterID: .hapticSharpness, value: 0.72),
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.78),
                    .init(parameterID: .hapticSharpness, value: 0.88),
                ],
                relativeTime: 0.055
            ),
        ])
    }

    func confirm() {
        play([
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.62),
                    .init(parameterID: .hapticSharpness, value: 0.42),
                ],
                relativeTime: 0
            ),
        ])
    }

    func reveal() {
        play([
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.2),
                    .init(parameterID: .hapticSharpness, value: 0.24),
                ],
                relativeTime: 0
            ),
        ])
    }

    private func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak self] in
                Task { @MainActor in
                    try? self?.engine?.start()
                }
            }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    private func play(_ events: [CHHapticEvent]) {
        guard let engine else { return }

        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            prepare()
        }
    }
}
