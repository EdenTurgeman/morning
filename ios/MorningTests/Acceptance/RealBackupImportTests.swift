//
//  RealBackupImportTests.swift
//
//  TEMPORARY. Delete after running — see the comment below.
//

import XCTest
@testable import Morning

/// Eden's ACTUAL phone export, decoded by the app's real decoder.
///
/// Every import test until now has used fixtures we wrote ourselves, which
/// proves the decoder matches our idea of the format. This proves it matches
/// HIS FILE, which is the only claim that matters — losing his history is the
/// one thing `04-rules.md §8` calls unacceptable.
///
/// The file is named by the `MORNING_REAL_EXPORT` environment variable and the
/// test **skips** when it is unset or the file is missing. His workout history
/// does not belong in the repo, and neither does the path to it — this repo is
/// public. A test that hard-fails on every other machine does not belong in the
/// suite either, but one that re-verifies the real file whenever it IS present
/// is worth keeping, for the next export as much as this one.
///
///     MORNING_REAL_EXPORT=~/Desktop/morning-backup-2026-09-12.json \
///         xcodebuild test -project ios/Morning.xcodeproj -scheme Morning …
///
/// The general rules it exercises are covered permanently and with fixtures by
/// `DataAcceptanceTests`. What only this can check is that HIS file, with its
/// own history and its own quirks, survives the trip.
@MainActor
final class RealBackupImportTests: XCTestCase {
    private var path: String? {
        ProcessInfo.processInfo.environment["MORNING_REAL_EXPORT"].map {
            NSString(string: $0).expandingTildeInPath
        }
    }

    func testHisRealExportImportsIntact() throws {
        guard let path else {
            throw XCTSkip("MORNING_REAL_EXPORT is not set — nothing to verify on this machine")
        }
        try XCTSkipUnless(
            FileManager.default.fileExists(atPath: path),
            "no export at \(path) — nothing to verify on this machine"
        )
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let decoded = try JSONDecoder().decode(AppData.self, from: data)

        // Nothing silently dropped. `LenientRecord` skips a malformed record
        // rather than throwing, so a partial decode looks like a success — the
        // count is what catches it.
        let raw = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let rawHistory = try XCTUnwrap(raw["history"] as? [[String: Any]])
        XCTAssertEqual(decoded.history.count, rawHistory.count, "a record was skipped as malformed")
        XCTAssertEqual(decoded.history.count, 12)

        for record in decoded.history {
            XCTAssertFalse(record.date.isEmpty)
            XCTAssertTrue(["A", "B"].contains(record.sessionKey), "unknown session key \(record.sessionKey)")
            XCTAssertGreaterThan(record.timestamp, 0, "ts is the record's identity")
            XCTAssertEqual(record.reps, record.log.values.reduce(0, +), "stored reps disagree with the log")
            XCTAssertGreaterThan(record.minutes, 0)
        }

        // Identity is the timestamp, and duplicates would corrupt milestone
        // diffing and "previous same session" lookups.
        XCTAssertEqual(Set(decoded.history.map(\.timestamp)).count, 12)

        // HIS FILE IS MIXED, and that is the interesting part.
        //
        // Eleven records carry a weight and the earliest, 2026-08-17, does not:
        // it predates the weight being adjustable. `CLAUDE.md` is blunt that a
        // missing `kg` is MEANINGFUL and must never be backfilled, because
        // filling it in retroactively rewrites tonnage that was never lifted.
        // A decoder that defaulted it to zero, or to the program default, would
        // look like it worked.
        let missing = decoded.history.filter { $0.kg == nil }
        XCTAssertEqual(missing.count, 1, "exactly one of his sessions predates adjustable weight")
        XCTAssertEqual(missing.first?.date, "2026-08-17")
        XCTAssertEqual(
            Set(decoded.history.compactMap(\.kg)),
            [5, 7.5],
            "the weights he actually used, unrounded and unaltered"
        )

        // The screens that read history have to survive it.
        let ledger = LedgerMath.compute(decoded.history)
        XCTAssertEqual(ledger.sessions, 12, "the Ledger lost sessions his file has")
        XCTAssertGreaterThan(ledger.reps, 0, "the Ledger read his history as empty")
        XCTAssertGreaterThan(ledger.bodyweightReps, 0, "bodyweight reps are 0 kg of tonnage but still count as reps")

        print("IMPORTED: \(decoded.history.count) sessions, \(decoded.history.reduce(0) { $0 + $1.reps }) reps total")
    }
}
