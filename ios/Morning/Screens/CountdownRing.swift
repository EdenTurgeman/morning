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
    var compact: Bool = false
    let accent: Color
    let namespace: Namespace.ID
    /// Shown under the number. "SEC" on a rest; the warm-up says what it is.
    var caption: String = "SEC"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var size: CGFloat {
        compact ? 136 : 232
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
                .stroke(Ink.hairline, lineWidth: compact ? 4 : 5)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(accent, style: StrokeStyle(lineWidth: compact ? 4 : 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.opacity(0.55), radius: 8 + urgency * 14)

            VStack(spacing: -2) {
                Text(Int(ceil(remaining)), format: .number)
                    .font(compact ? TypeScale.counterCompact : TypeScale.counter(82))
                    .monospacedDigit()
                    .contentTransition(Motion.numeric(reduceMotion: reduceMotion, countsDown: true))
                    .foregroundStyle(Ink.primary)

                Text(caption)
                    .font(TypeScale.label)
                    .tracking(1.2)
                    .foregroundStyle(Ink.secondary)
            }
        }
        .frame(width: size, height: size)
        // The counter is the source and the ring follows it, permanently.
        // Both declaring themselves the source is a conflict SwiftUI resolves
        // silently and inconsistently — it picked the counter, so Set→Rest
        // morphed and Rest→Set only cross-faded.
        .matchedGeometryEffect(id: WorkObject.id, in: namespace, isSource: false)
        .animation(Motion.timerResize(reduceMotion: reduceMotion), value: compact)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(ceil(remaining))) seconds remaining")
    }
}
