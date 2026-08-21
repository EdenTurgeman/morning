// @generated-scaffold — delete this line once you start implementing this suite.
//
//  DataAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Data"
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

final class DataAcceptanceTests: XCTestCase {
    /// A fresh install works end to end: start, log a session, see the first
    /// celebration tier, land on a Home screen with one session behind it.
    func testFreshInstallWorksEndToEndAndFiresTheFirstTier() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Every screen is reviewed at empty, one week and six months of seeded data.
    /// Empty states are designed screens with their own copy, not a fallback
    /// label.
    func testEveryScreenIsReviewedAtEmptyOneWeekAndSixMonths() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// The set screen with no history shows the first-run message and a sensible
    /// default, and does not look broken.
    func testSetScreenWithNoHistoryShowsTheFirstRunMessage() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Local dates do not shift by a day under any device timezone.
    func testLocalDatesDoNotShiftUnderAnyDeviceTimezone() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Records without kg fall back to the program default and are not
    /// backfilled.
    func testRecordsWithoutKgFallBackToTheProgramDefaultAndAreNotBackfilled() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Export → wipe → restore reproduces the history exactly.
    func testExportWipeRestoreReproducesTheHistoryExactly() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// A failed write surfaces an error and never silently drops a session.
    func testAFailedWriteSurfacesAnErrorAndNeverDropsASession() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Exported JSON is byte-compatible with the web app's format — open it in
    /// the web app's Restore box and confirm it parses.
    func testExportedJsonIsByteCompatibleWithTheWebAppFormat() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// PHASE 2, not v1: importing the real backup reproduces, exactly: total
    /// tonnage, total reps, session count, current streak, longest run, and the
    /// year grid.
    func testPhase2ImportingTheRealBackupReproducesEveryDerivedNumber() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// PHASE 2, not v1: malformed records are skipped; the rest of the import
    /// succeeds.
    func testPhase2MalformedRecordsAreSkippedAndTheRestSucceeds() throws {
        throw XCTSkip("Not implemented yet.")
    }
}
