//
//  LedgerAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Ledger"
//
//  4 assertions, and two of them are honesty constraints rather than
//  correctness ones — `04-rules.md §4`. Tonnage is the headline number on the
//  screen that exists to make the last six months feel like they happened, and
//  a headline number that is fiction is worse than no headline at all.
//

import XCTest
@testable import Morning

/// `@MainActor` because the app module builds with
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
@MainActor
final class LedgerAcceptanceTests: XCTestCase {
    /// Tonnage counts 2 × load per rep (two dumbbells, load is per handle).
    func testTonnageCountsTwiceLoadPerRep() throws {
        // A loaded slot from session A, taken from the compiled program rather
        // than hard-coded, so editing the program cannot silently invalidate
        // this.
        let loaded = try XCTUnwrap(
            StepCompiler.build(session: "A").compactMap(\.asSet).first { $0.load != nil },
            "session A has no loaded set"
        )
        let load = try XCTUnwrap(loaded.load)

        let ledger = LedgerMath.compute([
            record(key: "A", log: [loaded.slot: 10], kg: load),
        ])

        XCTAssertEqual(ledger.reps, 10)
        XCTAssertEqual(
            ledger.kilos,
            10 * load * 2,
            accuracy: 0.001,
            "every loaded movement is TWO dumbbells and the program's load is per handle"
        )
        XCTAssertEqual(ledger.tonnes, ledger.kilos / 1000, accuracy: 0.000_001)
    }

    /// Bodyweight reps contribute 0 kg but do count toward total reps.
    func testBodyweightRepsContributeZeroKgButCountAsReps() throws {
        let steps = StepCompiler.build(session: "A")
        let bodyweight = try XCTUnwrap(steps.compactMap(\.asSet).first(where: \.bodyweight))
        let loaded = try XCTUnwrap(steps.compactMap(\.asSet).first { $0.load != nil })
        let load = try XCTUnwrap(loaded.load)

        let ledger = LedgerMath.compute([
            record(key: "A", log: [bodyweight.slot: 12, loaded.slot: 10], kg: load),
        ])

        XCTAssertEqual(ledger.reps, 22, "push-up reps still count toward total reps")
        XCTAssertEqual(ledger.bodyweightReps, 12)
        XCTAssertEqual(
            ledger.kilos,
            10 * load * 2,
            accuracy: 0.001,
            "counting push-ups would need a bodyweight and a guessed multiplier — that is fiction"
        )

        // Bodyweight only: real reps, zero tonnage, and "0 tonnes" is then an
        // honest answer rather than a bug.
        let onlyBodyweight = LedgerMath.compute([record(key: "A", log: [bodyweight.slot: 12], kg: load)])
        XCTAssertEqual(onlyBodyweight.reps, 12)
        XCTAssertEqual(onlyBodyweight.kilos, 0)
    }

    /// Each session is valued at its own recorded kg; changing the working weight
    /// does not re-value past sessions.
    func testEachSessionIsValuedAtItsOwnRecordedKg() throws {
        let loaded = try XCTUnwrap(StepCompiler.build(session: "A").compactMap(\.asSet).first { $0.load != nil })

        let light = record(key: "A", log: [loaded.slot: 10], kg: 5, ts: 1000)
        let heavy = record(key: "A", log: [loaded.slot: 10], kg: 10, ts: 2000)

        let ledger = LedgerMath.compute([light, heavy])
        XCTAssertEqual(
            ledger.kilos,
            (10 * 5 * 2) + (10 * 10 * 2),
            accuracy: 0.001,
            "each session must be valued at the weight it was actually done at"
        )

        // Adding a heavier session must not change what the earlier one was
        // worth. That is what stops changing your working weight retroactively
        // rewriting what you lifted last month.
        let lightOnly = LedgerMath.compute([light])
        XCTAssertEqual(ledger.kilos - lightOnly.kilos, 10 * 10 * 2, accuracy: 0.001)

        // A record with NO kg falls back to the program default and is never
        // backfilled — the absence is meaningful.
        let noKg = record(key: "A", log: [loaded.slot: 10], kg: nil, ts: 3000)
        XCTAssertNil(noKg.kg)
        let defaultLoad = try XCTUnwrap(program.first { $0.key == "A" }?.defaultLoad)
        XCTAssertEqual(
            LedgerMath.compute([noKg]).kilos,
            10 * defaultLoad * 2,
            accuracy: 0.001
        )
    }

    /// Each milestone fires exactly once, on the session that crossed it.
    func testEachMilestoneFiresExactlyOnce() throws {
        let loaded = try XCTUnwrap(StepCompiler.build(session: "A").compactMap(\.asSet).first { $0.load != nil })
        let load = try XCTUnwrap(loaded.load)
        // Reps needed to move one tonne at this load, in one session.
        let repsPerTonne = Int((1000.0 / (load * 2)).rounded(.up))

        var history: [SessionRecord] = []
        var fired: [Int: Int] = [:]

        for index in 0 ..< 6 {
            let next = record(key: "A", log: [loaded.slot: repsPerTonne], kg: load, ts: (index + 1) * 1000)
            let before = LedgerMath.compute(history)
            history.append(next)
            let after = LedgerMath.compute(history)

            if let milestone = Milestones.crossed(before: before, after: after) {
                fired[milestone.value, default: 0] += 1
            }
        }

        // 1 and 5 tonnes are both inside six sessions at this rate.
        XCTAssertFalse(fired.isEmpty, "no milestone fired across six tonne-sized sessions")
        for (value, count) in fired {
            XCTAssertEqual(count, 1, "the \(value) milestone fired \(count) times")
        }

        // And re-running the same comparison does not fire it again: it is
        // computed by diffing the ledger with and without the session, so a
        // threshold belongs to the session that passed it and to no other.
        let settled = LedgerMath.compute(history)
        XCTAssertNil(Milestones.crossed(before: settled, after: settled))

        // Sparse on purpose: "a milestone you hit every fortnight is a chore".
        XCTAssertEqual(Milestones.tonnes, [1, 5, 10, 25, 50, 100, 250, 500, 1000])
        XCTAssertEqual(Milestones.sessions, [10, 25, 50, 100, 200, 365, 500, 1000])
        XCTAssertEqual(Milestones.reps, [1000, 5000, 10000, 25000, 50000, 100_000])
    }

    // MARK: - Helpers

    private func record(key: String, log: [String: Int], kg: Double?, ts: Int = 1000) -> SessionRecord {
        SessionRecord(
            date: "2026-08-16",
            sessionKey: key,
            log: log,
            minutes: 16,
            reps: log.values.reduce(0, +),
            timestamp: ts,
            kg: kg
        )
    }
}
