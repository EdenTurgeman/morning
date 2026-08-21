// @generated-scaffold — delete this line once you start implementing this suite.
//
//  WeekAndStreakAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Week and streak"
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

final class WeekAndStreakAcceptanceTests: XCTestCase {
    /// The week starts on Sunday.
    func testTheWeekStartsOnSunday() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Five sessions on any days completes a week; five consecutive days is not
    /// required and six days with four sessions does not count.
    func testFiveSessionsOnAnyDaysCompletesAWeek() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// An incomplete week in progress never breaks a streak.
    func testIncompleteWeekInProgressNeverBreaksAStreak() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// A complete week in progress extends it.
    func testCompleteWeekInProgressExtendsTheStreak() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Longest run survives the current streak dropping to zero.
    func testLongestRunSurvivesTheCurrentStreakDroppingToZero() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// canRestToday is false when the remaining days exactly equal the remaining
    /// sessions.
    func testCanRestTodayIsFalseWhenDaysLeftEqualSessionsLeft() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// The nudge names the correct weekdays.
    func testTheNudgeNamesTheCorrectWeekdays() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// completedThisWeek fires only on the session that reaches target, not on
    /// the ones after it.
    func testCompletedThisWeekFiresOnlyOnTheSessionThatReachesTarget() throws {
        throw XCTSkip("Not implemented yet.")
    }
}
