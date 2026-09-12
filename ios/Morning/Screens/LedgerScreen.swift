import SwiftUI

/* ===========================================================================
 *  THE LEDGER
 *  ---------------------------------------------------------------------------
 *  Everything ever: tonnage, reps, sessions, hours, and the next threshold.
 *  ONE STAGGERING TRUE NUMBER at the top.
 *
 *  `02-design-brief.md §8` says what this screen is for in one line, and it is
 *  worth keeping in view while reading the code: *"This is the screen that
 *  exists to make the last six months feel like they happened."*
 *
 *  Which is why the headline is tonnage rather than sessions or reps. Load is
 *  fixed and reps are the only signal, so tonnage is the number that turns that
 *  signal into something that visibly compounds — six months of "I did 14
 *  instead of 13" adds up to a figure you cannot argue with.
 *
 *  And why the provenance sits under it, quietly. A number this size is only
 *  worth anything if you can see where it came from.
 *
 *  EMPTY IS THE HARDEST STATE ON THIS SCREEN and `§8` says so. "0 tonnes" is a
 *  bad answer: it is a number pretending to be an achievement. What is true on
 *  day one is that nothing has been recorded yet and the first session is what
 *  starts it, so that is what it says.
 * ======================================================================== */

struct LedgerScreen: View {
    let history: [SessionRecord]
    let onClose: () -> Void

    /// THE ONE PLACE IN THE APP DELIGHT IS PERMITTED.
    ///
    /// `01-motion-doctrine.md` §3.2: *"Empty → first data. Delight permitted.
    /// Seen once, ever. Day one is the normal case, not an edge case. '0
    /// tonnes' must read as the beginning of a record."*
    ///
    /// This screen's own header has always said the same thing about its empty
    /// state and then had nothing to mark the moment it stopped being empty.
    /// The first time it has a number, the number arrives and a rule draws
    /// itself under it, left to right — a ledger page being opened and ruled,
    /// which is the object this screen has been named after all along.
    ///
    /// Claimed once, ever. See `FirstRecord`.
    @State private var firstRecord = false
    @State private var ruled = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var ledger: Ledger {
        LedgerMath.compute(history)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if history.isEmpty {
                empty
            } else {
                ScrollView {
                    // THE THRESHOLD BAR MOVED UP, AND THAT IS THE WHOLE
                    // CHANGE.
                    //
                    // `04-direction-reset.md` §2.3 asks this surface to stop
                    // leading with figures. It cannot stop HAVING them — a
                    // lifetime-totals screen without totals is not a demotion,
                    // it is a deletion — but it can stop leading with a bare
                    // one. "314 tonnes" alone is a number you have no feel for;
                    // 314 shown as a position on the way to 500 is a place you
                    // are standing.
                    //
                    // So the bar sits directly under the headline where it is
                    // read WITH it, instead of buried under the table where it
                    // was the last thing on the screen. Same data, same call to
                    // `Milestones.next(after:)`, no behaviour change.
                    VStack(alignment: .leading, spacing: Space.section) {
                        headline
                            .opacity(firstRecord && !ruled ? 0 : 1)
                            .offset(y: firstRecord && !ruled ? 10 : 0)
                        if let next = Milestones.next(after: ledger) {
                            nextThreshold(next)
                        }
                        facts
                        runLine
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, Space.section)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .paperGround()
        .onAppear(perform: claimFirstRecord)
    }

    /// `-first-record` forgets the claim, so the moment can be filmed more than
    /// once. It is seen once in a lifetime by design, which makes it the single
    /// hardest state in the app to look at — and this project has shipped
    /// unreachable states before.
    private func claimFirstRecord() {
        if ProcessInfo.processInfo.arguments.contains("-first-record") {
            FirstRecord.forget(FirstRecord.ledger)
        }
        guard !history.isEmpty, FirstRecord.claim(FirstRecord.ledger) else { return }
        firstRecord = true
        // A frame with the headline down and the page unruled, so there is a
        // "before" to animate from. Setting both in one runloop pass is how an
        // entrance ends up already finished — the bug `RestScreen` records at
        // length, and the one Home's stagger hit again this week.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.05))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.35)) {
                ruled = true
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Close", action: onClose)
                .font(TypeScale.label)
                .foregroundStyle(Paper.press)
                .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .leading)
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
            Spacer()
            Text("All time")
                .font(TypeScale.label)
                .foregroundStyle(Paper.press)
            Spacer()
            Color.clear.frame(width: Hit.minimum, height: Hit.minimum)
        }
        .padding(.horizontal, Space.gutter)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            Text(tonnage)
                .font(TypeScale.counter(76))
                .monospacedDigit()
                .foregroundStyle(Paper.press)

            Text("tonnes moved")
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)

