import SwiftUI

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
    @State private var session: WorkoutSession
    private let progressOverride: Double?
    /// `-slot 4.0.0` lands on one specific set. The worst content in the
    /// program is not the first set, and a screen that must never scroll has to
    /// be checked against its worst case rather than its first.
    private let slotOverride: String?

    init(sessionKey: String? = nil, progressOverride: Double? = nil, slot: String? = nil) {
        let store = Store()
        let history = store.load().history
        let key = sessionKey ?? NextSession.proposed(from: history)
        _session = State(
            initialValue: WorkoutSession(
                sessionKey: key,
                kg: store.load().loads?[key],
                history: history,
                store: store
            )
        )
        self.progressOverride = progressOverride
        slotOverride = slot
    }

    var body: some View {
        Group {
            if let set = session.currentSet {
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
                    onLog: advanceToNextSet,
                    onBack: { session.back() },
                    onEnd: { session.abandon() }
                )
            } else {
                waitingForRest
            }
        }
        .onAppear {
            Haptics.shared.prewarm()
            // Step 0 is the warm-up timer — a screen W5 owns and the brief
            // calls the least important in the app. Until it exists, start on
            // the first set rather than on a step this host cannot render.
            if let slotOverride {
                session.go(toSlot: slotOverride)
            } else if session.currentSet == nil, !session.isAtEnd {
                session.goToFirstSet()
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

    /// Until W5 builds Rest, logging a set walks past the rest to the next one
    /// rather than showing a screen that does not exist yet.
    private func advanceToNextSet() {
        session.advance()
        while session.currentSet == nil, !session.isAtEnd {
            session.advance()
        }
    }

    private var waitingForRest: some View {
        VStack(spacing: Space.step) {
            Text("Session complete")
                .font(TypeScale.title)
                .foregroundStyle(Ink.primary)
            Text("Rest, Summary and Daybreak are W5 and W7.")
                .font(TypeScale.body)
                .foregroundStyle(Ink.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DawnBackdrop(treatment: .atmospheric, progress: 1))
    }
}
