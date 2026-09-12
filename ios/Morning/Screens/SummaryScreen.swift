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
        .paperGround()
    }

    private var summary: some View {
        // The middle scrolls; Done does not.
        //
        // Ported from `src/screens/Summary.tsx`, which puts the celebration in
        // an `overflow-y-auto` and keeps the button outside it, with a comment
        // saying "the only thing that can ever scroll out of sight is the tail
        // of the card". This port had it all in one fixed column, and on a
        // 667pt iPhone SE the Done button was clipped by five points once the
        // study card revealed its answer.
        //
        // Measured before the reveal it looked fine — 12pt of clearance — which
        // is the same trap this review fell into twice: a number taken before
        // checking what it was a number of.
        //
        // `04-rules.md`'s no-scroll rule is about workout screens. This is the
        // screen after one.
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                celebrationBlock
            }
            .scrollBounceBehavior(.basedOnSize)

            PaperPrimaryButton(title: "Done") {
                onDone()
            }
            .padding(.top, Space.step)
        }
        .padding(.horizontal, Space.gutter)
        .safeAreaPadding(.vertical, Space.step)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var celebrationBlock: some View {
        VStack(alignment: .leading, spacing: Space.section) {
            VStack(alignment: .leading, spacing: Space.tight) {
                Text(celebration.eyebrow)
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Paper.press)

                Text(record.reps, format: .number)
                    .font(TypeScale.counter(76))
                    .monospacedDigit()
                    .foregroundStyle(Paper.press)

                // The unit is not decoration here. Without it "150" sits
                // directly above "Reps have stopped moving." and the two scan
                // as one sentence — "150 reps have stopped moving" — which is
                // a different and wrong claim. Daybreak has always had it; the
                // summary underneath did not, and nobody had looked at the
                // summary underneath.
                Text("reps")
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press)
                    .padding(.bottom, Space.snug)

                Text(celebration.headline)
                    .font(TypeScale.title)
                    .foregroundStyle(Paper.press)
                    .fixedSize(horizontal: false, vertical: true)

                Text(celebration.body)
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press)
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

            // WHAT YOU KNOW, ON THE SAME SCREEN AS WHAT YOU LIFTED.
            //
            // The deck's whole presence outside a rest is this sentence. It is
            // deliberately not a fifth entry in `factsRow`: those four are what
            // you just DID, and putting knowledge in the same row as tonnage
            // and the week would make it a fifth number to keep up, which is
            // the reading `plans/004` rules out.
            //
            // Below the card, because the card is the deck and this is a fact
            // about the same thing. It is absent entirely until it has
            // something true to say — see `Deck.Standing.line`.
            if let line = deckStanding.line {
                Text(line)
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Space.step)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// Facts, not praise. The delta is absent entirely when the working weight
    /// moved, because there is nothing honest to compare.
    private var factsRow: some View {
        HStack(alignment: .top, spacing: Space.gutter) {
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
                .foregroundStyle(Paper.press)
            // W15 #4, applied where it earns the most: these four numbers ARE
            // the screen. "What you just did, how it compares, where the week
            // stands" — and they were set at callout, one step above the
            // smallest label in the app, under a 96pt rep total.
            Text(value)
                .font(TypeScale.counter(22))
                .monospacedDigit()
                .foregroundStyle(Paper.press)
        }
    }

    /// The deck's standing, or a made-up one for review.
    ///
    /// `-standing <settled>/<shaky>/<questions>`. The shipped deck holds ONE
    /// question, so the only standing this screen can reach on its own is some
    /// arrangement of one — and the line was written for "19 of 26 solid. 4 you
    /// keep missing." A sentence nobody can look at is a sentence nobody has
    /// checked, which is the same reason `-tier`, `-card` and `-answer` exist.
    ///
    /// Read-only, like the others: it never writes mastery.
    private var deckStanding: Deck.Standing {
        let arguments = ProcessInfo.processInfo.arguments
        if let flag = arguments.firstIndex(of: "-standing"),
           arguments.indices.contains(flag + 1)
        {
            // `-standing met/cards/answered/settled/shaky`.
            let parts = arguments[flag + 1].split(separator: "/").compactMap { Int($0) }
            if parts.count == 5 {
                return Deck.Standing(
                    met: parts[0],
                    cards: parts[1],
                    answered: parts[2],
                    settled: parts[3],
                    shaky: parts[4]
                )
            }
        }
        return Deck.standing()
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
                    // Was `DawnPalette(progress: 1).accentText` — gold lifted
                    // toward white, which on paper stock measures **1.30:1**.
                    // The worst contrast anywhere in the app, and the pink Eden
                    // spotted. Blue matches the same label on the Rest screen's
                    // card: 7.02:1, and it is the ink for something already
                    // true, which a topic name is.
                    .foregroundStyle(Paper.blue)

                Text(card.q)
                    .font(TypeScale.question)
                    .foregroundStyle(Paper.press)
                    .fixedSize(horizontal: false, vertical: true)

                if revealed {
                    Text(card.a)
                        .font(TypeScale.answer)
                        .foregroundStyle(Paper.press)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(answerShown ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        // The Summary's study card. Same component role as the Rest screen's,
        // and it was missing its press state for the same reason.
        .buttonStyle(PressSheetStyle())
        .accessibilityLabel(revealed ? "\(card.q) \(card.a)" : "\(card.q). Reveal answer.")
    }
}
