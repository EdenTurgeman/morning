/* ===========================================================================
 *  THE PROGRAM
 *  ---------------------------------------------------------------------------
 *  This is the only file you need to touch to change the workout. Everything
 *  is a literal — exercise names, set counts, rest seconds, loads, cues. No ID
 *  lookups, no indirection, no second file to keep in sync, and deliberately
 *  NOT a JSON resource: you edit Swift, rebuild, and install.
 *
 *  Weights are PLATES ONLY. Add your handle weight mentally.
 *
 *  The `load` on each movement is the weight the session is WRITTEN for. Your
 *  actual working weight is set in the app (tap the loadout on the home
 *  screen) and overrides every loaded movement in the session.
 *
 *  Keep ONE weight per session. The whole premise is that load is fixed and
 *  reps are the only variable, and practically you should never be changing
 *  plates mid-workout at 6am. The acceptance tests enforce it.
 *
 *  Careful when changing these numbers: sessions logged BEFORE the app started
 *  recording weight have no weight of their own, so they fall back to this
 *  default — editing it silently re-values their tonnage. Sessions logged since
 *  carry their own figure and are unaffected.
 *
 *  ── how to edit ──────────────────────────────────────────────────────────
 *  Blocks run top to bottom. There are three kinds:
 *
 *    .warmup(Warmup(seconds:title:cues:))
 *        A countdown. Auto-advances at zero.
 *
 *    .straight(Straight(exercise:sub:sets:rest:load:bodyweight:target:targets:cues:intense:))
 *        N sets of one exercise with `rest` seconds between them. Pass
 *        `targets` (one string per set) instead of `target` when the sets
 *        differ — that is how the myo-rep block works.
 *
 *    .superset(Superset(sets:rest:items:))
 *        `sets` rounds of the listed exercises back to back. There is NO rest
 *        between partners — rest comes only after the round.
 *
 *  ── one caveat ───────────────────────────────────────────────────────────
 *  "What did I do last time on this exact set" is resolved by a slot id of the
 *  form `blockIndex.itemIndex.setIndex`. If you reorder blocks or change set
 *  counts, old slots stop matching and the rep counter quietly falls back to a
 *  default. History totals are never lost — only the per-set prefill resets.
 *  Adding or editing cues, names, loads and targets is always safe.
 *
 *  This is why the floor fly in B was APPENDED rather than inserted: inserting
 *  it earlier would have shifted every later block's slot ids and handed it the
 *  myo block's rep history as its starting target. Preserve that property.
 *
 *  ── provenance ───────────────────────────────────────────────────────────
 *  Transcribed mechanically from ios-port/content/program.json by
 *  ios/Tools/gen-program-swift.mjs. From here on THIS FILE is the source of
 *  truth; the JSON is a frozen snapshot of the web build and is not read at
 *  runtime. Do not re-run the generator over hand edits.
 * ======================================================================== */

import Foundation

// MARK: - Types

struct Movement {
    let exercise: String
    let sub: String?
    let load: Double?
    let bodyweight: Bool
    let target: String?
    let targets: [String]?
    let intense: Bool
    let cues: [String]

    init(
        exercise: String,
        sub: String? = nil,
        load: Double? = nil,
        bodyweight: Bool = false,
        target: String? = nil,
        targets: [String]? = nil,
        intense: Bool = false,
        cues: [String]
    ) {
        self.exercise = exercise
        self.sub = sub
        self.load = load
        self.bodyweight = bodyweight
        self.target = target
        self.targets = targets
        self.intense = intense
        self.cues = cues
    }
}

struct Warmup {
    let seconds: Int
    let title: String
    let cues: [String]

    init(seconds: Int, title: String, cues: [String]) {
        self.seconds = seconds
        self.title = title
        self.cues = cues
    }
}

struct Straight {
    let exercise: String
    let sub: String?
    let sets: Int
    let rest: Int
    let load: Double?
    let bodyweight: Bool
    let target: String?
    let targets: [String]?
    let intense: Bool
    let cues: [String]

