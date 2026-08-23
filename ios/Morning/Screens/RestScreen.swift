import SwiftUI

/* ===========================================================================
 *  THE REST SCREEN
 *  ---------------------------------------------------------------------------
 *  A countdown you can read from two metres, what is coming next, a way to add
 *  time and a way to skip. `02-design-brief.md §8`.
 *
 *  The number is the clock. The ring is supporting evidence — it reinforces
 *  direction, but a ring alone cannot be read at a glance from the floor, which
 *  is what the research pass concluded from Seconds and Ladder.
 *
 *  Remaining time is DERIVED from an absolute end date, never counted down. A
 *  tick counter drifts, and stops dead when the app is suspended — twenty
 *  seconds on a phone call would come back twenty seconds wrong.
 *
 *  On long rests a study card appears. `04-rules.md §6`, and the rule that
 *  shaped it:
 *
 *      You must never miss the timer because you were thinking.
 *
 *  So the answer AUTO-REVEALS and tapping only brings it forward. Nothing is
 *  gated behind an interaction, because at 6am mid-rest you will not reliably
 *  perform one, and a card you never got the answer to is worse than no card.
 *
 *  When the answer arrives the timer HALVES and gives its space to the text.
 *  That motion is the explanation — `§9` singles it out as the existing example
 *  of motion carrying meaning, and it survives into this build.
 *
 *  The card is SILENT. A haptic on reveal is welcome; sound is banned, because
 *  the app's audio vocabulary is entirely about time and a card making a noise
 *  during the last five seconds would be actively misleading.
 * ======================================================================== */

struct RestScreen: View {
    let seconds: Int
    let endsAt: Date
    let progress: Double
    let stepLabel: String
    let next: SetStep?
    let card: Card?
    let isMyo: Bool
    let namespace: Namespace.ID

    let onExtend: () -> Void
    let onSkip: () -> Void
    /// The rest running out. NOT the same as skipping: the web build wires
    /// `useCountdown`'s `onComplete` straight to `onAdvance`, so a rest that
    /// reaches zero moves on by itself. This port did not, and sat on "0 SEC"
    /// until something tapped it.
    let onComplete: () -> Void
    let onBack: () -> Void
    let onEnd: () -> Void

    @State private var revealed = false
    /// Separate from `revealed` because the card grows before the answer is
    /// readable. See `Motion.answer`.
    @State private var answerShown = false
    @State private var lastSpokenSecond: Int?
    /// Fires once per rest. `endsAt` resets it.
    @State private var completed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        VStack(spacing: 0) {
            WorkoutChrome(progress: progress, step: stepLabel, onBack: onBack, onEnd: onEnd)

            Spacer(minLength: Space.step)

            TimelineView(.animation) { context in
                let remaining = max(0, endsAt.timeIntervalSince(context.date))
                CountdownRing(
                    remaining: remaining,
                    total: Double(seconds),
                    compact: card != nil && revealed,
                    accent: palette.accent,
                    namespace: namespace
                )
                .onChange(of: Int(ceil(remaining))) { _, value in
                    speak(secondsLeft: value)
                    if value <= 0 {
                        finish()
                    }
                }
            }

            if isMyo {
                // The 20-second rest IS the training stimulus, not a
                // convenience. Amber says urgency without saying failure.
                Text("The 20-second rest IS the mechanism — don't stretch it")
                    .font(TypeScale.bodyEmphasis)
                    .foregroundStyle(Semantic.urgency)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Space.section)
                    .padding(.top, Space.step)
            }

            if let card {
                StudyCard(
                    card: card,
                    revealed: revealed,
                    answerShown: answerShown,
                    accent: palette.accent,
                    thinkingTime: Deck.revealDelay(forRestOf: seconds)
                ) {
                    // Tapping only brings the answer forward.
                    reveal()
                }
                .padding(.top, Space.step)
            }

            Spacer(minLength: Space.step)

            if let next {
                NextUp(step: next)
                    .padding(.bottom, Space.step)
            }

