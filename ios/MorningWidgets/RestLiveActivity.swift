import ActivityKit
import SwiftUI
import WidgetKit

/* ===========================================================================
 *  THE REST TIMER ON THE LOCK SCREEN AND IN THE DYNAMIC ISLAND
 *  ---------------------------------------------------------------------------
 *  W12, asked for by Eden: the countdown visible with the app closed, and
 *  tapping it comes back.
 *
 *  THE COUNTDOWN DRAWS ITSELF. `Text(timerInterval:)` renders a live count from
 *  an end date with no updates from the app — no push, no background task, no
 *  budget. That works here only because the rest timer was already built around
 *  an absolute `endsAt` rather than a tick count, which `RestScreen`'s header
 *  argues for on completely different grounds (a phone call must not desync
 *  it). The same decision pays twice.
 *
 *  IT IS NOT THE APP. A Live Activity is glanced at from across a room, on a
 *  Lock Screen the app does not control, next to notifications from other apps.
 *  So this does not try to be the Rest screen in miniature: no sky, no ring, no
 *  study card. A number, what is next, and the app's name. The dawn belongs to
 *  the app.
 * ======================================================================== */

struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestAttributes.self) { context in
            lockScreen(context.attributes)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    countdown(context.attributes, size: 34)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.isMyo ? "MYO" : "REST")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.4)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let next = context.attributes.nextExercise {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Next")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(next)
                                .font(.subheadline.weight(.semibold))
                            if let detail = context.attributes.nextDetail {
                                Text(detail)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } compactLeading: {
                Image(systemName: "sun.horizon.fill")
                    .foregroundStyle(accent)
            } compactTrailing: {
                countdown(context.attributes, size: 15)
                    .frame(width: 44)
            } minimal: {
                countdown(context.attributes, size: 13)
                    .frame(width: 34)
            }
            .widgetURL(RestActivityLink.url)
            .keylineTint(accent)
        }
    }

    // MARK: - Parts

    /// The dawn's mid-morning accent, hardcoded.
    ///
    /// The app's palette walks with session progress, but the Lock Screen is
    /// not the app and a colour that drifts between rests would read as a bug
    /// rather than as a sunrise. One value, and it is the one the accent passes
    /// through around the middle of a session.
    private var accent: Color {
        Color(red: 0.78, green: 0.55, blue: 0.95)
    }

    private func lockScreen(_ attributes: RestAttributes) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(attributes.isMyo ? "MYO REST" : "REST")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.6)
                    .foregroundStyle(accent)

                countdown(attributes, size: 44)
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
        .widgetURL(RestActivityLink.url)
    }

    /// The system draws this, once, from the end date. Monospaced digits so it
    /// does not jitter as it counts, the same rule the app's own counters use.
    private func countdown(_ attributes: RestAttributes, size: CGFloat) -> some View {
        Text(timerInterval: Date() ... attributes.endsAt, countsDown: true)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
    }
}

@main
struct MorningWidgets: WidgetBundle {
    var body: some Widget {
        RestLiveActivity()
    }
}