    init(
        exercise: String,
        sub: String? = nil,
        sets: Int,
        rest: Int,
        load: Double? = nil,
        bodyweight: Bool = false,
        target: String? = nil,
        targets: [String]? = nil,
        intense: Bool = false,
        cues: [String]
    ) {
        self.exercise = exercise
        self.sub = sub
        self.sets = sets
        self.rest = rest
        self.load = load
        self.bodyweight = bodyweight
        self.target = target
        self.targets = targets
        self.intense = intense
        self.cues = cues
    }
}

struct Superset {
    let sets: Int
    let rest: Int
    let items: [Movement]

    init(sets: Int, rest: Int, items: [Movement]) {
        self.sets = sets
        self.rest = rest
        self.items = items
    }
}

enum Block {
    case warmup(Warmup)
    case straight(Straight)
    case superset(Superset)
}

struct Session {
    let key: String
    let name: String
    let minutes: String
    let blocks: [Block]

    init(key: String, name: String, minutes: String, blocks: [Block]) {
        self.key = key
        self.name = name
        self.minutes = minutes
        self.blocks = blocks
    }
}

struct Plate {
    let kg: Double
    let count: Int

    init(kg: Double, count: Int) {
        self.kg = kg
        self.count = count
    }
}

// MARK: - The program

let program: [Session] = [
    Session(
        key: "A",
        name: "Heavy",
        minutes: "~16 min",
        blocks: [
            .warmup(Warmup(
                seconds: 90,
                title: "Warm-up",
                cues: [
                    "20 arm circles forward, 20 back",
                    "10 half-effort push-ups",
                    "10 towel dislocates — grip a towel wide, sweep it overhead and behind you",
                ]
            )),
            .straight(Straight(
                exercise: "Push-up",
                sub: "feet elevated",
                sets: 3,
                rest: 60,
                bodyweight: true,
                target: "8–15 reps",
                cues: [
                    "3s down · 1s PAUSE at the bottom · fast up",
                    "Elbows 45° from your torso, glutes squeezed",
                    "Go to failure, or one rep short",
                ]
            )),
            .superset(Superset(
                sets: 3,
                rest: 45,
                items: [
                    Movement(
                        exercise: "Overhead press",
                        sub: "standing, strict",
                        load: 7.5,
                        target: "8–15 reps",
                        cues: [
                            "Ribs down. No leg drive, no leaning back",
                            "Start at ear height, finish biceps by your ears",
                        ]
                    ),
                    Movement(
                        exercise: "Curl",
                        load: 7.5,
                        target: "10–18 reps",
                        cues: [
                            "3 seconds lowering",
                            "FULL arm extension at the bottom of every rep",
                            "That bottom inch is the whole exercise",
                        ]
                    ),
                ]
            )),
            .superset(Superset(
                sets: 2,
                rest: 45,
                items: [
                    Movement(
                        exercise: "Bent-over row",
                        load: 7.5,
                        target: "15–20 reps",
                        cues: [
                            "Hinge to 45°, flat back",
                            "Pull to your hips and squeeze",
                            "Shoulder insurance — don't skip it",
                        ]
                    ),
                    Movement(
                        exercise: "Hammer curl",
                        load: 7.5,
                        target: "12–20 reps",
                        cues: [
                            "Palms facing each other",
                            "Full stretch at the bottom",
                        ]
                    ),
                ]
            )),
        ]
    ),
    Session(
        key: "B",
        name: "Light",
        minutes: "~19 min",
        blocks: [
            .warmup(Warmup(
                seconds: 90,
                title: "Warm-up",
                cues: [
                    "20 arm circles forward, 20 back",
                    "10 half-effort push-ups",
                    "10 towel dislocates",
                    "Set the dumbbells while you do this",
                ]
            )),
            .straight(Straight(
                exercise: "Push-up",
                sub: "deficit — hands on books",
                sets: 3,
                rest: 60,
                bodyweight: true,
                target: "8–15 reps",
                cues: [
                    "Hands on books or blocks, chest sinking below them",
                    "3s down · 1s PAUSE at the bottom · fast up",
                    "Too easy → elevate your feet as well. Go to failure",
                ]
            )),
            .superset(Superset(
                sets: 3,
                rest: 45,
                items: [
                    Movement(
                        exercise: "Lateral raise",
                        load: 5,
                        target: "15–25 reps",
                        cues: [
                            "Lead with your elbows, stop at shoulder height",
                            "No swinging",
                            "At failure → 5–8 partial reps in the bottom third",
                        ]
                    ),
                    Movement(
                        exercise: "Rear-delt fly",
                        load: 5,
                        target: "15–25 reps",
                        cues: [
                            "Hinge until almost parallel to the floor",
                            "Open your arms wide like a curtain, squeeze the blades",
                        ]
                    ),
                ]
            )),
            .straight(Straight(
                exercise: "Lateral raise",
                sub: "myo-reps",
                sets: 3,
                rest: 20,
                load: 5,
                targets: [
                    "all-out to failure",
                    "4–5 reps",
                    "4–5 reps",
                ],
                intense: true,
                cues: [
                    "Set 1 is all-out. Then 20s rest, 4–5 reps, repeat",
                    "Stop when you can't get 4 clean reps",
                    "The 20-second rest IS the mechanism — don't stretch it",
                ]
            )),
            .straight(Straight(
                exercise: "Floor fly",
                sub: "lying on your back",
                sets: 2,
                rest: 60,
                load: 5,
                target: "15–25 reps",
                cues: [
                    "Elbows slightly bent and locked there — a fly, not a press",
                    "Lower until your triceps touch the floor · 1s PAUSE in the stretch",
                    "Past 25 clean reps? Slow the lowering to 4s. Go to failure",
                ]
            )),
        ]
    ),
]

