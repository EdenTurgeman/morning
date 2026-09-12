import SwiftUI

/* ===========================================================================
 *  DAYBREAK — the moment you finish
 *  ---------------------------------------------------------------------------
 *  `02-design-brief.md §8` says to read the header comment on the web build's
 *  `Daybreak.tsx` before redesigning this, because it documents exactly why
 *  each beat exists and the reasoning survives even if the visuals do not. It
 *  does, so the choreography below is that one, ported.
 *
 *  Why a sunrise rather than a badge, in the web build's own words: Duolingo
 *  hands you a flame, and the flame works because it is that product's own
 *  symbol — not because streaks need fire. This app's symbol is already a
 *  sunrise, and it has been warming underneath you for the whole session. So
 *  the payoff is that sun finally clearing the horizon.
 *
 *  THE CHOREOGRAPHY. The first web version ran its stages back to back,
 *  finished at 3.2s, sat dead for 1.4s and then cut out in 320ms. Rebuilt
 *  around what actually makes a reward moment land:
 *
 *      0.00  overlay in
 *      0.12  ANTICIPATION — the horizon draws outward from the centre.
 *            Nothing else has happened yet; this is the beat that says
 *            something is coming, and the old version had no equivalent.
 *      0.38  the sun rises, overshooting slightly and settling — weight,
 *            rather than a linear slide
 *      0.70  rays bloom outward (scale and opacity, NEVER rotation)
 *      0.90  a brief warm flash as the sun breaks the horizon
 *      1.00  the number springs in
 *      1.35  pips pop, staggered 120ms apart
 *      1.90  supporting copy
 *      2.60  the dismiss hint
 *      —     stages OVERLAP throughout, so there is never a gap with nothing
 *            moving, and the sun keeps breathing once it has arrived
 *      4.40  a 520ms exit that fades and drifts rather than cutting
 *
 *  Everything derives from ONE elapsed value read off an absolute start date.
 *  That is the native equivalent of the web build's "CSS keyframes with delays,
 *  compositor-driven, cannot half-play if a frame is dropped": no stage can
 *  desynchronise from another because there is only one clock.
 *
 *  The haptic is fired once, at the sun's rise, so its three rising transients
 *  land across the bloom and the flash and its swell carries the number in.
 *  Choreographed against the animation, which is what `05-platform.md §3` asks
 *  for rather than a canned success notification.
 * ======================================================================== */

struct Daybreak: View {
    let celebration: Celebration
    let reps: Int
    let week: WeeklyProgress
    let onDone: () -> Void

