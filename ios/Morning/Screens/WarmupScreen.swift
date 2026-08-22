import SwiftUI

/* ===========================================================================
 *  THE WARM-UP
 *  ---------------------------------------------------------------------------
 *  Step 0 of both sessions: 90 seconds, three cues, a clock.
 *
 *  This screen was deferred during W5 with a comment saying "until it exists,
 *  start on the first set rather than on a step this host cannot render", and
 *  then it never got built. Two things followed from that.
 *
 *  The app SKIPPED A PROGRAMMED STEP. `goToFirstSet()` jumped straight past the
 *  warm-up on every session. Content is fixed and this is content.
 *
 *  And the step was still reachable — `back()` has no guard, so one tap of Back
 *  from the first set landed on it. `WorkoutHost` had no branch for a timer, so
 *  it fell through to a developer placeholder reading "Session complete /
 *  Summary and Daybreak are W7." A workout that had not started announcing it
 *  was over, quoting a workstream number at the user.
 *
 *  The brief calls this the least important screen in the app, and it is. That
 *  is an argument for keeping it plain, not for leaving it out.
 *
 *  No figure. The web has one, but the three cues are three different movements
 *  and no single illustration shows them; the alternative was `ExerciseMovement`'s
 *  default, which is a bicep curl. The space goes to the clock instead.
 * ======================================================================== */

struct WarmupScreen: View {
    let step: TimerStep
    let endsAt: Date
    let progress: Double
    let stepLabel: String
    let namespace: Namespace.ID

    let onDone: () -> Void
    let onBack: () -> Void
    let onEnd: () -> Void

    /// Fires once. `endsAt` resets it.
    @State private var completed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        VStack(spacing: 0) {
            WorkoutChrome(progress: progress, step: stepLabel, onBack: onBack, onEnd: onEnd)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(TypeScale.title)
                    .foregroundStyle(Ink.primary)

                // Verbatim from the web build. Content is not ours to improve.
                Text("90 seconds. Don't skip it, don't extend it.")
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Space.snug)

            cues
                .padding(.top, Space.step)

            Spacer(minLength: Space.step)

            TimelineView(.animation) { context in
                let remaining = max(0, endsAt.timeIntervalSince(context.date))
                clock(remaining)
                    .onChange(of: Int(ceil(remaining))) { _, value in
                        if value <= 0 {
                            finish()
                        }
                    }
            }

            Spacer(minLength: Space.step)

            DawnPrimaryButton(title: "Done — start lifting", treatment: .atmospheric, accent: palette.accent) {
                finish()
            }
        }
        .padding(.horizontal, Space.gutter)
        .safeAreaPadding(.bottom, Space.snug)
        .dynamicTypeSize(.large)
        // The floor, for the same reason `RestScreen` has one: `TimelineView`
        // only ticks while the app is drawing.
        .task(id: endsAt) {
            completed = false
            try? await Task.sleep(for: .seconds(max(0, endsAt.timeIntervalSinceNow)))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    // MARK: - Parts

    /// The same treatment as the Set screen's cues, minus the emphasis: a
    /// warm-up has no cue carrying the training effect, and marking one would
    /// be inventing a hierarchy the program does not have.
    private var cues: some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            ForEach(Array(step.cues.enumerated()), id: \.offset) { _, cue in
                HStack(alignment: .top, spacing: Space.snug) {
                    Circle()
                        .fill(Ink.hairline)
                        .frame(width: 5, height: 5)
                        .padding(.top, 8)

                    Text(cue)
                        .font(TypeScale.body)
                        .foregroundStyle(Ink.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// `src/lib/format.ts`: bare seconds under a minute, `m:ss` above it.
    ///
    /// Carries the work object, so the warm-up's clock becomes the first set's
    /// rep counter rather than the two screens swapping.
    private func clock(_ remaining: TimeInterval) -> some View {
        let whole = Int(ceil(max(0, remaining)))
        let text = whole < 60 ? "\(whole)" : "\(whole / 60):\(String(format: "%02d", whole % 60))"
        return Text(text)
            .font(TypeScale.counter())
            .monospacedDigit()
            .foregroundStyle(Ink.primary)
            .contentTransition(Motion.numeric(reduceMotion: reduceMotion, countsDown: true))
            .matchedGeometryEffect(id: WorkObject.id, in: namespace, isSource: false)
            .accessibilityLabel("\(whole) seconds left in the warm-up")
    }

    // MARK: - Behaviour

    private func finish() {
        guard !completed else { return }
        completed = true
        onDone()
    }
}
