import SwiftUI

/* ===========================================================================
 *  SUMMARY
 *  ---------------------------------------------------------------------------
 *  What you just did, how it compares, where the week stands, one study card,
 *  and out. `02-design-brief.md §8`.
 *
 *  EXACTLY ONE HEADLINE — the highest tier actually earned. The tiers and their
 *  copy live in `Celebration.swift`; this screen only renders the one it is
 *  handed, because eleven possible headlines rendered by eleven `if`s is how
 *  two of them end up on screen together.
 *
 *  The rep total is the large number, and the headline sits under it. That
 *  ordering is why `04-rules.md §5` insists every headline adds something the
 *  number does not already say: a headline of "252 reps." prints the same
 *  figure twice, and Eden caught exactly that in the shipped build.
 *
 *  Daybreak plays OVER this rather than before it — the web build mounts the
 *  summary underneath and animates on top, so the moment you dismiss the
 *  celebration the numbers are already there rather than fading in late.
 * ======================================================================== */

struct SummaryScreen: View {
    let record: SessionRecord
    let celebration: Celebration
    let week: WeeklyProgress
    let card: Card?
    let onDone: () -> Void

    /// `-screen summary -skip-daybreak` shows what is underneath. Daybreak
    /// waits for a tap, and no tap reaches this app in the development
    /// environment — without this the summary is unreviewable.
    @State private var showingDaybreak = !ProcessInfo.processInfo.arguments.contains("-skip-daybreak")
    @State private var cardRevealed = false
    /// Separate from `cardRevealed`, exactly as on the rest screen: the card
    /// takes its space first and the words arrive once it has stopped growing.
    @State private var cardAnswerShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The session ended at sunrise, which is when it is actually happening.
    private let skyProgress = 1.0

    var body: some View {
        ZStack {
            summary

            if showingDaybreak {
                Daybreak(
                    celebration: celebration,
                    reps: record.reps,
                    week: week
                ) {
                    withAnimation(Motion.stage(reduceMotion: reduceMotion)) {
                        showingDaybreak = false
                    }
                }
                .transition(.opacity)
            }
        }
        .background(DawnBackdrop(treatment: .atmospheric, progress: skyProgress))
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: Space.section) {
            VStack(alignment: .leading, spacing: Space.tight) {
                Text(celebration.eyebrow)
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Ink.tertiary)

                Text(record.reps, format: .number)
                    .font(TypeScale.counter(76))
                    .monospacedDigit()
                    .foregroundStyle(Ink.primary)

                // The unit is not decoration here. Without it "150" sits
                // directly above "Reps have stopped moving." and the two scan
                // as one sentence — "150 reps have stopped moving" — which is
                // a different and wrong claim. Daybreak has always had it; the
                // summary underneath did not, and nobody had looked at the
                // summary underneath.
                Text("reps")
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
                    .padding(.bottom, Space.snug)

                Text(celebration.headline)
                    .font(TypeScale.title)
                    .foregroundStyle(Ink.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(celebration.body)
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.tight)
            }

            factsRow

            if let card {
                SummaryCard(card: card, revealed: cardRevealed, answerShown: cardAnswerShown) {
                    reveal()
                }
                .task(id: card.id) {
                    cardRevealed = false
                    cardAnswerShown = false
                    // Fourteen seconds rather than the rest screen's 6.5–11:
                    // there is no timer to beat here.
                    try? await Task.sleep(for: .seconds(Deck.summaryRevealDelay))
                    guard !Task.isCancelled else { return }
                    reveal()
                }
            }

            Spacer(minLength: Space.step)

            DawnPrimaryButton(
                title: "Done",
                treatment: .atmospheric,
                accent: DawnPalette(progress: skyProgress).accent
            ) {
                onDone()
            }
        }
        .padding(.horizontal, Space.gutter)
        .safeAreaPadding(.vertical, Space.step)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Facts, not praise. The delta is absent entirely when the working weight
    /// moved, because there is nothing honest to compare.
    private var factsRow: some View {
        HStack(spacing: Space.section) {
            fact("Session", record.sessionKey)
            fact("Minutes", "\(record.minutes)")
            if let delta = celebration.delta {
                fact("vs last", delta > 0 ? "+\(delta)" : "\(delta)")
            } else if let kg = record.kg {
                fact("At", "\(Plates.format(kg)) kg")
            }
            fact("This week", "\(week.done)/\(week.target)")
        }
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)
            Text(value)
                .font(TypeScale.bodyEmphasis.monospacedDigit())
                .foregroundStyle(Ink.primary)
        }
    }

    private func reveal() {
        guard !cardRevealed else { return }
        Haptics.shared.reveal()
        withAnimation(Motion.reveal(reduceMotion: reduceMotion)) {
            cardRevealed = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Motion.answerDelay(reduceMotion: reduceMotion)))
            guard !Task.isCancelled else { return }
            withAnimation(Motion.answer(reduceMotion: reduceMotion)) {
                cardAnswerShown = true
            }
        }
    }
}

/// The third card of the session. Same silent auto-reveal as the rest screen's.
private struct SummaryCard: View {
    let card: Card
    let revealed: Bool
    /// See `RepControl.comparison` and `StudyCard`: a `@ViewBuilder` branch
    /// insertion does not animate, `.transition(.opacity)` or not. The answer
    /// was appearing instantly. Opacity on a view that holds its space does.
    let answerShown: Bool
    let onReveal: () -> Void

    var body: some View {
        Button(action: onReveal) {
            VStack(alignment: .leading, spacing: Space.snug) {
                Text(card.topic.uppercased())
                    .font(TypeScale.microLabel)
                    .tracking(1.8)
                    .foregroundStyle(DawnPalette(progress: 1).accentText)

                Text(card.q)
                    .font(TypeScale.question)
                    .foregroundStyle(Ink.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if revealed {
                    Text(card.a)
                        .font(TypeScale.answer)
                        .foregroundStyle(Ink.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(answerShown ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(revealed ? "\(card.q) \(card.a)" : "\(card.q). Reveal answer.")
    }
}