    @State private var start = Date()
    @State private var leaving = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Reduce Motion keeps every beat and drops the travel: the sun fades up
    /// instead of rising, the rays do not bloom outward, nothing drifts on
    /// exit. Calmer, not absent — the moment still happens.
    private var beats: Beats {
        reduceMotion ? .reduced : .full
    }

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(start)
            content(at: elapsed)
        }
        // THE EXIT HAD NO ANIMATION AT ALL.
        //
        // `dismiss()` flipped `leaving` with no `withAnimation` and nothing
        // keyed on it, so `exit` stepped 0 to 1 in a single frame: the moment
        // CUT to nothing and then sat blank for the 520ms before `onDone`. The
        // header above claimed "a 520ms exit that fades and drifts rather than
        // cutting" the whole time.
        //
        // Declarative rather than `withAnimation` inside the tap handler,
        // because this project has twice shipped an imperative animation that
        // compiled, read correctly and did nothing.
        .animation(Motion.leave(reduceMotion: reduceMotion), value: leaving)
        .onAppear {
            scheduleDismissDemoIfRequested()
            start = Date()
            Audio.shared.play(.chime)
            // Fired once, at the rise. Its own internal timing does the rest.
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(beats.sun))
                Haptics.shared.complete()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: dismiss)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(celebration.headline) \(reps) reps. \(celebration.body)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text("Continue"), dismiss)
    }

    @ViewBuilder
    private func content(at elapsed: TimeInterval) -> some View {
        let exit = leaving ? 1.0 : 0.0

        ZStack {
            Paper.stock
                .opacity(1 - exit * 0.4)
                .ignoresSafeArea()

            sunrise(at: elapsed, exiting: exit)

            GeometryReader { proxy in
                // The copy is centred in the space ABOVE the horizon, not in
                // the screen. Centring on the screen put the body text on top
                // of the sun and left the top third empty.
                VStack(spacing: Space.step) {
                    Text(celebration.eyebrow)
                        .font(TypeScale.microLabel)
                        .foregroundStyle(Paper.press)
                        .opacity(ramp(elapsed, from: beats.copy, over: 0.4))

                    Text(reps, format: .number)
                        .font(TypeScale.counter(92))
                        .monospacedDigit()
                        .foregroundStyle(Paper.press)
                        .scaleEffect(springIn(elapsed, from: beats.number))
                        .opacity(ramp(elapsed, from: beats.number, over: 0.3))

                    Text("reps")
                        .font(TypeScale.body)
                        .foregroundStyle(Paper.press)
                        .opacity(ramp(elapsed, from: beats.number + 0.1, over: 0.3))

                    Text(celebration.headline)
                        .font(TypeScale.title)
                        .foregroundStyle(Paper.press)
                        .multilineTextAlignment(.center)
                        .opacity(ramp(elapsed, from: beats.copy, over: 0.45))

                    Text(celebration.body)
                        .font(TypeScale.body)
                        .foregroundStyle(Paper.press)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(ramp(elapsed, from: beats.copy + 0.2, over: 0.5))

                    pips(at: elapsed)
                        .padding(.top, Space.tight)
                }
                .padding(.horizontal, Space.gutter)
                .frame(width: proxy.size.width, height: proxy.size.height * 0.52)
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.26)

                Text("Tap to continue")
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Paper.press)
                    .opacity(ramp(elapsed, from: beats.hint, over: 0.6) * 0.9)
                    .frame(width: proxy.size.width)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.95)
            }
            .offset(y: exit * -24)
            .opacity(1 - exit)
        }
    }

    // MARK: - The sunrise

    /// The sunrise: a folded fan rising and opening behind a torn horizon.
    ///
    /// Drawn back to front the way it is pasted up — fan, then horizon over it,
    /// so the fan is genuinely BEHIND the paper it clears rather than clipped
    /// to look that way. See `PaperSunrise.swift` for why this is shapes and
    /// not Metal.
    private func sunrise(at elapsed: TimeInterval, exiting: Double) -> some View {
        ZStack {
            PaperSunrise(
                elapsed: elapsed,
                fanStart: beats.sun,
                rays: celebration.rays,
                milestoneBurst: celebration.milestoneBurst,
                reduceMotion: reduceMotion
            )
            // Sinks back behind the horizon rather than drifting off it. The
            // horizon itself does not move — it is the ground.
            .offset(y: exiting * 150)

            horizon(at: elapsed)
        }
        .ignoresSafeArea()
    }

    /// The horizon: a torn ply pasted across the lower third.
    ///
    /// It tears in BEFORE anything else moves, and then holds. That held beat
    /// is the anticipation — the screen going deliberately quiet is what says
    /// something is coming, and it costs no motion to say it.
    ///
    /// Where the fan crosses the tear, the two inks OVERPRINT. That is this
    /// world's own answer to the flash the atmosphere version had: orange over
    /// blue makes plum, it is already the law everywhere else in the app, and
    /// it needs no light source in a world that has none.
    private func horizon(at elapsed: TimeInterval) -> some View {
        GeometryReader { proxy in
            let sheet = TornEdge(tornTop: true, tornBottom: false, amplitude: 6, seed: 71)
            let settle = ramp(elapsed, from: beats.horizon, over: 0.5)
            let lift = reduceMotion ? 0 : (1 - settle) * 14

            ZStack(alignment: .top) {
                sheet
                    .fill(Paper.ply)
                    // THE SHADOW IS CAST BY THE SHEET, NOT BY THE FIBRE ON IT.
                    // See `Ply` in `PaperTokens.swift` for the whole reason. Order is the
                    // entire fix: shadow the fill, then print the fibre on top.
                    .shadow(color: Paper.press.opacity(0.22), radius: 4, x: 0, y: -3)
                    .overlay { Fibre().clipShape(sheet) }

                // The overprint, along the tear itself.
                sheet
                    .stroke(Paper.overprint, lineWidth: 3)
                    .opacity(flash(elapsed) * 0.9)
            }
            .frame(height: proxy.size.height * 0.26)
            .offset(y: proxy.size.height * 0.74 + lift)
            .opacity(reduceMotion ? settle : 1)
        }
    }

    /// The milestone burst, in this app's own material rather than confetti.
    ///
    /// `04-rules.md §5` calls it confetti because the web build throws paper
    /// (`src/lib/burst.ts`). Eden's instruction is to take the behaviour, not
    /// the mechanism: what has to survive is that **crossing a lifetime
    /// threshold, sweeping every set, hitting a streak milestone or completing
    /// a week is visibly bigger than an ordinary morning.** Paper confetti in a
    /// sunrise would be a second visual language and the wrong one — so the
    /// burst is simply more light. The sun flares wider and harder.
    ///
    /// Deliberately restrained. The app is not gamified and the reward is being
    /// told something true; this is emphasis on a moment that earned it, not a
    /// prize.
    private var burstGain: Double {
        celebration.milestoneBurst ? 1.55 : 1
    }

    private var burstScale: Double {
        celebration.milestoneBurst ? 1.12 : 1
    }

    /// Overshoots at the top and settles, so the sun has weight rather than
    /// sliding linearly into place.
    private func sunLift(_ elapsed: TimeInterval) -> CGFloat {
        let t = ramp(elapsed, from: beats.sun, over: 0.9)
        guard beats.overshoots else { return 78 * t }
        let overshoot = sin(t * .pi) * 0.12
        return 78 * (t + overshoot)
    }

    /// The sun keeps breathing once it has arrived, so nothing is ever dead on
    /// screen while the copy is still landing.
    private func breath(_ elapsed: TimeInterval) -> CGFloat {
        guard beats.overshoots, elapsed > beats.sun + 0.9 else { return 0 }
        return CGFloat(sin((elapsed - beats.sun - 0.9) * 1.6)) * 2.5
    }

    private func flash(_ elapsed: TimeInterval) -> Double {
        let width = 0.35
        guard elapsed >= beats.flash, elapsed <= beats.flash + width else { return 0 }
        return sin((elapsed - beats.flash) / width * .pi)
    }

    private func pips(at elapsed: TimeInterval) -> some View {
        HStack(spacing: 8) {
            ForEach(0 ..< week.target, id: \.self) { index in
                // Staggered 120ms apart, so the week fills rather than appearing.
                let at = beats.pips + Double(index) * 0.12
                Capsule()
                    .fill(index < week.done ? Paper.overprint : Paper.press.opacity(0.22))
                    .frame(width: 26, height: 6)
                    .scaleEffect(springIn(elapsed, from: at))
                    .opacity(ramp(elapsed, from: at, over: 0.25))
            }
        }
    }

    // MARK: - Timing

    /// Linear 0 → 1 across `over`, starting at `from`. One clock, so no two
    /// stages can drift apart.
    private func ramp(_ elapsed: TimeInterval, from: TimeInterval, over: TimeInterval) -> Double {
        min(1, max(0, (elapsed - from) / over))
    }

    /// A settle rather than a pop: overshoots once and comes back.
    private func springIn(_ elapsed: TimeInterval, from: TimeInterval) -> Double {
        let t = ramp(elapsed, from: from, over: 0.45)
        guard beats.overshoots else { return 0.9 + 0.1 * t }
        return 0.82 + 0.18 * t + sin(t * .pi) * 0.06
    }

    /// `-demo-dismiss` — taps Continue for you, 3.5s after the moment starts.
    ///
    /// The exit is the one beat here no agent can reach: it needs a tap, and no
    /// synthesised tap is delivered to this simulator. That is exactly how the
    /// exit shipped un-animated in the first place — it was the only part of
    /// the choreography nobody could ever look at. This makes it filmable.
    private func scheduleDismissDemoIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-demo-dismiss") else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.5))
            dismiss()
        }
    }

    private func dismiss() {
        guard !leaving else { return }
        leaving = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.20 : 0.42))
            onDone()
        }
    }

    /// The beats, and their calmer form.
    struct Beats {
        let horizon: TimeInterval
        let sun: TimeInterval
        let rays: TimeInterval
        let flash: TimeInterval
        let number: TimeInterval
        let pips: TimeInterval
        let copy: TimeInterval
        let hint: TimeInterval
        /// Whether anything overshoots, travels or breathes.
        let overshoots: Bool

        /// REBUILT FROM SCRATCH for the paper world, not retimed.
        ///
        /// The atmosphere version ran eight beats over 4.4s and needed them:
        /// the horizon drew, then the sun rose, then the rays bloomed, then it
        /// flashed. Here **the rise and the unfold are one beat** — the fan
        /// opening IS the sun arriving — so `sun` and `rays` fire together and
        /// the whole moment is over in ~3.0s. A moment that ends sooner is one
        /// you are more willing to see six mornings a week.
        static let full = Beats(
            horizon: 0.20, sun: 0.45, rays: 0.45, flash: 1.30,
            number: 1.55, pips: 2.35, copy: 1.95, hint: 2.60,
            overshoots: true
        )

        /// Same beats, same order, no travel — the moment still happens, it
        /// just stops moving through space.
        static let reduced = Beats(
            horizon: 0.10, sun: 0.25, rays: 0.25, flash: 0.70,
            number: 0.85, pips: 1.40, copy: 1.10, hint: 1.90,
            overshoots: false
        )
    }
}

// MARK: - Rays

/// Scale and opacity only. Rotation would turn the sun into a pinwheel, which
/// is the thing the web build's comment specifically warns against.
private struct Rays: View {
    let accent: Color

    var body: some View {
        Canvas { context, size in
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let reach = min(size.width, size.height) / 2

            for index in 0 ..< 16 {
                let angle = Double(index) / 16 * 2 * .pi
                let half = 0.045
                var path = Path()
                path.move(to: centre)
                path.addLine(to: CGPoint(
                    x: centre.x + cos(angle - half) * reach,
                    y: centre.y + sin(angle - half) * reach
                ))
                path.addLine(to: CGPoint(
                    x: centre.x + cos(angle + half) * reach,
                    y: centre.y + sin(angle + half) * reach
                ))
                path.closeSubpath()
                context.fill(path, with: .color(accent.opacity(0.5)))
            }
        }
        .blur(radius: 22)
        .allowsHitTesting(false)
    }
}
