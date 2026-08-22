import Foundation

/* ===========================================================================
 *  THE WEEK, AND THE STREAK
 *  ---------------------------------------------------------------------------
 *  The streak is measured in WEEKS, NOT CONSECUTIVE DAYS. `04-rules.md §3`.
 *
 *  The program is six mornings a week with a rest day, so a consecutive-day
 *  streak punishes you for following it correctly. A week counts if it contains
 *  five sessions, whichever days those land on — miss Tuesday, train Saturday,
 *  nothing is lost.
 *
 *  THE WEEK IN PROGRESS CAN NEVER BREAK A STREAK. It has not finished, so it
 *  only ever adds: already complete, it extends the count; not yet, the streak
 *  simply reads from last week backwards.
 *
 *  And the longest run is remembered separately. A missed week takes the
 *  current streak to zero, which is precisely when people stop — so the run you
 *  built stays on screen as something to chase back rather than disappearing as
 *  if it never happened.
 *
 *  ── THE TRAP ─────────────────────────────────────────────────────────────
 *  `weekStartsOn` MEANS A DIFFERENT NUMBER IN EACH BUILD. The web stores 0 for
 *  Sunday (JavaScript's `getDay()`); `Program.swift` stores 1 (Foundation's
 *  `weekday`, where 1 is Sunday). Same day, different number, and CLAUDE.md
 *  lists it as a trap that has already cost someone something.
 *
 *  The offset arithmetic below is identical to the web's *because* of that:
 *  `(weekday - weekStartsOn + 7) % 7` gives 0 on Sunday in both conventions.
 *  Do not "fix" either constant to match the other.
 * ======================================================================== */

struct WeekSummary: Equatable {
    /// ISO date of the week's first day. Sorts chronologically as a plain
    /// string, which sidesteps every ISO-week-number edge case.
    let key: String
    let count: Int
    let complete: Bool
}

struct WeeklyProgress: Equatable {
    let done: Int
    let target: Int
    /// Consecutive complete weeks, including this one if it is already complete.
    let streak: Int
    /// Still needed this week to make target.
    let remaining: Int
    /// Days left including today.
    let daysLeft: Int
    /// Enough days left to still make it, but only just.
    let atRisk: Bool
    /// Target can no longer be reached this week.
    let missed: Bool
    /// Most recent twelve weeks, oldest first.
    let recent: [WeekSummary]
    /// The best run of complete weeks ever had.
    let longestRun: Int
    /// You could skip today and still reach target on the days remaining.
    let canRestToday: Bool
    /// Weekday names left after today, e.g. ["Thu", "Fri", "Sat"].
    let daysAhead: [String]
    /// True when the week has just reached target — not when it is past it.
    let completedThisWeek: Bool
}

