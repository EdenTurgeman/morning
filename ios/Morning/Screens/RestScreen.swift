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
    let onBack: () -> Void
    let onEnd: () -> Void

    @State private var revealed = false
    @State private var lastSpokenSecond: Int?
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
                RestTimer(
                    remaining: remaining,
                    total: Double(seconds),
                    compact: card != nil && revealed,
                    accent: palette.accent,
                    namespace: namespace
                )
                .onChange(of: Int(ceil(remaining))) { _, value in
                    speak(secondsLeft: value)
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
                StudyCard(card: card, revealed: revealed, accent: palette.accent) {
                    // Tapping only brings the answer forward.
                    reveal()
                }
                .padding(.top, Space.step)
            }

            Spacer(minLength: Space.step)

            if let next {
                NextUp(set: next)
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
        .task(id: endsAt) {
            revealed = false
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

private struct RestTimer: View {
    let remaining: TimeInterval
    let total: Double
    let compact: Bool
    let accent: Color
    let namespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var size: CGFloat {
        compact ? 136 : 232
    }

    private var fraction: Double {
        total > 0 ? min(1, max(0, remaining / total)) : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Ink.hairline, lineWidth: compact ? 4 : 5)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(accent, style: StrokeStyle(lineWidth: compact ? 4 : 5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: -2) {
                Text(Int(ceil(remaining)), format: .number)
                    .font(compact ? TypeScale.counterCompact : TypeScale.counter(82))
                    .monospacedDigit()
                    .contentTransition(Motion.numeric(reduceMotion: reduceMotion, countsDown: true))
                    .foregroundStyle(Ink.primary)

                Text("SEC")
                    .font(TypeScale.label)
                    .tracking(1.2)
                    .foregroundStyle(Ink.secondary)
            }
        }
        .frame(width: size, height: size)
        // The counter is the source and the ring follows it, permanently.
        // Both declaring themselves the source is a conflict SwiftUI resolves
        // silently and inconsistently — it picked the counter, so Set→Rest
        // morphed and Rest→Set only cross-faded.
        .matchedGeometryEffect(id: WorkObject.id, in: namespace, isSource: false)
        .animation(Motion.timerResize(reduceMotion: reduceMotion), value: compact)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(ceil(remaining))) seconds remaining")
    }
}

// MARK: - What is coming

private struct NextUp: View {
    let set: SetStep

    var body: some View {
        VStack(spacing: 2) {
            Text("Next")
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)

            HStack(spacing: 6) {
                Text(set.exercise)
                    .font(TypeScale.bodyEmphasis)
                    .foregroundStyle(Ink.primary)
                if let sub = set.sub {
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
        var parts = ["set \(set.n) of \(set.of)"]
        if let load = set.load {
            parts.append("\(Plates.format(load)) kg")
        }
        parts.append(set.target)
        return parts.joined(separator: " · ")
    }
}

// MARK: - The card

private struct StudyCard: View {
    let card: Card
    let revealed: Bool
    let accent: Color
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
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Ink.hairline)
                        .frame(height: 1)
                    Rectangle()
                        .fill(revealed ? Ink.hairline : accent)
                        .frame(width: revealed ? nil : 92, height: revealed ? 1 : 2)
                }

                if revealed {
                    Text(card.a)
                        .font(TypeScale.answer)
                        .foregroundStyle(Ink.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
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
}
