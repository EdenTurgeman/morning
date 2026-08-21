// @generated-scaffold — delete this line once you start implementing this suite.
//
//  SessionLifecycleAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Session lifecycle"
//
//  8 assertions. Each one was once a real bug, which is why it is
//  written down. Implement them BEFORE the UI work, not after — a mis-ported
//  rule caught here takes seconds; caught in the Ledger six weeks from now it
//  takes an afternoon and a lost weekend of history.
//
//  To implement: delete the `throw XCTSkip` line and write the assertion.
//  The golden fixture is available as `GoldenSteps.load()`.
//

import XCTest
@testable import Morning

final class SessionLifecycleAcceptanceTests: XCTestCase {
    /// A fresh install proposes A; completing A proposes B, and vice versa.
    func testFreshInstallProposesAThenAlternates() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Rep counter pre-fills from the most recent same-session, same-slot value.
    func testRepCounterPrefillsFromMostRecentSameSessionSameSlot() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Back returns to the previous step without losing logged reps, and shows
    /// the number actually entered this session rather than last week's.
    func testBackReturnsWithoutLosingLoggedReps() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Rapid taps on the rep control never collapse into a single increment.
    func testRapidTapsNeverCollapseIntoASingleIncrement() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// End mid-session discards everything after a confirm, including sets
    /// already logged.
    func testEndMidSessionDiscardsEverythingAfterAConfirm() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Force-quitting mid-session and relaunching restores the same step, the
    /// same logged reps, and a correct remaining time.
    func testForceQuitMidSessionRestoresStepRepsAndRemainingTime() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// A phone call mid-rest leaves the timer correct on return.
    func testAPhoneCallMidRestLeavesTheTimerCorrect() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Finishing a session writes exactly ONE history record. The web build
    /// briefly wrote two — this is a real failure mode.
    func testFinishingASessionWritesExactlyOneHistoryRecord() throws {
        throw XCTSkip("Not implemented yet.")
    }
}