/* --- how often you're aiming to train ------------------------------------- */

/// Sessions per week that count as a full week. The streak is built on this,
/// not on consecutive days — rest days shouldn't cost you anything.
let weeklyTarget = 5

/// Which day a week starts on, in Foundation's convention: 1 = Sunday.
/// The web build stored 0 = Sunday; 0 there means Sunday here.
let weekStartsOn = 1

/// Cues containing any of these words carry the training effect, so they get
/// emphasised on the set screen rather than sitting in the grey list.
/// Case-sensitive substring match, exactly like the web build's regex.
let intensityWords = ["failure", "PAUSE", "FULL", "mechanism"]

/* --- equipment -------------------------------------------------------------
 * What you own, PER HANDLE. The loadout card derives its plate breakdown from
 * this, and it bounds how heavy a session can be set. Edit it if you buy more
 * plates.
 *
 * Bounded by this inventory, 7.5 kg resolves to 2×2.5 + 2×1.25. An unbounded
 * greedy fit returns 3×2.5, which is impossible — you only own two 2.5s.
 */

let plateInventory: [Plate] = [
    Plate(kg: 2.5, count: 2),
    Plate(kg: 1.25, count: 4),
]

// MARK: - Derived helpers

extension Session {
    /// The per-handle weight this session is written for — the default before
    /// any in-app adjustment. Read off the first loaded movement, so it stays
    /// correct if you edit the program.
    var defaultLoad: Double? {
        for block in blocks {
            switch block {
            case .warmup:
                continue
            case .straight(let s):
                if let load = s.load { return load }
            case .superset(let s):
                if let load = s.items.first(where: { $0.load != nil })?.load { return load }
            }
        }
        return nil
    }
}

/// The session the app proposes after `key` — A/B/A/B for a two-session
/// program, and it keeps working if you ever add a third. A fresh install,
/// where `key` is nil, proposes the first session.
func nextSession(after key: String?) -> Session {
    guard let key, let i = program.firstIndex(where: { $0.key == key }) else {
        return program[0]
    }
    return program[(i + 1) % program.count]
}

func session(for key: String) -> Session? {
    program.first { $0.key == key }
}
