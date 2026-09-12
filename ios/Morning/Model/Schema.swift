/* ===========================================================================
 *  THE STORAGE CONTRACT
 *  ---------------------------------------------------------------------------
 *  Exactly what the web app stores and exports — see ios-port/06-data.md §3.
 *  The terse field names ("d", "s", "ts") are NOT an accident and NOT ours to
 *  tidy up: keeping them identical is what makes the eventual import of the
 *  web history a file copy rather than a translation, and what lets an export
 *  from this app be pasted straight into the web app's Restore box.
 *
 *  Rules encoded here, all from 06-data.md:
 *
 *  · `ts` is the IDENTITY of a record. Deletion, "previous same session"
 *    lookups and milestone diffing all key off it. Never regenerate it.
 *
 *  · `d` is a LOCAL calendar date, not UTC. Week bucketing and the year grid
 *    depend on it. Parsing it as UTC shifts sessions across day and week
 *    boundaries. Parse as local, or at local noon.
 *
 *  · `kg` is optional AND ITS ABSENCE IS MEANINGFUL — "logged before the
 *    weight became adjustable". Fall back to the program default. Never
 *    backfill it; that would retroactively rewrite tonnage.
 *
 *  · `log` is keyed by the BARE slot id ("2.1.0"). The ledger's internal load
 *    table keys by "{sessionKey}:{slot}". Two shapes — keep them straight.
 *
 *  · `reps` is stored, not derived. Recompute from `log` only when missing.
 *
 *  · Parsing is LENIENT BY DESIGN. A malformed record is dropped, not thrown
 *    on, because a half-readable backup is better than none.
 *
 *  ── provenance ───────────────────────────────────────────────────────────
 *  Written as scaffolding from the spec. It has never been through a Swift
 *  compiler — see ios/Agents/00-handoff-log.md.
 * ======================================================================== */

import Foundation

// MARK: - Persisted history

/// One completed session. `ts` is its identity.
struct SessionRecord: Codable, Identifiable, Equatable {
    /// ISO date in the device's LOCAL calendar day. Not UTC.
    var date: String
    /// Session key: "A" | "B".
    var sessionKey: String
    /// Bare slot id ("block.item.set") -> reps.
    var log: [String: Int]
    /// Elapsed minutes.
    var minutes: Int
    /// Sum of `log` values. Stored, not derived.
    var reps: Int
    /// Epoch milliseconds. The record's identity.
    var timestamp: Int
    /// Plates per handle actually used. Absence means "before this was
    /// recorded" — fall back to the program default, and never backfill.
    var kg: Double?

    var id: Int {
        timestamp
    }

    enum CodingKeys: String, CodingKey {
        case date = "d"
        case sessionKey = "s"
        case log
        case minutes = "min"
        case reps
        case timestamp = "ts"
        case kg
    }
}

/// The whole file. One `Codable` struct written as JSON to Application Support.
/// A few tens of KB per year — SwiftData and Core Data buy nothing here.
/// ONE ANSWER HE ACTUALLY GAVE, kept forever.
///
/// `Deck.Mastery` is a summary — misses, and the run since the last one — and a
/// summary cannot answer a question it was not designed for. Eden asked for the
/// raw events *"so that if i wanna gamify it later i can"*, and the whole point
/// of that is that the shape of the game is not decided yet. So this records
/// what happened rather than what it is worth: which card, when, which option
/// he chose, and whether it was right.
///
/// **Which option** is the field that would be impossible to reconstruct later
/// and is worth the most: it is the difference between "he missed this" and
/// "he keeps confusing it with THAT", and the second is the one that could ever
/// teach him something.
///
/// It lives in `AppData` rather than beside the mastery store, because
/// `AppData` is what the backup file carries. Mastery has never been exported —
/// so until now a restore brought back every workout and none of the study
/// progress. Mastery is derivable from these events; the events are derivable
/// from nothing.
struct StudyAnswer: Codable, Equatable {
    /// The card's id. Not a reference to the card object: cards are content and
    /// may be reworded, and an event that happened does not change when they are.
    var card: String
    /// Epoch milliseconds, the same convention `06-data.md` uses for `ts`.
    var ts: Int
    /// Index into that card's options, as they stood when he answered.
    var picked: Int
    var right: Bool
    /// WHAT THAT OPTION SAID, as it read when he chose it.
    ///
    /// `picked` is an index, and an index is only a reference — the deck is
    /// written by agents who rephrase and reorder options, so index 2 in March
    /// is not necessarily the answer he gave in March. That is fine for
    /// counting misses and useless for saying anything about them: *"you keep
    /// answering Chenin Blanc"* is worth reading, and worth nothing at all if
    /// it might name an option he never picked. This app does not tell those.
    ///
    /// So the words ride along. About forty bytes an answer, and it is the
    /// difference between a log that can only count and one that can say what
    /// happened.
    ///
    /// **Optional, and its absence is meaningful** — "logged before the wording
    /// was recorded". Those answers still count as misses; they simply cannot
    /// say which one. Never backfill it from the card's options as they stand
    /// today: that is exactly the lie this field exists to prevent.
    var pickedText: String?
}

