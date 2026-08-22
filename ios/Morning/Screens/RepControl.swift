import SwiftUI

/* ===========================================================================
 *  THE REP CONTROL
 *  ---------------------------------------------------------------------------
 *  The most important control in the app, and the one `04-rules.md §1` is most
 *  specific about.
 *
 *  · It reports a DELTA, never an absolute. Two taps landing in one update
 *    cycle, both computed from the same stale value, collapse into one
 *    increment — and hold-to-repeat accelerates to a 60ms floor, so that is
 *    reachable in normal use rather than a thought experiment. The view never
 *    sees the number it is about to set; it only says "one more".
 *
 *  · The digit moves in the direction you pushed it, so a mistap is visible.
 *
 *  · Passing last time's number is THE EMOTIONAL CENTRE OF THE ENTIRE APP.
 *    It gets colour, motion and a distinct haptic — the mint is semantic and
 *    deliberately off the dawn ramp, so it can never collide with whatever the
 *    accent happens to be at that moment in the session.
 *
 *  · 82pt targets, because they are hit with a knuckle at 6:10am with sweaty
 *    hands, and a boundary you can actually see: measured as a component, the
 *    first version of this read 1.18:1 against WCAG's 3:1 while its glyph was
 *    a perfectly healthy 9.71:1. The symbol was doing all the work.
 * ======================================================================== */

/// The one object the workout carries from screen to screen.
///
/// `02-design-brief.md §7` asks for `matchedGeometryEffect` so a screen's
/// content BECOMES the next screen's rather than cross-fading, and the W1
/// prototype demonstrated it as the counter turning into the rest ring. The
/// real screens then shipped without it and swapped instantly — this is that
/// gap closed.
enum WorkObject {
    static let id = "work-object"
}

struct RepControl: View {
    let reps: Int
    let previous: History.PreviousSet?
    let isComparable: Bool
    let isBeating: Bool
    let accent: Color
    /// The work object's namespace. The counter is the thing that travels: it
    /// becomes the rest timer, and the rest timer becomes it again.
    let namespace: Namespace.ID
    /// Reports a delta. Never an absolute — see the header.
    let onAdjust: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var direction = 1

    var body: some View {
        VStack(spacing: Space.snug) {
            HStack(spacing: Space.gutter) {
                RepStepper(symbol: "−", label: "One rep fewer") { adjust(-1) }
                counter
                RepStepper(symbol: "+", label: "One rep more") { adjust(1) }
            }

            Text("Reps")
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)

            comparison
                // The counter has already changed by the time this arrives.
                // See `Motion.threshold`.
                .animation(Motion.threshold(reduceMotion: reduceMotion), value: isBeating)
        }
    }

    // MARK: - Parts

    private var counter: some View {
        Text(reps, format: .number)
            .font(TypeScale.counter())
            .monospacedDigit()
            // A three-digit count truncated to "3…" between the two 82pt
            // controls. Targets top out at 25 reps so three digits should never
            // arrive honestly — but the control reports a delta and has no
            // upper bound, so leaning on + reaches it, and a counter that
            // ELIDES its own value is the worst possible way to find that out.
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(Motion.numeric(reduceMotion: reduceMotion, countsDown: direction < 0))
            .foregroundStyle(isBeating ? Semantic.threshold : Ink.primary)
            .frame(minWidth: 150)
            .matchedGeometryEffect(id: WorkObject.id, in: namespace)
            .animation(Motion.rep(reduceMotion: reduceMotion), value: reps)
            .animation(Motion.rep(reduceMotion: reduceMotion), value: isBeating)
            .accessibilityLabel("\(reps) reps")
            .accessibilityValue(accessibilityComparison)
    }

    /// One line, and it only ever says something true.
    ///
    /// The comparable case keeps BOTH sentences in the tree and crossfades them
    /// on opacity, rather than swapping `@ViewBuilder` branches. That is not
    /// tidiness — a branch swap here does not animate. Measured off a 60fps
    /// capture, the beating sentence went 0% to 97% legible in a single frame
    /// and 0.12s BEFORE the digit began to move, with both `.transition` and a
    /// delayed `.animation(_:value:)` on it. Opacity on a view that never
    /// leaves the tree is the primitive that honours a delay reliably.
    @ViewBuilder
    private var comparison: some View {
        if let previous {
            if !isComparable {
                // Reps are only comparable at the same weight. Saying so is the
                // honest move; quietly implying a target is not.
                Text("Last time: \(previous.reps) at \(Plates.format(previous.kg ?? 0)) kg — different weight now")
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.tertiary)
            } else {
                ZStack {
                    // Equal or below, prefilled from last time: the number IS
                    // last time's number, so repeating it underneath would say
                    // it twice.
                    Text("Last time: \(previous.reps)")
                        .font(TypeScale.body)
                        .foregroundStyle(Ink.tertiary)
                        .opacity(isBeating || reps == previous.reps ? 0 : 1)

                    Text("Beating last time's \(previous.reps)")
                        .font(TypeScale.bodyEmphasis)
                        .foregroundStyle(Semantic.threshold)
                        .opacity(isBeating ? 1 : 0)
                }
            }
        } else {
            Text("First time — just go to failure")
                .font(TypeScale.body)
                .foregroundStyle(Ink.tertiary)
        }
    }

    private var accessibilityComparison: String {
        guard let previous else { return "First time on this set" }
        if !isComparable {
            return "Last time \(previous.reps), at a different weight"
        }
        return isBeating ? "Beating last time's \(previous.reps)" : "Last time \(previous.reps)"
    }

    // MARK: - Behaviour

    private func adjust(_ delta: Int) {
        let wouldCross = crosses(by: delta)
        direction = delta
        onAdjust(delta)

        // The threshold is two events 45ms apart; a rep is one. Rhythm rather
        // than volume, because that is what the hand can tell apart with the
        // phone face down on the floor.
        if wouldCross {
            Haptics.shared.threshold()
        } else {
            Haptics.shared.rep()
        }
    }

    /// True only on the tap that actually crosses last time's number — not on
    /// every tap while above it.
    private func crosses(by delta: Int) -> Bool {
        guard isComparable, let previous else { return false }
        let after = max(0, reps + delta)
        return reps <= previous.reps && after > previous.reps
    }
}

// MARK: - One stepper

private struct RepStepper: View {
    let symbol: String
    let label: String
    let action: () -> Void

    @State private var repeatTask: Task<Void, Never>?

    var body: some View {
        Text(symbol)
            .font(.system(size: 38, weight: .semibold, design: .rounded))
            .frame(width: Hit.repControl, height: Hit.repControl)
            .foregroundStyle(Ink.primary)
            .background(Control.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Control.border, lineWidth: Control.borderWidth)
            }
            .contentShape(Rectangle())
            // A DragGesture with no minimum distance rather than a Button,
            // because press-and-hold has to start repeating without waiting for
            // a tap to complete.
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in beginRepeating() }
                    .onEnded { _ in stopRepeating() }
            )
            .onDisappear(perform: stopRepeating)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: Text(label), action)
    }

    private func beginRepeating() {
        guard repeatTask == nil else { return }
        action()
        repeatTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Motion.Hold.firstDelay))
            var delay = Motion.Hold.repeatDelay
            while !Task.isCancelled {
                action()
                try? await Task.sleep(for: .milliseconds(delay))
                delay = max(Motion.Hold.floor, Int(Double(delay) * Motion.Hold.acceleration))
            }
        }
    }

    private func stopRepeating() {
        repeatTask?.cancel()
        repeatTask = nil
    }
}
