import SwiftUI

/* ===========================================================================
 *  HOME
 *  ---------------------------------------------------------------------------
 *  Answers "what am I doing and what do I set up?" in under two seconds.
 *  `02-design-brief.md §8`.
 *
 *  Which session is next — auto-derived, the opposite of whatever was logged
 *  last, A on a fresh install. The working weight and the plate breakdown for
 *  it, because the answer to "what do I set up" is a number of plates, not a
 *  weight you then have to do arithmetic on at 6am. One large start control. A
 *  quiet way to start the other session instead, for a skipped day. Where you
 *  are in the week. And a way into the reading screens.
 *
 *  EMPTY IS THE DAY-ONE CASE, not an edge case: v1 ships starting at zero and
 *  the web app keeps the real history. `§8` is explicit that a screen with no
 *  data still has to answer the two-second question, and that "0 tonnes" is a
 *  bad answer. So the week meter shows an honest empty week rather than hiding,
 *  and the nudge stays silent rather than inventing encouragement.
 *
 *  This screen is NOT inside a workout, so unlike Set and Rest it may scroll —
 *  though at the sizes here it does not need to.
 * ======================================================================== */

struct HomeScreen: View {
    let nextSession: String
    let otherSession: String
    let load: Double?
    let progress: WeeklyProgress
    let lastSession: SessionRecord?

    let onStart: (String) -> Void

    /// Home sits at the start of the day, so the sky sits at the start of its
    /// walk. The dawn belongs to the session, not to the menu.
    private let skyProgress = 0.08
    private var palette: DawnPalette {
        DawnPalette(progress: skyProgress)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.section) {
            header

            loadout

            WeekMeter(progress: progress, hasHistory: lastSession != nil, accent: palette.accent)

            Spacer(minLength: Space.step)

            VStack(spacing: Space.step) {
                DawnPrimaryButton(
                    title: "Start \(nextSession)",
                    treatment: .atmospheric,
                    accent: palette.accent
                ) {
                    Haptics.shared.logged()
                    onStart(nextSession)
                }

                // Quiet on purpose: for a skipped day or a repeat, not a
                // second equal choice.
                Button("Start \(otherSession) instead") {
                    onStart(otherSession)
                }
                .font(TypeScale.body)
                .foregroundStyle(Ink.tertiary)
                .frame(minHeight: Hit.minimum)
            }
        }
        .padding(.horizontal, Space.gutter)
        .safeAreaPadding(.vertical, Space.step)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DawnBackdrop(treatment: .atmospheric, progress: skyProgress))
    }

    // MARK: - Parts

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Morning")
                .font(TypeScale.title)
                .foregroundStyle(Ink.primary)

            Text(subtitle)
                .font(TypeScale.body)
                .foregroundStyle(Ink.secondary)
        }
    }

    /// On day one this says what the app is for. After that it says what you
    /// last did, which is the fact that makes "next" make sense.
    private var subtitle: String {
        guard let lastSession, let date = History.localDate(of: lastSession) else {
            return "First session. Session \(nextSession) to start."
        }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        let when = switch days {
        case ...0: "today"
        case 1: "yesterday"
        default: "\(days) days ago"
        }
        return "Last: \(lastSession.sessionKey), \(when) · \(History.reps(of: lastSession)) reps"
    }

    /// The answer to "what do I set up" is plates, not a weight.
    private var loadout: some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            Text("Set up")
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)

            if let load {
                Text("\(Plates.format(load)) kg per handle")
                    .font(TypeScale.counter(38))
                    .foregroundStyle(Ink.primary)

                Text(Plates.breakdown(for: load) ?? "not loadable with the plates you own")
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
            } else {
                Text("Bodyweight only")
                    .font(TypeScale.counter(38))
                    .foregroundStyle(Ink.primary)
            }
        }
    }
}

// MARK: - The week

/// Consistency without gamification. Pips, a count and one honest line — no
/// points, no badges, no streak-freeze economy.
private struct WeekMeter: View {
    let progress: WeeklyProgress
    /// On day one there is no week to have missed.
    let hasHistory: Bool
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            HStack {
                Text("This week")
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Ink.tertiary)
                Spacer()
                Text("\(progress.done) of \(progress.target)")
                    .font(TypeScale.microLabel.monospacedDigit())
                    .foregroundStyle(Ink.tertiary)
            }

            HStack(spacing: 6) {
                ForEach(0 ..< progress.target, id: \.self) { index in
                    Capsule()
                        .fill(index < progress.done ? accent : Ink.hairline)
                        .frame(height: 6)
                }
            }

            // A blank day is absence, not failure — so there is no red, and no
            // copy at all when there is nothing useful to say.
            //
            // And on a FRESH INSTALL there is nothing useful to say at all. The
            // arithmetic is right — five sessions will not fit in the days left
            // — but "this week's out of reach" is the wrong first sentence for
            // someone who has not started yet. The subtitle already says what
            // day one is. Silence beats filler at that hour.
            if hasHistory, let nudge = WeekNudge.text(for: progress) {
                Text(nudge)
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if progress.streak > 0 || progress.longestRun > 0 {
                Text(runLine)
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Ink.tertiary)
            }
        }
    }

    /// The longest run stays on screen after the current streak drops to zero.
    /// That is precisely when people stop, and a number you built disappearing
    /// as if it never happened is the wrong thing to do at that moment.
    private var runLine: String {
        let weeks = progress.streak == 1 ? "week" : "weeks"
        if progress.streak > 0 {
            return progress.longestRun > progress.streak
                ? "\(progress.streak) \(weeks) running · best \(progress.longestRun)"
                : "\(progress.streak) \(weeks) running"
        }
        return "Best run: \(progress.longestRun) weeks"
    }
}