            HStack(spacing: Space.step) {
                DawnSecondaryButton(title: "+15s", treatment: .atmospheric, accent: palette.accent, quiet: true) {
                    Haptics.shared.rep()
                    onExtend()
                }
                DawnSecondaryButton(title: "Skip →", treatment: .atmospheric, accent: palette.accent) {
                    Haptics.shared.logged()
                    onSkip()
                }
            }
        }
        .padding(.horizontal, Space.gutter)
        .safeAreaPadding(.bottom, Space.snug)
        // The sky is hoisted to `WorkoutHost`. See `SetScreen`.
        .dynamicTypeSize(.large)
        // `TimelineView` only ticks while the app is drawing. The web build
        // carries a `setInterval` alongside its rAF loop for exactly this, and
        // says why: "without it, a rest could hang forever on a phone that
        // decided not to paint." This is that floor.
        .task(id: endsAt) {
            completed = false
            let wait = max(0, endsAt.timeIntervalSinceNow)
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            finish()
        }
        .task(id: endsAt) {
            revealed = false
            answerShown = false
            lastSpokenSecond = nil
            guard card != nil else { return }
            try? await Task.sleep(for: .seconds(Deck.revealDelay(forRestOf: seconds)))
            guard !Task.isCancelled else { return }
            reveal()
        }
    }

    private func reveal() {
        guard !revealed else { return }
        // Silent, deliberately. The haptic is the whole acknowledgement.
        Haptics.shared.reveal()
        withAnimation(Motion.reveal(reduceMotion: reduceMotion)) {
            revealed = true
        }
        // The card takes its new shape now; the words arrive once it has
        // stopped moving.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Motion.answerDelay(reduceMotion: reduceMotion)))
            guard !Task.isCancelled else { return }
            withAnimation(Motion.answer(reduceMotion: reduceMotion)) {
                answerShown = true
            }
        }
    }

    /// Zero. Plays the cue first — `speak` is idempotent on the second, so it
    /// does not matter whether the frame or the floor got here first — then
    /// moves on, because the rest is over and the app should not need asking.
    private func finish() {
        guard !completed else { return }
        completed = true
        speak(secondsLeft: 0)
        onComplete()
    }

    /// The last five seconds and zero. Sound is for events you might not be
    /// looking at; the haptic beside it confirms what you are already feeling.
    private func speak(secondsLeft: Int) {
        guard lastSpokenSecond != secondsLeft else { return }
        lastSpokenSecond = secondsLeft

        if secondsLeft == 0 {
            Audio.shared.play(.go)
            Haptics.shared.zero()
        } else if (1 ... 5).contains(secondsLeft) {
            Audio.shared.play(.countdown(second: secondsLeft))
            Haptics.shared.countdown(second: secondsLeft)
        }
    }
}

// MARK: - The clock

// `CountdownRing` moved to its own file so the warm-up can use the same one.
// See `Screens/CountdownRing.swift`.

// MARK: - What is coming

private struct NextUp: View {
    /// Named `step`, not `set`: `set` is a contextual keyword, and referring
    /// to it as the first token of a computed property's body parses as a
    /// setter declaration. That cost a build error and then a fight with
    /// swiftformat, which correctly wanted to strip the `self.` that was
    /// working around it.
    let step: SetStep

    var body: some View {
        VStack(spacing: 2) {
            Text("Next")
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)

            HStack(spacing: 6) {
                Text(step.exercise)
                    .font(TypeScale.bodyEmphasis)
                    .foregroundStyle(Ink.primary)
                if let sub = step.sub {
                    Text("· \(sub)")
                        .font(TypeScale.body)
                        .foregroundStyle(Ink.secondary)
                }
            }

            Text(detail)
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)
        }
        .multilineTextAlignment(.center)
    }

    private var detail: String {
        step.summaryLine
    }
}

// MARK: - The card

private struct StudyCard: View {
    let card: Card
    let revealed: Bool
    /// The answer holds its layout space from the moment `revealed` flips, so
    /// the card grows on schedule, but stays invisible until this follows.
    let answerShown: Bool
    let accent: Color
    /// How long the reader gets before the answer arrives. The bar fills over
    /// exactly this, so the two cannot disagree about how much time is left.
    let thinkingTime: TimeInterval
    let onReveal: () -> Void

    @State private var thinking: Double = 0

    var body: some View {
        Button(action: onReveal) {
            VStack(alignment: .leading, spacing: Space.snug) {
                Text(card.topic.uppercased())
                    .font(TypeScale.microLabel)
                    .tracking(1.8)
                    .foregroundStyle(DawnPalette(progress: 0.5).accentText)

                Text(card.q)
                    .font(TypeScale.question)
                    .foregroundStyle(Ink.primary)
                    .fixedSize(horizontal: false, vertical: true)

                // The thinking bar fills, then becomes the rule the answer sits
                // under. One element doing both jobs.
                //
                // It never filled. It was a fixed 92pt rectangle — the comment
                // above described behaviour the code did not have, for as long
                // as the component has existed, and Eden reported it the first
                // time he watched one: "doesn't run or count down at all".
                //
                // `02-design-brief.md §9` singles this out as the app's example
                // of motion carrying meaning. A bar that does not move carries
                // none.
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Ink.hairline)
                            .frame(height: 1)
                        Rectangle()
                            .fill(revealed ? Ink.hairline : accent)
                            .frame(
                                width: revealed ? proxy.size.width : proxy.size.width * thinking,
                                height: revealed ? 1 : 2
                            )
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 2)

                if revealed {
                    Text(card.a)
                        .font(TypeScale.answer)
                        .foregroundStyle(Ink.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(answerShown ? 1 : 0)
                } else {
                    Text("Tap if you have it")
                        .font(TypeScale.body)
                        .foregroundStyle(Ink.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(revealed ? "\(card.q) \(card.a)" : "\(card.q). Reveal answer.")
        .onAppear {
            // Linear, because it is a clock. Anything eased would misreport how
            // much thinking time is left, which is the one thing it is for.
            withAnimation(.linear(duration: thinkingTime)) { thinking = 1 }
        }
    }
}
