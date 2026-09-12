import XCTest
@testable import Morning

/// Every action the app can perform, driven directly.
///
/// These exist because of a bug Eden found by tapping a button: "End and
/// discard" ran an empty closure for several workstreams. `ReviewHost` never
/// passed `onAbandon`, so it reached a `= {}` default and did nothing — and
/// nothing on screen could show it, because no tap reaches this app in the
/// development environment and an unwired callback looks exactly like a wired
/// one.
///
/// His reply was the right one: *"if end and discard didn't work i'm sure a lot
/// of other app functionality isn't wired yet"*. The eight actions behind the
/// app's buttons lived as `private func`s on a `View` struct, which meant no
/// test could reach any of them. They live in `AppModel` now, and this is the
/// file that calls each one and checks what it did to the store.
///
/// `@MainActor` for the same reason the other suites are — see
/// `ProgramCompilerAcceptanceTests`.
@MainActor
final class AppActionsAcceptanceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func model(seeded history: [SessionRecord] = []) throws -> AppModel {
        let store = Store(directory: directory)
        if !history.isEmpty {
            try store.save(AppData(v: 1, history: history, lastBackup: nil, loads: nil))
        }
        return AppModel(store: store)
    }

    private func record(_ key: String, at ts: Int, reps: Int = 100) -> SessionRecord {
        SessionRecord(
            date: "2026-08-20", sessionKey: key, log: ["0.0.0": reps],
            minutes: 16, reps: reps, timestamp: ts, kg: 7.5
        )
    }

    // MARK: - Starting, finishing, abandoning

    func testStartingASessionPutsOneOnScreenAndOnDisk() throws {
        let model = try model()
        XCTAssertNil(model.session, "nothing in progress on a fresh install")

        model.start("A")

        XCTAssertEqual(model.session?.sessionKey, "A")
        XCTAssertNotNil(Store(directory: directory).loadInProgress(), "a started session survives a relaunch")
    }

    func testFinishingWritesExactlyOneRecordAndClearsTheInProgressFile() throws {
        let model = try model()
        model.start("A")
        model.session?.goToFirstSet()
        model.session?.adjustReps(by: 3)

        model.finish()

        XCTAssertEqual(model.data.history.count, 1, "one finished session, one record")
        XCTAssertNil(model.session, "the workout is over")
        XCTAssertNotNil(model.finished, "the summary has something to show")
        XCTAssertNil(Store(directory: directory).loadInProgress())
        XCTAssertEqual(Store(directory: directory).load().history.count, 1, "and it reached the disk")
    }

    /// The bug that started all of this.
    func testEndAndDiscardThrowsTheSessionAwayAndWritesNothing() throws {
        let model = try model()
        model.start("A")
        model.session?.goToFirstSet()
        model.session?.adjustReps(by: 5)
        // COMMITTED, not just counted. Reps reach `log` on `advance`, and a
        // number still on the counter has never been recorded — which is why
        // the note below counts logged sets and not the draft.
        model.session?.advance()
        XCTAssertNotNil(Store(directory: directory).loadInProgress(), "mid-session")

        model.abandon()

        XCTAssertNil(model.session, "the workout is gone")
        XCTAssertTrue(model.data.history.isEmpty, "End writes NOTHING — 04-rules.md §1")
        XCTAssertNil(Store(directory: directory).loadInProgress(), "and leaves no in-progress file")
        XCTAssertNil(model.finished, "abandoning is not finishing; there is no summary")

        // AND THE APP SAYS SOMETHING ABOUT IT.
        //
        // It said nothing at all: the session cleared and Home appeared in
        // silence, as though the morning had not happened. The reps are
        // captured BEFORE the session is discarded, because afterwards there is
        // nothing left to count.
        // The COUNT is not asserted exactly: the rep control is prefilled from
        // last time, so `adjustReps(by: 5)` commits 15, and pinning the number
        // here would be testing `prefill` by accident. What matters is that
        // something was logged and the line says so.
        let note = try XCTUnwrap(model.lastAbandon)
        XCTAssertGreaterThan(note.reps, 0, "a committed set is what End actually throws away")
        XCTAssertEqual(note.line, "Nothing saved. The week is where it was.")

        // And the morning moves on when he does.
        model.start("A")
        XCTAssertNil(model.lastAbandon, "the note is about the last morning, not this one")
    }

    /// ENDING BEFORE LOGGING ANYTHING DID NOT LOSE ANYTHING.
    ///
    /// "Nothing saved" implies something was there to save. He presses End
    /// before the first set as often as after the fifth, and telling him he
    /// lost something he never had is the one way a line this short can be
    /// untrue.
    func testEndingAnEmptySessionSaysNothingWasLost() throws {
        let model = try model()
        model.start("A")
        model.session?.goToFirstSet()
        // Counted but never committed: this is a session that logged nothing,
        // and telling him it lost something would be untrue.
        model.session?.adjustReps(by: 8)
        model.abandon()

        XCTAssertEqual(model.lastAbandon, AbandonNote(reps: 0))
        XCTAssertEqual(model.lastAbandon?.line, "Ended. The week is where it was.")
    }

    /// THE ONE PLACE DELIGHT IS PERMITTED IS SPENT ONCE, EVER.
    ///
    /// `01-motion-doctrine.md` §3.2 grants it on exactly that condition. A
    /// treatment that plays every time data arrives is not a first-data moment,
    /// it is an animation on a reading screen — which the same table forbids
    /// for every other surface in the app.
    func testTheFirstRecordMomentIsClaimedOnceEver() throws {
        let name = "morning.firstrecord.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }

        XCTAssertTrue(FirstRecord.claim(FirstRecord.ledger, using: defaults), "the first time")
        XCTAssertFalse(FirstRecord.claim(FirstRecord.ledger, using: defaults), "and never again")
        XCTAssertFalse(FirstRecord.claim(FirstRecord.ledger, using: defaults))

        // Two different moments do not spend each other.
        XCTAssertTrue(FirstRecord.claim("something-else", using: defaults))

        // `forget` is what makes a once-in-a-lifetime state filmable at all.
        FirstRecord.forget(FirstRecord.ledger, using: defaults)
        XCTAssertTrue(FirstRecord.claim(FirstRecord.ledger, using: defaults))
    }

    func testDismissingTheSummaryReturnsToHome() throws {
        let model = try model()
        model.start("A")
        model.session?.goToFirstSet()
        model.finish()
        XCTAssertNotNil(model.finished)

        model.dismissSummary()

        XCTAssertNil(model.finished)
        XCTAssertNil(model.session, "and does not resurrect the workout")
    }

    func testAnInterruptedSessionIsRestoredOnLaunch() throws {
        let first = try model()
        first.start("B")
        first.session?.goToFirstSet()
        first.session?.adjustReps(by: 2)
        let step = try XCTUnwrap(first.session?.stepIndex)

        // A relaunch is a fresh model over the same store.
        let second = AppModel(store: Store(directory: directory))

        XCTAssertEqual(second.session?.sessionKey, "B", "the session came back")
        XCTAssertEqual(second.session?.stepIndex, step, "on the same step")
    }

    // MARK: - The data actions

    func testDeletingRemovesOneSessionByItsTimestamp() throws {
        let model = try model(seeded: [record("A", at: 1000), record("B", at: 2000), record("A", at: 3000)])

        model.delete(record("B", at: 2000))

        XCTAssertEqual(model.data.history.map(\.timestamp), [1000, 3000], "keyed off ts, not an index")
        XCTAssertEqual(Store(directory: directory).load().history.count, 2, "and it reached the disk")
    }

    func testEraseRemovesEverythingIncludingAnInProgressSession() throws {
        let model = try model(seeded: [record("A", at: 1000)])
        model.start("A")
        XCTAssertNotNil(Store(directory: directory).loadInProgress())

        model.erase()

        XCTAssertTrue(model.data.history.isEmpty)
        XCTAssertNil(
            Store(directory: directory).loadInProgress(),
            "an erase that left the workout behind is not an erase"
        )
        XCTAssertTrue(Store(directory: directory).load().history.isEmpty)
    }

    func testRestoreReplacesTheHistoryWholesale() throws {
        let model = try model(seeded: [record("A", at: 1000), record("A", at: 2000)])
        let incoming = AppData(v: 1, history: [record("B", at: 9000)], lastBackup: nil, loads: ["B": 10])

        model.restore(incoming)

        XCTAssertEqual(model.data.history.map(\.timestamp), [9000], "replaced, not merged")
        XCTAssertEqual(model.data.loads?["B"], 10)
        XCTAssertEqual(Store(directory: directory).load().history.count, 1)
    }

    func testChangingTheWorkingWeightPersistsAndFeedsTheNextSession() throws {
        let model = try model()
        XCTAssertNil(model.data.loads?["A"], "nothing stored yet — the program's default applies")

        model.setLoad(9.5, for: "A")

        XCTAssertEqual(model.data.loads?["A"], 9.5)
        XCTAssertEqual(model.load(for: "A"), 9.5, "and it is what Home shows")
        XCTAssertEqual(Store(directory: directory).load().loads?["A"], 9.5)

        model.start("A")
        model.session?.goToFirstSet()
        XCTAssertEqual(model.session?.finish().kg, 9.5, "the session records the weight it was done at")
    }

    func testExportingStampsTheBackupDate() throws {
        let model = try model(seeded: [record("A", at: 1000)])
        XCTAssertNil(model.data.lastBackup, "never backed up")

        model.stampBackup()

        XCTAssertNotNil(model.data.lastBackup, "the Backup screen can now say when")
        XCTAssertNotNil(Store(directory: directory).load().lastBackup)
    }

    // MARK: - What Home offers

    func testHomeProposesTheOppositeOfWhateverWasLoggedLast() throws {
        XCTAssertEqual(try model().nextKey, "A", "a fresh install proposes A")
        XCTAssertEqual(try model(seeded: [record("A", at: 1000)]).nextKey, "B")
        XCTAssertEqual(try model(seeded: [record("A", at: 1000), record("B", at: 2000)]).nextKey, "A")
    }

    // MARK: - Touch-target floors

    /// The sweaty-hands floors, asserted.
    ///
    /// `01-product.md` sets these and calls them non-negotiable: rep controls
    /// ≥78pt, primary actions ≥64pt. **Nothing tested them until now**, which
    /// mattered the moment `RepStepper` started drawing a 66pt box inside an
    /// 80pt target — a deliberate split so the key can be visually smaller
    /// without losing hittability. Collapse those two frames into one while
    /// "tidying" and the target silently becomes 66pt with no failure anywhere.
    ///
    /// This does not measure the rendered view; it guards the tokens the view
    /// is built from, which is the part a refactor actually changes.
    func testTouchTargetFloorsHold() {
        XCTAssertGreaterThanOrEqual(
            Hit.repControl, 78,
            "rep controls are hit with a knuckle at 6:10am — 78pt is the floor, not a guideline"
        )
        XCTAssertGreaterThanOrEqual(Hit.primary, 64, "primary actions floor at 64pt")
        XCTAssertGreaterThanOrEqual(Hit.minimum, 44, "everything tappable clears Apple's 44pt")
    }

    /// The Live Activity's mirrored inks must equal the real ones.
    ///
    /// `MorningWidgets` holds three files and cannot see `PaperTokens.swift`,
    /// so `RestActivityStyle` copies the ink values. A copy nobody checks is how
    /// two worlds drift apart, and this project has a documented history of
    /// exactly that — measured figures that "quietly stopped being true".
    ///
    /// This is what makes the duplication safe rather than hopeful.
    func testLiveActivityInksMatchPaper() {
        XCTAssertEqual(RestActivityStyle.stock, Paper.stock)
        XCTAssertEqual(RestActivityStyle.press, Paper.press)
        XCTAssertEqual(RestActivityStyle.orange, Paper.orange)
        XCTAssertEqual(RestActivityStyle.overprint, Paper.overprint)
    }
}
