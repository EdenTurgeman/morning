//
//  WeekAndStreakAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Week and streak"
//
//  8 assertions. The streak is measured in WEEKS, not consecutive days — the
//  program has a rest day, and a consecutive-day streak punishes you for
//  following it correctly. `04-rules.md §3`.
//
//  Every date here is fixed and the calendar is pinned to a known timezone.
//  A test that reads `Date()` passes for eleven months and then fails in the
//  week the clocks change.
//

import XCTest
@testable import Morning

/// `@MainActor` because the app module builds with
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
@MainActor
final class WeekAndStreakAcceptanceTests: XCTestCase {
    /// Pinned so a DST transition or a CI runner in another zone cannot move a
    /// week boundary underneath the assertions.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt
        calendar.locale = Locale(identifier: "en_GB")
        return calendar
    }

    /// The week starts on Sunday.
    func testTheWeekStartsOnSunday() throws {
        // 2026-08-16 is a Sunday; the 17th to the 22nd are Mon–Sat.
        for dayOfMonth in 16 ... 22 {
            let date = try XCTUnwrap(day(2026, 8, dayOfMonth))
            XCTAssertEqual(
                Week.key(of: date, calendar: calendar),
                "2026-08-16",
                "\(dayOfMonth) August did not bucket into the week starting Sunday the 16th"
            )
        }

        // And the 23rd, the next Sunday, starts a new one.
        let nextSunday = try XCTUnwrap(day(2026, 8, 23))
        XCTAssertEqual(Week.key(of: nextSunday, calendar: calendar), "2026-08-23")

        // `weekStartsOn` is 1 here and 0 in the web build — Foundation counts
        // Sunday as 1, JavaScript as 0. Same day, different number. CLAUDE.md
        // lists confusing them as a trap that has already cost someone.
        XCTAssertEqual(weekStartsOn, 1, "Foundation's convention: 1 is Sunday")
    }

    /// Five sessions on any days completes a week; five consecutive days is not
    /// required and six days with four sessions does not count.
    func testFiveSessionsOnAnyDaysCompletesAWeek() throws {
        // Scattered across the week, with gaps. Sun, Tue, Wed, Fri, Sat.
        let scattered = [16, 18, 19, 21, 22].map { record(2026, 8, $0) }
        let onSaturday = try XCTUnwrap(day(2026, 8, 22))
        let complete = Week.progress(history: scattered, today: onSaturday, calendar: calendar)

        XCTAssertEqual(complete.done, 5)
        XCTAssertEqual(complete.remaining, 0)
        XCTAssertEqual(complete.streak, 1, "five sessions on any days completes the week")

        // Six days, four sessions: not a week.
        let four = [16, 17, 18, 19].map { record(2026, 8, $0) }
        let short = Week.progress(history: four, today: onSaturday, calendar: calendar)
        XCTAssertEqual(short.done, 4)
        XCTAssertEqual(short.streak, 0, "four sessions is not a complete week however they land")
    }

    /// An incomplete week in progress never breaks a streak.
    func testIncompleteWeekInProgressNeverBreaksAStreak() throws {
        // Two complete weeks, then a current week with only one session in it.
        var history = completeWeek(startingSunday: 2) // 2026-08-02
        history += completeWeek(startingSunday: 9) // 2026-08-09
        history.append(record(2026, 8, 17)) // one session this week

        let onMonday = try XCTUnwrap(day(2026, 8, 17))
        let progress = Week.progress(history: history, today: onMonday, calendar: calendar)

        XCTAssertEqual(progress.done, 1)
        XCTAssertEqual(
            progress.streak,
            2,
            "the week in progress has not finished — it cannot have broken anything"
        )
    }

    /// A complete week in progress extends it.
    func testCompleteWeekInProgressExtendsTheStreak() throws {
        var history = completeWeek(startingSunday: 2)
        history += completeWeek(startingSunday: 9)
        history += completeWeek(startingSunday: 16)

        let onSaturday = try XCTUnwrap(day(2026, 8, 22))
        let progress = Week.progress(history: history, today: onSaturday, calendar: calendar)

        XCTAssertEqual(progress.done, 5)
        XCTAssertEqual(progress.streak, 3, "a complete current week counts toward the streak")
    }

    /// Longest run survives the current streak dropping to zero.
    func testLongestRunSurvivesTheCurrentStreakDroppingToZero() throws {
        // Three complete weeks, then a week missed entirely, then one session.
        var history = completeWeek(startingSunday: 26, month: 7) // 2026-07-26
        history += completeWeek(startingSunday: 2) // 2026-08-02
        history += completeWeek(startingSunday: 9) // 2026-08-09
        // 2026-08-16 missed entirely.
        history.append(record(2026, 8, 23))

        let onSunday = try XCTUnwrap(day(2026, 8, 23))
        let progress = Week.progress(history: history, today: onSunday, calendar: calendar)

        XCTAssertEqual(progress.streak, 0, "a missed week takes the current streak to zero")
        XCTAssertEqual(
            progress.longestRun,
            3,
            "the run you built must stay on screen — that is exactly when people stop"
        )
    }

    /// canRestToday is false when the remaining days exactly equal the remaining
    /// sessions.
    func testCanRestTodayIsFalseWhenDaysLeftEqualSessionsLeft() throws {
        // Wednesday, nothing done: 5 needed, 4 days left including today.
        let wednesday = try XCTUnwrap(day(2026, 8, 19))
        let behind = Week.progress(history: [], today: wednesday, calendar: calendar)
        XCTAssertEqual(behind.daysLeft, 4)
        XCTAssertEqual(behind.remaining, 5)
        XCTAssertTrue(behind.missed, "five sessions cannot fit in four days")
        XCTAssertFalse(behind.canRestToday)

        // Tuesday, one done: 4 needed, 5 days left. Exactly one spare.
        let tuesday = try XCTUnwrap(day(2026, 8, 18))
        let oneDone = Week.progress(history: [record(2026, 8, 16)], today: tuesday, calendar: calendar)
        XCTAssertEqual(oneDone.daysLeft, 5)
        XCTAssertEqual(oneDone.remaining, 4)
        XCTAssertTrue(oneDone.canRestToday, "four sessions still fit in the four days after today")
        XCTAssertFalse(oneDone.atRisk)

        // Wednesday, one done: 4 needed, 4 days left. No slack at all.
        let tight = Week.progress(history: [record(2026, 8, 16)], today: wednesday, calendar: calendar)
        XCTAssertEqual(tight.daysLeft, 4)
        XCTAssertEqual(tight.remaining, 4)
        XCTAssertFalse(tight.canRestToday, "rest today and the week is gone")
        XCTAssertTrue(tight.atRisk)
        XCTAssertFalse(tight.missed, "still reachable, but only just")
    }

    /// The nudge names the correct weekdays.
    func testTheNudgeNamesTheCorrectWeekdays() throws {
        // Monday the 17th, one session done. Days ahead are Tue–Sat.
        let monday = try XCTUnwrap(day(2026, 8, 17))
        let progress = Week.progress(history: [record(2026, 8, 16)], today: monday, calendar: calendar)

        XCTAssertEqual(progress.daysAhead, ["Tue", "Wed", "Thu", "Fri", "Sat"])

        let nudge = try XCTUnwrap(WeekNudge.text(for: progress))
        XCTAssertTrue(nudge.contains("4 to go"), "the nudge does the arithmetic: \(nudge)")

        // On a day with no slack it names the days resting would cost.
        let wednesday = try XCTUnwrap(day(2026, 8, 19))
        let tight = Week.progress(
            history: [16, 17].map { record(2026, 8, $0) },
            today: wednesday,
            calendar: calendar
        )
        XCTAssertEqual(tight.daysAhead, ["Thu", "Fri", "Sat"])
        let tightNudge = try XCTUnwrap(WeekNudge.text(for: tight))
        XCTAssertTrue(
            tightNudge.contains("Thu") && tightNudge.contains("Fri") && tightNudge.contains("Sat"),
            "resting costs named days: \(tightNudge)"
        )

        // And it never congratulates without saying something true.
        let complete = try Week.progress(
            history: completeWeek(startingSunday: 16),
            today: XCTUnwrap(day(2026, 8, 22)),
            calendar: calendar
        )
        XCTAssertEqual(WeekNudge.text(for: complete), "Week complete. Rest is part of it.")
    }

    /// completedThisWeek fires only on the session that reaches target, not on
    /// the ones after it.
    func testCompletedThisWeekFiresOnlyOnTheSessionThatReachesTarget() throws {
        let saturday = try XCTUnwrap(day(2026, 8, 22))

        for count in 1 ... 4 {
            let partial = (0 ..< count).map { record(2026, 8, 16 + $0) }
            XCTAssertFalse(
                Week.progress(history: partial, today: saturday, calendar: calendar).completedThisWeek,
                "\(count) sessions is not a completed week"
            )
        }

        let exactly = (0 ..< 5).map { record(2026, 8, 16 + $0) }
        XCTAssertTrue(Week.progress(history: exactly, today: saturday, calendar: calendar).completedThisWeek)

        // A sixth session is over target, not a second completion.
        let over = (0 ..< 6).map { record(2026, 8, 16 + $0) }
        let overProgress = Week.progress(history: over, today: saturday, calendar: calendar)
        XCTAssertFalse(
            overProgress.completedThisWeek,
            "the sixth session must not fire the completion again"
        )
        XCTAssertEqual(overProgress.done, 6)
        XCTAssertEqual(WeekNudge.text(for: overProgress), "Week complete, +1 over.")
    }

    // MARK: - Helpers

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 9))
    }

    private func record(_ year: Int, _ month: Int, _ dayOfMonth: Int) -> SessionRecord {
        SessionRecord(
            date: String(format: "%04d-%02d-%02d", year, month, dayOfMonth),
            sessionKey: dayOfMonth.isMultiple(of: 2) ? "A" : "B",
            log: ["1.0.0": 12],
            minutes: 16,
            reps: 12,
            timestamp: (year * 10000 + month * 100 + dayOfMonth) * 1000,
            kg: 7.5
        )
    }

    /// Five sessions in the week beginning on the given Sunday.
    private func completeWeek(startingSunday: Int, month: Int = 8) -> [SessionRecord] {
        (0 ..< 5).map { record(2026, month, startingSunday + $0) }
    }
}