enum Week {
    /// Midnight on the first day of the week containing `date`, in local time.
    static func start(of date: Date, calendar: Calendar = .current) -> Date {
        let midnight = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: midnight)
        let back = (weekday - weekStartsOn + 7) % 7
        return calendar.date(byAdding: .day, value: -back, to: midnight) ?? midnight
    }

    /// Stable id for a week: the ISO date of its first day.
    static func key(of date: Date, calendar: Calendar = .current) -> String {
        isoDate(start(of: date, calendar: calendar), calendar: calendar)
    }

    /// The week a stored record belongs to.
    ///
    /// Parsed at local NOON. `d` is a LOCAL calendar date and parsing it as UTC
    /// shifts sessions across day and week boundaries — `06-data.md §3`.
    static func key(ofRecord record: SessionRecord, calendar: Calendar = .current) -> String? {
        guard let date = History.localDate(of: record, calendar: calendar) else { return nil }
        return key(of: date, calendar: calendar)
    }

    static func shift(_ key: String, byWeeks delta: Int, calendar: Calendar = .current) -> String {
        guard let date = date(fromKey: key, calendar: calendar),
              let moved = calendar.date(byAdding: .day, value: delta * 7, to: date)
        else {
            return key
        }
        return isoDate(moved, calendar: calendar)
    }

    // MARK: - Derived state

    static func progress(
        history: [SessionRecord],
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> WeeklyProgress {
        var counts: [String: Int] = [:]
        for record in history {
            guard let week = key(ofRecord: record, calendar: calendar) else { continue }
            counts[week, default: 0] += 1
        }

        let current = key(of: today, calendar: calendar)
        let done = counts[current] ?? 0

        // The current week only ever adds. An unfinished week is not a broken one.
        var streak = 0
        if done >= weeklyTarget {
            streak += 1
        }
        var cursor = shift(current, byWeeks: -1, calendar: calendar)
        while (counts[cursor] ?? 0) >= weeklyTarget {
            streak += 1
            cursor = shift(cursor, byWeeks: -1, calendar: calendar)
        }

        let weekday = calendar.component(.weekday, from: today)
        let dayInWeek = (weekday - weekStartsOn + 7) % 7
        let daysLeft = 7 - dayInWeek
        let remaining = max(0, weeklyTarget - done)

        return WeeklyProgress(
            done: done,
            target: weeklyTarget,
            streak: streak,
            remaining: remaining,
            daysLeft: daysLeft,
            atRisk: remaining > 0 && remaining == daysLeft,
            missed: remaining > daysLeft,
            recent: recentWeeks(from: current, counts: counts, calendar: calendar),
            longestRun: longestRun(counts: counts, upTo: current, calendar: calendar),
            // Skipping today still leaves daysLeft - 1 chances.
            canRestToday: remaining <= daysLeft - 1,
            daysAhead: daysAhead(from: today, daysLeft: daysLeft, calendar: calendar),
            completedThisWeek: done == weeklyTarget
        )
    }

    /// Walks every week from the first with a session up to the current one, so
    /// a week with no sessions at all correctly breaks the run. ISO date keys
    /// sort lexicographically, which is why the cursor comparison works.
    private static func longestRun(
        counts: [String: Int],
        upTo current: String,
        calendar: Calendar
    ) -> Int {
        guard var cursor = counts.keys.min() else { return 0 }
        var longest = 0
        var run = 0
        while cursor <= current {
            if (counts[cursor] ?? 0) >= weeklyTarget {
                run += 1
                longest = max(longest, run)
            } else {
                run = 0
            }
            cursor = shift(cursor, byWeeks: 1, calendar: calendar)
        }
        return longest
    }

    private static func recentWeeks(
        from current: String,
        counts: [String: Int],
        calendar: Calendar
    ) -> [WeekSummary] {
        (0 ..< 12).reversed().map { offset in
            let key = shift(current, byWeeks: -offset, calendar: calendar)
            let count = counts[key] ?? 0
            return WeekSummary(key: key, count: count, complete: count >= weeklyTarget)
        }
    }

    private static func daysAhead(from today: Date, daysLeft: Int, calendar: Calendar) -> [String] {
        guard daysLeft > 1 else { return [] }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return (1 ..< daysLeft).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today).map(formatter.string(from:))
        }
    }

    // MARK: - Dates

    private static func isoDate(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static func date(fromKey key: String, calendar: Calendar) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        // Local noon, for the same reason records are parsed there.
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }
}

// MARK: - The nudge

enum WeekNudge {
    /// Plain-language nudge for the home screen.
    ///
    /// The question at 6am is not "how am I doing" — it is "can I skip today?"
    /// So that is what this answers, with the actual arithmetic rather than
    /// encouragement. `nil` when there is nothing useful to say; silence beats
    /// filler at that hour.
    static func text(for progress: WeeklyProgress) -> String? {
        if progress.missed {
            return "This week's out of reach. Next week starts clean."
        }

        if progress.done >= progress.target {
            return progress.done == progress.target
                ? "Week complete. Rest is part of it."
                : "Week complete, +\(progress.done - progress.target) over."
        }

        if progress.remaining == 1, progress.daysLeft > 1 {
            return "One more makes the week."
        }

        // Nothing left but today — say so plainly.
        if !progress.canRestToday {
            return progress.daysLeft == 1
                ? "Last day. This one makes the week."
                : "Train today or the week's gone — \(progress.remaining) left, \(progress.daysLeft) days."
        }

        // There is room to skip. Name the days it would cost you.
        let needed = Array(progress.daysAhead.suffix(progress.remaining))
        if needed.count == progress.daysAhead.count, !needed.isEmpty {
            return "Rest today and you still make \(progress.target) — but you'd need \(list(needed))."
        }

        let spare = progress.daysAhead.count - progress.remaining
        return "\(progress.remaining) to go, \(progress.daysLeft - 1) days after today. \(spare) spare."
    }

    private static func list(_ items: [String]) -> String {
        guard items.count > 1 else { return items.first ?? "" }
        return "\(items.dropLast().joined(separator: ", ")) and \(items[items.count - 1])"
    }
}
