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

enum HomeDestination: String, CaseIterable, Identifiable {
    var id: String {
        rawValue
    }

    case history, ledger, guide, backup

    var title: String {
        switch self {
        case .history: "History"
        case .ledger: "All time"
        case .guide: "Guide"
        case .backup: "Backup"
        }
    }
}

struct HomeScreen: View {
    let nextSession: String
    let otherSession: String
    let load: Double?
    let progress: WeeklyProgress
    let lastSession: SessionRecord?

    let onStart: (String) -> Void
    /// The way into the reading screens.
    let onOpen: (HomeDestination) -> Void
    /// The working weight for the session about to start.
    ///
    /// This was missing entirely. `Plates.swift`'s own header says "once the
    /// weight became adjustable the breakdown had to be derived" — the maths
    /// was built for a control that never shipped. `AppData.loads` was read and
    /// never written, the Guide told you to "change it on the home screen", and
    /// the whole weight-change chain downstream of it — the `weight-changed`
    /// celebration tier, the rep control's "different weight now" — could never
    /// fire, because the weight could never change.
    let onLoadChange: (Double) -> Void

    /// `-edit-load` opens the picker at launch, because no tap reaches this app
    /// in the development environment. Inline layout rather than a
    /// presentation, so an initial `@State` value is enough here.
    @State private var editingLoad = ProcessInfo.processInfo.arguments.contains("-edit-load")

    /// Home sits at the start of the day, so the sky sits at the start of its
    /// walk. The dawn belongs to the session, not to the menu.
    private let skyProgress = 0.08
    private var palette: DawnPalette {
        DawnPalette(progress: skyProgress)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Space.section) {
            header

            loadout

            if editingLoad {
                weightPicker
            }

            WeekMeter(progress: progress, hasHistory: lastSession != nil, accent: palette.accent)

            Spacer(minLength: Space.step)

            VStack(spacing: Space.step) {
                DawnPrimaryButton(
                    title: "Start \(nextSession)",
                    treatment: .atmospheric,
                    accent: palette.accent
                ) {
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

                // Quiet, and on one line: these are read occasionally, not at
                // 6:10am mid-workout, and four separate rows would compete with
                // the one control that matters.
                HStack(spacing: Space.section) {
                    ForEach(HomeDestination.allCases, id: \.self) { destination in
                        Button(destination.title) { onOpen(destination) }
                            .font(TypeScale.microLabel)
                            .foregroundStyle(Ink.tertiary)
                            .frame(minHeight: Hit.minimum)
                    }
                }
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
            HStack {
                Text("Set up")
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Ink.tertiary)

                Spacer()

                if load != nil {
                    Button(editingLoad ? "Done" : "Change") {
                        withAnimation(Motion.reveal(reduceMotion: reduceMotion)) {
                            editingLoad.toggle()
                        }
                    }
                    .font(TypeScale.microLabel)
                    .foregroundStyle(palette.accentText)
                    .frame(minHeight: Hit.minimum)
                }
            }

            if let load {
                // Hidden while the picker is open: the picker shows the same
                // number and the same plate breakdown, and two of each is one
                // too many.
                if !editingLoad {
                    Text("\(Plates.format(load)) kg per handle")
                        .font(TypeScale.counter(38))
                        .foregroundStyle(Ink.primary)

                    Text(Plates.breakdown(for: load) ?? "not loadable with the plates you own")
                        .font(TypeScale.body)
                        .foregroundStyle(Ink.secondary)
                }
            } else {
                Text("Bodyweight only")
                    .font(TypeScale.counter(38))
                    .foregroundStyle(Ink.primary)
            }
        }
    }

    /// Lighter / heavier, one plate step at a time.
    ///
    /// `04-rules.md` and the Guide both say the same thing: the program's
    /// numbers are a starting guess, and the honest fix when one is wrong is to
    /// tell the app, so that rep counts stay a measure of effort instead of a
    /// record of falling short of an arbitrary target. Bounded by the plates
    /// actually owned — `Plates.maximum` — because a weight you cannot load is
    /// not a weight you can pick.
    private var weightPicker: some View {
        let current = load ?? 0
        return VStack(spacing: Space.snug) {
            HStack(spacing: Space.gutter) {
                stepButton("−", label: "Lighter", enabled: current > 0) {
                    change(to: current - Plates.step)
                }

                VStack(spacing: 0) {
                    Text("\(Plates.format(current)) kg")
                        .font(TypeScale.counter(34))
                        .monospacedDigit()
                        .foregroundStyle(Ink.primary)
                    Text("per handle")
                        .font(TypeScale.microLabel)
                        .foregroundStyle(Ink.tertiary)
                }
                .frame(maxWidth: .infinity)

                stepButton("+", label: "Heavier", enabled: current < Plates.maximum) {
                    change(to: current + Plates.step)
                }
            }

            Text(Plates.breakdown(for: current) ?? "not loadable with the plates you own")
                .font(TypeScale.body)
                .foregroundStyle(Ink.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepButton(
        _ symbol: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .frame(width: 62, height: 62)
                .foregroundStyle(enabled ? Ink.primary : Ink.tertiary)
                .background(Control.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Control.border, lineWidth: Control.borderWidth)
                }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    /// Clamped to what the plates can actually make, and reported rounded so
    /// floating-point drift never puts 7.499999 in the file.
    private func change(to kg: Double) {
        let next = min(Plates.maximum, max(0, (kg * 100).rounded() / 100))
        guard next != load else { return }
        Audio.shared.play(.confirm)
        Haptics.shared.rep()
        onLoadChange(next)
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
