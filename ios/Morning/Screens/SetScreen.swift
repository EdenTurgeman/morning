import SwiftUI

/* ===========================================================================
 *  THE SET SCREEN
 *  ---------------------------------------------------------------------------
 *  The most important screen in the app. `02-design-brief.md §8`: everything on
 *  it competes for the same space, hierarchy here is the single hardest design
 *  problem in the app, and the web version's answer — fixed header, scrolling
 *  middle, pinned controls — is a DOM compromise, not an idea to inherit.
 *
 *  So nothing here scrolls. If the longest content did not fit, the design
 *  would be wrong, not the screen: the stress case is the longest exercise
 *  name with four cues, and it has a fixture.
 *
 *  What must be on screen at once, from `§8`: exercise name, sub-label, load,
 *  "set 2 of 3", superset position, the form cues with the ones carrying the
 *  training effect emphasised, the target range, the rep counter pre-filled
 *  from last time, last time's number, and ONE primary action.
 *
 *  Nothing important lives in the top 15%: at 6:10am the phone is on the floor.
 * ======================================================================== */

struct SetScreen: View {
    let setStep: SetStep
    let progress: Double
    let stepLabel: String
    let setsRemaining: Int
    let reps: Int
    let previous: History.PreviousSet?
    let isComparable: Bool
    let isBeating: Bool
    let namespace: Namespace.ID

    let onAdjust: (Int) -> Void
    let onLog: () -> Void
    let onBack: () -> Void
    let onEnd: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        VStack(spacing: 0) {
            WorkoutChrome(progress: progress, step: stepLabel, onBack: onBack, onEnd: onEnd)

            metadata

            ExerciseMotionBay(treatment: .atmospheric, exercise: setStep.exercise, accent: palette.accent)
                .frame(height: bayHeight)
                .padding(.top, Space.step)

            cues
                .padding(.top, Space.step)

            Spacer(minLength: Space.step)

            RepControl(
                reps: reps,
                previous: previous,
                isComparable: isComparable,
                isBeating: isBeating,
                accent: palette.accent,
                namespace: namespace,
                onAdjust: onAdjust
            )

            Spacer(minLength: Space.step)

            DawnPrimaryButton(title: "Done", treatment: .atmospheric, accent: palette.accent) {
                Haptics.shared.logged()
                onLog()
            }

            Text(setsRemaining == 1 ? "1 set to go" : "\(setsRemaining) sets to go")
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)
                .padding(.top, Space.snug)
        }
        .padding(.horizontal, Space.gutter)
        .safeAreaPadding(.bottom, Space.snug)
        // No backdrop here on purpose. The sky belongs to `WorkoutHost`, not to
        // this screen: it is the one thing that must not blink when Set becomes
        // Rest. Owned per-screen, it faded out and in with everything else and
        // the whole display dipped to near-black mid-transition.
        // The workout deliberately clamps Dynamic Type. `§6` allows it: this
        // type is already at the top of the scale, and a screen that must never
        // scroll would break rather than help at accessibility sizes. Reading
        // screens support them instead.
        .dynamicTypeSize(.large)
    }

    // MARK: - Parts

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(setStep.exercise)
                .font(TypeScale.title)
                .foregroundStyle(Ink.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            if let sub = setStep.sub {
                Text(sub)
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
            }

            Text(positionLine)
                .font(TypeScale.body)
                .foregroundStyle(Ink.secondary)

            Text("Target \(setStep.target)")
                .font(TypeScale.bodyEmphasis)
                .foregroundStyle(Ink.secondary)

            if setStep.straightIntoNext == true {
                Text("No rest after this — straight into the next one.")
                    .font(TypeScale.body)
                    .foregroundStyle(palette.accentText)
                    .padding(.top, Space.tight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Space.snug)
    }

    /// Load, set position and superset position on one line — three facts that
    /// are each too small to earn a line of their own.
    private var positionLine: String {
        var parts: [String] = []
        if let load = setStep.load {
            parts.append("\(Plates.format(load)) kg")
        } else if setStep.bodyweight {
            parts.append("bodyweight")
        }
        parts.append("set \(setStep.n) of \(setStep.of)")
        if let superset = setStep.superset {
            parts.append("superset \(superset.index) of \(superset.of)")
        }
        return parts.joined(separator: " · ")
    }

    private var cues: some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            ForEach(Array(setStep.cues.enumerated()), id: \.offset) { _, cue in
                HStack(alignment: .top, spacing: Space.snug) {
                    // The cues carrying the training effect are emphasised;
                    // `§8` asks for that and the emphasis is the dot plus the
                    // weight, not a second colour.
                    Circle()
                        .fill(carriesEffect(cue) ? palette.accent : Ink.hairline)
                        .frame(width: 5, height: 5)
                        .padding(.top, 8)

                    Text(cue)
                        .font(carriesEffect(cue) ? TypeScale.bodyEmphasis : TypeScale.body)
                        .foregroundStyle(carriesEffect(cue) ? Ink.primary : Ink.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A cue carries the training effect when it names one.
    ///
    /// `intensityWords` is already in `Program.swift`, transcribed from the web
    /// build's `INTENSITY_WORDS` — it is content, not a heuristic. My first
    /// version here guessed at "contains a shouted word", which silently missed
    /// "Go to failure" and "mechanism": both lowercase, both exactly the cues
    /// that matter most.
    ///
    /// The emphasis is brighter ink, heavier weight and a filled accent marker
    /// — deliberately NOT a second text colour. The accent is already doing a
    /// job and a second hue at 6am is noise.
    private func carriesEffect(_ cue: String) -> Bool {
        intensityWords.contains { cue.contains($0) }
    }

    /// Four cues need a shorter bay than two. The screen never scrolls, so
    /// something has to give, and it is the demonstration rather than the copy.
    private var bayHeight: CGFloat {
        setStep.cues.count >= 4 ? 142 : 178
    }
}

// MARK: - Chrome

/// Back, where you are, and End. Deliberately quiet: `01-product.md` puts
/// nothing important in the top 15% because the phone is on the floor.
struct WorkoutChrome: View {
    let progress: Double
    let step: String
    let onBack: () -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: Space.snug) {
            ZStack {
                HStack {
                    Button(action: onBack) {
                        Label("Back", systemImage: "chevron.left")
                            .labelStyle(.titleAndIcon)
                            .font(TypeScale.label)
                            .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .leading)
                    }

                    Spacer()

                    Button("End", action: onEnd)
                        .font(TypeScale.label)
                        .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .trailing)
                }
                .foregroundStyle(Ink.secondary)

                Text(step)
                    .font(TypeScale.label.monospacedDigit())
                    .foregroundStyle(Ink.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Ink.hairline)
                    Capsule()
                        .fill(DawnPalette(progress: progress).accent)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 3)
        }
        .frame(height: 72)
    }
}
