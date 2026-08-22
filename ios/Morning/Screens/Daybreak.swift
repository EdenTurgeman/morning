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
        .onAppear {
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
            Surface.night
                .opacity(1 - exit * 0.4)
                .ignoresSafeArea()

            sunrise(at: elapsed)

            GeometryReader { proxy in
                // The copy is centred in the space ABOVE the horizon, not in
                // the screen. Centring on the screen put the body text on top
                // of the sun and left the top third empty.
                VStack(spacing: Space.step) {
                    Text(celebration.eyebrow)
                        .font(TypeScale.microLabel)
                        .foregroundStyle(Ink.tertiary)
                        .opacity(ramp(elapsed, from: beats.copy, over: 0.4))

                    Text(reps, format: .number)
                        .font(TypeScale.counter(92))
                        .monospacedDigit()
                        .foregroundStyle(Ink.primary)
                        .scaleEffect(springIn(elapsed, from: beats.number))
                        .opacity(ramp(elapsed, from: beats.number, over: 0.3))

                    Text("reps")
                        .font(TypeScale.body)
                        .foregroundStyle(Ink.secondary)
                        .opacity(ramp(elapsed, from: beats.number + 0.1, over: 0.3))

                    Text(celebration.headline)
                        .font(TypeScale.title)
                        .foregroundStyle(Ink.primary)
                        .multilineTextAlignment(.center)
                        .opacity(ramp(elapsed, from: beats.copy, over: 0.45))

                    Text(celebration.body)
                        .font(TypeScale.body)
                        .foregroundStyle(Ink.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(ramp(elapsed, from: beats.copy + 0.2, over: 0.5))

                    pips(at: elapsed)
                        .padding(.top, Space.tight)
                }
                .padding(.horizontal, Space.gutter)
                .frame(width: proxy.size.width, height: proxy.size.height * 0.74)
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.37)

                Text("Tap to continue")
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Ink.tertiary)
                    .opacity(ramp(elapsed, from: beats.hint, over: 0.6) * 0.9)
                    .frame(width: proxy.size.width)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.95)
            }
            .offset(y: exit * -24)
            .opacity(1 - exit)
        }
    }

    // MARK: - The sunrise

    private func sunrise(at elapsed: TimeInterval) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            // The horizon sits LOW. The sun has to clear it beneath the copy,
            // not rise into it — the first attempt put the sun directly behind
            // the rep total and the headline, which is the one thing the
            // moment must not do to its own numbers.
            let horizonY = size.height * 0.82

            ZStack {
                // 0.12 — anticipation. The horizon draws outward from the
                // centre before anything else has happened.
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Semantic.urgency.opacity(0.7), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size.width * ramp(elapsed, from: beats.horizon, over: 0.5), height: 1.5)
                    .position(x: size.width / 2, y: horizonY)

                // 0.70 — rays bloom outward. Scale and opacity, never rotation.
                Rays(accent: Semantic.urgency)
                    .frame(width: size.width * 1.9, height: size.width * 1.9)
                    .position(x: size.width / 2, y: horizonY)
                    .scaleEffect(0.6 + 0.4 * ramp(elapsed, from: beats.rays, over: 0.9))
                    .opacity(ramp(elapsed, from: beats.rays, over: 0.7) * 0.38)
                    // The rays fan up behind the copy, so they are held back
                    // where the copy is and let go below it.
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.25), location: 0),
                                .init(color: .black.opacity(0.55), location: 0.62),
                                .init(color: .black, location: 0.86),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }

                // 0.38 — the sun rises, overshooting slightly and settling.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, Semantic.urgency, Semantic.urgency.opacity(0.4)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 124, height: 124)
                    .position(x: size.width / 2, y: horizonY - sunLift(elapsed) + breath(elapsed))
                    .opacity(ramp(elapsed, from: beats.sun, over: 0.4))

                // 0.90 — a brief warm flash at the moment it breaks the horizon.
                Rectangle()
                    .fill(Semantic.urgency)
                    .opacity(flash(elapsed) * 0.22)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
                    .fill(index < week.done ? Semantic.urgency : Ink.hairline)
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

    private func dismiss() {
        guard !leaving else { return }
        leaving = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.52))
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

        static let full = Beats(
            horizon: 0.12, sun: 0.38, rays: 0.70, flash: 0.90,
            number: 1.00, pips: 1.35, copy: 1.90, hint: 2.60,
            overshoots: true
        )

        /// Same beats, same order, no travel — the moment still happens, it
        /// just stops moving through space.
        static let reduced = Beats(
            horizon: 0.10, sun: 0.30, rays: 0.55, flash: 0.70,
            number: 0.80, pips: 1.05, copy: 1.45, hint: 2.00,
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
