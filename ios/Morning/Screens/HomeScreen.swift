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
    /// Home is not inside a workout, so it supports the accessibility sizes
    /// rather than clamping the way Set and Rest do. The session panel is the
    /// part that needs to know: see `upNext`.
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // THE ORDER OF THIS SCREEN IS THE ARGUMENT.
        //
        // W15 #8, and it is the only item on Eden's list that is a design
        // problem rather than a spacing one: *"suuuper dull, doesn't really
        // entice me to do a workout, it's mostly empty, emphesising the weights
        // and the 'this week' counter is small and dull and really dull UX."*
        //
        // He is right about all three, and they are one fault. `§8` says Home
        // answers "what am I doing and what do I set up?" in under two seconds
        // — and this screen only ever answered the second half. The largest
        // thing on it was a plate configuration at 38pt; the answer to "what am
        // I doing" was the letter B, inside the start button. So the most
        // prominent element was setup for a session the screen never described,
        // and 240pt of the middle was empty underneath it.
        //
        // Nothing here is invented content. `Session.name` ("Light") and
        // `Session.minutes` ("~19 min") have been in `Program.swift` since it
        // was transcribed and no screen has ever shown them, and the movement
        // list is the session's own structure. It is a hierarchy change: what
        // you are about to do goes where the plate maths was, the plate maths
        // becomes one line next to the button it belongs to, and the week gets
        // read from across a room instead of squinted at.
        //
        // Still not gamified. No points, no badges, no streak economy, nothing
        // congratulating anybody. Bigger type on a true number is emphasis, not
        // a reward.
        VStack(alignment: .leading, spacing: Space.gutter) {
            header

            upNext

            WeekMeter(progress: progress, hasHistory: lastSession != nil, accent: palette.accent)

            Spacer(minLength: Space.step)

            // The loadout sits with the start control now, because that is the
            // order the two things actually happen in: read the weight, load
            // the handles, press the button. As the hero it was answering a
            // question nobody asks until they are already committed.
            //
            // The whole row is the target, not just the word "Change".
            // `guide.json` — content, and not mine to reword — says "tap the
            // loadout on the home screen", so the loadout has to be the thing
            // you tap, and a ~60pt target beats a 44pt one at 6:10am.
            Button {
                withAnimation(Motion.reveal(reduceMotion: reduceMotion)) {
                    editingLoad.toggle()
                }
            } label: {
                loadout
            }
            .buttonStyle(.plain)
            .disabled(load == nil)
            .accessibilityLabel(
                load.map { "Working weight \(Plates.format($0)) kilograms per handle. Change it." }
                    ?? "Bodyweight only"
            )

            if editingLoad {
                weightPicker
            }

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
                            // `label` (caption, 12pt) rather than `microLabel`
                            // (caption2, 11pt). Still the quietest thing on the
                            // screen and still one line — but 11pt is the floor
                            // of the whole type system, and these four are the
                            // only route into four of the app's ten screens.
                            // Being deliberately quiet is right; being the
                            // smallest text in the app is more than that asked
                            // for.
                            .font(TypeScale.label)
                            .foregroundStyle(Ink.tertiary)
                            .frame(minHeight: Hit.minimum)
                    }
                }
            }
        }
        .padding(.horizontal, Space.gutter)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        // SCROLLS ONLY WHEN IT MUST.
        //
        // The header of this file has always said Home may scroll, unlike Set
        // and Rest — and until the session panel arrived it never needed to. On
        // a 375x667 SE it now does: measured, the title was cut off the top and
        // the History/All time/Guide/Backup row was off the bottom entirely,
        // which loses the only route into four screens.
        //
        // `minHeight` plus `.basedOnSize` means a 16 Pro gets a fixed page that
        // cannot be dragged, and the SE gets a scroll. Not a compromise for the
        // phone Eden actually holds.
        .modifier(FillOrScroll())
        .safeAreaPadding(.vertical, Space.step)
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
            // The panel below already says SESSION A in 38pt type. Saying it twice,
            // 90pt apart, is not orientation.
            return "Nothing logged yet."
        }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        let when = switch days {
        case ...0: "today"
        case 1: "yesterday"
        default: "\(days) days ago"
        }
        return "Last: \(lastSession.sessionKey), \(when) · \(History.reps(of: lastSession)) reps"
    }

    /// WHAT YOU ARE ABOUT TO DO.
    ///
    /// The thing this screen never said. `Session.name` and `Session.minutes`
    /// are program content that has been sitting in `Program.swift` unread
    /// since it was transcribed, and the movement outline is the session's own
    /// block structure — a superset is one line because that is how it is
    /// performed, which also explains the bunched ticks on the workout rail.
    ///
    /// One panel, not a stack of them. `§8` notes Home is "currently a stack of
    /// cards; it does not have to be", and the fix for an empty screen is not
    /// four boxes.
    private var upNext: some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            // Side by side normally, stacked at the accessibility sizes.
            //
            // Measured at accessibility-XXXL: the two ends of this row squeezed
            // each other into two columns four characters wide and the label
            // came out as "UP NEXT · SES-SION B", hyphenated. Neither half is
            // long; they just cannot both be on one line at that size.
            let stacked = typeSize.isAccessibilitySize
            AnyLayout(stacked
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
            ) {
                Text("UP NEXT · SESSION \(nextSession)")
                    .font(TypeScale.microLabel)
                    .tracking(1.5)
                    .foregroundStyle(Ink.tertiary)
                if !stacked {
                    Spacer()
                }
                Text(sessionSummary)
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Ink.tertiary)
            }

            Text(session(for: nextSession)?.name ?? "Session \(nextSession)")
                .font(TypeScale.counter(38))
                .foregroundStyle(Ink.primary)

            if !outline.isEmpty {
                Divider()
                    .overlay(Ink.hairline)
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: Space.snug) {
                    ForEach(Array(outline.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(TypeScale.bodyEmphasis)
                            .foregroundStyle(Ink.secondary)
                            // Wrap rather than truncate. At accessibility sizes
                            // one line turned "Lateral raise + Rear-delt fly"
                            // into "Lateral raise + R…", which hides half of
                            // what the superset is.
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Space.gutter - 4)
        .padding(.vertical, Space.gutter - 4)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.26), Color.black.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.75)
        }
        .accessibilityElement(children: .combine)
    }

    /// "~19 min · 14 sets". Both halves are facts the app already holds and
    /// neither was on screen.
    private var sessionSummary: String {
        var parts: [String] = []
        if let minutes = session(for: nextSession)?.minutes {
            parts.append(minutes)
        }
        let sets = StepCompiler.countSets(StepCompiler.build(session: nextSession, kg: load))
        parts.append("\(sets) sets")
        return parts.joined(separator: " · ")
    }

    /// One line per block, in the order performed. A superset is one line with
    /// its partners joined, because that is one round of work.
    private var outline: [String] {
        guard let session = session(for: nextSession) else { return [] }

        let blocks: [(name: String, sub: String?)] = session.blocks.compactMap { block in
            switch block {
            case .warmup:
                // The warm-up is not a movement, and listing it would put
                // "Warm-up" at the top of a list whose whole job is to say what
                // the session IS.
                nil
            case let .straight(straight):
                (straight.exercise, straight.sub)
            case let .superset(superset):
                (superset.items.map(\.exercise).joined(separator: " + "), nil)
            }
        }

        // THE SUB-LABEL SURVIVES ONLY WHERE IT TELLS TWO LINES APART.
        //
        // Dropping it everywhere was right for "Push-up — deficit — hands on
        // books" (W15 #1: Eden called that text *"uneeded"* on a screen with
        // far more room for it) and wrong for session B, where "Lateral raise"
        // appears in the superset AND again as the myo block — the list read as
        // if it had a duplicate in it, which is worse than a long line.
        //
        // So: setup detail goes, disambiguation stays.
        // Counted per EXERCISE, not per line. Session B's clash is between a
        // superset line reading "Lateral raise + Rear-delt fly" and a straight
        // block reading "Lateral raise" — two different strings, so counting
        // whole lines found no duplicate and the list still showed the same
        // movement twice with nothing telling them apart.
        var counts: [String: Int] = [:]
        for block in session.blocks {
            switch block {
            case .warmup: break
            case let .straight(straight): counts[straight.exercise, default: 0] += 1
            case let .superset(superset):
                for item in superset.items {
                    counts[item.exercise, default: 0] += 1
                }
            }
        }

        return blocks.map { block in
            guard let sub = block.sub, counts[block.name, default: 0] > 1 else { return block.name }
            return "\(block.name) · \(sub)"
        }
    }

    /// The answer to "what do I set up" is plates, not a weight — but it is one
    /// line, not the headline. See the note on `body`.
    private var loadout: some View {
        HStack(alignment: .center, spacing: Space.step) {
            VStack(alignment: .leading, spacing: 1) {
                if let load {
                    Text("\(Plates.format(load)) kg per handle")
                        .font(TypeScale.action)
                        .foregroundStyle(Ink.primary)

                    Text(Plates.breakdown(for: load) ?? "not loadable with the plates you own")
                        .font(TypeScale.body)
                        .foregroundStyle(Ink.tertiary)
                } else {
                    Text("Bodyweight only")
                        .font(TypeScale.action)
                        .foregroundStyle(Ink.primary)
                }
            }

            Spacer(minLength: 0)

            // A label, not a control — the whole row is the control. It stays
            // because without it nothing says the loadout is tappable, and the
            // Guide's instruction only helps someone who has read the Guide.
            if load != nil {
                Text(editingLoad ? "Done" : "Change")
                    .font(TypeScale.label)
                    .foregroundStyle(palette.accentText)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
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
        // W15 #8's third clause: *"the 'this week' counter is small and dull"*.
        //
        // It was three lines of 11pt grey and a row of 6pt hairlines. Every
        // number on it is true and worth reading — how many sessions are in the
        // week, how many weeks the run has lasted, what the best run was — and
        // all of them were set at the quietest size in the type system, under a
        // 38pt plate configuration.
        //
        // So the count is read from across the room, the pips have weight, and
        // the run line is body copy rather than a footnote. No new facts, no
        // new copy, and still nothing that congratulates.
        VStack(alignment: .leading, spacing: Space.snug) {
            HStack(alignment: .firstTextBaseline) {
                Text("THIS WEEK")
                    .font(TypeScale.microLabel)
                    .tracking(1.5)
                    .foregroundStyle(Ink.tertiary)
                Spacer()
                // "2" carries, "of 5" is the scale it is read against — one
                // fact, two weights, rather than two greys the same size.
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(progress.done)")
                        .font(TypeScale.counter(30))
                        .monospacedDigit()
                        .foregroundStyle(progress.done > 0 ? Ink.primary : Ink.tertiary)
                    Text("of \(progress.target)")
                        .font(TypeScale.body)
                        .monospacedDigit()
                        .foregroundStyle(Ink.tertiary)
                }
            }

            HStack(spacing: 6) {
                ForEach(0 ..< progress.target, id: \.self) { index in
                    Capsule()
                        .fill(index < progress.done ? accent : Ink.hairline)
                        .frame(height: 10)
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
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
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
