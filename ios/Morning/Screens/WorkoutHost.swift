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
        step: Int? = nil
    ) {
        _session = State(initialValue: session)
        self.onFinish = onFinish
        self.onAbandon = onAbandon
        self.progressOverride = progressOverride
        slotOverride = slot
        repsOverride = reps
        stepOverride = step
    }

    var body: some View {
        Group {
            if case let .rest(rest) = session.currentStep, let endsAt = session.endsAt {
                RestScreen(
                    seconds: rest.seconds,
                    endsAt: endsAt,
                    progress: progressOverride ?? sessionProgress,
                    stepLabel: "Rest",
                    next: session.upcomingSet,
                    card: drawnCards[session.stepIndex],
                    isMyo: rest.seconds < Deck.minimumRestForCard,
                    onExtend: { session.extendRest(by: 15) },
                    onSkip: { session.skipRest() },
                    onBack: { session.back() },
                    onEnd: endSession
                )
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
                    onAdjust: { session.adjustReps(by: $0) },
                    onLog: logSet,
                    onBack: { session.back() },
                    onEnd: endSession
                )
            } else {
                sessionEnded
            }
        }
        .onAppear {
            Haptics.shared.prewarm()
            Audio.shared.isEnabled = true
            // The screen must not sleep mid-set. Released on end or abandon.
            UIApplication.shared.isIdleTimerDisabled = true
            cardRests = Set(Deck.cardRestIndices(in: session.steps))
            // Step 0 is the warm-up timer — a screen W5 owns and the brief
            // calls the least important in the app. Until it exists, start on
            // the first set rather than on a step this host cannot render.
            if let stepOverride {
                session.go(toStep: stepOverride)
            } else if let slotOverride {
                session.go(toSlot: slotOverride)
            } else if session.currentSet == nil, !session.isAtEnd {
                session.goToFirstSet()
            }
            if let repsOverride {
                session.adjustReps(by: repsOverride - session.draftReps)
            }
            drawCardIfNeeded()
        }
        .onChange(of: session.stepIndex) { _, _ in
            drawCardIfNeeded()
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
            session.advance()
        }
    }

    private func drawCardIfNeeded() {
        let index = session.stepIndex
        guard cardRests.contains(index), drawnCards[index] == nil else { return }
        drawnCards[index] = Deck.draw()
    }

    private func endSession() {
        onAbandon()
    }

    private var sessionEnded: some View {
        VStack(spacing: Space.step) {
            Text("Session complete")
                .font(TypeScale.title)
                .foregroundStyle(Ink.primary)
            Text("Summary and Daybreak are W7.")
                .font(TypeScale.body)
                .foregroundStyle(Ink.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DawnBackdrop(treatment: .atmospheric, progress: 1))
        .onAppear {
            // The screen may sleep again, and the music may come back. Holding
            // either past the end of the session is a bug the user feels as a
            // hot phone and silent headphones.
            UIApplication.shared.isIdleTimerDisabled = false
            Audio.shared.stop()
        }
    }
}
