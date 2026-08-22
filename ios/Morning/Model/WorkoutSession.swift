import Foundation
import Observation

/* ===========================================================================
 *  THE WORKOUT
 *  ---------------------------------------------------------------------------
 *  The session state machine, deliberately separate from any view. Every one of
 *  the eight `SessionLifecycleAcceptanceTests` is about THIS, not about SwiftUI
 *  — which is the reason it is a plain observable object and not view state.
 *
 *  The rules it exists to hold, all from `04-rules.md §1`:
 *
 *  · The rep control reports a DELTA, never an absolute. Two taps landing in
 *    one update cycle, both computed from the same stale value, collapse into
 *    one increment — and hold-to-repeat accelerates to 60ms, so that collapse
 *    is reachable in normal use, not a thought experiment.
 *
 *  · Prefill priority is this session's own value, THEN last time on this exact
 *    set, THEN a plausible default. Getting that order wrong is how Back
 *    silently ate a correction in an early build.
 *
 *  · End abandons: confirm first, then save NOTHING — not even sets already
 *    logged. Deliberate, and the confirmation copy says so.
 *
 *  · Finishing writes EXACTLY ONE history record. The web build briefly wrote
 *    two.
 *
 *  · Remaining time comes from an absolute `endsAt`, never a tick counter. A
 *    counter drifts, and stops dead when the app is suspended.
 * ======================================================================== */

@Observable
final class WorkoutSession {
    let sessionKey: String
    let steps: [Step]
    let startedAt: Int

    private(set) var stepIndex: Int
    /// Bare slot id -> reps logged so far THIS session.
    private(set) var log: [String: Int]
    /// Absolute end of the running timer. Remaining time is derived from it.
    private(set) var endsAt: Date?

    /// The reps currently showing on the counter for the current set. Held
    /// separately from `log` because a set is not logged until you advance —
    /// Back must show what you entered, not what you committed.
    private(set) var draftReps: Int

    private let history: [SessionRecord]
    private let store: Store?

    // MARK: - Starting and restoring

    init(
        sessionKey: String,
        kg: Double? = nil,
        history: [SessionRecord] = [],
        store: Store? = nil,
        now: Date = Date()
    ) {
        self.sessionKey = sessionKey
        self.history = history
        self.store = store
        steps = StepCompiler.build(session: sessionKey, kg: kg)
        stepIndex = 0
        log = [:]
        endsAt = nil
        startedAt = Int(now.timeIntervalSince1970 * 1000)
        draftReps = 0
        draftReps = prefill(for: stepIndex)
        // Step 0 is the warm-up timer. Arming it here rather than only in
        // `move(to:)` is the difference between a countdown and a frozen 90.
        endsAt = Self.endsAt(for: steps.first, now: now)
    }

    /// Restores a session that was interrupted. Must land on the same step with
    /// the same logged reps and a correct remaining time — a crash, a phone
    /// call or a force-quit costs nothing.
    init?(
        restoring saved: InProgressSession,
        kg: Double? = nil,
        history: [SessionRecord] = [],
        store: Store? = nil
    ) {
        sessionKey = saved.sessionKey
        self.history = history
        self.store = store
        steps = StepCompiler.build(session: saved.sessionKey, kg: kg)
        guard steps.indices.contains(saved.stepIndex) else { return nil }

        stepIndex = saved.stepIndex
        log = saved.log
        startedAt = saved.startedAt
        endsAt = saved.endsAt.map { Date(timeIntervalSince1970: Double($0) / 1000) }
        draftReps = 0
        draftReps = prefill(for: saved.stepIndex)
    }

    // MARK: - Reading

    var currentStep: Step? {
        steps[safe: stepIndex]
    }

    var currentSet: SetStep? {
        currentStep?.asSet
    }

    /// Jumps to an arbitrary step index. Lands on rests and timers too, which
    /// `go(toSlot:)` cannot — and without a Simulator UI on this machine, a
    /// launch argument is the only way to reach a rest at all.
    func go(toStep index: Int, now: Date = Date()) {
        move(to: index, now: now)
    }

