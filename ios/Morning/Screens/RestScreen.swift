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
    /// The rail's ticks. See `WorkoutChrome.setMarks` — passed on every screen
    /// in the workout, because a rail that changes shape between them reads as
    /// a bug.
    let setMarks: [Double]

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
    /// When the answer is due. The thinking bar fills against this rather than
    /// against an animation, so the two cannot disagree. See `StudyCard`.
    @State private var revealAt: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        VStack(spacing: 0) {
            WorkoutChrome(progress: progress, step: stepLabel, setMarks: setMarks, onBack: onBack, onEnd: onEnd)

            // CENTRED IN ITS OWN BAND.
            //
            // W15 #15: *"the counter isn't centered in it's section at the top,
            // the spacing is weird between the elements."* Measured off his
            // photo, the rail-to-ring gap was ~150px and the ring-to-card gap
            // ~50px.
            //
            // The cause was two `Spacer(minLength:)`s splitting the leftover
            // space evenly — one above the ring and one below the card. The
            // upper one pushed the ring DOWN while the card stayed pinned right
            // under it, so the ring drifted to the bottom of the space it was
            // supposed to sit in the middle of. One flexible band, and the gap
            // below the card is fixed.
            GeometryReader { proxy in
                TimelineView(.animation) { context in
                    let remaining = max(0, endsAt.timeIntervalSince(context.date))
                    CountdownRing(
                        remaining: remaining,
                        total: Double(seconds),
                        // The band is what is left between the chrome and the
                        // card, so this shrinks only as far as the answer
                        // actually forces it to.
                        diameter: min(proxy.size.width, proxy.size.height) - Space.gutter,
                        accent: palette.accent
                    )
                    .onChange(of: Int(ceil(remaining))) { _, value in
                        speak(secondsLeft: value)
                        if value <= 0 {
                            finish()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                    thinkingTime: Deck.revealDelay(forRestOf: seconds),
                    revealAt: revealAt
                ) {
                    // Tapping only brings the answer forward.
                    reveal()
                }
                .padding(.top, Space.step)
            }

            Spacer(minLength: Space.section)
                .layoutPriority(-1)

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
            guard card != nil else {
                revealAt = nil
                return
            }
            let delay = Deck.revealDelay(forRestOf: seconds)
            revealAt = Date().addingTimeInterval(delay)
            try? await Task.sleep(for: .seconds(delay))
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
    /// The moment the answer is due, set by the Rest screen when the rest
    /// begins. `nil` until then.
    let revealAt: Date?
    let onReveal: () -> Void

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

                        if revealed {
                            Rectangle()
                                .fill(Ink.hairline)
                                .frame(width: proxy.size.width, height: 1)
                        } else {
                            TimelineView(.animation) { context in
                                Rectangle()
                                    .fill(accent)
                                    .frame(width: proxy.size.width * filled(at: context.date), height: 2)
                            }
                        }
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
    }

    /// How much of the thinking time has gone, 0…1.
    ///
    /// READ OFF A CLOCK, because the animation version did not run.
    ///
    /// It was `withAnimation(.linear(duration: thinkingTime)) { thinking = 1 }`
    /// in `onAppear`, and measured across a 16-second capture of a real rest
    /// the bar was never on screen at all: nothing at 4.5s, 7.5s or 10.5s, then
    /// the full-width rule at 12.0s once the answer arrived. `thinking` stayed
    /// at 0, so the bar had zero width, so there was no bar. That is exactly
    /// what Eden reported — *"doesn't run or count down at all"* — and it is
    /// the second fix this component has had for the same complaint.
    ///
    /// An implicit animation is a side effect that either happens or does not,
    /// and there is no way to look at a screenshot and tell which. A fraction
    /// of two dates is a value: if the bar is in the wrong place, the number is
    /// wrong, and the number can be printed. Every other timer in this app
    /// already works this way — that is what `endsAt` is for — and this was the
    /// one that did not.
    ///
    /// Linear, because it is a clock. Anything eased would misreport how much
    /// thinking time is left, which is the one thing it is for.
    private func filled(at now: Date) -> Double {
        guard let revealAt, thinkingTime > 0 else { return 0 }
        let remaining = revealAt.timeIntervalSince(now)
        return min(1, max(0, 1 - remaining / thinkingTime))
    }
}
