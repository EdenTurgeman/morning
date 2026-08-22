//
//  SessionLifecycleAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Session lifecycle"
//
//  8 assertions. Each one was once a real bug, which is why it is written down.
//
//  All eight are about the STATE MACHINE, not about SwiftUI — which is why
//  `WorkoutSession` is a plain observable object rather than view state.
//

import XCTest
@testable import Morning

/// `@MainActor` because the app module builds with
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
@MainActor
final class SessionLifecycleAcceptanceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("morning-lifecycle-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    /// A fresh install proposes A; completing A proposes B, and vice versa.
    func testFreshInstallProposesAThenAlternates() {
        XCTAssertEqual(NextSession.proposed(from: []), "A", "a fresh install proposes A")

        let didA = [record(key: "A", at: 1000)]
        XCTAssertEqual(NextSession.proposed(from: didA), "B")

        let didB = didA + [record(key: "B", at: 2000)]
        XCTAssertEqual(NextSession.proposed(from: didB), "A")

        // Ordered by `ts`, the record's identity — never by array position,
        // because nothing guarantees the file is sorted.
        let outOfOrder = [record(key: "B", at: 2000), record(key: "A", at: 1000)]
        XCTAssertEqual(NextSession.proposed(from: outOfOrder), "A", "must use ts, not array order")
    }

    /// Rep counter pre-fills from the most recent same-session, same-slot value.
    func testRepCounterPrefillsFromMostRecentSameSessionSameSlot() throws {
        let slot = try firstSetSlot(of: "A")
        let history = [
            record(key: "A", at: 1000, log: [slot: 11]),
            record(key: "A", at: 3000, log: [slot: 14]), // the most recent
            record(key: "A", at: 2000, log: [slot: 12]),
            record(key: "B", at: 9000, log: [slot: 99]), // a different session
        ]

        let session = WorkoutSession(sessionKey: "A", history: history)
        session.goToFirstSet()
        XCTAssertEqual(session.draftReps, 14, "prefill must take the most recent, by ts")

        // With no history at all it falls back to a plausible default so a
        // first run is still one tap.
        let fresh = WorkoutSession(sessionKey: "A", history: [])
        fresh.goToFirstSet()
        let set = try XCTUnwrap(fresh.currentSet)
        XCTAssertEqual(fresh.draftReps, set.bodyweight ? 10 : 12)
    }

    /// Reps are only comparable at the same weight — and bodyweight sets have
    /// no weight, so they always are.
    ///
    /// Not one of the eight; added because running the real screen over real
    /// seeded history showed 14 push-ups labelled "at a different weight now".
    /// The record's `kg` is the session's dumbbell weight and has nothing to do
    /// with a push-up.
    func testBodyweightSetsAreAlwaysComparable() throws {
        let steps = StepCompiler.build(session: "B")
        let bodyweight = try XCTUnwrap(steps.compactMap(\.asSet).first(where: \.bodyweight))
        let loaded = try XCTUnwrap(steps.compactMap(\.asSet).first { $0.load != nil })

        // History logged at a weight that has since changed.
        let history = [record(key: "B", at: 1000, log: [bodyweight.slot: 14, loaded.slot: 12], kg: 6.25)]
        let session = WorkoutSession(sessionKey: "B", kg: 5, history: history)

        session.go(toSlot: bodyweight.slot)
        XCTAssertTrue(session.previousIsComparable, "a push-up has no load — 14 is still 14")

        session.go(toSlot: loaded.slot)
        XCTAssertFalse(
            session.previousIsComparable,
            "a loaded set at 5 kg must not treat 6.25 kg reps as a target"
        )
    }

    /// Back returns to the previous step without losing logged reps, and shows
    /// the number actually entered this session rather than last week's.
    func testBackReturnsWithoutLosingLoggedReps() throws {
        let slot = try firstSetSlot(of: "A")
        let session = WorkoutSession(sessionKey: "A", history: [record(key: "A", at: 1000, log: [slot: 11])])
        session.goToFirstSet()

        XCTAssertEqual(session.draftReps, 11, "prefilled from last time")
        session.adjustReps(by: 3)
        XCTAssertEqual(session.draftReps, 14)

        let setIndex = session.stepIndex
        session.advance()
        XCTAssertEqual(session.log[slot], 14, "advancing logs what was entered")
        XCTAssertNotEqual(session.stepIndex, setIndex)

        session.back()
        XCTAssertEqual(session.stepIndex, setIndex)
        XCTAssertEqual(session.log[slot], 14, "Back must not destroy the log")
        XCTAssertEqual(
            session.draftReps,
            14,
            "Back showed last week's number instead of the correction just made — the exact bug"
        )
    }

    /// Rapid taps on the rep control never collapse into a single increment.
    func testRapidTapsNeverCollapseIntoASingleIncrement() {
        let session = WorkoutSession(sessionKey: "A", history: [])
        session.goToFirstSet()
        let start = session.draftReps

        // Hold-to-repeat accelerates to a 60ms floor, so two taps landing in one
        // update cycle is reachable in normal use. The control reports a DELTA,
        // so each one applies from whatever the value is at the time.
        for _ in 0 ..< 20 {
            session.adjustReps(by: 1)
        }
        XCTAssertEqual(session.draftReps, start + 20, "20 increments collapsed into fewer")

        for _ in 0 ..< 5 {
            session.adjustReps(by: -1)
        }
        XCTAssertEqual(session.draftReps, start + 15)

        // The counter can never go negative.
        for _ in 0 ..< 200 {
            session.adjustReps(by: -1)
        }
        XCTAssertEqual(session.draftReps, 0)
    }

    /// End mid-session discards everything after a confirm, including sets
    /// already logged.
    func testEndMidSessionDiscardsEverythingAfterAConfirm() {
        let store = Store(directory: directory)
        let session = WorkoutSession(sessionKey: "A", store: store)
        session.goToFirstSet()
        session.adjustReps(by: 2)
        session.advance()

        XCTAssertFalse(session.log.isEmpty, "something was logged before ending")
        XCTAssertNotNil(store.loadInProgress(), "the in-progress file exists mid-session")

        session.abandon()

        // Deliberate, and the confirmation copy says so: not even sets already
        // logged survive.
        XCTAssertTrue(session.log.isEmpty, "End kept logged sets")
        XCTAssertNil(store.loadInProgress(), "End left an in-progress file behind")
        XCTAssertTrue(store.load().history.isEmpty, "End wrote history")
    }

    /// Force-quitting mid-session and relaunching restores the same step, the
    /// same logged reps, and a correct remaining time.
    func testForceQuitMidSessionRestoresStepRepsAndRemainingTime() throws {
        let store = Store(directory: directory)
        let start = Date()
        let session = WorkoutSession(sessionKey: "A", store: store, now: start)
        session.goToFirstSet()
        session.adjustReps(by: 4)
        session.advance(now: start) // -> a rest, timer running

        let savedIndex = session.stepIndex
        let savedLog = session.log
        let savedEnd = try XCTUnwrap(session.endsAt, "a rest should be timing")

        // Force quit. Only what reached disk survives.
        let saved = try XCTUnwrap(store.loadInProgress(), "nothing was persisted to restore from")
        let restored = try XCTUnwrap(WorkoutSession(restoring: saved, store: store))

        XCTAssertEqual(restored.stepIndex, savedIndex, "landed on a different step")
        XCTAssertEqual(restored.log, savedLog, "logged reps were lost")
        XCTAssertEqual(restored.startedAt, session.startedAt, "the session's start time changed")

        let restoredEnd = try XCTUnwrap(restored.endsAt)
        XCTAssertEqual(
            restoredEnd.timeIntervalSince1970,
            savedEnd.timeIntervalSince1970,
            accuracy: 0.001,
            "the timer's absolute end moved"
        )

        // And the remaining time is DERIVED from that absolute end, so time
        // spent quit is time spent resting.
        let tenLater = start.addingTimeInterval(10)
        XCTAssertEqual(
            restored.remaining(at: tenLater),
            session.remaining(at: tenLater),
            accuracy: 0.001
        )
    }

    /// A phone call mid-rest leaves the timer correct on return.
    func testAPhoneCallMidRestLeavesTheTimerCorrect() throws {
        let start = Date()
        let session = WorkoutSession(sessionKey: "A", now: start)
        session.goToFirstSet()
        session.advance(now: start) // -> rest

        let rest = try XCTUnwrap(session.currentStep?.restSeconds, "expected a rest after the first set")
        XCTAssertEqual(session.remaining(at: start), TimeInterval(rest), accuracy: 0.001)

        // Suspended for 20 seconds. A tick counter would have stopped dead here
        // and come back 20 seconds wrong; an absolute end date cannot.
        let back = start.addingTimeInterval(20)
        XCTAssertEqual(session.remaining(at: back), TimeInterval(rest) - 20, accuracy: 0.001)

        // Away longer than the rest: it is over, not negative.
        let muchLater = start.addingTimeInterval(TimeInterval(rest) + 300)
        XCTAssertEqual(session.remaining(at: muchLater), 0, accuracy: 0.001)

        // +15s from an ALREADY EXPIRED timer must give 15 seconds from now, not
        // fifteen seconds further into the past.
        session.extendRest(by: 15, now: muchLater)
        XCTAssertEqual(session.remaining(at: muchLater), 15, accuracy: 0.001)
    }

    /// Finishing a session writes exactly ONE history record. The web build
    /// briefly wrote two — this is a real failure mode.
    func testFinishingASessionWritesExactlyOneHistoryRecord() throws {
        let store = Store(directory: directory)
        let session = WorkoutSession(sessionKey: "A", store: store)
        session.goToFirstSet()
        session.adjustReps(by: 1)

        let finished = session.finish()

        // finish() RETURNS the record; there is exactly one place that appends.
        var data = store.load()
        data.history.append(finished)
        try store.save(data)
        try store.saveInProgress(nil)

        XCTAssertEqual(store.load().history.count, 1, "one finished session, one record")
        XCTAssertNil(store.loadInProgress())
        XCTAssertEqual(finished.reps, finished.log.values.reduce(0, +), "stored reps must match the log")
        XCTAssertFalse(finished.log.isEmpty, "the set on screen when you finished was not logged")
        XCTAssertEqual(finished.sessionKey, "A")
    }

    /// `src/hooks/useWorkout.ts` computes minutes as `Math.max(1, ...)`. The
    /// port had `max(0, ...)`, so a session finished inside thirty seconds
    /// recorded a duration the web build cannot produce — in a file the web
    /// build reads back through Restore.
    func testAVeryShortSessionStillRecordsOneMinute() {
        let store = Store(directory: directory)
        let session = WorkoutSession(sessionKey: "A", store: store)
        session.goToFirstSet()
        session.adjustReps(by: 1)

        // Finished the instant it started.
        let finished = session.finish(now: Date(timeIntervalSince1970: Double(session.startedAt) / 1000))

        XCTAssertEqual(finished.minutes, 1, "no session lasts zero minutes")
    }

    // MARK: - Helpers

    private func record(
        key: String,
        at ts: Int,
        log: [String: Int] = ["0.0.0": 1],
        kg: Double = 7.5
    ) -> SessionRecord {
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

    private func firstSetSlot(of key: String) throws -> String {
        let slot = StepCompiler.build(session: key).compactMap(\.asSet).first?.slot
        return try XCTUnwrap(slot, "\(key) compiled with no sets")
    }
}
