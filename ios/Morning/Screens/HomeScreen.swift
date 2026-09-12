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

    case history, ledger, study, guide, backup

    var title: String {
        switch self {
        case .history: "History"
        case .ledger: "All time"
        // `plans/004` refused a twelfth surface when the deck was 26 cards.
        // Eden reopened it at 356 — `plans/010`.
        case .study: "Study"
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
    /// What to say about a session that was ended and discarded, or nil.
    let abandon: AbandonNote?

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
    /// Whether Home has landed. Drives the one entrance in the app that
    /// `01-motion-doctrine.md` §3.2 explicitly affords — see `arriving(_:)`.
    @State private var arrived = false

    /// Home sits at the start of the day, so the sky sits at the start of its
    /// walk. The dawn belongs to the session, not to the menu.
    private let skyProgress = 0.08
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
            // The note shares the header's rank rather than taking a sixth.
            // The stagger's budget is 80ms TOTAL — §3.2 — and a sixth rank at
            // 18ms would spend 90. It is also the header's news, not a separate
            // announcement.
            VStack(alignment: .leading, spacing: Space.step) {
                header
                if let abandon {
                    abandonNote(abandon)
                }
            }
            .modifier(arriving(0))

            upNext
                .modifier(arriving(1))

            WeekMeter(progress: progress, hasHistory: lastSession != nil, accent: Paper.orange)
                .modifier(arriving(2))

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
            // A ~60pt target with no press state. The comment above explains at
            // length why the whole row is the target; nothing told you when you
            // had hit it.
            .buttonStyle(PressSheetStyle())
            .disabled(load == nil)
            .accessibilityLabel(
                load.map { "Working weight \(Plates.format($0)) kilograms per handle. Change it." }
                    ?? "Bodyweight only"
            )
            .modifier(arriving(3))

            if editingLoad {
                weightPicker
            }

            VStack(spacing: Space.step) {
                PaperPrimaryButton(title: "Start \(nextSession)") {
                    onStart(nextSession)
                }

                // Quiet on purpose: for a skipped day or a repeat, not a
                // second equal choice.
                Button("Start \(otherSession) instead") {
                    onStart(otherSession)
                }
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
                .frame(minHeight: Hit.minimum)
                // THE WHOLE TARGET IS TAPPABLE, NOT JUST THE GLYPHS.
                // A `.frame(min…: Hit.…)` on a Button reserves the layout space and does
                // NOT extend its hit region — SwiftUI still hit-tests the rendered label.
                // With `alignment: .leading` the text is then pinned to one edge of a 68pt
                // box, so most of the target was dead paper.
                //
                // Eden, on the phone: *"seems like the clickable area is the text of the
                // button not the button itself, this feels bad to click."* At 6:10am with a
                // knuckle this is the difference between a control and a dare.
                .contentShape(Rectangle())

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
                            .foregroundStyle(Paper.press)
                            .frame(minHeight: Hit.minimum)
                            // THE WHOLE TARGET IS TAPPABLE, NOT JUST THE GLYPHS.
                            // A `.frame(min…: Hit.…)` on a Button reserves the layout space and does
                            // NOT extend its hit region — SwiftUI still hit-tests the rendered label.
                            // With `alignment: .leading` the text is then pinned to one edge of a 68pt
                            // box, so most of the target was dead paper.
                            //
                            // Eden, on the phone: *"seems like the clickable area is the text of the
                            // button not the button itself, this feels bad to click."* At 6:10am with a
                            // knuckle this is the difference between a control and a dare.
                            .contentShape(Rectangle())
                    }
                }
            }
            .modifier(arriving(4))
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
        .paperGround()
        // ARRIVAL, IN `onAppear` AND NOWHERE ELSE.
        //
        // Not a `.task`, which would re-run; not an initial `@State` of true,
        // which would mean there was never a "before" to animate from. This
        // fires once per appearance and the whole entrance is over inside a
        // third of a second.
        .onAppear {
            guard !arrived else { return }
            // NO `withAnimation`. Each element carries its own animation with
            // its own delay, and an explicit ambient transaction overrides
            // them: measured on a 60fps capture, `withAnimation { arrived =
            // true }` produced all four bands rising in LOCKSTEP — 24/24/24/23%
            // at the same frame, then 41/39/41/41, then 60/60/60/60. The
            // stagger was written, compiled, and did nothing.
            //
            // Setting it plainly leaves `.animation(_:value:)` as the only
            // source, which is what makes the ranks mean anything.
            arrived = true
        }
    }

    /// One element of Home's entrance.
    ///
    /// A modifier rather than five copies of the same three lines, because five
    /// copies is how a stagger drifts out of its budget: the doctrine caps the
    /// TOTAL at 80ms and there is no way to see that from any one call site.
    /// Here the ranks are visible in one place and `Motion.homeArrival` owns
    /// the arithmetic.
    private func arriving(_ rank: Int) -> some ViewModifier {
        HomeArrival(rank: rank, arrived: arrived, reduceMotion: reduceMotion)
    }

    // MARK: - Parts

    /// ONE TRUE LINE ABOUT THE MORNING THAT DID NOT HAPPEN.
    ///
    /// Under an orange rule, because orange in this world is a MARK and never a
    /// glyph — a short stroke in the margin is exactly the vocabulary for "note
    /// this", and it keeps the line itself in press black where it is
    /// readable. See `AbandonNote` for why the copy is what it is.
    ///
    /// It arrives with Home and it does not leave on a timer. A line that
    /// vanished while he was reading it would be the app taking back the one
    /// thing it said, and collapsing its own space to do it.
    private func abandonNote(_ note: AbandonNote) -> some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            Rectangle()
                .fill(Paper.orange)
                .frame(width: 24, height: 2)

            Text(note.line)
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Morning")
                .font(TypeScale.title)
                .foregroundStyle(Paper.press)

            Text(subtitle)
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
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
                    .foregroundStyle(Paper.press)
                if !stacked {
                    Spacer()
                }
                Text(sessionSummary)
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Paper.press)
            }

            Text(session(for: nextSession)?.name ?? "Session \(nextSession)")
                .font(TypeScale.counter(38))
                .foregroundStyle(Paper.press)

            if !outline.isEmpty {
                Divider()
                    .overlay(Paper.press.opacity(0.22))
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: Space.snug) {
                    ForEach(Array(outline.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(TypeScale.bodyEmphasis)
                            .foregroundStyle(Paper.press)
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
        // A PASTED PLY, not a rounded translucent card.
        //
        // This was a `LinearGradient` inside a 22pt corner radius with a white
        // hairline — three separate pieces of the previous world's vocabulary,
        // and a gradient is the one thing this world cannot produce. The
        // session panel is the most important block on Home, so it is the one
        // that gets the material.
        .background {
            let sheet = TornEdge(tornTop: true, tornBottom: true, seed: 47)
            sheet
                .fill(Paper.ply)
                // THE SHADOW IS CAST BY THE SHEET, NOT BY THE FIBRE ON IT.
                // See `Ply` in `PaperTokens.swift` for the whole reason. Order is the
                // entire fix: shadow the fill, then print the fibre on top.
                .shadow(color: Paper.press.opacity(0.22), radius: 3, x: 0, y: 2)
                .overlay { Fibre().clipShape(sheet) }
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
                        .foregroundStyle(Paper.press)

                    Text(Plates.breakdown(for: load) ?? "not loadable with the plates you own")
                        .font(TypeScale.body)
                        .foregroundStyle(Paper.press)
                } else {
                    Text("Bodyweight only")
                        .font(TypeScale.action)
                        .foregroundStyle(Paper.press)
                }
            }

            Spacer(minLength: 0)

            // A label, not a control — the whole row is the control. It stays
            // because without it nothing says the loadout is tappable, and the
            // Guide's instruction only helps someone who has read the Guide.
            if load != nil {
                Text(editingLoad ? "Done" : "Change")
                    .font(PaperType.micro)
                    .tracking(TypeScale.microTracking)
                    // Blue, because it is the ink for things that are already
                    // true and this is the one affordance on Home that has to
                    // look tappable without being the primary action. It was
                    // `accentText`, which in a light world is invisible.
                    .foregroundStyle(Paper.blue)
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
                        .foregroundStyle(Paper.press)
                    Text("per handle")
                        .font(TypeScale.microLabel)
                        .foregroundStyle(Paper.press)
                }
                .frame(maxWidth: .infinity)

                stepButton("+", label: "Heavier", enabled: current < Plates.maximum) {
                    change(to: current + Plates.step)
                }
            }

            Text(Plates.breakdown(for: current) ?? "not loadable with the plates you own")
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
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
                .foregroundStyle(enabled ? Paper.press : Paper.press)
                .background(Color.clear, in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Paper.press, lineWidth: 2.5)
                }
        }
        // Key-sized, so 0.97 — the same factor `PressKeyStyle` uses. Not
        // `PressKeyStyle` itself: it draws its own square border and this key
        // already has a rounded one, so the two would stack.
        .buttonStyle(PressSheetStyle(scale: 0.97))
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
/// Home's entrance, one element at a time.
///
/// `01-motion-doctrine.md` §3.2 is the only place in the app that affords an
/// arrival at all, and it affords a small one: *"≤250ms. Stagger permitted but
/// capped at 80ms total across all items… a long cascade delays the one tap the
/// user came to make."*
private struct HomeArrival: ViewModifier {
    let rank: Int
    let arrived: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(arrived ? 1 : 0)
            // No offset under Reduce Motion: the element still fades in, so
            // nothing appears from nowhere, but nothing travels.
            .offset(y: arrived || reduceMotion ? 0 : Motion.homeArrivalRise)
            .animation(Motion.homeArrival(reduceMotion: reduceMotion, rank: rank), value: arrived)
    }
}

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
                    .foregroundStyle(Paper.press)
                Spacer()
                // "2" carries, "of 5" is the scale it is read against — one
                // fact, two weights, rather than two greys the same size.
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(progress.done)")
                        .font(TypeScale.counter(30))
                        .monospacedDigit()
                        .foregroundStyle(progress.done > 0 ? Paper.press : Paper.press)
                    Text("of \(progress.target)")
                        .font(TypeScale.body)
                        .monospacedDigit()
                        .foregroundStyle(Paper.press)
                }
            }

            HStack(spacing: 6) {
                ForEach(0 ..< progress.target, id: \.self) { index in
                    Capsule()
                        .fill(index < progress.done ? accent : Paper.press.opacity(0.22))
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
                    .foregroundStyle(Paper.press)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if progress.streak > 0 || progress.longestRun > 0 {
                Text(runLine)
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press)
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
