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
    @State private var confirming: SessionRecord?

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
                        YearGrid(history: history)

                        weekStrip

                        sessions
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, Space.section)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DawnBackdrop(treatment: .atmospheric, progress: 0.12))
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
                Text("\(confirming.sessionKey) on \(readable(confirming.date)) — "
                    + "\(History.reps(of: confirming)) reps. This cannot be undone.")
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Close", action: onClose)
                .font(TypeScale.label)
                .foregroundStyle(Ink.secondary)
                .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .leading)

            Spacer()

            Text("History")
                .font(TypeScale.label)
                .foregroundStyle(Ink.secondary)

            Spacer()

            if history.isEmpty {
                Color.clear.frame(width: Hit.minimum, height: Hit.minimum)
            } else {
                Button(editing ? "Done" : "Edit") { editing.toggle() }
                    .font(TypeScale.label)
                    .foregroundStyle(editing ? DawnPalette(progress: 0.12).accentText : Ink.secondary)
                    .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .trailing)
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
                    .foregroundStyle(Ink.tertiary)

                Spacer()

                if week.streak > 0 || week.longestRun > 0 {
                    Text(runLine(week))
                        .font(TypeScale.microLabel)
                        .foregroundStyle(Ink.tertiary)
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

    private func barColour(_ summary: WeekSummary) -> Color {
        if summary.complete {
            return DawnPalette(progress: 0.55).accent
        }
        // Bound to a local because `empty_count` fires on `summary.count == 0`.
        // It is a tally of sessions, not the size of a collection, so `isEmpty`
        // is not a thing it has — a false positive worth sidestepping rather
        // than disabling the rule for the file.
        let sessions = summary.count
        return sessions > 0 ? Ink.primary.opacity(0.28) : Ink.primary.opacity(0.10)
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
    private var empty: some View {
        VStack(alignment: .leading, spacing: Space.step) {
            Text("Nothing here yet")
                .font(TypeScale.title)
                .foregroundStyle(Ink.primary)

            Text("Every session you finish lands here — the date, which one, and "
                + "how many reps. A year of them fits on one screen.")
                .font(TypeScale.body)
                .foregroundStyle(Ink.secondary)
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
                                .foregroundStyle(Color(red: 0.94, green: 0.38, blue: 0.38))
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 44, minHeight: Hit.minimum)
                        .accessibilityLabel("Delete \(record.sessionKey) on \(readable(record.date))")
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(readable(record.date))
                            .font(TypeScale.bodyEmphasis)
                            .foregroundStyle(Ink.primary)
                        Text("Session \(record.sessionKey) · \(record.minutes) min")
                            .font(TypeScale.microLabel)
                            .foregroundStyle(Ink.tertiary)
                    }

                    Spacer()

                    Text(History.reps(of: record), format: .number)
                        .font(TypeScale.bodyEmphasis.monospacedDigit())
                        .foregroundStyle(Ink.secondary)
                }
                .frame(minHeight: 56)

                Divider().overlay(Ink.hairline)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: editing)
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

    var body: some View {
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

            for week in 0 ..< Self.weeks {
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
                        with: .color(colour(for: cellModel, in: model))
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
            return cell.future ? Ink.hairline.opacity(0.35) : Ink.hairline
        }
        let span = Double(model.maximum - model.minimum)
        let position = span > 0 ? Double(cell.reps - model.minimum) / span : 1
        return DawnPalette(progress: 0.15 + position * 0.85).accent
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
