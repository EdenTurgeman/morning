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

/* ---------------------------------------------------------------------------
 *  THE WORK OBJECT, REMOVED
 *  ---------------------------------------------------------------------------
 *  There used to be a `matchedGeometryEffect` here with the id "work-object":
 *  the counter was the permanent source and the rest ring followed it, so the
 *  timer grew out of the number you had just logged and shrank back into the
 *  next one. `02-design-brief.md §7` asks for exactly that, and the W1
 *  direction prototype demonstrated it.
 *
 *  It is gone because Eden asked for it gone, twice, having watched it on the
 *  phone: *"the rep number animates wildly on screen load"*, then *"once you
 *  enter an exercise screen, the middle rep number animates jumps a little,
 *  there's absolutly no reason for that. let's kill that."*
 *
 *  He is describing it accurately. Traced across a 30fps capture of a rest
 *  ending: at 22.99s the digit sits high and right where the ring's number was,
 *  at 23.09s it is low and LEFT of the counter's slot, and it only settles at
 *  23.16s. Two hundred milliseconds of a large number sliding diagonally across
 *  the screen, at the exact moment you look down to read what to do next.
 *
 *  The idea reads better in a prototype than it does at 6:10am. Restoring it
 *  means putting `.matchedGeometryEffect(id:in:)` back on `counter` and
 *  `.matchedGeometryEffect(id:in:isSource: false)` back on `CountdownRing`,
 *  with a `@Namespace` on `WorkoutHost` — but ask him first.
 * ------------------------------------------------------------------------- */

struct RepControl: View {
    let reps: Int
    let previous: History.PreviousSet?
    let isComparable: Bool
    let isBeating: Bool
    let accent: Color
    /// Identifies the set on screen. Changes exactly when the step does.
    ///
    /// It exists to tell the two reasons the number can change apart. See the
    /// `transaction` on `counter`.
    var stepKey: String = ""
    /// Reports a delta. Never an absolute — see the header.
    let onAdjust: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var direction = 1

    /// ONE HEIGHT, ALWAYS.
    ///
    /// W15 #2 asked for the counter to stop moving between exercises, and the
    /// screen above this now hands it whatever space is left over — which only
    /// pins it if this control is the same height every time. It was not: the
    /// comparison line wraps to two lines when the weight has changed ("Last
    /// time: 12 at 6.25 kg — different weight now") and to one when it has not,
    /// so the counter sat 19pt higher on some sets than others.
    static let height: CGFloat = 150

    var body: some View {
        VStack(spacing: Space.snug) {
            // The three parts are ONE control, and they have to look like it.
            //
            // W15 #11: *"its sizing and spacing from the + and - buttons are
            // terrible"*. They were 22pt apart with a 150pt counter slot
            // between them, which put each 82pt button hard against the screen
            // gutter and left ~40pt of nothing on either side of the digits —
            // two big empty boxes with a small number stranded between them.
            //
            // Closer together, and the number is bigger than the buttons now
            // rather than smaller. The slot is a FIXED width, not a minimum, so
            // going from 9 reps to 10 cannot shove the buttons outwards.
            HStack(spacing: Space.step) {
                RepStepper(symbol: "−", label: "One rep fewer") { adjust(-1) }

                // The caption belongs to the number, not to the row. Nine
                // points under the digits instead of under the whole cluster.
                VStack(spacing: -4) {
                    counter
                    Text("Reps")
                        .font(TypeScale.microLabel)
                        .foregroundStyle(Ink.tertiary)
                }

                RepStepper(symbol: "+", label: "One rep more") { adjust(1) }
            }

            comparison
                // One line, whatever it says. See `height`.
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(height: 20)
                // The counter has already changed by the time this arrives.
                // See `Motion.threshold`.
                .animation(Motion.threshold(reduceMotion: reduceMotion), value: isBeating)
        }
        .frame(height: Self.height)
    }

    // MARK: - Parts

    private var counter: some View {
        Text(reps, format: .number)
            .font(TypeScale.counter(104))
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
            .animation(Motion.rep(reduceMotion: reduceMotion), value: reps)
            .animation(Motion.rep(reduceMotion: reduceMotion), value: isBeating)
            // A NEW SET IS A NEW NUMBER, not a change to the old one.
            //
            // Identity, because nothing weaker works here. The first attempt
            // was `.transaction(value: stepKey) { $0.animation = nil }` on the
            // outside of this chain, and a filmstrip off a 60fps capture shows
            // it doing nothing: at 5.48s the digits are still cross-dissolving
            // 24 into 22 across a step change. `.animation(_:value:)` sets the
            // animation for everything below it and an outer transaction
            // cannot reach past it.
            //
            // Moving the animation to the tap site would work and would break
            // something else — `-autorep` drives the counter without
            // `withAnimation` precisely so the harness animates the way the
            // product does, and its comment says so.
            //
            // So the digit gets a new identity per set. `contentTransition`
            // interpolates between two values of ONE view; two views do not
            // interpolate at all. `.identity` because the default for an
            // identity change is a cross-fade, and a fade is a quieter version
            // of the same wrong idea.
            .transition(.identity)
            .id(stepKey)
            .frame(width: 138)
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
        //
        // And a tone, which was missing. `04-rules.md §1` is explicit that
        // passing last time's number is the emotional centre and to "give it
        // everything: haptic detent, colour, motion, sound" — the port had
        // three of the four. `Cue.beatIt` was composed, tested, and never
        // played; `src/components/RepDial.tsx` fires its equivalent right here.
        if wouldCross {
            Haptics.shared.threshold()
            Audio.shared.play(.beatIt)
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
