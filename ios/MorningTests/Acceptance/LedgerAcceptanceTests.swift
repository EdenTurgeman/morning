// @generated-scaffold — delete this line once you start implementing this suite.
//
//  LedgerAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Ledger"
//
//  4 assertions. Each one was once a real bug, which is why it is
//  written down. Implement them BEFORE the UI work, not after — a mis-ported
//  rule caught here takes seconds; caught in the Ledger six weeks from now it
//  takes an afternoon and a lost weekend of history.
//
//  To implement: delete the `throw XCTSkip` line and write the assertion.
//  The golden fixture is available as `GoldenSteps.load()`.
//

import XCTest
@testable import Morning

final class LedgerAcceptanceTests: XCTestCase {
    /// Tonnage counts 2 × load per rep (two dumbbells, load is per handle).
    func testTonnageCountsTwiceLoadPerRep() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Bodyweight reps contribute 0 kg but do count toward total reps.
    func testBodyweightRepsContributeZeroKgButCountAsReps() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Each session is valued at its own recorded kg; changing the working weight
    /// does not re-value past sessions.
    func testEachSessionIsValuedAtItsOwnRecordedKg() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Each milestone fires exactly once, on the session that crossed it.
    func testEachMilestoneFiresExactlyOnce() throws {
        throw XCTSkip("Not implemented yet.")
    }
}
