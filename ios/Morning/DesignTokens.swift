import SwiftUI

// ---------------------------------------------------------------------------
//  THE DESIGN SYSTEM — colour, ink, type, space
//
//  Deliverable 4 of `ios-port/02-design-brief.md §11`, for the agreed direction:
//  Atmospheric Dawn. `ios/Docs/design-system.md` is the prose; this file is the
//  same decisions as code, so a screen never reaches for a literal.
//
//  Every contrast figure quoted here was MEASURED on rendered simulator frames
//  across the whole progress range, not calculated from declared alphas. The
//  harness snaps to the glyph rows before sampling, because a hand-placed band
//  drifts onto a gradient and reports a number for the wrong thing.
// ---------------------------------------------------------------------------

// MARK: - The dawn ramp

/// The app's entire colour is a function of one number: how far through the
/// session you are. It walks a real dawn, astronomical twilight to sunrise.
///
/// The five stops are hand-picked from the phases of a dawn, not generated —
/// `src/lib/sunrise.ts` puts it plainly: *"a formula gave an even ramp; it did
/// not give a sunrise."* They are ported as sRGB because the perceptual
/// interpolation now happens in `Color.mix(in: .perceptual)`, which is the
/// native equivalent of the web build's OKLCH walk.
struct DawnPalette {
    let progress: Double

    private var clamped: Double {
        min(1, max(0, progress))
    }

    /// The live accent. Progress bar, timer ring, primary fill, horizon light.
    var accent: Color {
        interpolate(stops: Self.stops)
    }

    /// The accent, lifted for use as **text**.
    ///
    /// The ramp's values are picked to be a light source. Used as small glyphs
    /// on a lit background its darker end measures 4.59:1 — barely over AA and
    /// well under this app's 6.6:1 tertiary bar. Lifted 42% toward white it
    /// reads 7.37:1 at twilight and 8.75:1 at gold, and still unmistakably
    /// belongs to the accent family.
    ///
    /// **Rule: the raw `accent` fills and lights. `accentText` writes.**
    var accentText: Color {
        accent.mix(with: .white, by: 0.42, in: .perceptual)
    }

    /// The accent, lifted for use as a FILL THAT CARRIES A LABEL.
    ///
    /// Same problem as `accentText`, from the other side. Black on the raw
    /// accent measures 5.84:1 at twilight on the Set screen and 5.99:1 on Home,
    /// which sits at the ramp's dark end permanently rather than passing
    /// through it. Both were about to be written down as "documented
    /// exceptions"; a 12% lift clears the floor at every progress instead, and
    /// is invisible at the gold end.
    ///
    /// So the rule has three parts, not two: the raw `accent` LIGHTS,
    /// `accentText` WRITES, and `accentFill` CARRIES A LABEL.
    var accentFill: Color {
        accent.mix(with: .white, by: 0.12, in: .perceptual)
    }

    /// The top of the sky. Deliberately NOT the accent hue: Rayleigh scattering
    /// is wavelength-dependent, so a real zenith stays deep blue even at the
    /// height of a sunrise. A sky that takes the accent everywhere reads as a
    /// coloured wash rather than as sky.
    var zenith: Color {
        Color(
            red: 0.015 + clamped * 0.025,
            green: 0.02 + clamped * 0.018,
            blue: 0.055 + clamped * 0.018
        )
    }

    var middle: Color {
        accent.opacity(0.35)
    }

    var horizon: Color {
        accent
    }

    static let stops: [(Double, Color)] = [
        (0.00, Color(red: 0x6F / 255.0, green: 0x80 / 255.0, blue: 0xE0 / 255.0)), // astronomical twilight
        (0.26, Color(red: 0xA9 / 255.0, green: 0x74 / 255.0, blue: 0xE3 / 255.0)), // nautical — violet
        (0.50, Color(red: 0xED / 255.0, green: 0x6B / 255.0, blue: 0xAF / 255.0)), // civil — the rose band
        (0.74, Color(red: 0xFF / 255.0, green: 0x82 / 255.0, blue: 0x71 / 255.0)), // first light — coral
        (1.00, Color(red: 0xFF / 255.0, green: 0xB4 / 255.0, blue: 0x40 / 255.0)), // sunrise — gold
    ]

