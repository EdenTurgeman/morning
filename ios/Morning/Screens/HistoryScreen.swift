import SwiftUI

/* ===========================================================================
 *  HISTORY
 *  ---------------------------------------------------------------------------
 *  Reverse-chronological sessions, a week strip, and a year of mornings as one
 *  picture. `04-rules.md §7`.
 *
 *  THE CONSTRAINT THAT KILLED THE FIRST WEB VERSION: the grid must FIT THE
 *  SCREEN. A fixed-cell version was wider than a phone, which pushed the recent
 *  weeks off the right edge — you had to scroll to find today, and the whole
 *  point of showing a year is seeing it at once.
 *
 *  So the grid is drawn in a `Canvas` sized from the container: cell size is
 *  derived from the width it is given, never the other way round. It cannot
 *  overflow, because there is no dimension it could overflow into.
 *
 *  Each cell is a day, painted from the sunrise ramp, with position on the ramp
 *  set by how hard that session was RELATIVE TO YOUR OWN RANGE — your quietest
 *  is pre-dawn indigo, your best is full gold. Scaled to you rather than to an
 *  arbitrary target, so a good month literally looks warmer than a bad one.
 *
 *  Deletion sits behind an EXPLICIT EDIT MODE. Never a swipe: sweaty hands, and
 *  an accidental delete is unrecoverable.
 *
 *  And empty is real here. "0 tonnes" is a bad answer and so is hiding the
 *  screen — the empty state has to read as the beginning of a record.
 * ======================================================================== */

struct HistoryScreen: View {
    let history: [SessionRecord]
    let onDelete: (SessionRecord) -> Void
    let onClose: () -> Void

    @State private var editing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirming: SessionRecord?
    /// When the year grid's once-ever wipe began. See `YearGrid.inkingFrom`.
    @State private var inkingFrom: Date?
    /// Whether the claim has been made. The grid is held back for the frame it
    /// takes, so a first-data wipe never starts by flashing the finished grid.
    @State private var claimed = false

