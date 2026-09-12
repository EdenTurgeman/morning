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
    /// THE FIGURE HAS SOMEWHERE TO GO.
    ///
    /// When a question opens on the Rest screen the ring leaves and a small
    /// inked badge takes over in the card's corner. What travels between them
    /// is the NUMBER — the track, the arc and the caption are drawn evidence
    /// about this ring and they do not belong on a stamp, but the figure is the
    /// fact and the fact is the same fact.
    ///
    /// The whole ring used to carry the `matchedGeometryEffect` instead, and it
    /// could not work: a circle cannot interpolate into a rectangular chip, and
    /// the id sat on a `maxHeight: .infinity` container, so the match was
    /// between a full-height band and a 54pt chip. Matching a figure to a
    /// figure is a match between two things that are actually alike.
    ///
    /// `nil` everywhere else — the warm-up's ring goes nowhere.
    var figureMatch: FigureFlight?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let minimumDiameter: CGFloat = 136
    static let maximumDiameter: CGFloat = 232
    /// The figure's point size, as a fraction of the diameter. Named because
    /// the flight has to know it to scale the figure correctly.
    static let figureFraction: CGFloat = 0.353

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
            // NO GLOW PAD, NO SHADOW, NO ROUNDED CAP.
            //
            // The glow was a RadialGradient and a coloured drop shadow — both
            // the previous world's vocabulary, and a gradient is the one thing
            // this world cannot produce. What replaced them is what a press
            // gives you: a printed track, and an arc of solid ink laid over it
            // with hard ends. Urgency is carried by the arc getting HEAVIER
            // rather than by light, because ink cannot glow.
            // THE FURNITURE LEAVES FIRST.
            //
            // Track and arc are evidence about THIS ring and they have nowhere
            // to go, so when the figure is travelling they clear out in 0.14s
            // rather than riding the same half-second spring. Filmed with them
            // on the same curve, the study card grew up over a still
            // full-strength orange circle and the whole thing read as a
            // dissolve rather than as one object moving.
            Group {
                Circle()
                    .stroke(Paper.press.opacity(0.18), lineWidth: stroke)

                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        Paper.orange,
                        style: StrokeStyle(lineWidth: stroke + urgency * 6, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }
            .modifier(FurnitureExit(travelling: figureMatch != nil))

            VStack(spacing: -2) {
                Text(Int(ceil(remaining)), format: .number)
                    .font(PaperType.counter(size * Self.figureFraction)).tracking(TypeScale.counterTracking)
                    .monospacedDigit()
                    .contentTransition(Motion.numeric(reduceMotion: reduceMotion, countsDown: true))
                    .foregroundStyle(Paper.press)
                    .modifier(MatchedFigure(match: figureMatch, from: size * Self.figureFraction))

                Text(caption)
                    .modifier(FurnitureExit(travelling: figureMatch != nil))
                    .font(TypeScale.label)
                    .tracking(1.2)
                    // Primary, not secondary. Measured on the myo rest — whose
                    // sky is the warmest and brightest the palette reaches —
                    // white at 0.78 came out at 6.15:1 against the app's 6.6:1
                    // floor. Hierarchy here is carried by size: this is 12pt
                    // under a 112pt number, and it does not need to be dimmer
                    // as well as ninety points smaller.
                    .foregroundStyle(Paper.press)
            }
        }
        .frame(width: size, height: size)
        .animation(Motion.timerResize(reduceMotion: reduceMotion), value: size)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(ceil(remaining))) seconds remaining")
    }
}

/// Where a countdown's figure is going, and how big it is when it gets there.
struct FigureFlight {
    let id: String
    let namespace: Namespace.ID
    /// The figure's point size at the OTHER end. The ring needs it to work out
    /// how far to shrink; without it the two ends are two unrelated numbers.
    let destinationSize: CGFloat
}

/// The figure travelling, or standing still.
///
/// **`properties: .position`, never the frame.** Matching frames is the obvious
/// thing to write and it is wrong here, because a matched geometry effect
/// resizes the BOX and leaves the font alone: filmed, the ring's 82pt "56" was
/// handed the badge's 54pt-wide box and rendered as `•••`, an ellipsis, for the
/// whole flight. The number turned into three dots on its way across the
/// screen.
///
/// So each end keeps its own type size and only the position is shared, and the
/// change in size is carried by `scaleEffect` — which scales the drawing rather
/// than re-running layout, which is what "the same number, smaller" actually
/// means. The scale is exact rather than eyeballed: the ring knows its own
/// figure size and is told the badge's.
/// A countdown figure that may or may not be travelling.
///
/// Internal rather than private because BOTH ends of the flight use it — the
/// ring here and the badge on the Rest screen. Two hand-written
/// `matchedGeometryEffect` calls is two places to forget the same detail, and
/// the detail they would forget is Reduce Motion.
struct MatchedFigure: ViewModifier {
    let match: FigureFlight?
    /// This end's own figure size, so the ratio can be computed.
    let from: CGFloat

    func body(content: Content) -> some View {
        if let match {
            content
                .matchedGeometryEffect(id: match.id, in: match.namespace, properties: .position)
                .transition(
                    .scale(scale: from > 0 ? match.destinationSize / from : 1)
                        .combined(with: .opacity)
                )
        } else {
            content
        }
    }
}

/// A ring's track, arc and caption, when the figure is leaving without them.
///
/// A plain `if` on a value that never changes at runtime is safe — every call
/// site either flies or does not, for the life of the view.
private struct FurnitureExit: ViewModifier {
    let travelling: Bool

    func body(content: Content) -> some View {
        if travelling {
            content.transition(.opacity.animation(.easeOut(duration: 0.14)))
        } else {
            content
        }
    }
}