    /// Jumps to the step logging `slot`. For tests and for anything that needs
    /// to land on a specific set rather than walk to it.
    func go(toSlot slot: String, now: Date = Date()) {
        guard let index = steps.firstIndex(where: { $0.asSet?.slot == slot }) else { return }
        move(to: index, now: now)
    }

    /// Jumps to the first set, past the warm-up. Used by tests and by anything
    /// that wants to skip the least important screen in the app.
    func goToFirstSet(now: Date = Date()) {
        guard let index = steps.firstIndex(where: { $0.asSet != nil }) else { return }
        move(to: index, now: now)
    }

    /// What was done on this exact set last time, with the weight it was done
    /// at — because without the weight the caller cannot tell whether it is a
    /// target at all.
    var previous: History.PreviousSet? {
        guard let slot = currentSet?.slot else { return nil }
        return History.previousSet(slot: slot, sessionKey: sessionKey, in: history)
    }

    /// Whether last time's number is a like-for-like target. Reps are only
    /// comparable at the same weight; if the working weight moved, every delta
    /// is meaningless and the screen must say so rather than imply a target.
    ///
    /// **Bodyweight sets are always comparable.** A push-up has no load, so the
    /// session's dumbbell weight has nothing to do with it — comparing the two
    /// told a real seeded history that 14 push-ups were "at a different weight
    /// now", which is both false and the kind of thing only running against
    /// real data catches.
    var previousIsComparable: Bool {
        guard let previous, let set = currentSet else { return false }
        if set.bodyweight {
            return true
        }
        return previous.kg == set.load
    }

    /// The emotional centre of the entire app.
    var isBeatingPrevious: Bool {
        guard previousIsComparable, let previous else { return false }
        return draftReps > previous.reps
    }

    /// The next set after here — what a rest is counting down towards.
    var upcomingSet: SetStep? {
        steps[(stepIndex + 1)...].compactMap(\.asSet).first
    }

    /// Which set this is, and how many the session has. "Set 2 / 25" counting
    /// STEPS is a different and misleading number: it includes the warm-up and
    /// every rest.
    var setPosition: (index: Int, total: Int)? {
        guard currentSet != nil else { return nil }
        let sets = steps.enumerated().filter { $0.element.asSet != nil }
        guard let position = sets.firstIndex(where: { $0.offset == stepIndex }) else { return nil }
        return (position + 1, sets.count)
    }

    /// True on the last step. `advance()` deliberately does nothing here — the
    /// caller finishes rather than walking off the end.
    var isAtEnd: Bool {
        stepIndex >= steps.count - 1
    }

    /// Seconds left on the running timer, derived from the absolute end date.
    func remaining(at now: Date = Date()) -> TimeInterval {
        guard let endsAt else { return 0 }
        return max(0, endsAt.timeIntervalSince(now))
    }

    // MARK: - The rep control

    /// Reports a DELTA. Never set an absolute from the view: two taps in one
    /// update cycle would both compute from the same stale value and collapse
    /// into one increment.
    func adjustReps(by delta: Int) {
        draftReps = max(0, draftReps + delta)
    }

    // MARK: - Moving through the session

    /// Logs the current set — if it is a set — and moves on.
    func advance(now: Date = Date()) {
        if let set = currentSet {
            log[set.slot] = draftReps
        }
        move(to: stepIndex + 1, now: now)
    }

    /// Back must show the number actually entered this session, not last week's.
    /// `prefill` handles that; this only has to not destroy the log.
    ///
    /// Stepping back onto a rest restarts its timer, matching
    /// `useWorkout.ts`'s `back()`, which recomputes `endsAt` from now.
    func back(now: Date = Date()) {
        move(to: stepIndex - 1, now: now)
    }

    func skipRest(now: Date = Date()) {
        guard case .rest = currentStep else { return }
        move(to: stepIndex + 1, now: now)
    }

