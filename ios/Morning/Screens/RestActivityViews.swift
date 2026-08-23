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

/// The dawn's mid-morning accent, hardcoded.
///
/// The app's palette walks with session progress, but the Lock Screen is not
/// the app and a colour that drifted between rests would read as a bug rather
/// than as a sunrise. One value, and it is the one the accent passes through
/// around the middle of a session.
enum RestActivityStyle {
    static let accent = Color(red: 0.78, green: 0.55, blue: 0.95)
}

/// The Lock Screen presentation.
struct RestActivityLockScreen: View {
    let attributes: RestAttributes
    /// Frozen for the preview, so a screenshot is reproducible. `nil` in the
    /// real activity, where the system draws a live countdown.
    var frozenAt: Date?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.isMyo ? "MYO REST" : "REST")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.6)
                    .foregroundStyle(RestActivityStyle.accent)

                RestActivityCountdown(attributes: attributes, size: 44, frozenAt: frozenAt)
            }

            if let next = attributes.nextExercise {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Next")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(next)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let detail = attributes.nextDetail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
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
        .font(.system(size: size, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.primary)
    }

    /// `src/lib/format.ts`'s shape: bare seconds under a minute, `m:ss` above.
    static func clock(_ remaining: TimeInterval) -> String {
        let whole = Int(ceil(max(0, remaining)))
        return whole < 60 ? "\(whole)" : "\(whole / 60):\(String(format: "%02d", whole % 60))"
    }
}