    private var sorted: [SessionRecord] {
        history.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if history.isEmpty {
                empty
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.section) {
                        YearGrid(history: history, inkingFrom: inkingFrom)
                            .opacity(claimed ? 1 : 0)

                        weekStrip

                        sessions
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, Space.section)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .paperGround()
        .onAppear(perform: claimFirstRecord)
        // See `WorkoutHost`: the sheet form has no visible cancel on iOS 26.
        .alert(
            "Delete this session?",
            isPresented: .constant(confirming != nil)
        ) {
            Button("Delete", role: .destructive) {
                if let confirming {
                    onDelete(confirming)
                }
                confirming = nil
            }
            Button("Keep", role: .cancel) { confirming = nil }
        } message: {
            // An accidental delete is unrecoverable, so the confirmation says
            // what is about to be lost rather than "are you sure".
            if let confirming {
                Text("\(confirming.sessionKey) on \(readable(confirming.date)). "
                    + "\(History.reps(of: confirming)) reps. This cannot be undone.")
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

            Text("History")
                .font(TypeScale.label)
                .foregroundStyle(Paper.press)

            Spacer()

            if history.isEmpty {
                Color.clear.frame(width: Hit.minimum, height: Hit.minimum)
            } else {
                Button(editing ? "Done" : "Edit") { editing.toggle() }
                    .font(TypeScale.label)
                    .foregroundStyle(editing ? Paper.blue : Paper.press)
                    .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .trailing)
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
        .padding(.horizontal, Space.gutter)
    }

    /// The last twelve weeks, one bar each.
    ///
    /// `04-rules.md §7` asks for "a week strip **and** a year grid" and this
    /// file's own header has always claimed both — only the grid existed.
    /// `WeeklyProgress.recent` was computed for it and read by nothing.
    ///
    /// The grid answers "which mornings"; this answers "which weeks held
    /// together", which is the unit the streak is actually measured in
    /// (`§3`: weeks, not consecutive days). Complete weeks take the accent;
    /// partial weeks are present but quiet; empty weeks are still drawn,
    /// because a gap you can see is the point.
    private var weekStrip: some View {
        let week = Week.progress(history: history)
        return VStack(alignment: .leading, spacing: Space.snug) {
            HStack {
                Text("Last 12 weeks")
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Paper.press)

                Spacer()

                if week.streak > 0 || week.longestRun > 0 {
                    Text(runLine(week))
                        .font(TypeScale.microLabel)
                        .foregroundStyle(Paper.press)
                }
            }

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(week.recent, id: \.key) { summary in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColour(summary))
                        .frame(height: 8 + CGFloat(min(summary.count, 7)) * 3.5)
                        .accessibilityLabel("\(summary.key): \(summary.count) sessions")
                }
            }
            .frame(height: 34, alignment: .bottom)
        }
        .padding(.horizontal, Space.gutter)
    }

    /// This session's reps as a fraction of the best session on screen.
    ///
    /// Scaled against the visible history rather than against a fixed ceiling,
    /// because a fixed one would make every bar tiny on a light week and the
    /// shape would say nothing. Guards a zero max: a history where nothing was
    /// logged has no shape to draw and every bar stays empty rather than
    /// dividing by nothing.
    private func fraction(of record: SessionRecord) -> CGFloat {
        let best = sorted.map { History.reps(of: $0) }.max() ?? 0
        guard best > 0 else { return 0 }
        return CGFloat(History.reps(of: record)) / CGFloat(best)
    }

    private func barColour(_ summary: WeekSummary) -> Color {
        if summary.complete {
            // Blue: a finished week is ALREADY TRUE. The dawn ramp put a
            // different hue here for every position in the session, which meant the
            // colour of a week said nothing — it was decoration keyed to an
            // unrelated number.
            return Paper.blue
        }
        // Bound to a local because `empty_count` fires on `summary.count == 0`.
        // It is a tally of sessions, not the size of a collection, so `isEmpty`
        // is not a thing it has — a false positive worth sidestepping rather
        // than disabling the rule for the file.
        let sessions = summary.count
        return sessions > 0 ? Paper.press.opacity(0.28) : Paper.press.opacity(0.10)
    }

    /// Same rule as the home screen's: the longest run stays visible after the
    /// current streak drops to zero.
    private func runLine(_ week: WeeklyProgress) -> String {
        let unit = week.streak == 1 ? "week" : "weeks"
        if week.streak > 0 {
            return "\(week.streak) \(unit) running"
        }
        return "Best run: \(week.longestRun) weeks"
    }

    /// Not "no sessions yet". The beginning of a record.
    /// `-first-record` forgets the claim, so a once-in-a-lifetime state can be
    /// filmed more than once. The same flag `LedgerScreen` uses; the two keys
    /// are separate so neither spends the other.
    private func claimFirstRecord() {
        if ProcessInfo.processInfo.arguments.contains("-first-record") {
            FirstRecord.forget(FirstRecord.history)
        }
        if !history.isEmpty, FirstRecord.claim(FirstRecord.history) {
            inkingFrom = .now
        }
        claimed = true
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: Space.step) {
            Text("Nothing here yet")
                .font(TypeScale.title)
                .foregroundStyle(Paper.press)

            Text("Every session you finish lands here. The date, which one, how many "
                + "reps. A year of them fits on one screen.")
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
                .fixedSize(horizontal: false, vertical: true)

            // The grid is shown EMPTY rather than hidden, so the shape of what
            // is coming is visible from day one.
            YearGrid(history: [])
                .padding(.top, Space.step)
                .opacity(0.5)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.section)
    }

    private var sessions: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sorted, id: \.timestamp) { record in
                HStack(spacing: Space.step) {
                    if editing {
                        Button {
                            confirming = record
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Paper.danger)
                        }
                        .buttonStyle(PressSheetStyle(scale: 0.97))
                        .frame(minWidth: 44, minHeight: Hit.minimum)
                        .accessibilityLabel("Delete \(record.sessionKey) on \(readable(record.date))")
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(readable(record.date))
                            .font(TypeScale.bodyEmphasis)
                            .foregroundStyle(Paper.press)
                        Text("Session \(record.sessionKey) · \(record.minutes) min")
                            .font(TypeScale.microLabel)
                            .foregroundStyle(Paper.press)
                    }

                    Spacer(minLength: Space.step)

                    // SHAPE FIRST, FIGURE SECOND.
                    //
                    // `04-direction-reset.md` §2.3: History stops leading with
                    // figures and leads with something qualitative. The number
                    // was `bodyEmphasis`, isolated on the right — the loudest
                    // thing in every row, so the list read as a column of
                    // totals and you had to compare them by arithmetic.
                    //
                    // The bar is that same number as a LENGTH, scaled against
                    // the best session on screen, so scanning the column shows
                    // the shape of the training without reading anything. The
                    // figure stays — it is still true and still wanted — it is
                    // just no longer the headline.
                    //
                    // No behaviour change: `History.reps(of:)` is the same call
                    // it always was.
                    HStack(spacing: Space.snug) {
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Paper.press.opacity(0.18))
                                    .frame(height: 6)
                                Rectangle()
                                    .fill(Paper.blue)
                                    .frame(
                                        width: proxy.size.width * fraction(of: record),
                                        height: 6
                                    )
                            }
                            .frame(height: proxy.size.height, alignment: .center)
                        }
                        .frame(width: 92, height: 6)

                        Text(History.reps(of: record), format: .number)
                            .font(TypeScale.microLabel.monospacedDigit())
                            .foregroundStyle(Paper.press)
                            .frame(width: 34, alignment: .trailing)
                    }
                }
                .frame(minHeight: 56)

                Divider().overlay(Paper.press.opacity(0.22))
            }
        }
        // Was `.easeInOut(duration: 0.18)` — the only hand-written curve left in
        // production, and the wrong shape besides: the delete controls are
        // ENTERING, and ease-in-out withholds movement at the moment the eye is
        // on it. `Motion.stage` is the token for a state change you are waiting
        // on, and it carries its own reduced form.
        .animation(Motion.stage(reduceMotion: reduceMotion), value: editing)
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
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM")
        return formatter.string(from: date)
    }
}

