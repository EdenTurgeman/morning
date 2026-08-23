import ActivityKit
import SwiftUI
import WidgetKit

/* ===========================================================================
 *  THE WIDGET CONFIGURATION
 *  ---------------------------------------------------------------------------
 *  W12, asked for by Eden: the rest countdown visible with the app closed, and
 *  tapping it comes back.
 *
 *  Only the configuration lives here. The views are in
 *  `Morning/Screens/RestActivityViews.swift`, compiled into both targets, so
 *  the app can render them for review — a `Widget` cannot be shown from the
 *  app, but a `View` can, and otherwise the one part of this workstream with a
 *  visual design would be the one part nobody could look at.
 *
 *  THE COUNTDOWN DRAWS ITSELF. `Text(timerInterval:)` renders a live count from
 *  an end date with no updates from the app — no push, no background task, no
 *  budget. That works only because the rest timer was already built around an
 *  absolute `endsAt` rather than a tick count, which `RestScreen`'s header
 *  argues for on entirely different grounds. The same decision pays twice.
 * ======================================================================== */

struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestAttributes.self) { context in
            RestActivityLockScreen(attributes: context.attributes)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(RestActivityLink.url)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RestActivityCountdown(attributes: context.attributes, size: 34)
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
                    .foregroundStyle(RestActivityStyle.accent)
            } compactTrailing: {
                RestActivityCountdown(attributes: context.attributes, size: 15)
                    .frame(width: 44)
            } minimal: {
                RestActivityCountdown(attributes: context.attributes, size: 13)
                    .frame(width: 34)
            }
            .widgetURL(RestActivityLink.url)
            .keylineTint(RestActivityStyle.accent)
        }
    }
}

@main
struct MorningWidgets: WidgetBundle {
    var body: some Widget {
        RestLiveActivity()
    }
}
