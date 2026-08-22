import Foundation

/* ===========================================================================
 *  THE STEP MACHINE
 *  ---------------------------------------------------------------------------
 *  A session compiles to a FLAT, LINEAR list of steps, and the workout screen
 *  only ever renders `steps[i]`. It never knows about blocks, supersets or
 *  rounds. That is what keeps "one screen, one action" honest rather than
 *  aspirational — `01-product.md` non-negotiable 1.
 *
 *  Reference implementation: `src/lib/steps.ts`. Where that file and
 *  `04-rules.md` disagree about *why*, the doc wins; about *what*, the source
 *  wins, and the golden fixture settles it either way.
 *
 *  Golden fixture: `ios/MorningTests/Fixtures/compiled-steps.json`.
 *  A must produce 21 steps, B must produce 25 — and the tests assert the WHOLE
 *  list, not the counts, because the counts were right in a build where the
 *  slot ids were not.
 * ======================================================================== */

// MARK: - Steps

struct TimerStep: Equatable {
    let seconds: Int
    let title: String
    let cues: [String]
}

/// Position within a superset round — "superset 1 of 2".
struct SupersetPosition: Equatable {
    let index: Int
    let of: Int
}

struct SetStep: Equatable {
    let exercise: String
    let sub: String?
    /// Per handle. Absent for bodyweight movements.
    let load: Double?
    let bodyweight: Bool
    let target: String
    let cues: [String]
    let intense: Bool
    /// 1-based, for "set 2 of 3".
    let n: Int
    let of: Int
    /// `blockIndex.itemIndex.setIndex` — the key history is stored under.
    ///
    /// LOAD-BEARING. Reordering blocks or changing set counts breaks the match
    /// and the rep counter silently falls back to a default. This is why the
    /// floor fly in B was appended rather than inserted.
    let slot: String
    let superset: SupersetPosition?
    /// True when the next partner follows immediately with no rest. Only
    /// meaningful inside a superset, hence optional rather than defaulted.
    let straightIntoNext: Bool?
}

struct RestStep: Equatable {
    let seconds: Int
}

enum Step: Equatable {
    case timer(TimerStep)
    case set(SetStep)
    case rest(RestStep)

    var isRest: Bool {
        if case .rest = self {
            return true
        }
        return false
    }

    var asSet: SetStep? {
        if case let .set(step) = self {
            return step
        }
        return nil
    }

    /// Seconds this step counts down for, if it counts down at all.
    var restSeconds: Int? {
        switch self {
        case let .rest(rest): rest.seconds
        case let .timer(timer): timer.seconds
        case .set: nil
        }
    }
}

// MARK: - The compiler

enum StepCompiler {
    /// - Parameter kg: Working weight per handle. Overrides every loaded
    ///   movement in the session, because the program gives each session a
    ///   single dumbbell weight and one number is the whole adjustment.
    ///   Bodyweight movements are untouched.
    static func build(session key: String, kg: Double? = nil) -> [Step] {
        guard let session = program.first(where: { $0.key == key }) else { return [] }

        var steps: [Step] = []

        for (blockIndex, block) in session.blocks.enumerated() {
            switch block {
            case let .warmup(warmup):
                steps.append(.timer(TimerStep(
                    seconds: warmup.seconds,
                    title: warmup.title,
                    cues: warmup.cues
                )))

            case let .straight(straight):
                for setIndex in 0 ..< straight.sets {
                    steps.append(.set(SetStep(
                        exercise: straight.exercise,
                        sub: straight.sub,
                        load: resolved(straight.load, kg: kg),
                        bodyweight: straight.bodyweight,
                        target: target(straight.targets, straight.target, at: setIndex),
                        cues: straight.cues,
                        intense: straight.intense,
                        n: setIndex + 1,
                        of: straight.sets,
                        slot: "\(blockIndex).0.\(setIndex)",
                        superset: nil,
                        straightIntoNext: nil
                    )))
                    // A rest after EVERY set, including the last of the block —
                    // that one is the gap before the next exercise. Trailing
                    // rests at the end of the session are stripped below.
                    steps.append(.rest(RestStep(seconds: straight.rest)))
                }

            case let .superset(superset):
                // Partners run back to back; rest comes only after the round.
                for setIndex in 0 ..< superset.sets {
                    for (itemIndex, item) in superset.items.enumerated() {
                        steps.append(.set(SetStep(
                            exercise: item.exercise,
                            sub: item.sub,
                            load: resolved(item.load, kg: kg),
                            bodyweight: item.bodyweight,
                            target: target(item.targets, item.target, at: setIndex),
                            cues: item.cues,
                            intense: item.intense,
                            n: setIndex + 1,
                            of: superset.sets,
                            slot: "\(blockIndex).\(itemIndex).\(setIndex)",
                            superset: SupersetPosition(index: itemIndex + 1, of: superset.items.count),
                            straightIntoNext: itemIndex < superset.items.count - 1
                        )))
                    }
                    steps.append(.rest(RestStep(seconds: superset.rest)))
                }
            }
        }

        // Never leave the user staring at a countdown after the last set.
        while let last = steps.last, last.isRest {
            steps.removeLast()
        }

        return steps
    }

    /// Total logged sets in a session — sizes the progress bar's ticks and
    /// sanity-checks a restored session.
    static func countSets(_ steps: [Step]) -> Int {
        steps.compactMap(\.asSet).count
    }

    /// `nil` load means bodyweight and must stay nil; the session weight
    /// overrides only movements that were written with a load.
    private static func resolved(_ programmed: Double?, kg: Double?) -> Double? {
        guard let programmed else { return nil }
        return kg ?? programmed
    }

    /// Per-set targets win over the block target — that is how the myo block
    /// says "all-out to failure" then "4–5 reps" twice.
    private static func target(_ targets: [String]?, _ single: String?, at index: Int) -> String {
        if let targets, targets.indices.contains(index) {
            return targets[index]
        }
        return single ?? "to failure"
    }
}
