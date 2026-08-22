import Foundation

/* ===========================================================================
 *  THE LEDGER — everything you have done, ever
 *  ---------------------------------------------------------------------------
 *  The headline number is tonnage: reps × load. The program's whole premise is
 *  that load is fixed and reps are the only signal, which makes tonnage the one
 *  number that turns that signal into something visibly compounding. Six months
 *  of "I did 14 instead of 13" adds up to a figure you cannot argue with.
 *
 *  TWO HONESTY CONSTRAINTS, both non-negotiable — `04-rules.md §4`:
 *
 *  · Every loaded movement is TWO DUMBBELLS and the program's load is per
 *    handle, so a rep moves 2 × load.
 *
 *  · BODYWEIGHT WORK CONTRIBUTES 0 KG. Counting push-ups would need Eden's
 *    bodyweight and a guessed multiplier, which would make the headline number
 *    fiction. Those reps still count toward total REPS — they just do not
 *    inflate tonnage.
 *
 *  And one more: sessions are valued at THE WEIGHT THEY WERE ACTUALLY DONE AT,
 *  from their own `kg`, so changing your working weight never retroactively
 *  rewrites what you lifted last month.
 * ======================================================================== */

/// Every loaded exercise here is a pair of dumbbells.
private let handsPerRep = 2.0

struct Ledger: Equatable {
    let tonnes: Double
    let kilos: Double
    let reps: Int
    /// Reps that moved no external load.
    let bodyweightReps: Int
    let sessions: Int
    let minutes: Int
    /// The first session's ISO date, or nil.
    let since: String?
    /// Whole weeks between the first session and today.
    let weeks: Int
    let perSession: [String: Int]

    static let empty = Ledger(
        tonnes: 0, kilos: 0, reps: 0, bodyweightReps: 0,
        sessions: 0, minutes: 0, since: nil, weeks: 0, perSession: [:]
    )
}

enum LedgerMath {
    /// `"{sessionKey}:{slot}"` → kilos moved per rep, for the program as it
    /// currently stands.
    ///
    /// Note the key shape. A record's `log` is keyed by the BARE slot
    /// (`"2.1.0"`); this table keys by `"A:2.1.0"`. Two shapes, and CLAUDE.md
    /// lists confusing them as a way to mis-value imported history.
    ///
    /// Slots that no longer resolve — because the program was edited — contribute
    /// reps but no tonnage. The alternative is inventing a load for them.
    static func loadBySlot(kg: Double?) -> [String: Double] {
        var table: [String: Double] = [:]
        for session in program {
            for step in StepCompiler.build(session: session.key, kg: kg) {
                guard let set = step.asSet else { continue }
                table["\(session.key):\(set.slot)"] = (set.load ?? 0) * handsPerRep
            }
        }
        return table
    }

    static func compute(_ history: [SessionRecord], now: Date = Date()) -> Ledger {
        var cache: [String: [String: Double]] = [:]
        func loads(for kg: Double?) -> [String: Double] {
            let id = kg.map { String($0) } ?? "default"
            if let cached = cache[id] {
                return cached
            }
            let table = loadBySlot(kg: kg)
            cache[id] = table
            return table
        }

        var kilos = 0.0
        var reps = 0
        var bodyweightReps = 0
        var minutes = 0
        var perSession: [String: Int] = [:]

        for record in history {
            minutes += record.minutes
            perSession[record.sessionKey, default: 0] += 1
            let table = loads(for: record.kg)
            for (slot, count) in record.log {
                reps += count
                let perRep = table["\(record.sessionKey):\(slot)"] ?? 0
                if perRep > 0 {
                    kilos += Double(count) * perRep
                } else {
                    bodyweightReps += count
                }
            }
        }

        let first = history.min { $0.date < $1.date }
        var weeks = 0
        if let first, let date = History.localDate(of: first) {
            let elapsed = now.timeIntervalSince(date) / (7 * 86400)
            weeks = max(1, Int(elapsed.rounded()))
        }

        return Ledger(
            tonnes: kilos / 1000,
            kilos: kilos,
            reps: reps,
            bodyweightReps: bodyweightReps,
            sessions: history.count,
            minutes: minutes,
            since: first?.date,
            weeks: weeks,
            perSession: perSession
        )
    }
}

// MARK: - Milestones

/* Deliberately sparse. "A milestone you hit every fortnight is a chore; one you
 * hit twice a year is an event." */

struct Milestone: Equatable {
    enum Kind: String { case tonnage, reps, sessions }
    let kind: Kind
    /// The threshold that was crossed.
    let value: Int
    let headline: String
    let body: String
}

enum Milestones {
    static let tonnes = [1, 5, 10, 25, 50, 100, 250, 500, 1000]
    static let reps = [1000, 5000, 10000, 25000, 50000, 100_000]
    static let sessions = [10, 25, 50, 100, 200, 365, 500, 1000]

    /// The milestone this session crossed, if any.
    ///
    /// Compares the ledger BEFORE and AFTER, so a threshold fires exactly once
    /// — on the session that passed it — rather than on every session after.
    static func crossed(before: Ledger, after: Ledger) -> Milestone? {
        for step in tonnes.reversed() where before.tonnes < Double(step) && after.tonnes >= Double(step) {
            return Milestone(
                kind: .tonnage,
                value: step,
                headline: "\(format(step)) \(step == 1 ? "tonne" : "tonnes") moved.",
                body: "That's every rep you've ever logged, multiplied by what was in your hands. "
                    + "It only exists because you kept writing it down."
            )
        }
        for step in reps.reversed() where before.reps < step && after.reps >= step {
            return Milestone(
                kind: .reps,
                value: step,
                headline: "\(format(step)) reps.",
                body: "Every one of them taken to failure, or one short of it. "
                    + "That's the whole program in a single number."
            )
        }
        for step in sessions.reversed() where before.sessions < step && after.sessions >= step {
            return Milestone(
                kind: .sessions,
                value: step,
                headline: "\(format(step)) sessions.",
                body: step >= 100
                    ? "Roughly the point where this stops being something you're doing "
                    + "and starts being something you are."
                    : "Mornings you got up and did it anyway."
            )
        }
        return nil
    }

    /// The next threshold being headed for, for the Ledger screen.
    struct NextThreshold: Equatable {
        let label: String
        let remaining: String
        let fraction: Double
    }

    static func next(after ledger: Ledger) -> NextThreshold? {
        guard let target = tonnes.first(where: { Double($0) > ledger.tonnes }) else { return nil }
        let previous = tonnes.last { Double($0) <= ledger.tonnes } ?? 0
        let span = Double(target - previous)
        return NextThreshold(
            label: "\(format(target)) tonnes",
            remaining: String(format: "%.1f t to go", Double(target) - ledger.tonnes),
            fraction: span > 0 ? (ledger.tonnes - Double(previous)) / span : 0
        )
    }

    /// Grouped with separators, matching the web build's `toLocaleString`.
    static func format(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

func formatDuration(minutes: Int) -> String {
    if minutes < 60 {
        return "\(minutes) min"
    }
    let hours = minutes / 60
    let rest = minutes % 60
    if hours < 48 {
        return rest > 0 ? "\(hours) h \(rest) min" : "\(hours) h"
    }
    return "\(hours) hours"
}
