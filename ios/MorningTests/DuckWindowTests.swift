//
//  DuckWindowTests.swift
//
//  Not one of the 54 acceptance assertions, but the rule it protects came from
//  a bug Eden reported against the web build in his own words: *"working, and
//  not letting me play music"*. `05-platform.md §3` turns that into a
//  requirement — the countdown's last five seconds must be ONE duck, not six
//  pumps — and this is the part of it that can be checked without a device.
//

import XCTest
@testable import Morning

/// `@MainActor` because the app module builds with
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
@MainActor
final class DuckWindowTests: XCTestCase {
    /// Six cues one second apart must leave the session held open throughout,
    /// releasing only after the last one. Six separate windows would pump the
    /// music five times on the way to zero.
    func testTheCountdownIsOneDuckNotSixPumps() {
        let start = Date()
        var window = DuckWindow()

        // 5, 4, 3, 2, 1 — one per second.
        for second in stride(from: 5, through: 1, by: -1) {
            let at = start.addingTimeInterval(Double(5 - second))
            window.extend(from: at, by: DuckWindow.hold + Cue.countdown(second: second).length)

            // Still ducked as the next tick approaches.
            let justBeforeNext = at.addingTimeInterval(0.99)
            XCTAssertFalse(
                window.shouldRelease(at: justBeforeNext),
                "the session was released between ticks — that is a pump"
            )
        }

        // Then zero.
        let zero = start.addingTimeInterval(5)
        window.extend(from: zero, by: DuckWindow.hold + Cue.go.length)
        XCTAssertFalse(window.shouldRelease(at: zero.addingTimeInterval(0.5)))

        // And the music comes back promptly afterwards.
        XCTAssertTrue(
            window.shouldRelease(at: zero.addingTimeInterval(DuckWindow.hold + Cue.go.length + 0.01)),
            "the session stayed active after the last cue — that ducks music for the whole workout"
        )
    }

    /// The deadline only ever moves forward. A short cue arriving after a long
    /// one must not cut the long one's window short.
    func testTheDeadlineOnlyMovesForward() throws {
        let start = Date()
        var window = DuckWindow()

        window.extend(from: start, by: 5)
        let far = try XCTUnwrap(window.releaseAt)

        window.extend(from: start, by: 0.2)
        XCTAssertEqual(window.releaseAt, far, "a short cue pulled the release deadline back")
    }

    /// Nothing is held open before a cue, and `close()` really closes.
    func testAnIdleWindowNeverHoldsTheSession() {
        var window = DuckWindow()
        XCTAssertNil(window.releaseAt)
        XCTAssertFalse(window.shouldRelease(at: Date()), "an idle window must not claim a release")

        window.extend()
        XCTAssertNotNil(window.releaseAt)
        window.close()
        XCTAssertNil(window.releaseAt)
    }

    /// The count-in ascends, and each step is louder and longer than the last —
    /// so you can tell where you are without listening for pitch, with the
    /// phone on the floor and you face-down over it.
    func testTheCountInAscendsAndGrows() throws {
        let ticks = (1 ... 5).reversed().map { Cue.countdown(second: $0) }
        let notes = ticks.compactMap(\.notes.first)
        XCTAssertEqual(notes.count, 5)

        for (earlier, later) in zip(notes, notes.dropFirst()) {
            XCTAssertGreaterThan(later.frequency, earlier.frequency, "the count-in must rise")
            XCTAssertGreaterThan(later.gain, earlier.gain, "each step must be louder")
            XCTAssertGreaterThan(later.duration, earlier.duration, "each step must be longer")
        }

        // Zero is longer and louder than any tick.
        let go = try XCTUnwrap(Cue.go.notes.first)
        XCTAssertGreaterThan(go.gain, notes.last?.gain ?? 1)
        XCTAssertGreaterThan(Cue.go.length, ticks.last?.length ?? 1)
    }
}
