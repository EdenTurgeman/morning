import Foundation
import os

#if canImport(ActivityKit)
    import ActivityKit
#endif

/* ===========================================================================
 *  STARTING AND STOPPING THE LIVE ACTIVITY
 *  ---------------------------------------------------------------------------
 *  One activity at a time, started when a rest begins and ended when it stops
 *  being the current step — including when the session ends, is abandoned, or
 *  the rest is skipped or extended.
 *
 *  EXTENDING ENDS AND RESTARTS. `+15s` moves `endsAt`, and `endsAt` lives in
 *  the static half of the attributes so the system can render the countdown
 *  without the app ever waking. The price of that is it cannot be edited, so an
 *  extension is a new activity. That is the right trade: the alternative is
 *  pushing a content update every second of every rest, for a number the system
 *  can already draw itself.
 *
 *  EVERYTHING IS BEST-EFFORT. A Live Activity that fails to start must never
 *  take a rep with it, so every call here swallows its failure and logs. The
 *  rest screen in the app is the source of truth; this is a convenience on the
 *  Lock Screen.
 *
 *  NOT VERIFIED VISUALLY. There is no `Simulator.app` on the development
 *  machine, so the app cannot be backgrounded and the Lock Screen cannot be
 *  reached — the presentation is unlooked-at, exactly like the haptics and the
 *  audio cues. What *is* checked here is that an activity starts and ends at
 *  the right moments, which shows up in the device log. See the device
 *  checklist.
 * ======================================================================== */

@MainActor
final class RestActivityController {
    static let shared = RestActivityController()

    private let log = Logger(subsystem: "com.edenturgeman.morning", category: "live-activity")

    /// The end date of the rest an activity was last requested for.
    ///
    /// `syncLiveActivity()` is called from both `onAppear` and the `endsAt`
    /// change, and on arriving at a rest both fire. Without this guard that
    /// produced **two** activities for one rest — confirmed in the device log,
    /// "starting, 20s" twice and then "ending, 2 running" — which on the Lock
    /// Screen is two identical countdowns stacked.
    private var startedFor: Date?

    private init() {}

    /// True when the user has Live Activities switched on for this app. Reading
    /// it rather than assuming, because it is a per-app toggle in Settings and
    /// the whole feature is silently absent when it is off.
    var isAvailable: Bool {
        #if canImport(ActivityKit)
            ActivityAuthorizationInfo().areActivitiesEnabled
        #else
            false
        #endif
    }

    /// Begins the countdown on the Lock Screen. Ends any previous one first, so
    /// a skipped rest never leaves a stale timer running behind the new step.
    func start(rest: RestStep, endsAt: Date, next: SetStep?) {
        #if canImport(ActivityKit)
            guard isAvailable, startedFor != endsAt else { return }
            startedFor = endsAt

            let attributes = RestAttributes(
                endsAt: endsAt,
                seconds: rest.seconds,
                nextExercise: next?.exercise,
                nextDetail: next?.summaryLine,
                isMyo: rest.seconds < Deck.minimumRestForCard
            )

            // Ending and starting in ONE task, in order. `end()` is async, so
            // firing it and then requesting immediately leaves both alive for
            // as long as the teardown takes — the previous rest's countdown and
            // this one's, side by side.
            let seconds = rest.seconds
            Task { @MainActor in
                await endAll()
                do {
                    // Logged on success as well as failure. The presentation
                    // cannot be seen from here — no `Simulator.app`, so the app
                    // cannot be backgrounded and the Lock Screen cannot be
                    // reached — and a feature nobody can observe is a feature
                    // nobody can verify. This is what makes "an activity starts
                    // when a rest begins" checkable at all.
                    log.notice("live activity starting, \(seconds, privacy: .public)s")
                    _ = try Activity.request(
                        attributes: attributes,
                        content: .init(state: .init(), staleDate: endsAt.addingTimeInterval(60)),
                        pushType: nil
                    )
                    // The count, not just "it did not throw". `request` can
                    // succeed and leave nothing running, and the difference is
                    // invisible without this — which is the whole problem with
                    // a feature whose output lives on a Lock Screen this
                    // machine cannot reach.
                    let count = Activity<RestAttributes>.activities.count
                    log.notice("live activity started, now \(count, privacy: .public) running")
                } catch {
                    // Swallowed on purpose. See the header.
                    log.error("live activity did not start: \(error.localizedDescription, privacy: .public)")
                }
            }
        #endif
    }

    /// Ends it now rather than letting it linger. `.immediate` because the
    /// countdown reaching zero is the whole content — leaving a spent timer on
    /// the Lock Screen for four hours is the system default and it is wrong
    /// here.
    ///
    /// Asks the system for its activities rather than holding one. Two reasons,
    /// and the second is the better one:
    ///
    /// 1. An `Activity` handed out of main-actor state and captured by a task
    ///    is "sent" across isolation domains, which Swift 6 rejects. Looking it
    ///    up inside the task sends nothing.
    /// 2. **It cleans up after a force-quit.** An activity outlives the process
    ///    that started it. Tracking one in memory means a session killed
    ///    mid-rest leaves a countdown on the Lock Screen that nothing will ever
    ///    end; asking the system means the next rest clears it.
    func end() {
        #if canImport(ActivityKit)
            startedFor = nil
            Task { @MainActor in await endAll() }
        #endif
    }

    #if canImport(ActivityKit)
        private func endAll() async {
            let running = Activity<RestAttributes>.activities
            guard !running.isEmpty else { return }
            log.notice("live activity ending, \(running.count, privacy: .public) running")
            for activity in running {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    #endif
}
