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
    /// weight now. Last time: 12 at 6.25 kg") and to one when it has not,
    /// so the counter sat 19pt higher on some sets than others.
    /// Raised from 150 when the counter went to bib scale. At 118pt the
    /// digits plus the caption plus the comparison line exceeded 150 and the
    /// COMPARISON was what got clipped — which is last time's number, the one
    /// thing `spec.md` §3.3 says must be beside the counter always. A fixed
    /// height is still what keeps the control on the same line on every
    /// exercise; it just has to be the right fixed height.
    ///
    /// 164 since the counter came down from 118pt to 100pt. The comparison line
    /// is what gets clipped when this is too small — last time's number, which
    /// `spec.md` §3.3 says must always sit beside the counter — so if you
    /// change the counter size, re-shoot `-reps 12` and confirm the line is
    /// still drawn before believing it fits.
    static let height: CGFloat = 164

    var body: some View {
        // ONE SHARED CENTRE LINE, and even rows beneath it.
        //
        // The old layout put "Reps" inside the counter's own VStack, so the
        // NUMBER AND ITS CAPTION centred as a pair against the keys — which
        // left the numeral itself sitting high and nothing on the control
        // sharing a centre with anything else. Eden: *"ugly not symmetric and
        // weirdly spaced."*
        //
        // Now the numeral and the two keys are one row on one centre line, and
        // the caption and the comparison are their own rows under it with
        // explicit heights, so the vertical rhythm is stated rather than
        // emergent.
        VStack(spacing: Space.tight) {
            // THE COUNTERWEIGHT, and it is not padding for its own sake.
            //
            // `comparison` keeps its 22pt row even when it is hidden — at
            // `reps == previous.reps` the line is deliberately invisible, and
            // the row has to stay reserved or the sheet would RESIZE the moment
            // you cross, which is a layout jump on the most important event in
            // the app. The cost is 22pt of empty paper at the bottom with
            // nothing balancing it at the top, which is exactly what read as
            // "not symmetric".
            //
            // So the top gets the same weight back. This balances the RESTING
            // state, which is what is on screen almost all of the time, and the
            // crossing no longer changes the sheet at all — see `crossingRule`
            // — so the balance holds in both states rather than only in one.
            Color.clear.frame(height: 20)

            HStack(spacing: Space.step) {
                RepStepper(symbol: "−", label: "One rep fewer", ink: Paper.press) { adjust(-1) }

                // FLEXIBLE, not a fixed slot. The keys are pinned to the row's
                // ends, so the number is centred between them by construction
                // and going from 9 reps to 10 cannot shove anything — which is
                // what the old fixed 150pt slot was for, achieved without the
                // asymmetry a fixed slot leaves when the row is wider than the
                // parts.
                counter
                    .frame(maxWidth: .infinity)

                RepStepper(symbol: "+", label: "One rep more", ink: Paper.press) { adjust(1) }
            }
            .frame(height: 96)
            // UNDER THE NUMBER, and it costs the layout nothing.
            //
            // An overlay on a row that is already a fixed 96pt, so the mark
            // cannot move the counter, the caption or the comparison line — and
            // this control's whole reason for a fixed height is that nothing
            // here is allowed to shift between sets.
            .overlay(alignment: .bottom) { crossingRule }

            Text("Reps")
                .font(TypeScale.microLabel)
                .foregroundStyle(Paper.press)
                .frame(height: 18)

            comparison
                // One line, whatever it says. See `height`.
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(height: 22)
                // The counter has already changed by the time this arrives.
                // See `Motion.threshold`.
                .animation(Motion.threshold(reduceMotion: reduceMotion), value: isBeating)
        }
        .frame(height: Self.height)
        // EVEN ON ALL FOUR SIDES. It was horizontal-only, so the sheet extended
        // 12pt past the content at the sides and 0pt top and bottom — which is
        // most of why the block read as cramped and off.
        .padding(Space.step)
        .background { ply }
    }

    /// THE CROSSING: A MARK UNDER THE NUMBER, NOT A NEW CARD.
    ///
    /// This existed only in `PrototypeR4Worlds.swift` — the direction Eden
    /// chose was built, screenshotted, approved, and then the port kept the
    /// colours and dropped the motion. What shipped was a plain foreground
    /// swap on the digit, on the moment `spec.md` calls the emotional centre of
    /// the whole product and `01-motion-doctrine.md` §1.1 singles out as the
    /// one event that earns the best motion in the workout loop.
    ///
    /// It then spent two rounds being the wrong thing loudly. It FLOODED the
    /// whole ply — first in `Paper.overprint`, a plum, then in press black —
    /// with the figure and both keys knocked out of it. Eden on the plum:
    /// *"it doesn't look good and positive for raising the amount of reps, it
    /// really doesn't fit the app's theme."* Eden on the black: *"i don't like
    /// the grey we picked… or we can rethink the ux of repainting the entire
    /// card for something else that's pretty and motivating."*
    ///
    /// **Repainting the card was the mistake, and it was the mistake both
    /// times.** A colour that survives being poured over the most important
    /// number in the app, at 6:10am, while keeping the number legible, is
    /// necessarily a dark one — and dark is the opposite of what beating last
    /// week's number means. Every candidate for the flood failed for the same
    /// reason, so the flood was the thing to drop.
    ///
    /// So: **the sheet stays paper, and the number gets a mark.** A bar of
    /// orange ink rolls in under the figure, left to right, the direction a
    /// roller travels.
    ///
    /// Orange is not a new colour here and it is not a breach of the ink law —
    /// it is the law working. `Ink`'s rule is that orange is a MARK and never a
    /// glyph, because it measures 2.14:1 as text. It is also already this
    /// world's word for a good morning: the cue bullets, the compact timer's
    /// rule, and the whole sunrise the session ends on.
    ///
    /// **Measured on the frame, 2.48:1 against the ply** — and measured is the
    /// operative word. Calculated from the tokens it comes out at 3.12:1, which
    /// would have cleared WCAG 1.4.11's 3:1 for a graphical object and would
    /// have been wrong: `PaperGround` lays a halftone over every surface, so the
    /// rendered ply is darker than `Paper.ply` and every ratio derived from the
    /// token is optimistic. `02-design-brief.md` says to measure rendered
    /// frames for exactly this reason.
    ///
    /// 2.48:1 is under the 3:1 floor and it stays, on the narrow ground the
    /// floor is written for: 1.4.11 covers objects **required to understand the
    /// content**, and nothing here is. The figure states the number at 11.35:1
    /// and the line under it says "Beating last time's 14" in words. The rule is
    /// emphasis on a fact already given twice. It is also the strongest orange
    /// mark in the app by some margin — the cue bullets on this same sheet
    /// measure 1.38:1 — so it is not a new licence, it is the existing one used
    /// better.
    ///
    /// What it buys beyond looking right:
    ///
    /// · The figure stays press black on ply at **11.35:1** in both states. It
    ///   used to invert to near-white, which is why `onPly` existed and why
    ///   `RepStepper` needed a paragraph about its border vanishing.
    /// · Nothing on the sheet changes colour, so nothing can lose contrast.
    /// · It is two cheap layers — a fill and a scaled rectangle — against a
    ///   masked torn-edge flood.
    ///
    /// `Motion.threshold` carries the two-beat timing and its own reduced form.
    /// Neither is re-derived here.
    private var crossingRule: some View {
        // SCALED, NOT RESIZED — and no `GeometryReader`.
        //
        // The flood this replaces animated `frame(width:)` inside a mask, so
        // every frame of the most important animation in the app ran a layout
        // pass and re-masked a torn-edge fill. Eden: *"i click the button, it is
        // stuck for a moment then does it choppily."*
        //
        // `scaleEffect` is a transform: no layout, no re-mask, GPU. It is the
        // third time this exact swap has been the fix here — the Ledger's first
        // rule and `EndSessionConfirm`'s hold bar were the other two.
        // **Animating a width in this codebase is a bug.**
        Rectangle()
            .fill(Paper.orange)
            // As wide as the counter's own slot, so the mark belongs to the
            // number rather than to the card.
            .frame(width: 138, height: 9)
            .scaleEffect(x: isBeating ? 1 : 0, y: 1, anchor: .leading)
            .animation(Motion.threshold(reduceMotion: reduceMotion), value: isBeating)
            .accessibilityHidden(true)
    }

    /// The sheet the counter is pasted on. It does not change.
    private var ply: some View {
        let sheet = TornEdge(tornTop: true, tornBottom: true, seed: 29)
        return sheet
            .fill(Paper.ply)
            // Shadow on the fill, fibre over the top — see `Ply`.
            .shadow(color: Paper.press.opacity(0.22), radius: 3, x: 0, y: 2)
            .overlay { Fibre().clipShape(sheet) }
    }

    // MARK: - Parts

    private var counter: some View {
        Text(reps, format: .number)
            .font(PaperType.counter(88)).tracking(TypeScale.counterTracking)
            .monospacedDigit()
            // A three-digit count truncated to "3…" between the two 82pt
            // controls. Targets top out at 25 reps so three digits should never
            // arrive honestly — but the control reports a delta and has no
            // upper bound, so leaning on + reaches it, and a counter that
            // ELIDES its own value is the worst possible way to find that out.
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(Motion.numeric(reduceMotion: reduceMotion, countsDown: direction < 0))
            .foregroundStyle(Paper.press)
            .animation(Motion.rep(reduceMotion: reduceMotion), value: reps)
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
                Text("Different weight now. Last time: \(previous.reps) at \(Plates.format(previous.kg ?? 0)) kg")
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press)
            } else {
                ZStack {
                    // Equal or below, prefilled from last time: the number IS
                    // last time's number, so repeating it underneath would say
                    // it twice.
                    Text("Last time: \(previous.reps)")
                        .font(TypeScale.body)
                        .foregroundStyle(Paper.press)
                        .opacity(isBeating || reps == previous.reps ? 0 : 1)

                    Text("Beating last time's \(previous.reps)")
                        .font(TypeScale.bodyEmphasis)
                        // Printed, not knocked out. There is no flood to knock
                        // it out of any more, and press on ply is 11.35:1.
                        .foregroundStyle(Paper.press)
                        .opacity(isBeating ? 1 : 0)
                }
            }
        } else {
            Text("First time here. Go to failure")
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
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
    /// The ink the key is drawn in. Press black, always.
    ///
    /// It used to invert, because the crossing flooded the sheet under it and
    /// press black on that flood measured ~1.06:1 — the key's boundary simply
    /// vanished, under WCAG 1.4.11's 3:1, on the control you hit with a knuckle.
    /// The crossing is a mark under the number now and floods nothing, so the
    /// key keeps its ink and this parameter is a constant at both call sites.
    /// It stays a parameter because a stepper has no business knowing which
    /// sheet it is printed on.
    let ink: Color
    let action: () -> Void

    @State private var repeatTask: Task<Void, Never>?
    /// THE MOST-TAPPED CONTROL IN THE APP HAD NO PRESS STATE.
    ///
    /// This is a `Text` with a `DragGesture` rather than a `Button` — press-and-
    /// hold has to start repeating without waiting for a tap to complete — and
    /// the cost of that, unnoticed until now, is that **no `ButtonStyle` ever
    /// reaches it.** Every press treatment in `PaperTokens` applied to
    /// everything except the one control hit twenty-eight times a session with
    /// a knuckle. So the gesture drives the state itself.
    @State private var pressed = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(symbol)
            // A printed key: square, hard-edged, 2.5pt of press black.
            // Nothing in this world is a rounded translucent capsule, and the
            // boundary carries far more than WCAG 1.4.11's 3:1 — the first
            // Atmospheric rep control measured 1.18:1 and had no shape at all.
            .font(.system(size: 38, weight: .black))
            .foregroundStyle(pressed ? Paper.stock : ink)
            // THE DRAWN BOX IS SMALLER THAN THE TOUCH TARGET, deliberately.
            //
            // `01-product.md`'s ≥78pt floor is about what your knuckle has to
            // HIT at 6:10am, not about how much ink the key spends. The box is
            // 66pt and the target is still `Hit.repControl` — the padding below
            // is inside the tap area — so the control gives the sheet room to
            // breathe without losing a single point of hittability.
            //
            // Do not "tidy" this by collapsing the two frames into one. The gap
            // between them IS the feature.
            .frame(width: 66, height: 66)
            .background(pressed ? ink : Color.clear)
            .overlay {
                Rectangle().stroke(ink, lineWidth: 2.5)
            }
            .scaleEffect(pressed ? 0.97 : 1)
            .animation(Motion.press(reduceMotion: reduceMotion), value: pressed)
            .frame(width: Hit.repControl, height: Hit.repControl)
            .contentShape(Rectangle())
            // A DragGesture with no minimum distance rather than a Button,
            // because press-and-hold has to start repeating without waiting for
            // a tap to complete.
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        pressed = true
                        beginRepeating()
                    }
                    .onEnded { _ in
                        pressed = false
                        stopRepeating()
                    }
            )
            .onDisappear {
                pressed = false
                stopRepeating()
            }
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