// MARK: - A year of mornings

/// 53 columns of 7 days, drawn in one pass.
///
/// The cell size is derived from the width the view is GIVEN, so the year
/// always fits whatever it gets. Cells end up around 5pt on a phone, which is
/// what these charts look like at this density anyway — and seeing the whole
/// year at once is the entire point.
struct YearGrid: View {
    let history: [SessionRecord]

    private static let weeks = 53
    private static let days = 7

    /// WHEN THE FIRST-RECORD WIPE BEGAN, or nil for a grid that is simply
    /// there.
    ///
    /// `01-motion-doctrine.md` §3.2 permits delight in exactly two places and
    /// this is one of them — *"Empty → first data (year grid, lifetime).
    /// Delight permitted. Seen once, ever."* — with the reason attached:
    /// *"Day one is the normal case, not an edge case."*
    ///
    /// **A wipe of the whole grid, not the one inked cell.** The obvious move
    /// was to ink the single trained day, and it is the wrong one: a cell here
    /// is about five points across, so a lone square fading in is a delight
    /// moment nobody can see. The grid laying itself out IS the statement —
    /// here is the year, and your first day is in it — and it is unmissable.
    ///
    /// Left to right, the direction a sheet comes off a press, and the same
    /// vocabulary as `plans/001`'s ink wipe and the Ledger's drawn rule.
    var inkingFrom: Date?

    /// How long the wipe takes. Longer than anything else on a reading surface
    /// is allowed to be, because §3.2 exempts this moment: it is seen once in
    /// the lifetime of an install.
    static let wipeSeconds: TimeInterval = 0.8

