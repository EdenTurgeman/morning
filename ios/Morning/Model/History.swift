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
            // A record written against B's old shape is read through the map,
            // and ONLY through it. Reading the raw slot as well would find
            // `2.0.0` in an old record and hand the myo block a number from
            // the superset lateral raise — the exact confusion the map exists
            // to prevent.
            let key = isLegacyB(record) ? legacySlot(for: slot) : slot
            guard let reps = record.log[key] else { continue }
            return PreviousSet(reps: reps, kg: resolvedLoad(for: record), timestamp: record.timestamp)
        }
        return nil
    }

    /* --- B's 2026-09-19 restructure ---------------------------------------
     * The blocks were reordered, so every slot id in B came to mean a
     * different exercise: the floor fly would have inherited the myo block's
     * numbers and told him he was beating a set he had never done.
     *
     * No movement was removed, only moved, so the map below is a bijection and
     * nothing is lost. Records on disk are NEVER rewritten — a stored session
     * is a record of what he actually lifted, and re-keying it to suit a later
     * program is the same class of dishonesty as backfilling `kg`. The
     * translation happens on the way out, here.
     *
     *     new             old      movement
     *     1.0   <-->      1.0      push-up, deficit   (did not move)
     *     1.1   <-->      2.0      lateral raise, superset partner
     *     2.0   <-->      3.0      lateral raise, myo-reps
     *     3.0   <-->      4.0      floor fly
     *     3.1   <-->      2.1      rear-delt fly
     *
     * The set index is carried across untouched. The five-set myo era (3.0.3
     * and 3.0.4, logged once on 2026-08-19) maps onto a block that has three
     * sets now, so those two numbers have nowhere to land — as was already
     * true before this change.
     */

    /// New `block.item` -> the `block.item` the same movement used to occupy.
    /// The push-up is absent because it did not move.
    static let bSlotMoves = [
        "1.1": "2.0",
        "2.0": "3.0",
        "3.0": "4.0",
        "3.1": "2.1",
    ]

    /// True when this record was logged against B's pre-restructure shape.
    ///
    /// Detected by SHAPE, not by date. Only the old B had a second movement in
    /// block 2 — the rear-delt fly, before it moved next to the floor fly — so
    /// a `2.1.*` key can only have come from it. A date cutoff would have been
    /// wrong for anything restored from an older backup, which is precisely the
    /// case this has to survive.
    static func isLegacyB(_ record: SessionRecord) -> Bool {
        record.sessionKey == "B" && record.log.keys.contains { $0.hasPrefix("2.1.") }
    }

    /// `record.log` re-keyed into the CURRENT program's slots, so two records
    /// written against different shapes of B can be compared set by set. A
    /// no-op for anything already current.
    static func currentSlotLog(of record: SessionRecord) -> [String: Int] {
        guard isLegacyB(record) else { return record.log }
        let toCurrent = Dictionary(uniqueKeysWithValues: bSlotMoves.map { ($0.value, $0.key) })

        // Sorted, and assigning rather than `uniqueKeysWithValues`, because
        // that initialiser TRAPS on a duplicate key. No log the old B could
        // write produces one, but a malformed or hand-edited backup could, and
        // a crash while reading history is the worst possible outcome here.
        // Sorting makes the survivor deterministic instead of hash-ordered.
        var out: [String: Int] = [:]
        for (slot, reps) in record.log.sorted(by: { $0.key < $1.key }) {
            out[remap(slot, through: toCurrent)] = reps
        }
        return out
    }

    private static func legacySlot(for slot: String) -> String {
        remap(slot, through: bSlotMoves)
    }

    /// Swaps a slot's `block.item` prefix, keeping its set index. An unmapped
    /// prefix is returned unchanged, which is how the push-up passes through.
    private static func remap(_ slot: String, through moves: [String: String]) -> String {
        let parts = slot.split(separator: ".")
        guard parts.count == 3, let moved = moves["\(parts[0]).\(parts[1])"] else { return slot }
        return "\(moved).\(parts[2])"
    }

    /* --- what has stopped moving -------------------------------------------
     * `PRODUCT.md`: "Three identical sessions in a row is the most valuable
     * output the app has: it means the program needs to change." The app has
     * always believed that and has only ever checked it against the session
     * TOTAL, which is the coarsest possible reading — a total can hold still
     * while half the sets move, and it can move while one set never has.
     *
     * The per-set version is the one that catches the thing nobody sees: a
     * number accepted rather than counted. The rep control prefills with last
     * time's figure and one tap logs it, so a set that is never actually
     * counted reproduces itself forever and looks exactly like a set that is
     * being trained and has plateaued. Both readings want the same response —
     * go and look at that movement — so the line does not have to tell them
     * apart, and deliberately does not try.
     */

    /// A movement whose reps have not changed for several sessions.
    struct Stall: Equatable {
        let exercise: String
        /// The rep count, when every set of the movement sits on the same one.
        /// Nil when its sets differ from each other — 10/11/12 repeated
        /// identically is still a stall, it just has no single number.
        let reps: Int?
        /// Consecutive sessions at these numbers, this one included.
        let sessions: Int
    }

    /// Movements that have not moved, in program order.
    ///
    /// Every set of a movement must be identical to the same set in each of the
    /// preceding sessions. One set moving is progress and disqualifies the
    /// whole movement, because the response — go and look at it — is already
    /// happening.
    ///
    /// **The run stops at a weight change**, like every other comparison in
    /// this app. Reps held level across a heavier load are not a stall, they
    /// are an improvement the arithmetic cannot see.
    static func stalls(
        after record: SessionRecord,
        in history: [SessionRecord],
        minimum: Int = 3
    ) -> [Stall] {
        // Built rather than taken from `history`, so this is correct whether or
        // not the caller has already appended the finished session.
        let earlier = history
            .filter { $0.sessionKey == record.sessionKey && $0.timestamp < record.timestamp }
            .sorted { $0.timestamp > $1.timestamp }
        var window = [record]
        for previous in earlier {
            // Comparable only while the load holds. The first change ends the
            // run rather than being skipped over.
            guard let here = resolvedLoad(for: previous),
                  let now = resolvedLoad(for: record),
                  abs(here - now) < 0.01
            else {
                break
            }
            window.append(previous)
        }
        guard window.count >= minimum else { return [] }

        let logs = window.map { currentSlotLog(of: $0) }
        var seen: Set<String> = []
        var out: [Stall] = []

        for set in StepCompiler.build(session: record.sessionKey).compactMap(\.asSet) {
            guard !seen.contains(set.exercise) else { continue }
            seen.insert(set.exercise)

            let slots = StepCompiler.build(session: record.sessionKey)
                .compactMap(\.asSet)
                .filter { $0.exercise == set.exercise }
                .map(\.slot)

            // How many sessions back every one of this movement's sets reads
            // the same as it does today.
            var run = 1
            guard let today = reps(of: slots, in: logs[0]) else { continue }
            for log in logs.dropFirst() {
                guard reps(of: slots, in: log) == today else { break }
                run += 1
            }

            guard run >= minimum else { continue }
            let uniform = Set(today).count == 1 ? today.first : nil
            out.append(Stall(exercise: set.exercise, reps: uniform, sessions: run))
        }

        return out
    }

    /// Every one of `slots` read from one session, or nil if any is absent — a
    /// movement half-logged cannot be compared against one that was not.
    private static func reps(of slots: [String], in log: [String: Int]) -> [Int]? {
        let found = slots.compactMap { log[$0] }
        return found.count == slots.count ? found : nil
    }

    /// The Summary's line, **or nothing at all** — the same contract as
    /// `Deck.Standing.line`. It states the fact and stops: the plateau
    /// celebration already names the rung to climb, and the Guide has the
    /// ladder. Saying it a third time here would make this a nag.
    static func stallLine(_ stalls: [Stall]) -> String? {
        guard let shortest = stalls.map(\.sessions).min() else { return nil }
        let span = "\(spelled(shortest)) sessions"

        switch stalls.count {
        case 1:
            let only = stalls[0]
            guard let reps = only.reps else {
                return "\(only.exercise) has not moved in \(span)."
            }
            return "\(only.exercise) has been \(reps) for \(span)."
        case 2:
            return "\(stalls[0].exercise) and \(lowered(stalls[1].exercise)) "
                + "have not moved in \(span)."
        default:
            let others = stalls.count - 2
            let count = others == 1 ? "one other" : "\(spelled(others)) others"
            return "\(stalls[0].exercise), \(lowered(stalls[1].exercise)) and \(count) "
                + "have not moved in \(span)."
        }
    }

    /// Mid-sentence, "Floor fly" is a movement and not a proper noun.
    private static func lowered(_ exercise: String) -> String {
        exercise.prefix(1).lowercased() + exercise.dropFirst()
    }

    /// Small counts read as words in this app's prose — "One more identical
    /// session", "Third A at the same total". Digits are for measurements.
    private static func spelled(_ count: Int) -> String {
        let words = ["zero", "one", "two", "three", "four", "five",
                     "six", "seven", "eight", "nine", "ten"]
        return words.indices.contains(count) ? words[count] : "\(count)"
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
