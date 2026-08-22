import SwiftUI
import UIKit

/* ===========================================================================
 *  RUNNING THE REAL SCREENS
 *  ---------------------------------------------------------------------------
 *  Drives `SetScreen` from a real `WorkoutSession` over real persisted history,
 *  so the screen can be reviewed and MEASURED against the same bars the
 *  prototype was, rather than against hardcoded fixtures.
 *
 *      -screen set                  the real Set screen
 *      -screen set -seed six-months over six months of history
 *      -screen set -progress 0.85   at a chosen point in the dawn
 *
 *  Rest is W5. Landing on one here shows what it is waiting for rather than
 *  pretending: a half-built Rest screen would be worse than an honest gap.
 * ======================================================================== */

struct WorkoutHost: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State var session: WorkoutSession
    private let progressOverride: Double?
    /// `-slot 4.0.0` lands on one specific set. The worst content in the
    /// program is not the first set, and a screen that must never scroll has to
    /// be checked against its worst case rather than its first.
    private let slotOverride: String?
    /// `-reps 15` sets the counter on arrival.
    ///
    /// This exists because there is no Simulator UI on this machine — only the
    /// headless `simctl` runtime — so synthesized touches have nothing to be
    /// delivered to and the threshold state cannot be reached by tapping. The
    /// state machine is covered by the acceptance tests; this is how the SCREEN
    /// for that state gets looked at and measured.
    private let repsOverride: Int?
    /// `-step 2` lands on any step, rests included.
    private let stepOverride: Int?
    /// Review only. The app starts a session on step 0, the warm-up, exactly as
    /// the web build does — but `-screen set` should mean the Set screen, so
    /// the review host skips ahead. Keeping these two paths separate is the
    /// point: the app used to skip the warm-up because the review tool wanted
    /// it skipped, and the warm-up went unbuilt for five workstreams as a
    /// result.
    private let startAtFirstSet: Bool

    /// The namespace the work object travels in. One per host, so the counter
    /// and the timer are the same object to SwiftUI.
    @Namespace private var workObject

    /// "End" discards the whole session, so it asks first. See `endSession`.
    ///
    /// `-confirm-end` opens it shortly after launch. A confirmation dialog
    /// nobody can reach is a confirmation dialog nobody has read, and no tap
    /// reaches this app in the development environment. Deferred rather than
    /// set as the initial value: a dialog raised during the first render, before
    /// the view is in a window, is simply dropped.
    @State private var confirmingEnd = false
    @State private var cardRests: Set<Int> = []
    @State private var drawnCards: [Int: Card] = [:]

    /// The session belongs to whoever started it — `AppRoot` in the app, or a
    /// launch argument in review. The host only renders it and reports back.
    let onFinish: () -> Void
    let onAbandon: () -> Void

    init(
        session: WorkoutSession,
        onFinish: @escaping () -> Void = {},
        onAbandon: @escaping () -> Void = {},
        progressOverride: Double? = nil,
        slot: String? = nil,
        reps: Int? = nil,
        step: Int? = nil,
        startAtFirstSet: Bool = false
    ) {
        _session = State(initialValue: session)
        self.onFinish = onFinish
        self.onAbandon = onAbandon
        self.progressOverride = progressOverride
        slotOverride = slot
        repsOverride = reps
        stepOverride = step
        self.startAtFirstSet = startAtFirstSet
    }

    var body: some View {
        Group {
            if case let .timer(timer) = session.currentStep, let endsAt = session.endsAt {
                WarmupScreen(
                    step: timer,
                    endsAt: endsAt,
                    progress: progressOverride ?? sessionProgress,
                    // Blank on purpose. The chrome's centre is orientation —
                    // "Set 2 / 14", "Rest" — and here the headline directly
                    // beneath it already says "Warm-up". Saying it twice, 40pt
                    // apart, is not orientation.
                    stepLabel: "",
                    namespace: workObject,
                    onDone: { advance { session.advance() } },
                    onBack: { advance { session.back() } },
                    onEnd: endSession
                )
                .transition(Motion.screenSwap(reduceMotion: reduceMotion))
            } else if case let .rest(rest) = session.currentStep, let endsAt = session.endsAt {
                RestScreen(
                    seconds: rest.seconds,
                    endsAt: endsAt,
                    progress: progressOverride ?? sessionProgress,
                    stepLabel: "Rest",
                    next: session.upcomingSet,
                    card: drawnCards[session.stepIndex],
                    isMyo: rest.seconds < Deck.minimumRestForCard,
                    namespace: workObject,
                    onExtend: { session.extendRest(by: 15) },
                    onSkip: { advance { session.skipRest() } },
                    onComplete: { advance { session.skipRest() } },
                    onBack: { advance { session.back() } },
                    onEnd: endSession
                )
                .transition(Motion.screenSwap(reduceMotion: reduceMotion))
            } else if let set = session.currentSet {
                SetScreen(
                    setStep: set,
                    progress: progressOverride ?? sessionProgress,
                    stepLabel: setLabel,
                    setsRemaining: setsRemaining,
                    reps: session.draftReps,
                    previous: session.previous,
                    isComparable: session.previousIsComparable,
                    isBeating: session.isBeatingPrevious,
                    namespace: workObject,
                    onAdjust: { session.adjustReps(by: $0) },
                    onLog: logSet,
                    onBack: { advance { session.back() } },
                    onEnd: endSession
                )
                .transition(Motion.screenSwap(reduceMotion: reduceMotion))
            } else {
                sessionEnded
            }
        }
        // The web build guards End with a confirmation and this port did not:
        // `endSession()` called `onAbandon()` straight through, so one tap of a
        // control in the corner of every workout screen discarded the whole
        // session — every logged set, silently, no undo. `04-rules.md §8` calls
        // losing a session the one unacceptable failure mode, and the acceptance
        // test for the rule is literally named "...AfterAConfirm" while its
        // comment refers to "the confirmation copy". That copy existed only in
        // the web build. Verbatim from `src/screens/Workout.tsx`.
        //
        // An `alert`, not a `confirmationDialog`. The sheet version renders on
        // iOS 26 as a translucent card floating over the exercise figure, with
        // the message in low-contrast grey over a busy background and **no
        // visible cancel** — measured on a settled frame, not guessed at. For
        // the one control that throws a session away, "how do I say no" must be
        // on screen, and the sentence explaining what you are about to lose has
        // to be readable at 6:10am.
        .alert("End this session?", isPresented: $confirmingEnd) {
            Button("End and discard", role: .destructive) { onAbandon() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Nothing will be saved — not even the sets you've already logged.")
        }
        // One sky, behind everything, for the whole session. Screens fade
        // across it; it never fades itself. This is also what makes the dawn
        // read as continuous rather than as a property of the current step.
        .background(DawnBackdrop(treatment: .atmospheric, progress: progressOverride ?? sessionProgress))
        .onAppear {
            Haptics.shared.prewarm()
            Audio.shared.isEnabled = true
            // Bring the audio session up now, not during a countdown tick.
            Audio.shared.prepare()
            // The screen must not sleep mid-set. Released on end or abandon.
            UIApplication.shared.isIdleTimerDisabled = true
            cardRests = Set(Deck.cardRestIndices(in: session.steps))
            // The session starts on step 0, the warm-up, exactly as the web
            // build does. This used to call `goToFirstSet()` and skip it,
            // deferred "until the screen exists" — see `WarmupScreen`.
            if let stepOverride {
                session.go(toStep: stepOverride)
            } else if let slotOverride {
                session.go(toSlot: slotOverride)
            } else if startAtFirstSet {
                session.goToFirstSet()
            }
            if let repsOverride {
                session.adjustReps(by: repsOverride - session.draftReps)
            }
            drawCardIfNeeded()

            // `-autoplay` advances one step after a beat, so the transition
            // itself can be captured. No tap reaches this app in the
            // development environment, and a transition nobody can trigger is
            // a transition nobody has seen.
            autorunIfAsked()

            if ProcessInfo.processInfo.arguments.contains("-confirm-end") {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.0))
                    confirmingEnd = true
                }
            }

            if ProcessInfo.processInfo.arguments.contains("-autoplay") {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.4))
                    logSet()
                }
            }

            // `-autorep` nudges the counter up one after the same beat. The
            // counter prefills to last time's number, so one step crosses it —
            // which is the moment `01-product.md` calls the emotional centre of
            // the app, and the only way to watch it happen here.
            if ProcessInfo.processInfo.arguments.contains("-autorep") {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.4))
                    // Deliberately NOT wrapped in `withAnimation`. A tap is not
                    // wrapped either — `RepControl` drives the counter and the
                    // comparison line from `.animation(_:value:)` alone. An
                    // explicit wrap here would animate the capture with a
                    // timing the product never uses, which is a harness that
                    // measures itself.
                    session.adjustReps(by: 1)
                }
            }
        }
        .onChange(of: session.stepIndex) { _, _ in
            drawCardIfNeeded()
            autorunIfAsked()

            if ProcessInfo.processInfo.arguments.contains("-confirm-end") {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.0))
                    confirmingEnd = true
                }
            }
        }
    }

    private var setLabel: String {
        guard let position = session.setPosition else { return "" }
        return "Set \(position.index) / \(position.total)"
    }

    /// The dawn walks with the session. One value drives sky, accent, progress
    /// rail and primary action, which is what makes progress legible from
    /// across the room without reading anything.
    private var sessionProgress: Double {
        guard session.steps.count > 1 else { return 0 }
        return Double(session.stepIndex) / Double(session.steps.count - 1)
    }

    private var setsRemaining: Int {
        session.steps[(session.stepIndex + 1)...].compactMap(\.asSet).count
    }

    /// Rests carry a card at the two indices the deck chose for this session.
    ///
    /// Drawn when the step CHANGES, never inside `body`. A computed property
    /// that draws on read looks tidy and is wrong twice over: SwiftUI discards
    /// state written during a view update, and a re-render would deal a second
    /// card halfway through reading the first.
    /// Logging the last set finishes the session rather than walking off the
    /// end of the step list.
    private func logSet() {
        if session.isAtEnd {
            onFinish()
        } else {
            advance { session.advance() }
        }
    }

    /// `-autorun` plays a whole session through, hands-free.
    ///
    /// Only sets need it: the warm-up and every rest now advance themselves
    /// when their clock reaches zero, which is the behaviour this flag exposed
    /// as missing in the first place. So this logs the current set after a
    /// beat and then waits for the rest to hand the next one over.
    ///
    /// It is how the app first ran start to finish. `07-acceptance.md` asks for
    /// "a full session of A and a full session of B, zero glitches", and with
    /// no Simulator UI on this machine there was otherwise no way to ask.
    private func autorunIfAsked() {
        guard ProcessInfo.processInfo.arguments.contains("-autorun"),
              session.currentSet != nil else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled, session.currentSet != nil else { return }
            logSet()
        }
    }

    /// Every step change goes through here, so the work object travels rather
    /// than the screen swapping. `Motion.stage` carries its own reduced form.
    private func advance(_ change: () -> Void) {
        withAnimation(Motion.stage(reduceMotion: reduceMotion)) {
            change()
        }
    }

    private func drawCardIfNeeded() {
        let index = session.stepIndex
        guard cardRests.contains(index), drawnCards[index] == nil else { return }
        drawnCards[index] = Deck.draw()
    }

    private func endSession() {
        confirmingEnd = true
    }

    /// The end of the session, and the only place the screen is allowed to
    /// sleep again.
    /// Nothing should reach this.
    ///
    /// It is the `else` on a `Group` that now has a branch for every step kind
    /// — timer, rest and set — and the real end of a session goes through
    /// `onFinish`, not through here. It used to read "Session complete /
    /// Summary and Daybreak are W7", and one tap of Back from the first set
    /// landed on it, because the warm-up had no branch.
    ///
    /// So it stays, deliberately blank apart from the sky, and it releases the
    /// resources rather than announcing anything. A silent screen is a bug; a
    /// screen that lies about the session being over is a worse one.
    private var sessionEnded: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // Holding the screen awake or the audio session open past the end
                // of the session is a bug the user feels as a hot phone and silent
                // headphones. This ran on the HOST for a while, which meant it
                // released both immediately on every appear — the screen would
                // have slept mid-set.
                UIApplication.shared.isIdleTimerDisabled = false
                Audio.shared.stop()
            }
    }
}