    var body: some View {
        Group {
            if let inkingFrom {
                // READ OFF A CLOCK, not driven by `withAnimation`. This file's
                // siblings record two animations that were written, compiled
                // and moved nothing — `RestScreen`'s thinking bar and Home's
                // stagger. A `Canvas` redrawn from a date is a value that can
                // be printed and measured.
                TimelineView(.animation) { context in
                    grid(wipe: Self.wipe(at: context.date, from: inkingFrom))
                }
            } else {
                grid(wipe: 1)
            }
        }
        .aspectRatio(CGFloat(Self.weeks) / CGFloat(Self.days), contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("A year of sessions")
        .accessibilityValue("\(history.count) sessions")
    }

    /// 0…1 of the wipe, eased out.
    ///
    /// Eased rather than linear: this is a thing arriving, not a clock. The
    /// countdown ring and the thinking bar are linear because easing a clock
    /// makes it lie; nothing here is reporting time.
    static func wipe(at now: Date, from start: Date) -> Double {
        let t = min(1, max(0, now.timeIntervalSince(start) / wipeSeconds))
        // Written out rather than pulled from `UnitCurve`, so the value in a
        // frame capture can be checked against arithmetic on paper.
        return 1 - pow(1 - t, 2)
    }

    /// How much of the grid's width the wipe's leading edge is smeared over.
    ///
    /// Without it the wipe is a hard vertical line marching across, which reads
    /// as a loading bar. A soft edge reads as ink spreading.
    private static let wipeEdge = 0.12

    private func grid(wipe: Double) -> some View {
        Canvas { context, size in
            let model = Model(history: history)
            let gap: CGFloat = 2
            let cell = min(
                (size.width - gap * CGFloat(Self.weeks - 1)) / CGFloat(Self.weeks),
                (size.height - gap * CGFloat(Self.days - 1)) / CGFloat(Self.days)
            )
            guard cell > 0 else { return }

            let gridWidth = cell * CGFloat(Self.weeks) + gap * CGFloat(Self.weeks - 1)
            let originX = (size.width - gridWidth) / 2

            // The wipe's leading edge, carried past 1 so the last column
            // finishes rather than stopping at the threshold.
            let head = wipe * (1 + Self.wipeEdge)

            for week in 0 ..< Self.weeks {
                let column = Double(week) / Double(Self.weeks - 1)
                let alpha = min(1, max(0, (head - column) / Self.wipeEdge))
                guard alpha > 0 else { continue }

                for day in 0 ..< Self.days {
                    let index = week * Self.days + day
                    guard index < model.cells.count else { continue }
                    let cellModel = model.cells[index]

                    let rect = CGRect(
                        x: originX + CGFloat(week) * (cell + gap),
                        y: CGFloat(day) * (cell + gap),
                        width: cell,
                        height: cell
                    )
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: cell * 0.28),
                        with: .color(colour(for: cellModel, in: model).opacity(alpha))
                    )
                }
            }
        }
        // Self-sizing rather than given a fixed height. 53 columns of 7 days
        // has a fixed aspect, and pinning a height instead left the grid
        // floating in dead space — the cell size is derived from the width, so
        // the height it needs is not a free choice.
        .aspectRatio(CGFloat(Self.weeks) / CGFloat(Self.days), contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("A year of sessions")
        .accessibilityValue("\(history.count) sessions")
    }

    /// A day you trained is painted from the sunrise ramp, positioned by how
    /// hard that session was relative to your OWN range.
    private func colour(for cell: Model.Cell, in model: Model) -> Color {
        guard cell.reps > 0 else {
            // Future days are quieter than past ones: a blank day behind you is
            // absence, a blank day ahead has not happened yet.
            return cell.future ? Paper.press.opacity(0.22).opacity(0.35) : Paper.press.opacity(0.22)
        }
        let span = Double(model.maximum - model.minimum)
        let position = span > 0 ? Double(cell.reps - model.minimum) / span : 1
        // The year grid inks by DENSITY, not by hue. `04-direction-reset.md`
        // §2.3 demotes the analytical surfaces from leading with figures to
        // leading with shape and texture, and a year of blue at varying weight
        // IS the texture — a printed sheet where the busy months are darker.
        // A rainbow keyed to position said nothing true about the day.
        return Paper.blue.opacity(0.25 + position * 0.75)
    }

    /// The days, week-major so each column is a whole week.
    struct Model {
        struct Cell {
            let reps: Int
            let future: Bool
        }

        let cells: [Cell]
        let minimum: Int
        let maximum: Int

        init(history: [SessionRecord], today: Date = Date(), calendar: Calendar = .current) {
            var byDate: [String: Int] = [:]
            for record in history {
                byDate[record.date, default: 0] += History.reps(of: record)
            }

            // Start on a week boundary so every column is a whole week.
            let thisWeek = Week.start(of: today, calendar: calendar)
            let first = calendar.date(byAdding: .day, value: -(YearGrid.weeks - 1) * 7, to: thisWeek) ?? thisWeek

            var cells: [Cell] = []
            for week in 0 ..< YearGrid.weeks {
                for day in 0 ..< YearGrid.days {
                    guard let date = calendar.date(byAdding: .day, value: week * 7 + day, to: first) else {
                        continue
                    }
                    let parts = calendar.dateComponents([.year, .month, .day], from: date)
                    let iso = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
                    cells.append(Cell(reps: byDate[iso] ?? 0, future: date > today))
                }
            }

            let reps = history.map { History.reps(of: $0) }.filter { $0 > 0 }
            self.cells = cells
            minimum = reps.min() ?? 0
            maximum = reps.max() ?? 1
        }
    }
}