    private func interpolate(stops: [(Double, Color)]) -> Color {
        for index in 1 ..< stops.count where clamped <= stops[index].0 {
            let lower = stops[index - 1]
            let upper = stops[index]
            let local = (clamped - lower.0) / (upper.0 - lower.0)
            return lower.1.mix(with: upper.1, by: local, in: .perceptual)
        }
        return stops.last?.1 ?? .white
    }
}

// MARK: - Ink

/// Text levels, with the contrast each one holds against the Atmospheric sky.
///
/// `02-design-brief.md §6` sets the bar: *"The current palette holds 18:1 /
/// 10:1 / 6.6:1 for its three text levels — match or beat that."*
///
/// R2, 2026-08-25 — RAISED, because the figure that used to sit here was no
/// longer true. It read "19.05:1 / 9.87:1 / 7.00:1 at its weakest", and the
/// Rest screen's next-up meta line measured **6.18:1 at progress 1.00**: under
/// the floor, on a rendered frame, for the whole life of the gold end of every
/// session. It passes at twilight (8.46:1), which is why nobody saw it. Third
/// time this project has recorded a documented measurement that quietly stopped
/// being true — re-measure, do not inherit.
///
/// The repair was not available at the old values, and that is the interesting
/// part. `secondary` 0.78 and `tertiary` 0.72 sat six points apart, so there
/// was no room to lift tertiary off the floor without it colliding with
/// secondary. A hierarchy compressed that tight has no repair strategy; the
/// spacing between the levels is what buys you the ability to fix one of them.
enum Ink {
    /// Exercise name, rep count, timer. The one thing you must read at 1.5m.
    static let primary = Color.white

    /// Sub-label, load, set position, cue text.
    static let secondary = Color.white.opacity(0.88)

    /// `Reps`, `MOVEMENT`, the footer, next-exercise meta.
    ///
    /// 0.78, and the floor is what sets it. 0.62 was tried and delivered
    /// 5.98:1; 0.72 held everywhere it was measured and then failed at 6.18:1
    /// on the one zone that had never been measured at the gold end.
    ///
    /// Note what this level is NOT allowed to become: a way to make text quiet.
    /// It is the floor-pinned level, and `apple-design` §15 is explicit that
    /// hierarchy is built from weight, size and leading as a set — not from
    /// alpha alone. If a label needs to recede further than this, it recedes by
    /// getting smaller or lighter in weight, never by going more transparent.
    static let tertiary = Color.white.opacity(0.78)

    /// Non-text furniture only — hairlines, inactive rails. Never glyphs.
    static let hairline = Color.white.opacity(0.13)

    /// A label sitting on a filled accent control. Full black, not 82% —
    /// measured, that difference is 5.76:1 against 6.98:1.
    static let onAccent = Color.black
}

// MARK: - Semantic colour

/// Kept deliberately **off** the dawn ramp, per `§6`, so they can never collide
/// with whatever the accent happens to be at that moment in the session.
enum Semantic {
    /// Passing last time's number — the emotional centre of the app. Mint reads
    /// as "changed state" even at 2m, where the words beside it have already
    /// gone soft, which is the correct order for this to degrade in.
    ///
    /// Lifted slightly from the first value (0.20/0.83/0.60): as a 92pt numeral
    /// that measured 6.03:1, which is comfortably fine for text that size but
    /// under this app's own floor. Ten percent more luminance clears it without
    /// the colour becoming anything other than mint — better than carrying a
    /// second documented exception.
    static let threshold = Color(red: 0.35, green: 0.88, blue: 0.68)

    /// The 20-second myo rest, which *is* the training stimulus. Amber says
    /// urgency without saying failure.
    static let urgency = Color(red: 1.00, green: 0.76, blue: 0.34)

    /// Destructive, and "you have no copy of this".
    ///
    /// `02-design-brief.md §6` asks for semantic colours for success **and
    /// destruction** kept off the accent ramp. Success had a token; destruction
    /// did not, so `HistoryScreen` carried this exact value inline for its
    /// delete control and the Backup screen had nothing to say "never backed
    /// up" with. One definition, two uses.
    static let danger = Color(red: 0.94, green: 0.38, blue: 0.38)

