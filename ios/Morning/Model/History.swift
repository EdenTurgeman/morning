import Foundation

/* ===========================================================================
 *  DERIVED HISTORY
 *  ---------------------------------------------------------------------------
 *  The small reads every screen needs, in one place, so the traps live in one
 *  place too. `04-rules.md`, `06-data.md §3`.
 *
 *  Three of those traps are worth stating before the code:
 *
 *  · `d` is a LOCAL calendar date. Parsing it as UTC shifts sessions across day
 *    and week boundaries and quietly corrupts the year grid. Parsed at local
 *    noon here, which is far enough from either midnight that no timezone or
 *    DST transition can move the day.
 *
 *  · A missing `kg` is MEANINGFUL — "logged before the weight was adjustable".
 *    It falls back to the program default for valuation and is NEVER written
 *    back, because backfilling retroactively rewrites what you lifted.
 *
 *  · Reps are only comparable at the SAME WEIGHT. A previous set done at a
 *    different working weight is not a target, and the caller has to be able to
 *    tell the difference — which is why the lookup returns the weight too
 *    rather than just a number.
 * ======================================================================== */

enum History {
    /// What was done on this exact set last time, and at what weight.
    ///
    /// Returns the weight alongside the reps because the caller cannot decide
    /// whether this is a target without it. `04-rules.md §1`: *"If last time's
    /// reps were done at a different working weight, they are not a
    /// like-for-like target and the control must say so."*
    struct PreviousSet: Equatable {
        let reps: Int
        /// Per handle, resolved — never nil, because an absent `kg` falls back
        /// to the program default rather than meaning "no weight".
        let kg: Double?
        /// The record it came from, by identity.
        let timestamp: Int
    }

    /// The most recent record for `sessionKey` that logged this slot.
    ///
    /// Scans newest first by `ts`, which is the record's identity — never by
    /// array order, because nothing guarantees the file is sorted.
    static func previousSet(
        slot: String,
        sessionKey: String,
        in history: [SessionRecord]
    ) -> PreviousSet? {
        for record in history.filter({ $0.sessionKey == sessionKey }).sorted(by: { $0.timestamp > $1.timestamp }) {
            guard let reps = record.log[slot] else { continue }
            return PreviousSet(reps: reps, kg: resolvedLoad(for: record), timestamp: record.timestamp)
        }
        return nil
    }

    /// The weight a record should be valued at.
    ///
    /// An absent `kg` means "logged before the weight was adjustable" and falls
    /// back to the program's default for that session. This is read-only: the
    /// fallback is never persisted.
    static func resolvedLoad(for record: SessionRecord) -> Double? {
        if let kg = record.kg {
            return kg
        }
        return program.first { $0.key == record.sessionKey }?.defaultLoad
    }

    /// The local calendar day a record belongs to.
    ///
    /// Parsed at local NOON. Midnight is the wrong anchor: a timezone shift or a
    /// DST transition can move it across a day boundary, and the year grid and
    /// week bucketing both key off this.
    static func localDate(of record: SessionRecord, calendar: Calendar = .current) -> Date? {
        let parts = record.date.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(
            year: parts[0],
            month: parts[1],
            day: parts[2],
            hour: 12
        ))
    }

    /// Total reps in a record. Stored rather than derived — `reps` is
    /// authoritative and only recomputed when it is missing or obviously wrong.
    static func reps(of record: SessionRecord) -> Int {
        record.reps > 0 ? record.reps : record.log.values.reduce(0, +)
    }
}
