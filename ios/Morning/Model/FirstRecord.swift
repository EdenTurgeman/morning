import Foundation

/* ===========================================================================
 *  SEEN ONCE, EVER
 *  ---------------------------------------------------------------------------
 *  `01-motion-doctrine.md` §3.2 permits delight in exactly one place and gives
 *  the reason in three words: *"Empty → first data. Delight permitted. Seen
 *  once, ever."* And the requirement it is serving: *"Day one is the normal
 *  case, not an edge case. '0 tonnes' must read as the beginning of a record."*
 *
 *  Once-ever is the whole licence. A treatment that plays every time data
 *  arrives is not a first-data moment, it is an animation on a reading screen —
 *  which the same table rules out for every other surface in the app.
 *
 *  So the claim is a WRITE, and it happens the first time it is asked. There is
 *  no "check" that does not also spend it, deliberately: a caller that could
 *  look without spending would eventually look twice.
 * ======================================================================== */

enum FirstRecord {
    /// True exactly once, ever, per key. Every call after the first is false,
    /// across launches and reinstalls of the same install.
    static func claim(_ key: String, using defaults: UserDefaults = .standard) -> Bool {
        let stored = "morning.firstrecord.\(key).v1"
        guard !defaults.bool(forKey: stored) else { return false }
        defaults.set(true, forKey: stored)
        return true
    }

    /// For tests and for `-fresh`, which has to be able to see the moment more
    /// than once.
    static func forget(_ key: String, using defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: "morning.firstrecord.\(key).v1")
    }

    /// The lifetime total finding its first number.
    static let ledger = "ledger"

    /// The year grid getting its first inked day.
    ///
    /// A separate key from `ledger` on purpose: §3.2 names both surfaces —
    /// *"Empty → first data (year grid, lifetime)"* — and they are reached
    /// independently. Spending one must not spend the other.
    static let history = "history"
}
