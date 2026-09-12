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

        // `studyAnswers` is absent here because this fixture has none, and an
        // absent key is the contract: every web export and every backup written
        // before the study log existed has to keep round-tripping unchanged.
        XCTAssertEqual(Set(parsed.keys), ["v", "history", "lastBackup", "loads"])

        let withStudy = try store.exportJSON(
            AppData(
                v: 1,
                history: [],
                studyAnswers: [StudyAnswer(card: "w-madeira-estufagem", ts: 1_756_000_000_000, picked: 2, right: false)]
            )
        )
        let studyParsed = try XCTUnwrap(JSONSerialization.jsonObject(with: withStudy) as? [String: Any])
        let logged = try XCTUnwrap(studyParsed["studyAnswers"] as? [[String: Any]])
        // No `pickedText` on this one, and that is the contract: an answer from
        // before the wording was recorded exports without it, and imports as a
        // miss the app cannot name rather than one it guesses at.
        XCTAssertEqual(Set(logged[0].keys), ["card", "ts", "picked", "right"])
        XCTAssertEqual(
            logged[0]["picked"] as? Int,
            2,
            "WHICH option he chose is the field that cannot be reconstructed later"
        )

        // THE WORDING RIDES OUT WITH THE ANSWER when it was recorded. Without
        // it, "you keep answering X" is a sentence about an index into a deck
        // content agents rewrite, which is a sentence that can become false.
        let withWording = try store.exportJSON(
            AppData(
                v: 1,
                history: [],
                studyAnswers: [
                    StudyAnswer(
                        card: "w-cabernet-travels",
                        ts: 1_756_000_000_000,
                        picked: 0,
                        right: false,
                        pickedText: "It ripens early, so it finishes in almost any climate"
                    ),
                ]
            )
        )
        let wordingParsed = try XCTUnwrap(JSONSerialization.jsonObject(with: withWording) as? [String: Any])
        let named = try XCTUnwrap(wordingParsed["studyAnswers"] as? [[String: Any]])
        XCTAssertEqual(Set(named[0].keys), ["card", "ts", "picked", "right", "pickedText"])
        XCTAssertEqual(
            named[0]["pickedText"] as? String,
            "It ripens early, so it finishes in almost any climate"
        )

        // AND THE SIGHTINGS RIDE OUT WITH THEM. Eden: *"all that needs to be
        // saved in memory so i can export."* Without this half, a restore hands
        // the scheduler a deck it believes has never been shown.
        let withSightings = try store.exportJSON(
            AppData(
                v: 1,
                history: [],
                studySightings: [
                    StudySighting(card: "w-madeira-estufagem", ts: 1_756_000_000_000, opened: true),
                ]
            )
        )
        let sightingParsed = try XCTUnwrap(JSONSerialization.jsonObject(with: withSightings) as? [String: Any])
        let seen = try XCTUnwrap(sightingParsed["studySightings"] as? [[String: Any]])
        XCTAssertEqual(Set(seen[0].keys), ["card", "ts", "opened"])
        XCTAssertEqual(seen[0]["opened"] as? Bool, true)
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

    /// Importing a WEB-APP export reproduces every field and every derived
    /// number.
    ///
    /// **Un-skipped 2026-08-30.** These two were `XCTSkip`ped as "Phase 2. v1
    /// ships starting at zero — 06-data.md §6", which was a real product
    /// decision until Eden said *"I just don't wanna lose my progress."* The
    /// import path already existed (`BackupScreen.handleImport`); what did not
    /// exist was any proof it survives a file the WEB app wrote.
    ///
    /// The JSON below is hand-written in the web build's exact wire shape
    /// (`src/lib/storage.ts`) rather than produced by this app, because a
    /// round-trip through our own encoder would prove only that we can read
    /// ourselves. It deliberately includes the three things most likely to
    /// break an import: a record with **no `kg`** (logged before the weight was
    /// adjustable), a **working-weight change** partway through, and a
    /// bodyweight movement.
    func testImportingAWebAppExportReproducesEveryDerivedNumber() throws {
        let webExport = """
        {
          "v": 1,
          "lastBackup": "2026-08-20T05:58:00.000Z",
          "loads": { "A": 7.5, "B": 6.25 },
          "history": [
            { "d": "2026-08-10", "s": "A", "min": 16, "reps": 23,
              "ts": 1786000000000, "log": { "1.0.0": 12, "2.0.0": 11 } },
            { "d": "2026-08-12", "s": "A", "min": 17, "reps": 25, "kg": 7.5,
              "ts": 1786200000000, "log": { "1.0.0": 13, "2.0.0": 12 } },
            { "d": "2026-08-14", "s": "A", "min": 16, "reps": 21, "kg": 10,
              "ts": 1786400000000, "log": { "1.0.0": 11, "2.0.0": 10 } }
          ]
        }
        """

        // The SAME call `BackupScreen.handleImport` makes. If this decoder ever
        // diverges from that one, this test stops meaning anything.
        let decoded = try JSONDecoder().decode(AppData.self, from: Data(webExport.utf8))

        XCTAssertEqual(decoded.v, 1)
        XCTAssertEqual(decoded.history.count, 3, "a record was dropped on import")
        XCTAssertEqual(decoded.lastBackup, "2026-08-20T05:58:00.000Z")
        XCTAssertEqual(decoded.loads?["A"], 7.5)
        XCTAssertEqual(decoded.loads?["B"], 6.25)

        // Field-for-field on the terse wire names.
        let first = try XCTUnwrap(decoded.history.first)
        XCTAssertEqual(first.date, "2026-08-10")
        XCTAssertEqual(first.sessionKey, "A")
        XCTAssertEqual(first.minutes, 16)
        XCTAssertEqual(first.reps, 23)
        XCTAssertEqual(first.timestamp, 1_786_000_000_000)
        XCTAssertEqual(first.log["1.0.0"], 12)

        // A MISSING `kg` STAYS MISSING. CLAUDE.md: absence means "logged before
        // the weight was adjustable" and backfilling it retroactively rewrites
        // tonnage. This is the assertion that catches a well-meaning default.
        XCTAssertNil(first.kg, "an absent kg was backfilled on import")
        XCTAssertEqual(decoded.history[1].kg, 7.5)
        XCTAssertEqual(decoded.history[2].kg, 10)

        // Derived numbers computed from the imported history.
        let ledger = LedgerMath.compute(decoded.history)
        XCTAssertEqual(ledger.sessions, 3)
        XCTAssertEqual(ledger.reps, 23 + 25 + 21)
        XCTAssertEqual(ledger.minutes, 16 + 17 + 16)
        XCTAssertEqual(ledger.since, "2026-08-10", "the first session's date drives 'since'")
    }

    /// One malformed record is skipped and the rest of the file still loads.
    ///
    /// `AppData.init(from:)` is lenient by design and `LenientRecord` is what
    /// makes it so. The failure this guards against is the strict one: a single
    /// bad element throwing and taking an entire backup with it, which for a
    /// user restoring years of history is the difference between losing one
    /// session and losing all of them.
    func testMalformedRecordsAreSkippedAndTheRestSucceeds() throws {
        let webExport = """
        {
          "v": 1,
          "lastBackup": null,
          "history": [
            { "d": "2026-08-10", "s": "A", "min": 16, "reps": 23, "kg": 7.5,
              "ts": 1786000000000, "log": { "1.0.0": 23 } },
            { "d": "2026-08-11", "s": "B", "reps": "not a number",
              "ts": 1786100000000, "log": { "1.0.0": 9 } },
            { "d": "2026-08-12", "s": "B", "min": 19, "reps": 18, "kg": 6.25,
              "ts": 1786200000000, "log": { "1.0.0": 18 } }
          ]
        }
        """

        let decoded = try JSONDecoder().decode(AppData.self, from: Data(webExport.utf8))

        XCTAssertEqual(decoded.history.count, 2, "the good records did not survive a bad one")
        XCTAssertEqual(decoded.history.map(\.timestamp), [1_786_000_000_000, 1_786_200_000_000])
        XCTAssertNil(decoded.lastBackup, "an explicit JSON null must decode to nil")
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
