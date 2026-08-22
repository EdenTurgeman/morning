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

    private var ledger: Ledger {
        LedgerMath.compute(history)
    }

    private var palette: DawnPalette {
        DawnPalette(progress: 0.72)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if history.isEmpty {
                empty
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.section) {
                        headline
                        facts
                        if let next = Milestones.next(after: ledger) {
                            nextThreshold(next)
                        }
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, Space.section)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DawnBackdrop(treatment: .atmospheric, progress: 0.72))
    }

    private var header: some View {
        HStack {
            Button("Close", action: onClose)
                .font(TypeScale.label)
                .foregroundStyle(Ink.secondary)
                .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .leading)
            Spacer()
            Text("All time")
                .font(TypeScale.label)
                .foregroundStyle(Ink.secondary)
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
                .foregroundStyle(Ink.primary)

            Text("tonnes moved")
                .font(TypeScale.body)
                .foregroundStyle(Ink.secondary)

            // The provenance, quietly. Two dumbbells, load per handle, and
            // bodyweight work counted as reps but never as kilos — a headline
            // number is only worth something if you can see where it came from.
            Text(provenance)
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.snug)
        }
    }

    private var tonnage: String {
        ledger.tonnes >= 10
            ? String(format: "%.0f", ledger.tonnes)
            : String(format: "%.1f", ledger.tonnes)
    }

    private var provenance: String {
        let bodyweight = ledger.bodyweightReps
        let base = "\(Milestones.format(ledger.reps)) reps, each moving two dumbbells at the weight "
            + "that session was actually done at."
        guard bodyweight > 0 else { return base }
        return base + " \(Milestones.format(bodyweight)) of them were bodyweight — they count as reps, not as kilos."
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
                .foregroundStyle(Ink.secondary)
            Spacer()
            Text(value)
                .font(TypeScale.bodyEmphasis.monospacedDigit())
                .foregroundStyle(Ink.primary)
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
                    .foregroundStyle(Ink.tertiary)
                Spacer()
                Text(next.remaining)
                    .font(TypeScale.microLabel.monospacedDigit())
                    .foregroundStyle(Ink.tertiary)
            }

            Text(next.label)
                .font(TypeScale.bodyEmphasis)
                .foregroundStyle(Ink.primary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Ink.hairline)
                    Capsule()
                        .fill(palette.accent)
                        .frame(width: proxy.size.width * min(1, max(0, next.fraction)))
                }
            }
            .frame(height: 4)
        }
    }

    /// Not "0 tonnes". A zero rendered at 76pt is a number pretending to be an
    /// achievement, which is the opposite of what this screen is for.
    private var empty: some View {
        VStack(alignment: .leading, spacing: Space.step) {
            Text("Nothing moved yet")
                .font(TypeScale.title)
                .foregroundStyle(Ink.primary)

            Text("This screen adds up every rep you ever log and tells you what it "
                + "came to. One session from now it starts being worth reading.")
                .font(TypeScale.body)
                .foregroundStyle(Ink.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("The first threshold is one tonne.")
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)
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