    /// The same red, as a GLYPH.
    ///
    /// Exactly the split the dawn palette already makes between `accent` and
    /// `accentText`, and for the same measured reason. `danger` on the sky
    /// comes out at **4.27:1** — fine for a 1.5pt rule or a filled icon, under
    /// this app's 6.6:1 text floor and under WCAG AA's 4.5:1 for ordinary text.
    /// Lifted toward white it clears both without stopping being red.
    static let dangerText = Color(red: 0.94, green: 0.38, blue: 0.38)
        .mix(with: .white, by: 0.34, in: .perceptual)
}

// MARK: - Surfaces

enum Surface {
    /// Behind the sky, and the base of any non-workout screen.
    static let night = Color(red: 0.012, green: 0.018, blue: 0.050)

    /// Near-black, faintly blue. Pure black flattens the night out of the sky.
    static let ink = Color(red: 0.016, green: 0.020, blue: 0.039)

    /// The lab's own chrome. Not part of the product surface.
    static let labChrome = Color(red: 0.025, green: 0.030, blue: 0.065)
}

// MARK: - Type

/// Workout screens use fixed sizes on purpose. `§6`: they are already at the
/// top of the scale, and Dynamic Type there would break a layout that must
/// never scroll. Reading screens — Guide, cards, History — support the
/// accessibility sizes instead.
enum TypeScale {
    /// The rep counter and the rest timer. The number you read from 1.5m.
    static func counter(_ size: CGFloat = 92) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    /// The compact timer, once a study card has taken half the screen.
    static let counterCompact = Font.system(size: 64, weight: .bold, design: .rounded)

    /// Exercise name.
    static let title = Font.system(size: 34, weight: .medium)

    /// Sub-label and cue text.
    // W15 #4. Eden, after using it: "Some of the texts are a little small,
    // should be a tad bigger."
    //
    // One step each: `subheadline` (15pt) → `callout` (16pt), `caption2` (11pt)
    // → `caption` (12pt). Both are still text styles, so they still scale with
    // Dynamic Type; this moves the floor, not the mechanism.
    //
    // W14 round three withdrew a finding that looked like this one, because it
    // had been derived from measured band heights and band height does not tell
    // you font size. That withdrawal was right about the measurement and it is
    // not evidence about the type — he is reading it on a phone at arm's length
    // and I was reading pixel counts.
    static let body = Font.callout
    static let bodyEmphasis = Font.callout.weight(.semibold)

    /// Study-card question.
    static let question = Font.system(size: 17, weight: .semibold)
    /// 15, not 14.5. A half-point size is not a decision anyone made — it is a
    /// value that was nudged until it looked about right, which is the exact
    /// thing `apple-design` §16 Craft says a token may not be. SF ships optical
    /// sizing and tracking tables at whole points; asking it for 14.5 opts out
    /// of them to buy nothing.
    static let answer = Font.system(size: 15)

    /// Chrome and footers. Sentence-case, read as text.
    static let label = Font.caption.weight(.semibold)

    /// Units and all-caps micro-labels — `SEC`, `MOVEMENT`, `TARGET`.
    ///
    /// This was byte-identical to `label` — two names for one value, which
    /// means one of them was going to be different and never became different.
    ///
    /// It is different now, and `apple-design` §15 says how: **tracking is
    /// size-specific and a fixed letter-spacing is wrong somewhere.** Small
    /// text wants slightly positive tracking to stay legible, and all-caps
    /// wants more of it again, because caps have no ascender/descender rhythm
    /// to separate them. This is the level that is always small and usually
    /// caps, so it is the level that takes the tracking.
    ///
    /// Apply as `.font(TypeScale.microLabel).tracking(TypeScale.microTracking)`.
    static let microLabel = Font.caption.weight(.semibold)
    static let microTracking: CGFloat = 0.6

    /// Large display type wants NEGATIVE tracking — letters read too far apart
    /// as they grow (`apple-design` §15). The counter is 92pt; at that size the
    /// default spacing is visibly loose.
    static let counterTracking: CGFloat = -1.5
    static let titleTracking: CGFloat = -0.4

    /// The primary action.
    static let action = Font.headline
}

// MARK: - Space and hit targets

enum Space {
    static let hairline: CGFloat = 1
    static let tight: CGFloat = 4
    static let snug: CGFloat = 9
    static let step: CGFloat = 12
    static let gutter: CGFloat = 22
    static let section: CGFloat = 30
}

