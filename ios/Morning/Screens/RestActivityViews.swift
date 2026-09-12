import SwiftUI

/* ===========================================================================
 *  WHAT THE LIVE ACTIVITY LOOKS LIKE
 *  ---------------------------------------------------------------------------
 *  Split out of `RestLiveActivity.swift` so it can be compiled into the APP as
 *  well as the extension, and therefore looked at.
 *
 *  That is the whole reason this file exists. There is no `Simulator.app` on
 *  the development machine, so the app cannot be backgrounded and the Lock
 *  Screen cannot be reached — which made the one part of W12 with a visual
 *  design the one part nobody could see. A `Widget` cannot be rendered from the
 *  app (its `@main` bundle belongs to the extension), but a `View` can, so the
 *  views move here and the configuration stays there.
 *
 *      -screen live-activity     the Lock Screen presentation, at app size
 *
 *  It is not a substitute for the phone: the real thing is composited by the
 *  system, tinted by it, and sits at a size this preview only approximates.
 *  It is the difference between a layout nobody has ever seen and one that has
 *  at least been measured.
 *
 *  IT IS NOT THE APP. A Live Activity is glanced at from across a room, on a
 *  Lock Screen the app does not control, next to notifications from other apps.
 *  So no sky, no ring, no study card — a number, what is next, and nothing
 *  else. The dawn belongs to the app.
 * ======================================================================== */

/// The paper world's inks, mirrored for the widget target.
///
/// **This is a deliberate copy, not an oversight.** `MorningWidgets` contains
/// exactly three files and cannot see `PaperTokens.swift`; pulling the token
/// files into the extension would drag `DesignTokens` and a dead dawn palette
/// in with them. The file has always kept its own constant for this reason —
/// the old comment here explained the same thing about the dawn accent.
///
/// The copy is safe because it is ASSERTED: `testLiveActivityInksMatchPaper`
/// fails the build the day these drift from `Paper`. Duplication that a test
/// pins is a different thing from duplication that hopes.
///
/// **The Lock Screen only.** See `RestLiveActivity` — the Dynamic Island is a
/// black pill the system owns, and paper ink on it would be invisible.
enum RestActivityStyle {
    /// Mirrors `Paper.stock`.
    static let stock = Color(red: 0.788, green: 0.749, blue: 0.675)
    /// Mirrors `Paper.press`.
    static let press = Color(red: 0.180, green: 0.169, blue: 0.149)
    /// Mirrors `Paper.orange`. A MARK, never a glyph.
    static let orange = Color(red: 0.878, green: 0.322, blue: 0.110)
    /// Mirrors `Paper.overprint`. The myo rest, which IS the training stimulus.
    static let overprint = Color(red: 0.340, green: 0.130, blue: 0.170)
}

/// The Lock Screen presentation.
struct RestActivityLockScreen: View {
    let attributes: RestAttributes
    /// Frozen for the preview, so a screenshot is reproducible. `nil` in the
    /// real activity, where the system draws a live countdown.
    var frozenAt: Date?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // The app's signature mark, and the only orange on the slip.
            // Orange lights and never writes — the same law as every other
            // surface — so it appears here as a rule and not as a label.
            Rectangle()
                .fill(RestActivityStyle.orange)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.isMyo ? "MYO REST" : "REST")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.6)
                    // The myo rest IS the training stimulus, so it gets the
                    // overprint — the same ink `RestScreen` uses for the same
                    // sentence, and the only one here that reads urgent while
                    // still clearing the floor as text.
                    .foregroundStyle(attributes.isMyo
                        ? RestActivityStyle.overprint
                        : RestActivityStyle.press)

                RestActivityCountdown(attributes: attributes, size: 44, frozenAt: frozenAt)
            }

            if let next = attributes.nextExercise {
                // Press black throughout. The system's `.secondary` and
                // `.tertiary` adapt to the SYSTEM's appearance, not to the
                // paper tint underneath them, so on this slip they were a
                // guess. Hierarchy is size and weight here, which is the Ink
                // doctrine's rule anyway: a level recedes by getting smaller or
                // lighter in weight, never by going more transparent.
                VStack(alignment: .leading, spacing: 1) {
                    Text("Next")
                        .font(.caption2)
                    Text(next)
                        .font(.subheadline.weight(.semibold))
                    if let detail = attributes.nextDetail {
                        Text(detail)
                            .font(.caption2)
                    }
                }
                .foregroundStyle(RestActivityStyle.press)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.trailing, 18)
        .padding(.vertical, 14)
        .foregroundStyle(RestActivityStyle.press)
    }
}

/// The number. The system draws it from the end date, once, with no updates.
///
/// Monospaced digits so it does not jitter as it counts — the same rule every
/// counter in the app follows, and it matters more here because the Dynamic
/// Island's compact slot is a fixed 44pt and a proportional digit would make
/// the whole island twitch.
struct RestActivityCountdown: View {
    let attributes: RestAttributes
    let size: CGFloat
    var frozenAt: Date?

    var body: some View {
        Group {
            if let frozenAt {
                Text(Self.clock(attributes.endsAt.timeIntervalSince(frozenAt)))
            } else {
                Text(timerInterval: Date() ... attributes.endsAt, countsDown: true)
            }
        }
        // `.black`, and NOT `.rounded`. The paper world's display voice is a
        // grotesque at poster weight; a rounded cut belongs to the world this
        // replaced. `design:` is omitted rather than set, so the Dynamic
        // Island — which is not paper — still gets the system face.
        .font(.system(size: size, weight: .black))
        .monospacedDigit()
    }

    /// `src/lib/format.ts`'s shape: bare seconds under a minute, `m:ss` above.
    static func clock(_ remaining: TimeInterval) -> String {
        let whole = Int(ceil(max(0, remaining)))
        return whole < 60 ? "\(whole)" : "\(whole / 60):\(String(format: "%02d", whole % 60))"
    }
}
