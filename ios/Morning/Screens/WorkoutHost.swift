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

    /// "End" discards the whole session, so it asks first. See `endSession`.
    ///
    /// `-confirm-end` opens it shortly after launch. A confirmation dialog
    /// nobody can reach is a confirmation dialog nobody has read, and no tap
    /// reaches this app in the development environment. Deferred rather than
    /// set as the initial value: a dialog raised during the first render, before
    /// the view is in a window, is simply dropped.
    @State private var confirmingEnd = false
    /// The rest steps that carry a card, IN ORDER.
    ///
    /// An array rather than a `Set` because the ORDER is now load-bearing: the
    /// first card of a session and the second are asked for different things —
    /// see `Deck.intent(forCardNumber:)` — and a set has no first.
    @State private var cardRests: [Int] = []
    @State private var drawnCards: [Int: Card] = [:]

    /// The session belongs to whoever started it — `AppRoot` in the app, or a
    /// launch argument in review. The host only renders it and reports back.
    let onFinish: () -> Void
    let onAbandon: () -> Void

    init(
        session: WorkoutSession,
        // NO DEFAULTS. They are what let `ReviewHost` omit both for several
        // workstreams, which meant "End and discard" ran an empty closure and
        // did nothing — and nothing on screen could show it, because a callback
        // that is not wired looks exactly like one that is. Eden found it by
        // tapping the button.
        //
        // Required parameters make that a compile error instead.
        onFinish: @escaping () -> Void,
        onAbandon: @escaping () -> Void,
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
        // THE GROUND IS A SIBLING, NOT A BACKGROUND.
        //
        // `.paperGround()` used to sit on the `Group` below, which put the
        // stock and its halftone INSIDE the subtree the step transition fades.
        // So every Set → Rest → Set swap washed the whole screen to white for
        // about 0.1s. Measured on a 60fps capture of a myo rest running out:
        // mean luma **185 → 241 → 184**, and the frame at the peak shows the
        // Rest screen's ring, its copy and its buttons all ghosted on bare
        // white with not a halftone dot left.
        //
        // That is the failure `01-motion-doctrine.md` §3.1 names, in this
        // world's colours instead of the old one's: *"Fading the sky
        // per-screen measured 50 → 7 → 40 mean luma: a blackout between two
        // screens. Hoisted it is 50 → 22 → 40, a breath. Do not un-hoist it."*
        // The sky is gone and the stock inherited its job, and it inherited
        // this trap with it.
        //
        // A `ZStack` sibling cannot be faded by a transition on its siblings.
        // The screens now genuinely cross over the ground rather than taking it
        // with them.
        ZStack {
            Paper.stock
                .overlay(Halftone())
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // HOISTED, for exactly the reason the ground above it is.
                //
                // It was rendered inside all three screens, so the rail, the
                // set marks, BACK and END were destroyed and rebuilt on every
                // swap — 28 times a session — even though they are the same
                // component with near-identical content on both sides.
                //
                // And because the chrome was the only thing that could have
                // stayed on screen through the transition's gap, its absence
                // is what made a step change read as the whole screen
                // repainting. Measured before this, on a Set → Rest at 60fps:
                // **220ms at 0.00% ink coverage** — no rail, no ring, no text,
                // bare stock. `plans/006` scored the same swap as mean luma
                // 185 → 188 → 185 and passed it, because on a light ground the
                // entire content vanishing moves the mean by three points.
                // Mean luma cannot see a blank screen here.
                //
                // The comment at the foot of this ZStack has claimed since W5
                // that the chrome "is owned by the host… it must not blink when
                // Set becomes Rest". It was a true statement of intent and a
                // false statement about the code. See `plans/011`.
                WorkoutChrome(
                    progress: progressOverride ?? sessionProgress,
                    step: chromeLabel,
                    setMarks: setMarks,
                    onBack: { advance { session.back() } },
                    onEnd: endSession
                )
                .padding(.horizontal, Space.gutter)

                Group {
                    if case let .timer(timer) = session.currentStep, let endsAt = session.endsAt {
                        WarmupScreen(
                            step: timer,
                            endsAt: endsAt,
                            onDone: { advance { session.advance() } }
                        )
                        .transition(Motion.screenSwap(reduceMotion: reduceMotion))
                    } else if case let .rest(rest) = session.currentStep, let endsAt = session.endsAt {
                        RestScreen(
                            seconds: rest.seconds,
                            endsAt: endsAt,
                            next: session.upcomingSet,
                            card: drawnCards[session.stepIndex],
                            restIndex: session.stepIndex,
                            isMyo: rest.seconds < Deck.minimumRestForCard,
                            onExtend: { session.extendRest(by: 15) },
                            onSkip: { advance { session.skipRest() } },
                            onComplete: { advance { session.skipRest() } }
                        )
                        .transition(Motion.screenSwap(reduceMotion: reduceMotion))
                    } else if let set = session.currentSet {
                        SetScreen(
                            setStep: set,
                            stepLabel: setLabel,
                            reps: session.draftReps,
                            previous: session.previous,
                            isComparable: session.previousIsComparable,
                            isBeating: session.isBeatingPrevious,
                            subDisambiguates: repeatedExercises.contains(set.exercise),
                            onAdjust: { session.adjustReps(by: $0) },
                            onLog: logSet
                        )
                        // ONE STEP, ONE IDENTITY.
                        //
                        // Superset partners are adjacent `.set` steps —
                        // `Steps.swift`: *"Partners run back to back; rest
                        // comes only after the round."* Both land in this
                        // branch, so without an explicit identity SwiftUI
                        // updates the same view in place and `.transition`
                        // never fires: tapping `Done` inside a superset
                        // animated nothing at all.
                        //
                        // That is the exact failure `01-motion-doctrine.md`
                        // §3.1 says this transition exists to prevent — *"a
                        // user who taps Done with a knuckle, not looking, has
                        // no way to tell whether the tap registered"* — going
                        // unserved in the one place two near-identical set
                        // screens follow each other. See `plans/012`.
                        .id(session.stepIndex)
                        .transition(Motion.screenSwap(reduceMotion: reduceMotion))
                    } else {
                        sessionEnded
                    }
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
            // THE ONE DESTRUCTIVE ACTION IN THE APP, AND IT WAS ONE TAP.
            //
            // A system `.alert` put "End and discard" beside "Keep going" at
            // equal weight, and `04-rules.md §1` is that ending throws away
            // every set already logged. `01-motion-doctrine.md` §3.2 rules this
            // row asymmetric and names hold-to-confirm as appropriate; see
            // `EndSessionConfirm` for what that costs and why.
            //
            // Inside the ZStack rather than as a `.sheet` or `.alert`, so it
            // lays over the workout instead of replacing it — he can still see
            // the session he is deciding about.
            .overlay {
                if confirmingEnd {
                    EndSessionConfirm(
                        onEnd: onAbandon,
                        onKeepGoing: { confirmingEnd = false }
                    )
                    .transition(.opacity)
                }
            }
            .animation(Motion.reveal(reduceMotion: reduceMotion), value: confirmingEnd)
            // One sky, behind everything, for the whole session. Screens fade
            // across it; it never fades itself. This is also what makes the dawn
            // read as continuous rather than as a property of the current step.
            // THE SKY IS GONE. `DawnBackdrop` walked the real phases of a dawn as
            // the session ran, and that is the load-bearing idea this world had to
            // replace rather than delete: progress legible from across the room
            // without reading anything. The answer here is the STEP BLOCK in the
            // chrome — every set printed, inked as it is finished — which is a
            // discrete count you can read at 1.5m instead of a colour you have to
            // interpret. It is owned by the host for the same reason the sky was:
            // it must not blink when Set becomes Rest.
        }
        .onAppear {
            Haptics.shared.prewarm()
            Audio.shared.isEnabled = true
            // Bring the audio session up now, not during a countdown tick.
            Audio.shared.prepare()
            // The screen must not sleep mid-set. Released on end or abandon.
            UIApplication.shared.isIdleTimerDisabled = true
            cardRests = Deck.cardRestIndices(in: session.steps)
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
            crossingDemoIfAsked()

            // `-autoplay` advances one step after a beat, so the transition
            // itself can be captured. No tap reaches this app in the
            // development environment, and a transition nobody can trigger is
            // a transition nobody has seen.
            autorunIfAsked()
            syncLiveActivity()

            // `-autoabandon` fires what the "End and discard" button fires.
            //
            // The tap itself cannot be synthesised here, but the wiring behind
            // it can be — and the wiring is what was broken: `ReviewHost` never
            // passed `onAbandon`, so the button reached a `= {}` default and
            // did nothing. Reasoning about a closure is not the same as running
            // it.
            if ProcessInfo.processInfo.arguments.contains("-autoabandon") {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2.0))
                    onAbandon()
                }
            }

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
        }
        // Keyed on `endsAt`, not on the step. `+15s` moves the end date without
        // changing the step, and the Lock Screen countdown is drawn from that
        // date — so an extension has to restart the activity or the phone keeps
        // counting down to the old zero.
        .onChange(of: session.endsAt) { _, _ in
            syncLiveActivity()
        }
    }

    /// The chrome's centre, for whichever step is current.
    ///
    /// The warm-up's is blank on purpose, and that ruling comes from the call
    /// site this replaced: its own headline directly beneath already says
    /// "Warm-up", and saying it twice 40pt apart is not orientation.
    private var chromeLabel: String {
        switch session.currentStep {
        case .timer: ""
        case .rest: "Rest"
        case .set: setLabel
        // Past the last step. The chrome stays on screen through the end of
        // the session rather than blinking out one step early.
        case nil: ""
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

    /// Exercises that appear in more than one block of this session.
    ///
    /// Session B has a lateral raise in the superset and another as the myo
    /// block, and with the sub-label dropped from the header they were two
    /// identical screens. See `SetScreen.factLine`.
    private var repeatedExercises: Set<String> {
        var counts: [String: Int] = [:]
        var seen: Set<String> = []
        for step in session.steps {
            guard let set = step.asSet else { continue }
            // Per BLOCK, not per set: three sets of one exercise are not a
            // repeat of anything.
            let block = set.slot.split(separator: ".").first.map(String.init) ?? set.slot
            guard seen.insert("\(block)|\(set.exercise)").inserted else { continue }
            counts[set.exercise, default: 0] += 1
        }
        return Set(counts.filter { $0.value > 1 }.keys)
    }

    /// Every set's position in the session, 0…1, for the rail's ticks.
    private var setMarks: [Double] {
        guard session.steps.count > 1 else { return [] }
        let last = Double(session.steps.count - 1)
        return session.steps.enumerated()
            .filter { $0.element.asSet != nil }
            .map { Double($0.offset) / last }
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

        // `-card <id>` forces one specific card, for review.
        //
        // `Deck.draw()` is random by design, so a question card appears in a
        // screenshot only by luck — and a study QUESTION has states a factoid
        // does not (unanswered, right, wrong) that all have to be looked at.
        // Same reason `-tier` and `-demo-crossing` exist: a state nobody can
        // reach is a state nobody has checked.
        if let forced = ProcessInfo.processInfo.arguments.firstIndex(of: "-card"),
           ProcessInfo.processInfo.arguments.indices.contains(forced + 1),
           let card = Cards.all.first(where: { $0.id == ProcessInfo.processInfo.arguments[forced + 1] })
        {
            drawnCards[index] = card
            return
        }

        // WHICH card of the session this is, which is what decides what it is
        // for: the first opens the deck up, the second brings back something
        // he got wrong. `firstIndex` rather than a counter, so a rest revisited
        // by going Back asks for the same kind of card it asked for before.
        drawnCards[index] = Deck.draw(
            preferring: Deck.intent(forCardNumber: cardRests.firstIndex(of: index) ?? 0)
        )
    }

    /// `-demo-crossing` — pushes the counter past last time's number a beat
    /// after arrival, so the crossing can be FILMED.
    ///
    /// This hook existed only in `PrototypeSetVariants`, which is a DIFFERENT
    /// layout with its own crossing — so the one that actually ships had no way
    /// to be looked at, and it was designed, then redesigned twice, entirely on
    /// Eden's report of a phone rather than on a rendered frame. A state nobody
    /// can reach is a state nobody has checked, which is the same reason
    /// `-tier`, `-card` and `-autoplay` exist.
    ///
    /// It drives the real `adjustReps`, so what gets filmed is the app's own
    /// state change and not a puppet of one.
    private func crossingDemoIfAsked() {
        guard ProcessInfo.processInfo.arguments.contains("-demo-crossing"),
              let previous = session.previous,
              session.previousIsComparable
        else {
            return
        }
        session.adjustReps(by: previous.reps - session.draftReps)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            session.adjustReps(by: 1)
        }
    }

    private func endSession() {
        confirmingEnd = true
    }

    /// The Lock Screen countdown follows the rest, and only the rest.
    ///
    /// W12, and Eden's words: "show even if my app is closed... i can re-open
    /// the app from that". Started on arriving at a rest and ended on leaving
    /// one, which covers skipping, extending, finishing and abandoning, because
    /// all four move either the step or the end date.
    private func syncLiveActivity() {
        guard case let .rest(rest) = session.currentStep, let endsAt = session.endsAt else {
            RestActivityController.shared.end()
            return
        }
        RestActivityController.shared.start(rest: rest, endsAt: endsAt, next: session.upcomingSet)
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
