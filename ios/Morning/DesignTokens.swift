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
/// 10:1 / 6.6:1 for its three text levels — match or beat that."* Measured
/// across progress 0.00 → 1.00, this system holds **19.05:1 / 9.87:1 / 7.00:1**
/// at its weakest.
enum Ink {
    /// Exercise name, rep count, timer. The one thing you must read at 1.5m.
    /// Measured 19.05:1.
    static let primary = Color.white

    /// Sub-label, load, set position, cue text. Measured 9.87–11.45:1.
    static let secondary = Color.white.opacity(0.78)

    /// `Reps`, `MOVEMENT`, the footer, next-exercise meta.
    ///
    /// 0.72, not 0.62. The first value here was written down from the
    /// prototype's *measured* results without checking what the prototype was
    /// actually using — its labels were at 0.72 and had never been switched to
    /// the token. Built on the real screen, 0.62 delivered 5.98:1 against a
    /// 6.6:1 floor. A token that does not deliver the number recorded beside it
    /// is worse than no token.
    static let tertiary = Color.white.opacity(0.72)

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
    static let threshold = Color(red: 0.20, green: 0.83, blue: 0.60)

    /// The 20-second myo rest, which *is* the training stimulus. Amber says
    /// urgency without saying failure.
    static let urgency = Color(red: 1.00, green: 0.76, blue: 0.34)
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
    static let body = Font.subheadline
    static let bodyEmphasis = Font.subheadline.weight(.semibold)

    /// Study-card question.
    static let question = Font.system(size: 17, weight: .semibold)
    static let answer = Font.system(size: 14.5)

    /// Chrome, footers, units.
    static let label = Font.caption.weight(.semibold)
    static let microLabel = Font.caption2.weight(.semibold)

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

    /// Rep controls get more, because they are hit with a knuckle. Floor 78pt;
    /// these are 82.
    static let repControl: CGFloat = 82

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
