// @generated-scaffold — delete this line once you start implementing this suite.
//
//  ProgramCompilerAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Program and step compiler"
//
//  10 assertions. Each one was once a real bug, which is why it is
//  written down. Implement them BEFORE the UI work, not after — a mis-ported
//  rule caught here takes seconds; caught in the Ledger six weeks from now it
//  takes an afternoon and a lost weekend of history.
//
//  To implement: delete the `throw XCTSkip` line and write the assertion.
//  The golden fixture is available as `GoldenSteps.load()`.
//

import XCTest
@testable import Morning

final class ProgramCompilerAcceptanceTests: XCTestCase {
    /// Session A compiles to 21 steps; B to 25. Assert the full list against
    /// compiled-steps.json, not just the counts.
    func test_sessionACompilesTo21StepsAndBTo25() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// No rest step appears between superset partners.
    func test_noRestBetweenSupersetPartners() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// A rest appears after each superset round, including the last of a block.
    func test_restAfterEachSupersetRoundIncludingTheLast() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// No rest is left dangling at the very end of a session.
    func test_noDanglingRestAtTheEndOfASession() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// The myo block produces 3 sets with per-set targets and 20s rests.
    func test_myoBlockProduces3SetsWithPerSetTargetsAnd20sRests() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// One weight per session — no session contains two different loads.
    func test_oneWeightPerSession() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Lateral raises are under 50% of session B's working sets.
    func test_lateralRaisesAreUnderHalfOfSessionBWorkingSets() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// The floor fly is present in B.
    func test_floorFlyIsPresentInSessionB() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Slot IDs are stable and unique, and match the golden fixture exactly.
    func test_slotIdsAreStableUniqueAndMatchTheGoldenFixture() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Plate breakdowns are derived from the inventory and are achievable: 7.5 kg
    /// resolves to 2×2.5 + 2×1.25, never 3×2.5.
    func test_plateBreakdownsAreDerivedFromInventoryAndAchievable() throws {
        throw XCTSkip("Not implemented yet.")
    }
}