    /// Extends from the LATER of the saved end date or now, so an expired timer
    /// never stays stuck at zero.
    ///
    /// This DIVERGES from `src/hooks/useWorkout.ts`, which does
    /// `endsAt + seconds` unconditionally: tap `+15s` on a timer that already
    /// expired and it stays at zero, fifteen seconds further into the past. The
    /// W1 interaction audit caught it in the prototype; the fix belongs here.
    func extendRest(by seconds: TimeInterval, now: Date = Date()) {
        endsAt = max(endsAt ?? now, now).addingTimeInterval(seconds)
        persist()
    }

    // MARK: - Ending

    /// Abandons. Saves NOTHING — not even sets already logged. Deliberate:
    /// `04-rules.md §1`, and the confirmation copy says so.
    func abandon() {
        log = [:]
        endsAt = nil
        try? store?.saveInProgress(nil)
    }

    /// Finishes, writing EXACTLY ONE history record. The web build briefly
    /// wrote two, which is why this RETURNS the record rather than appending it
    /// anywhere itself — there is one place that can append, and it is the
    /// caller.
    ///
    /// Ordering matters: the caller must save the record BEFORE clearing the
    /// in-progress file. Clear first and a failed save loses the session, which
    /// is the one unacceptable failure mode.
    func finish(now: Date = Date(), calendar: Calendar = .current) -> SessionRecord {
        if let set = currentSet {
            log[set.slot] = draftReps
        }
        let minutes = max(0, Int((Double(Int(now.timeIntervalSince1970 * 1000) - startedAt) / 60000).rounded()))
        return SessionRecord(
            date: Self.localDateString(now, calendar: calendar),
            sessionKey: sessionKey,
            log: log,
            minutes: minutes,
            reps: log.values.reduce(0, +),
            timestamp: Int(now.timeIntervalSince1970 * 1000),
            kg: currentKg
        )
    }

    // MARK: - Internals

    /// The weight this session was done at, for the record's `kg`.
    ///
    /// One weight per session is enforced by the compiler tests, so the first
    /// loaded set speaks for all of them. Nil only if a session were entirely
    /// bodyweight — which would read as "logged before the weight was
    /// adjustable" and is why neither A nor B is.
    private var currentKg: Double? {
        steps.compactMap(\.asSet).compactMap(\.load).first
    }

    private func move(to index: Int, now: Date) {
        guard steps.indices.contains(index) else { return }
        stepIndex = index
        draftReps = prefill(for: index)

        endsAt = Self.endsAt(for: steps[index], now: now)
        persist()
    }

    /// In this exact order. Getting it wrong is how Back silently ate a
    /// correction in an early build.
    private func prefill(for index: Int) -> Int {
        guard let set = steps[safe: index]?.asSet else { return 0 }

        // 1. What you already logged for this slot IN THIS SESSION.
        if let mine = log[set.slot] {
            return mine
        }

        // 2. What you did on this exact set LAST TIME. The whole point of the app.
        if let previous = History.previousSet(slot: set.slot, sessionKey: sessionKey, in: history) {
            return previous.reps
        }

        // 3. A plausible default, so a first run is still one tap.
        return set.bodyweight ? 10 : 12
    }

    /// The `endsAt` a step carries when you arrive on it. Sets do not time.
    private static func endsAt(for step: Step?, now: Date) -> Date? {
        switch step {
        case let .rest(rest): now.addingTimeInterval(TimeInterval(rest.seconds))
        case let .timer(timer): now.addingTimeInterval(TimeInterval(timer.seconds))
        default: nil
        }
    }

    private func persist() {
        guard let store else { return }
        try? store.saveInProgress(InProgressSession(
            sessionKey: sessionKey,
            stepIndex: stepIndex,
            log: log,
            endsAt: endsAt.map { Int($0.timeIntervalSince1970 * 1000) },
            startedAt: startedAt
        ))
    }

    private static func localDateString(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

// MARK: - Which session is next

enum NextSession {
    /// The opposite of whatever was logged last. A fresh install proposes A.
    /// `04-rules.md §2`.
    static func proposed(from history: [SessionRecord]) -> String {
        guard let last = history.max(by: { $0.timestamp < $1.timestamp }) else { return "A" }
        return last.sessionKey == "A" ? "B" : "A"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
