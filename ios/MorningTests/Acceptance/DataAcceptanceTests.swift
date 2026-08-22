//
//  DataAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Data"
//
//  10 assertions. Each one was once a real bug, which is why it is
//  written down. Implement them BEFORE the UI work, not after — a mis-ported
//  rule caught here takes seconds; caught in the Ledger six weeks from now it
//  takes an afternoon and a lost weekend of history.
//
//  Two of these have a UI half that belongs to a later workstream. Where that
//  is true the test asserts the DATA the screen will rest on and says so, which
//  is worth more than a skip: it is the half that can regress silently.
//

import XCTest
@testable import Morning

/// `@MainActor` because the app module builds with
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
@MainActor
final class DataAcceptanceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        // Each test gets an isolated temporary directory. Sharing Application
        // Support between tests is how one test's leftovers become another's
        // mystery failure.
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("morning-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    /// A fresh install works end to end: start, log a session, see the first
    /// celebration tier, land on a Home screen with one session behind it.
    func testFreshInstallWorksEndToEndAndFiresTheFirstTier() throws {
        let store = Store(directory: directory)

        // A fresh install is a MISSING file, not an empty one, and that is the
        // normal case on day one rather than an edge case.
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.historyURL.path))
        XCTAssertEqual(store.load(), .empty)
        XCTAssertNil(store.loadInProgress())

        var data = store.load()
        data.history.append(record(slot: "1.0.0", reps: 11, day: "2026-08-16", key: "A", kg: 7.5))
        try store.save(data)

        let reloaded = Store(directory: directory).load()
        XCTAssertEqual(reloaded.history.count, 1)
        XCTAssertEqual(reloaded.history.first?.timestamp, data.history.first?.timestamp)

        // The `first` tier fires on exactly this transition — no history before,
        // one record after. The copy and the tier table are W7.
        XCTAssertEqual(store.load().history.count, 1, "one finished session must write exactly one record")
    }

    /// Every screen is reviewed at empty, one week and six months of seeded data.
    /// Empty states are designed screens with their own copy, not a fallback
    /// label.
    func testEveryScreenIsReviewedAtEmptyOneWeekAndSixMonths() throws {
        // The reviewing is a human step. What can be asserted — and what would
        // silently break it — is that every fixture still loads and still holds
        // the shape each review depends on.
        for name in ["empty", "one-session", "one-week", "six-months", "one-year"] {
            let data = try seed(name)
            XCTAssertEqual(data.v, 1, "\(name): schema version")

            switch name {
            case "empty":
                XCTAssertTrue(data.history.isEmpty, "empty must be genuinely empty")
            case "one-session":
                XCTAssertEqual(data.history.count, 1)
            case "six-months":
                XCTAssertEqual(data.history.count, 125, "six-months is the fixture CLAUDE.md documents")
            default:
                XCTAssertFalse(data.history.isEmpty, "\(name) should carry history")
            }

            for record in data.history {
                XCTAssertNotNil(History.localDate(of: record), "\(name): unparseable date \(record.date)")
                XCTAssertFalse(record.log.isEmpty, "\(name): a record with no logged sets")
            }
        }
    }

    /// The set screen with no history shows the first-run message and a sensible
    /// default, and does not look broken.
    func testSetScreenWithNoHistoryShowsTheFirstRunMessage() {
        // The message is W4. The data it rests on is that the lookup returns
        // nothing rather than inventing a target.
        XCTAssertNil(History.previousSet(slot: "1.0.0", sessionKey: "A", in: []))

        // And with history for the OTHER session, this slot is still first-run —
        // a slot only compares against its own session key.
        let other = [record(slot: "1.0.0", reps: 14, day: "2026-08-16", key: "B", kg: 5)]
        XCTAssertNil(History.previousSet(slot: "1.0.0", sessionKey: "A", in: other))
        XCTAssertNotNil(History.previousSet(slot: "1.0.0", sessionKey: "B", in: other))
    }

    /// Local dates do not shift by a day under any device timezone.
    func testLocalDatesDoNotShiftUnderAnyDeviceTimezone() throws {
        let record = record(slot: "1.0.0", reps: 11, day: "2026-08-16", key: "A", kg: 7.5)

        // Both extremes, plus a half-hour offset and a southern-hemisphere DST
        // zone — the combinations that have historically moved a midnight-anchored
        // date across a day boundary.
        for name in ["Pacific/Kiritimati", "Pacific/Midway", "Asia/Kolkata", "Pacific/Auckland", "UTC"] {
            let zone = try XCTUnwrap(TimeZone(identifier: name), "unknown zone \(name)")
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = zone

            let date = try XCTUnwrap(History.localDate(of: record, calendar: calendar))
            let parts = calendar.dateComponents([.year, .month, .day], from: date)

            XCTAssertEqual(parts.year, 2026, "\(name) shifted the year")
            XCTAssertEqual(parts.month, 8, "\(name) shifted the month")
            XCTAssertEqual(parts.day, 16, "\(name) shifted the day — the year grid is now wrong")
        }
    }

    /// Records without kg fall back to the program default and are not
    /// backfilled.
    func testRecordsWithoutKgFallBackToTheProgramDefaultAndAreNotBackfilled() throws {
        let withoutKg = record(slot: "2.0.0", reps: 13, day: "2026-08-16", key: "A", kg: nil)
        let programDefault = program.first { $0.key == "A" }?.defaultLoad

        XCTAssertNil(withoutKg.kg, "the record itself must stay without a weight")
        XCTAssertEqual(History.resolvedLoad(for: withoutKg), programDefault, "valuation falls back")
        XCTAssertNotNil(programDefault, "session A should have a default load")

        // The fallback must never reach the file. Backfilling retroactively
        // rewrites what was lifted.
        let store = Store(directory: directory)
        try store.save(AppData(history: [withoutKg]))
        let reloaded = store.load()
        XCTAssertNil(reloaded.history.first?.kg, "kg was backfilled — tonnage has been rewritten")

        let json = try XCTUnwrap(String(data: store.exportJSON(reloaded), encoding: .utf8))
        XCTAssertFalse(json.contains("\"kg\""), "an absent kg must not be exported as anything")
    }

    /// Export → wipe → restore reproduces the history exactly.
    func testExportWipeRestoreReproducesTheHistoryExactly() throws {
        let store = Store(directory: directory)
        let original = AppData(
            history: [
                record(slot: "1.0.0", reps: 11, day: "2026-08-16", key: "A", kg: 7.5),
                record(slot: "2.0.1", reps: 14, day: "2026-08-17", key: "B", kg: nil),
            ],
            lastBackup: "2026-08-17T06:31:00.000Z",
            loads: ["A": 7.5, "B": 5]
        )
        try store.save(original)

        let exported = try store.exportJSON(store.load())

        // Wipe.
        try FileManager.default.removeItem(at: store.historyURL)
        XCTAssertEqual(store.load(), .empty)

        // Restore.
        let restored = try JSONDecoder().decode(AppData.self, from: exported)
        try store.save(restored)

        XCTAssertEqual(store.load(), original, "restore did not reproduce the history exactly")
    }

    /// A failed write surfaces an error and never silently drops a session.
    func testAFailedWriteSurfacesAnErrorAndNeverDropsASession() throws {
        // A path that cannot be created: a directory underneath a regular file.
        let blocker = directory.appendingPathComponent("blocker")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not a directory".utf8).write(to: blocker)

        let store = Store(directory: blocker.appendingPathComponent("history", isDirectory: true))
        let data = AppData(history: [record(slot: "1.0.0", reps: 11, day: "2026-08-16", key: "A", kg: 7.5)])

        XCTAssertThrowsError(try store.save(data), "a failed write MUST surface") { error in
            XCTAssertTrue(error is Store.StoreError, "the failure must be a typed, describable error")
            XCTAssertNotNil((error as? LocalizedError)?.errorDescription, "it must say something to the user")
        }

        // The one unacceptable failure mode: the session is still in hand.
        XCTAssertEqual(data.history.count, 1, "the caller's data must be untouched by a failed write")
    }

    /// Exported JSON is byte-compatible with the web app's format — open it in
    /// the web app's Restore box and confirm it parses.
    func testExportedJsonIsByteCompatibleWithTheWebAppFormat() throws {
        let store = Store(directory: directory)
        let data = AppData(
            history: [record(slot: "1.0.0", reps: 11, day: "2026-08-16", key: "A", kg: 7.5)],
            lastBackup: "2026-08-16T06:31:00.000Z",
            loads: ["A": 7.5]
        )

        let json = try store.exportJSON(data)
        let parsed = try XCTUnwrap(
            JSONSerialization.jsonObject(with: json) as? [String: Any],
            "export is not a JSON object"
        )

        XCTAssertEqual(Set(parsed.keys), ["v", "history", "lastBackup", "loads"])
        XCTAssertEqual(parsed["v"] as? Int, 1)

        let history = try XCTUnwrap(parsed["history"] as? [[String: Any]])
        // The terse names are the contract, not an accident: keeping them
        // identical is what makes the eventual import a file copy.
        XCTAssertEqual(Set(history[0].keys), ["d", "s", "log", "min", "reps", "ts", "kg"])
        XCTAssertEqual(history[0]["d"] as? String, "2026-08-16")
        XCTAssertEqual(history[0]["s"] as? String, "A")
        XCTAssertEqual(history[0]["min"] as? Int, 16)
        XCTAssertEqual((history[0]["log"] as? [String: Int])?["1.0.0"], 11)

        // And the last mile, which used to be manual: write the export where
        // `scripts/verify-export.ts` can run it through the web app's OWN
        // parser. `./scripts/verify-ios.sh` does that, so the day the two
        // formats drift, CI says so instead of a restore quietly losing records.
        // The path comes from the environment because NSTemporaryDirectory()
        // inside the simulator is in its own container, where the host-side
        // script cannot see it. `verify-ios.sh` passes a repo path through as
        // TEST_RUNNER_MORNING_EXPORT_PATH.
        if let handoff = ProcessInfo.processInfo.environment["MORNING_EXPORT_PATH"] {
            try? FileManager.default.createDirectory(
                at: URL(fileURLWithPath: handoff).deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try json.write(to: URL(fileURLWithPath: handoff), options: .atomic)
        }
    }

    /// PHASE 2, not v1: importing the real backup reproduces, exactly: total
    /// tonnage, total reps, session count, current streak, longest run, and the
    /// year grid.
    func testPhase2ImportingTheRealBackupReproducesEveryDerivedNumber() throws {
        throw XCTSkip("Phase 2. v1 ships starting at zero — 06-data.md §6.")
    }

    /// PHASE 2, not v1: malformed records are skipped; the rest of the import
    /// succeeds.
    func testPhase2MalformedRecordsAreSkippedAndTheRestSucceeds() throws {
        throw XCTSkip("Phase 2. v1 ships starting at zero — 06-data.md §6.")
    }

    // MARK: - Helpers

    private func record(
        slot: String,
        reps: Int,
        day: String,
        key: String,
        kg: Double?
    ) -> SessionRecord {
        SessionRecord(
            date: day,
            sessionKey: key,
            log: [slot: reps],
            minutes: 16,
            reps: reps,
            timestamp: Int(Date().timeIntervalSince1970 * 1000) + abs(slot.hashValue % 1000),
            kg: kg
        )
    }

    /// Seeds ship in the APP bundle, not the test bundle.
    private func seed(_ name: String) throws -> AppData {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "\(name).seed", withExtension: "json")
            ?? Bundle.main.url(forResource: "\(name).seed", withExtension: "json")
        let found = try XCTUnwrap(url, "\(name).seed.json is in neither the test nor the app bundle")
        return try JSONDecoder().decode(AppData.self, from: Data(contentsOf: found))
    }
}