            // The provenance, quietly. Two dumbbells, load per handle, and
            // bodyweight work counted as reps but never as kilos — a headline
            // number is only worth something if you can see where it came from.
            Text(provenance)
                .font(TypeScale.microLabel)
                .foregroundStyle(Paper.press)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.snug)

            if firstRecord {
                firstRule
            }
        }
    }

    /// THE PAGE BEING RULED, once, on the first number this screen ever holds.
    ///
    /// Drawn left to right, the direction a rule is actually drawn, and slower
    /// than anything else on a reading surface is allowed to be — §3.2 exempts
    /// this moment because it is seen once, ever. It is the whole delight
    /// budget for this screen and it is spent on a straight line, which is the
    /// most this world would ever do.
    ///
    /// **A rule rather than a number counting up.** The first session is about
    /// a third of a tonne, and counting from zero to 0.3 is a slot machine with
    /// nowhere to go. What is beginning is the RECORD, and a ledger begins by
    /// being ruled.
    ///
    /// **Scaled, not width-animated.** The first version read its width from a
    /// `GeometryReader` pinned to `height: 2` inside the scrolling stack.
    /// `scaleEffect` on a full-width rectangle needs no proposed size at all,
    /// and it is the same move `EndSessionConfirm`'s hold bar makes — which is
    /// filmed, and works.
    private var firstRule: some View {
        Rectangle()
            .fill(Paper.press)
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .scaleEffect(x: ruled ? 1 : 0, y: 1, anchor: .leading)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.2)
                    : .easeOut(duration: 0.75).delay(0.18),
                value: ruled
            )
            .padding(.top, Space.step)
    }

    private var tonnage: String {
        ledger.tonnes >= 10
            ? String(format: "%.0f", ledger.tonnes)
            : String(format: "%.1f", ledger.tonnes)
    }

    private var provenance: String {
        let bodyweight = ledger.bodyweightReps
        let base = "\(Milestones.format(ledger.reps)) reps, each moving two dumbbells at "
            + "whatever that session's weight was."
        guard bodyweight > 0 else { return base }
        return base + " \(Milestones.format(bodyweight)) were bodyweight, so they count as reps but not as kilos."
    }

    /// The closing line, ported from `src/screens/Ledger.tsx`.
    ///
    /// The port stopped at the next threshold and left the bottom third of the
    /// screen empty — measured, 309pt with nothing pinned to it, the only void
    /// in the app with no action to justify it. The web closes with the run,
    /// which is the right thing to end a lifetime page on: everything above is
    /// what you moved, and this is how long you have kept doing it.
    ///
    /// `04-rules.md §3`: the longest run stays visible after the current streak
    /// drops to zero, because that is exactly when people stop.
    @ViewBuilder
    private var runLine: some View {
        let week = Week.progress(history: history)
        if week.longestRun > 0 {
            let unit = week.streak == 1 ? "week" : "weeks"
            let bestUnit = week.longestRun == 1 ? "week" : "weeks"
            // The best run is only worth naming when it is not the current one.
            // The web prints both unconditionally and at the one-week seed that
            // reads "1 week running. Longest run 1 week." — the same fact
            // twice. `HomeScreen.runLine` already had the right rule; this now
            // matches it rather than the source.
            Text(week.streak > 0
                ? (week.longestRun > week.streak
                    ? "\(week.streak) \(unit) running. Longest run \(week.longestRun) \(bestUnit)."
                    : "\(week.streak) \(unit) running.")
                : "Longest run \(week.longestRun) \(bestUnit).")
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: Space.step) {
            row("Sessions", Milestones.format(ledger.sessions))
            row("Reps", Milestones.format(ledger.reps))
            row("Time", formatDuration(minutes: ledger.minutes))
            if let since = ledger.since {
                row("Since", readable(since))
            }
            row("Session A", "\(ledger.perSession["A"] ?? 0)")
            row("Session B", "\(ledger.perSession["B"] ?? 0)")
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
            Spacer()
            Text(value)
                .font(TypeScale.bodyEmphasis.monospacedDigit())
                .foregroundStyle(Paper.press)
        }
    }

    /// Milestones are deliberately sparse, so the next one is genuinely far
    /// off. Showing how far is more honest than a progress bar that looks
    /// nearly full.
    private func nextThreshold(_ next: Milestones.NextThreshold) -> some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            HStack {
                Text("Next")
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Paper.press)
                Spacer()
                Text(next.remaining)
                    .font(TypeScale.microLabel.monospacedDigit())
                    .foregroundStyle(Paper.press)
            }

            Text(next.label)
                .font(TypeScale.bodyEmphasis)
                .foregroundStyle(Paper.press)

            // RECTANGLES, not capsules. Nothing in this world has a rounded
            // end — it is printed rules and torn edges — and a capsule was the
            // previous world's shape language surviving in a corner. Thicker
            // too, now that it leads rather than trails.
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Paper.press.opacity(0.22))
                    Rectangle()
                        .fill(Paper.orange)
                        .frame(width: proxy.size.width * min(1, max(0, next.fraction)))
                }
            }
            .frame(height: 10)
        }
    }

    /// Not "0 tonnes". A zero rendered at 76pt is a number pretending to be an
    /// achievement, which is the opposite of what this screen is for.
    private var empty: some View {
        VStack(alignment: .leading, spacing: Space.step) {
            Text("Nothing moved yet")
                .font(TypeScale.title)
                .foregroundStyle(Paper.press)

            Text("Every rep you ever log adds up here. One session from now it "
                + "starts being worth reading.")
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
                .fixedSize(horizontal: false, vertical: true)

            Text("The first threshold is one tonne.")
                .font(TypeScale.microLabel)
                .foregroundStyle(Paper.press)
                .padding(.top, Space.snug)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.section)
    }

    private func readable(_ iso: String) -> String {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = Calendar.current.date(
                  from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)
              )
        else {
            return iso
        }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        return formatter.string(from: date)
    }
}
