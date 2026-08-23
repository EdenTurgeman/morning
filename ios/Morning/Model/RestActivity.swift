import Foundation

#if canImport(ActivityKit)
    import ActivityKit
#endif

/* ===========================================================================
 *  THE REST TIMER, OUTSIDE THE APP
 *  ---------------------------------------------------------------------------
 *  W12. Eden asked for this in these words:
 *
 *      "wire this into a live activity thing that will show even if my app is
 *       closed i think it would be good and i can re-open the app from that at
 *       the top."
 *
 *  So the requirement is his: the rest countdown is legible with the app shut,
 *  and tapping it comes back to the step it is counting.
 *
 *  WHY THIS COSTS ALMOST NOTHING. The rest timer already derives every frame
 *  from an absolute `endsAt` rather than counting ticks down — `RestScreen`'s
 *  header explains why, and it is the same reason a phone call cannot desync
 *  it. `Text(timerInterval:)` on the Lock Screen wants exactly that: hand it an
 *  end date and the system renders the countdown with no further updates from
 *  the app at all. No background task, no push, no budget.
 *
 *  This file is compiled into BOTH the app and the widget extension, because
 *  `ActivityAttributes` has to be the same type on both sides.
 * ======================================================================== */

/// What the Lock Screen and Dynamic Island are told about a rest.
///
/// `endsAt` is in the static half rather than the state, deliberately. It never
/// changes for a given rest — extending one ends the activity and starts a new
/// one — and keeping it static means the system can render the whole countdown
/// without the app waking up to push a single update.
nonisolated struct RestAttributes: Codable, Hashable {
    /// `ActivityAttributes` requires a `ContentState`, and this activity has
    /// none: the countdown is drawn from `endsAt`, which never changes for a
    /// given rest. Empty on purpose rather than carrying a placeholder.
    struct State: Codable, Hashable {}

    let endsAt: Date
    /// "Push-up", or nil at the end of a session.
    let nextExercise: String?
    /// "set 2 of 3 · 8–15 reps"
    let nextDetail: String?
    /// True for the 20-second myo rest, which is the training stimulus rather
    /// than a convenience — worth saying differently even here.
    let isMyo: Bool
}

#if canImport(ActivityKit)
    /// `nonisolated` on the type AND on the conformance, and the compiler asked
    /// for both in turn rather than me choosing either.
    ///
    /// The module is main-actor-isolated by default
    /// (`SWIFT_DEFAULT_ACTOR_ISOLATION`, and `CLAUDE.md` explains why that is
    /// right for this app), which makes this conformance main-actor-isolated
    /// too. `Activity.end` is concurrent, so it cannot use one — and hopping
    /// the *call* back to the main actor does not help, because it is the
    /// conformance that is isolated, not the call site. That was my first
    /// attempt and it failed identically.
    ///
    /// Three attempts, recorded because the error text points at the wrong fix
    /// twice:
    ///
    /// 1. Hop the *call* to the main actor — no. It is the conformance that is
    ///    isolated, not the call site, and it fails identically.
    /// 2. `nonisolated extension` — accepted by the parser and does nothing.
    ///    The modifier does not reach the conformance.
    /// 3. `extension T: nonisolated P` **and** `nonisolated struct T`. The
    ///    conformance cannot be nonisolated while the type it conforms is not.
    ///
    /// A plain `Codable` value with no UI is exactly what `nonisolated` is for,
    /// and `CLAUDE.md` allows it precisely here: only where the compiler asks.
    extension RestAttributes: nonisolated ActivityAttributes {
        typealias ContentState = State
    }
#endif

/// Where tapping the Live Activity lands.
///
/// It does not need to carry the step: the app restores an in-progress session
/// on launch already — `AppRoot.init` loads it before anything is drawn — so
/// coming back to the right place is the behaviour that already exists rather
/// than something this has to arrange.
enum RestActivityLink {
    static let scheme = "morning"
    static let url = URL(string: "morning://rest")
}
