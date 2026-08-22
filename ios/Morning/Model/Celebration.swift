import Foundation

/* ===========================================================================
 *  WHAT THE SUMMARY CELEBRATES
 *  ---------------------------------------------------------------------------
 *  Eleven tiers, in priority order, and EXACTLY ONE FIRES — the highest thing
 *  actually earned. `04-rules.md §5`.
 *
 *  The rule the whole file is holding to, and the reason this app is not a
 *  gamified fitness app:
 *
 *      Every headline states something TRUE and specific. No points, no
 *      badges, no levels, no "great job!". The reward for finishing is being
 *      told exactly what you did, well.
 *
 *  All copy is VERBATIM from `src/lib/celebration.ts`. `CLAUDE.md` rule 3:
 *  celebration copy is not ours to improve.
 *
 *  ── THE BUG THIS FILE KEEPS RE-LEARNING ──────────────────────────────────
 *  The summary renders the rep total as a large number directly above the
 *  headline, so a headline of "252 reps." prints the same figure twice. Eden
 *  caught that one in the shipped build. Every headline here has to add
 *  something the number does not already say — and the same applies to an
 *  eyebrow restating its headline.
 *
 *  ── AND THE ONE THAT MATTERS MOST ────────────────────────────────────────
 *  `plateau` is the app's most valuable output. Three same-letter sessions on
 *  an identical total means it is time to change the program. It must NOT read
 *  as a failure state; the copy names the rung to move to.
 * ======================================================================== */

enum CelebrationTier: String, Equatable {
    case lifetimeMilestone
    case cleanSweep
    case weightChanged
    case streakMilestone
    case weekComplete
    case record
    case first
    case plateau
    case improved
    case matched
    case done
}

struct Celebration: Equatable {
    let tier: CelebrationTier
    /// Small line above the number.
    let eyebrow: String
    /// The main statement. Short — read at a glance, sweaty.
    let headline: String
    /// One or two sentences of substance.
    let body: String
    /// The LARGER milestone burst, reserved for week completions and lifetime
    /// thresholds. Ordinary confetti is not this flag — it fires on every
    /// finished session and is not conditional on anything.
    let milestoneBurst: Bool
    /// Radiating rays behind the number.
    let rays: Bool
    /// Signed rep delta vs the last same-letter session, when there is one.
    let delta: Int?
}

/// Week counts that get their own headline.
private let streakMilestones: [Int: (headline: String, body: String)] = [
    2: (
        "Past the first drop-off.",
        "The first week is willpower. The second is where it starts becoming a habit — "
            + "and where most people have already stopped."
    ),
    4: (
        "A month of mornings.",
        "Four full weeks, every one of them hit. Go and look at what your first session's numbers were."
    ),
    8: (
        "Long enough to be real.",
        "Eight weeks is past the point where gains are just your nervous system learning the movement. "
            + "This is tissue now."
    ),
    12: (
        "A quarter of a year.",
        "Twelve weeks is the length of most training studies. You've run a full one on yourself."
    ),
    26: (
        "Half a year.",
        "Twenty-six weeks. Go back and look at what your first session's numbers were."
    ),
    52: (
        "A year of mornings.",
        "Fifty-two weeks. Nothing to add — just don't stop."
    ),
]

enum Celebrations {
    /// **Ordinary confetti fires on every finished session.** Eden asked for
    /// this explicitly; it is not gated on a tier. `Celebration.milestoneBurst`
    /// is the separate, larger burst.
    static let ordinaryConfettiAlways = true