/// ONE TIME A CARD WAS PUT IN FRONT OF HIM.
///
/// The answer log records what he CHOSE; this records what he was SHOWN, and
/// the two are not the same event. A question he let run out writes nothing to
/// the answer log — deliberately, so a slow morning is never recorded as
/// ignorance — and a factoid can never write to it at all. Before this, more
/// than a quarter of the deck had no record of ever having been seen.
///
/// Eden asked for exactly this: *"i want to start remembering which questions i
/// saw, how many times i saw each, so it's always diverse."* Times seen is the
/// only thing that can make the draw diverse, because it is the only thing that
/// knows a factoid has come round four times.
///
/// Kept as EVENTS rather than a per-card counter for the same reason
/// `StudyAnswer` is: a counter can answer "how many", and nothing else. These
/// can answer "how many, in what order, how far apart, and did he engage" —
/// including questions nobody has thought of yet.
struct StudySighting: Codable, Equatable {
    /// The card's id.
    var card: String
    /// Epoch milliseconds.
    var ts: Int
    /// Whether he opened it by hand, rather than letting the clock open it.
    ///
    /// The one signal that separates a card he engaged with from a card that
    /// merely happened at him — and the only way to ever notice that some card
    /// is being skipped every single time it comes round.
    var opened: Bool = false
}

struct AppData: Codable, Equatable {
    var v: Int
    var history: [SessionRecord]
    /// ISO-8601 instant, or nil if never backed up.
    var lastBackup: String?
    /// Current working weight per session key. Absent means "use the program
    /// default". It lives in data rather than the program so changing it needs
    /// no rebuild.
    var loads: [String: Double]?
    /// Every study answer he has given, oldest first. Absent in files written
    /// before this existed, and in every web export.
    var studyAnswers: [StudyAnswer]?
    /// Every time a card was shown to him, oldest first. Absent in files
    /// written before this existed, and in every web export.
    ///
    /// It rides in the backup for the reason Eden gave — *"all that needs to be
    /// saved in memory so i can export"* — and because without it a restore
    /// hands the scheduler a deck it believes has never been shown, and the
    /// whole rotation starts again from nothing.
    var studySightings: [StudySighting]?

    static let empty = AppData(v: 1, history: [], lastBackup: nil, loads: nil)

    // Declared explicitly rather than relying on synthesis. Swift only
    // synthesises CodingKeys while it is synthesising at least one of
    // init(from:)/encode(to:) — this type hand-writes init(from:), so the day
    // someone hand-writes encode(to:) as well the synthesised enum silently
    // disappears and init(from:) stops compiling. Cheap insurance.
    enum CodingKeys: String, CodingKey {
        case v
        case history
        case lastBackup
        case loads
        case studyAnswers
        case studySightings
    }

    init(
        v: Int = 1,
        history: [SessionRecord] = [],
        lastBackup: String? = nil,
        loads: [String: Double]? = nil,
        studyAnswers: [StudyAnswer]? = nil,
        studySightings: [StudySighting]? = nil
    ) {
        self.v = v
        self.history = history
        self.lastBackup = lastBackup
        self.loads = loads
        self.studyAnswers = studyAnswers
        self.studySightings = studySightings
    }

    /// Lenient by design: a malformed record is skipped and the rest of the
    /// file still loads. A half-readable backup is better than none.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        v = try container.decodeIfPresent(Int.self, forKey: .v) ?? 1
        lastBackup = try container.decodeIfPresent(String.self, forKey: .lastBackup)
        loads = try container.decodeIfPresent([String: Double].self, forKey: .loads)
        studyAnswers = try container.decodeIfPresent([StudyAnswer].self, forKey: .studyAnswers)
        studySightings = try container.decodeIfPresent([StudySighting].self, forKey: .studySightings)
        let lenient = try container.decodeIfPresent([LenientRecord].self, forKey: .history) ?? []
        history = lenient.compactMap(\.record)
    }
}

/// Decodes to nil instead of throwing, so one bad element does not take the
/// whole array with it.
private struct LenientRecord: Decodable {
    let record: SessionRecord?

    init(from decoder: Decoder) throws {
        record = try? SessionRecord(from: decoder)
    }
}

// MARK: - The in-progress session

/// Stored SEPARATELY from the history, so a crash, phone call or force-quit
/// mid-workout costs nothing. Required in v1.
struct InProgressSession: Codable, Equatable {
    /// Which session: "A" | "B".
    var sessionKey: String
    /// Index into the compiled step list.
    var stepIndex: Int
    /// Bare slot id -> reps logged so far this session.
    var log: [String: Int]
    /// Epoch milliseconds the current timer ends, or nil if not timing.
    ///
    /// Remaining time is COMPUTED FROM THIS, never counted down. A tick
    /// counter drifts, and stops entirely when the app is suspended.
    var endsAt: Int?
    var startedAt: Int

    enum CodingKeys: String, CodingKey {
        case sessionKey = "key"
        case stepIndex = "i"
        case log
        case endsAt
        case startedAt
    }
}