/// Two hard minimums from `01-product.md`, both about sweaty hands at 6:10am.
enum Hit {
    /// Primary actions. The brief's floor is 64pt; the primary action is 68.
    static let primary: CGFloat = 68

    /// Rep controls get more, because they are hit with a knuckle.
    ///
    /// **The floor is 78 and it is not a guideline** — `01-product.md`, sweaty
    /// hands at 6:10am. These were 82; they are 80 so the control block sits
    /// more comfortably on its ply. That leaves 2pt of margin above the floor,
    /// which is nearly all of it: there is no more room here, and the next
    /// person who wants this block smaller has to take it out of the counter,
    /// not out of the target.
    static let repControl: CGFloat = 80

    /// Everything else that can be tapped, including Back and End.
    static let minimum: CGFloat = 64
}

// MARK: - Controls

/// Control surfaces and the boundary that makes them findable.
///
/// WCAG 2.1 SC 1.4.11 asks for **3:1 on the boundary of a UI component**, and
/// the first Atmospheric rep control measured **1.18:1** — a `white 0.07` fill
/// behind a `white 0.1` hairline, over a lit sky. Its glyph was fine at 9.71:1,
/// so the symbol was doing all the work and the button had no shape at all.
///
/// That matters more here than the number suggests. This is the control a
/// half-awake person hits with a knuckle from a metre away, and the 82pt target
/// is worth nothing if you cannot see where it is. Measured again with these
/// values, the boundary reads 4.5:1 while the surface stays quiet enough not to
/// compete with the counter — which is the actual design goal, and was never
/// "make it invisible".
enum Control {
    /// Quiet enough to sit under a 92pt counter without competing with it.
    static let surface = Color.white.opacity(0.10)

    /// The edge that makes the target findable. Carries the boundary contrast.
    static let border = Color.white.opacity(0.44)
    static let borderWidth: CGFloat = 1.5

    /// A control that is deliberately subordinate — `+15s` next to `Skip`.
    static let quietBorder = Color.white.opacity(0.30)
}

// MARK: - The legibility scrim

/// The sky gets bright enough near the bottom to swallow secondary text. This
/// sits BEHIND content, so it lowers background luminance without touching the
/// glyphs — which is what makes it buy contrast rather than cost it.
///
/// It scales with progress because the sky it holds back does. A fixed scrim
/// that cleared the bar at twilight let cue text, `Reps` and the footer fall to
/// 6.2–6.5:1 by the time the palette reached gold.
enum Scrim {
    static func atmospheric(progress: Double) -> [Gradient.Stop] {
        let ramp = min(1, max(0, progress))
        return [
            .init(color: Surface.ink.opacity(0.30), location: 0),
            .init(color: Surface.ink.opacity(0.14 + 0.04 * ramp), location: 0.38),
            .init(color: Surface.ink.opacity(0.20 + 0.08 * ramp), location: 0.58),
            .init(color: Surface.ink.opacity(0.48 + 0.08 * ramp), location: 0.78),
            .init(color: Surface.ink.opacity(0.64 + 0.07 * ramp), location: 1),
        ]
    }

    /// Precise and Tactile are frozen W1 comparison treatments. They carry far
    /// less light, so they keep the gentler original shape.
    static let comparison: [Gradient.Stop] = [
        .init(color: Surface.ink.opacity(0.36), location: 0),
        .init(color: Surface.ink.opacity(0.16), location: 0.42),
        .init(color: Surface.ink.opacity(0.10), location: 0.62),
        .init(color: Surface.ink.opacity(0.38), location: 1),
    ]
}

/// Fills the screen when the content fits and scrolls when it does not.
///
/// The reading screens are not inside a workout, so unlike Set and Rest they
/// may scroll — but a screen that scrolls when it does not need to is a screen
/// whose primary action can be dragged out of reach for no reason.
///
/// Both halves are load-bearing and both were found the same way. Home needed
/// the scroll on a 375x667 SE, where the session panel pushed the title off the
/// top and the History/All time/Guide/Backup row off the bottom — losing the
/// only route into four screens. Backup needed it at accessibility text sizes,
/// where a plain `VStack` overflowed in BOTH directions and printed "Never
/// backed up." underneath the Dynamic Island.
struct FillOrScroll: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            ScrollView {
                content
                    .frame(minHeight: proxy.size.height, alignment: .topLeading)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
