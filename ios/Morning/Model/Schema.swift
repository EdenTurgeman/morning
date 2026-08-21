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
struct AppData: Codable, Equatable {
    var v: Int
    var history: [SessionRecord]
    /// ISO-8601 instant, or nil if never backed up.
    var lastBackup: String?
    /// Current working weight per session key. Absent means "use the program
    /// default". It lives in data rather than the program so changing it needs
    /// no rebuild.
    var loads: [String: Double]?

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
    }

    init(v: Int = 1, history: [SessionRecord] = [], lastBackup: String? = nil, loads: [String: Double]? = nil) {
        self.v = v
        self.history = history
        self.lastBackup = lastBackup
        self.loads = loads
    }

    /// Lenient by design: a malformed record is skipped and the rest of the
    /// file still loads. A half-readable backup is better than none.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        v = try container.decodeIfPresent(Int.self, forKey: .v) ?? 1
        lastBackup = try container.decodeIfPresent(String.self, forKey: .lastBackup)
        loads = try container.decodeIfPresent([String: Double].self, forKey: .loads)
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
