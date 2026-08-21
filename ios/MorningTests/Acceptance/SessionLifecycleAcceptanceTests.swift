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
    func test_freshInstallProposesAThenAlternates() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Rep counter pre-fills from the most recent same-session, same-slot value.
    func test_repCounterPrefillsFromMostRecentSameSessionSameSlot() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Back returns to the previous step without losing logged reps, and shows
    /// the number actually entered this session rather than last week's.
    func test_backReturnsWithoutLosingLoggedReps() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Rapid taps on the rep control never collapse into a single increment.
    func test_rapidTapsNeverCollapseIntoASingleIncrement() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// End mid-session discards everything after a confirm, including sets
    /// already logged.
    func test_endMidSessionDiscardsEverythingAfterAConfirm() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Force-quitting mid-session and relaunching restores the same step, the
    /// same logged reps, and a correct remaining time.
    func test_forceQuitMidSessionRestoresStepRepsAndRemainingTime() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// A phone call mid-rest leaves the timer correct on return.
    func test_aPhoneCallMidRestLeavesTheTimerCorrect() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Finishing a session writes exactly ONE history record. The web build
    /// briefly wrote two — this is a real failure mode.
    func test_finishingASessionWritesExactlyOneHistoryRecord() throws {
        throw XCTSkip("Not implemented yet.")
    }
}