    // Long on purpose. The eleven tiers read top to bottom in priority order,
    // and that ordering IS the specification — `04-rules.md §5`'s table in
    // executable form. Splitting it into per-tier helpers would hide the one
    // property most worth being able to check at a glance.
    // swiftlint:disable:next function_body_length
    static func forSession(
        _ record: SessionRecord,
        history: [SessionRecord],
        today: Date = Date()
    ) -> Celebration {
        let week = Week.progress(history: history, today: today)
        let previous = previousSameSession(history, key: record.sessionKey, before: record.timestamp)

        // Reps are only comparable at the same weight. If the working weight
        // moved, "+18 reps" for dropping 2.5 kg a side is not progress and
        // "dead level" at a heavier weight is not a plateau.
        let weightChanged: Bool = if let previous, let now = record.kg, let then = previous.kg {
            abs(now - then) > 0.01
        } else {
            false
        }

        let delta = (previous != nil && !weightChanged) ? record.reps - (previous?.reps ?? 0) : nil

        let sameLetter = history.filter { $0.sessionKey == record.sessionKey && $0.timestamp != record.timestamp }
        let isFirstEver = history.count <= 1
        let bestBefore = sameLetter.map(\.reps).max() ?? 0
        let isRecord = !sameLetter.isEmpty && record.reps > bestBefore && !weightChanged

        // Three same-letter sessions ending on the identical total is the
        // signal the program is built around: reps have stopped moving.
        let lastTwo = sameLetter.sorted { $0.timestamp < $1.timestamp }.suffix(2)
        let isPlateau = delta == 0 && lastTwo.count == 2 && lastTwo.allSatisfy { $0.reps == record.reps }

        // 1. Lifetime thresholds outrank everything. Crossing 10 tonnes or a
        //    hundredth session is far rarer than completing a week and should
        //    never be hidden behind one.
        let withoutThis = history.filter { $0.timestamp != record.timestamp }
        if let crossed = Milestones.crossed(
            before: LedgerMath.compute(withoutThis, now: today),
            after: LedgerMath.compute(history, now: today)
        ) {
            return Celebration(
                tier: .lifetimeMilestone,
                eyebrow: "All time",
                headline: crossed.headline,
                body: crossed.body,
                milestoneBurst: true,
                rays: true,
                delta: delta
            )
        }

        // 2. Beating every single set. Rare, unambiguous, and entirely measured
        //    against your own past — the best thing in here.
        if let previous, !sameLetter.isEmpty, !weightChanged {
            let slots = Array(record.log.keys)
            let comparable = slots.filter { previous.log[$0] != nil }
            let beatEvery = comparable.count >= 3
                && comparable.count == slots.count
                && comparable.allSatisfy { (record.log[$0] ?? 0) > (previous.log[$0] ?? 0) }

            if beatEvery {
                return Celebration(
                    tier: .cleanSweep,
                    eyebrow: "\(slots.count) of \(slots.count) sets improved",
                    headline: "Clean sweep.",
                    body: "Not one set matched last time — every single one went up. "
                        + "On a fixed load that is as good as this program gets.",
                    milestoneBurst: true,
                    rays: true,
                    delta: delta
                )
            }
        }

        // 3. Weight moved: report it honestly rather than a comparison that
        //    is not one.
        if weightChanged, let previous {
            let heavier = (record.kg ?? 0) > (previous.kg ?? 0)
            let was = Plates.format(previous.kg ?? 0)
            return Celebration(
                tier: .weightChanged,
                eyebrow: "Now at \(Plates.format(record.kg ?? 0)) kg",
                headline: heavier ? "Heavier than last time." : "Lighter than last time.",
                body: heavier
                    ? "You were at \(was) kg. Reps aren't comparable across a weight change, "
                    + "so this session starts a fresh baseline — beat it next time."
                    : "You were at \(was) kg. Dropping to a weight you can actually take to failure "
                    + "is the right call; reps start a fresh baseline here.",
                milestoneBurst: false,
                rays: false,
                delta: delta
            )
        }

        // 4. A week completed AND that completion hit a milestone count.
        if week.completedThisWeek, let milestone = streakMilestones[week.streak] {
            return Celebration(
                tier: .streakMilestone,
                // The headline already names the count in words ("A month of
                // mornings"), so the eyebrow must not print it again as a number.
                eyebrow: "Streak milestone",
                headline: milestone.headline,
                body: milestone.body,
                milestoneBurst: true,
                rays: true,
                delta: delta
            )
        }

        // 5. The week just completed.
        if week.completedThisWeek {
            return Celebration(
                tier: .weekComplete,
                // "5 of 5 this week" would restate the headline, and the week
                // meter lower down the same screen shows the pips anyway.
                eyebrow: week.streak > 1 ? "\(week.streak) weeks running" : "Your first full week",
                headline: "Week complete.",
                body: "Rest properly. The adaptation happens between sessions, not during them.",
                milestoneBurst: true,
                rays: true,
                delta: delta
            )
        }

        // 6. A personal best on this letter.
        if isRecord {
            return Celebration(
                tier: .record,
                eyebrow: "Best \(record.sessionKey) yet",
                headline: "A personal best.",
                body: "Your previous best on \(record.sessionKey) was \(bestBefore). That's the number to beat now.",
                milestoneBurst: false,
                rays: true,
                delta: delta
            )
        }

        // 7. The first session ever. Fires exactly once, ever.
        if isFirstEver {
            return Celebration(
                tier: .first,
                eyebrow: "First session logged",
                headline: "You started.",
                body: "From now on this screen tells you whether you beat the last one. That's the whole game.",
                milestoneBurst: false,
                rays: true,
                delta: delta
            )
        }

        // 8. The most valuable output the app has. NOT a failure state — the
        //    copy names the rung to move to.
        if isPlateau {
            return Celebration(
                tier: .plateau,
                eyebrow: "Third \(record.sessionKey) at the same total",
                headline: "Reps have stopped moving.",
                body: "Time for the next rung: slow the eccentric to 4–5s and add a 2s pause in the stretch. "
                    + "Same weight, more tension.",
                milestoneBurst: false,
                rays: false,
                delta: delta
            )
        }

        // 9. More than last time.
        if let delta, delta > 0 {
            return Celebration(
                tier: .improved,
                eyebrow: "+\(delta) on your last \(record.sessionKey)",
                headline: "You moved it.",
                body: "Load stayed the same and you did more work. "
                    + "That's the only progress signal this program has, and it went up.",
                milestoneBurst: false,
                rays: false,
                delta: delta
            )
        }

        // 10. Exactly equal.
        if delta == 0 {
            return Celebration(
                tier: .matched,
                eyebrow: "Same as your last \(record.sessionKey)",
                headline: "Dead level.",
                body: "Matched it exactly. One more identical session and it's time to move up the ladder.",
                milestoneBurst: false,
                rays: false,
                delta: delta
            )
        }

        // 11. Anything else, including down on last time.
        let down = delta != nil && (delta ?? 0) < 0
        return Celebration(
            tier: .done,
            eyebrow: delta != nil ? "\(delta ?? 0) vs your last \(record.sessionKey)" : "Session logged",
            headline: down ? "Down on last time." : "Logged.",
            body: down
                ? "Sleep, food and stress all show up here. One dip means nothing; three in a row means something."
                : "Eat, shower, get on with the day.",
            milestoneBurst: false,
            rays: false,
            delta: delta
        )
    }

    /// The most recent same-letter session before this one, by `ts` — the
    /// record's identity, never array order.
    static func previousSameSession(
        _ history: [SessionRecord],
        key: String,
        before timestamp: Int
    ) -> SessionRecord? {
        history
            .filter { $0.sessionKey == key && $0.timestamp < timestamp }
            .max { $0.timestamp < $1.timestamp }
    }
}
