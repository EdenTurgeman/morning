import SwiftUI

/* ===========================================================================
 *  THE COUNTDOWN
 *  ---------------------------------------------------------------------------
 *  One ring, used by every timed step.
 *
 *  W15 #5. Eden, on the warm-up: *"doesn't have the same countdown as other
 *  screens"*. It did not — the rest showed this ring and the warm-up showed
 *  bare `m:ss` text, so the two screens that both count down looked like they
 *  came from different apps. This lived as a `private struct` inside
 *  `RestScreen`, which is why the warm-up grew its own.
 *
 *  It carries the urgency ramp, the glow, the numeric roll and the work object's
 *  namespace, so a screen that adopts it gets all of that rather than a subset
 *  somebody remembered to copy.
 * ======================================================================== */

struct CountdownRing: View {
    let remaining: TimeInterval
    let total: Double
    /// An explicit diameter, when the caller has measured the space.
    ///
    /// It replaced a `compact: Bool` that switched between 232pt and 136pt.
    /// Eden, on the revealed state: *"when we show the answer for a question in
    /// the rest timer you can see we can enlarge the timer, it's a bit too
    /// small"* — and he is right, because the flag was answering the wrong
    /// question. It asked "has the answer appeared", when what matters is "how
    /// much room is there", and after the ring was re-centred in a flexible
    /// band those stopped being the same thing: on a 16 Pro there was ~140pt
    /// going spare above a ring that had shrunk to its floor.
    ///
    /// So the caller measures and this fills what it is given, between a floor
    /// where the digits stop being readable from 1.5m and a ceiling where the
    /// ring would start competing with the screen.
    var diameter: CGFloat?
    let accent: Color
    /// Shown under the number. "SEC" on a rest; the warm-up says what it is.
    var caption: String = "SEC"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let minimumDiameter: CGFloat = 136
    static let maximumDiameter: CGFloat = 232

    private var size: CGFloat {
        guard let diameter else { return Self.maximumDiameter }
        return min(Self.maximumDiameter, max(Self.minimumDiameter, diameter))
    }

    /// Everything inside scales with the ring, so there is one number to change
    /// and no combination of diameter and type size that was never looked at.
    private var stroke: CGFloat {
        size < 170 ? 4 : 5
    }

    private var fraction: Double {
        total > 0 ? min(1, max(0, remaining / total)) : 0
    }

    /// 0 until five seconds remain, then ramps to 1 at zero.
    ///
    /// Ported from `src/components/Ring.tsx`, which calls it what it is:
    /// peripheral warning. The phone is on the floor 1.5m away and you are not
    /// necessarily reading the digits — the ring getting hot is the part you
    /// catch out of the corner of your eye. The port had the audio ramp and the
    /// haptic ramp and no visual one at all.
    private var urgency: Double {
        remaining <= 5 ? 1 - max(0, remaining) / 5 : 0
    }

    var body: some View {
        ZStack {
            // The glow pad behind the ring. Same 0.20→0.65 range as the web.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent, accent.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.70
                    )
                )
                .opacity(0.20 + urgency * 0.45)
                .blur(radius: 12)

            Circle()
                .stroke(Ink.hairline, lineWidth: stroke)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(accent, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.opacity(0.55), radius: 8 + urgency * 14)

            VStack(spacing: -2) {
                Text(Int(ceil(remaining)), format: .number)
                    .font(TypeScale.counter(size * 0.353))
                    .monospacedDigit()
                    .contentTransition(Motion.numeric(reduceMotion: reduceMotion, countsDown: true))
                    .foregroundStyle(Ink.primary)

                Text(caption)
                    .font(TypeScale.label)
                    .tracking(1.2)
                    // Primary, not secondary. Measured on the myo rest — whose
                    // sky is the warmest and brightest the palette reaches —
                    // white at 0.78 came out at 6.15:1 against the app's 6.6:1
                    // floor. Hierarchy here is carried by size: this is 12pt
                    // under a 112pt number, and it does not need to be dimmer
                    // as well as ninety points smaller.
                    .foregroundStyle(Ink.primary)
            }
        }
        .frame(width: size, height: size)
        .animation(Motion.timerResize(reduceMotion: reduceMotion), value: size)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(ceil(remaining))) seconds remaining")
    }
}
