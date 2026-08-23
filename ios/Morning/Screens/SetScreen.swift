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
    /// Where each set falls in the session, 0…1. See `WorkoutChrome.setMarks`.
    var setMarks: [Double] = []

    let onAdjust: (Int) -> Void
    let onLog: () -> Void
    let onBack: () -> Void
    let onEnd: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        // The one screen that must never scroll has to fit the shortest phone
        // it can run on, and it did not. Measured on a 667pt iPhone SE: the
        // whole chrome — Back, "Set 3 / 13", End — was pushed off the top and
        // the Done button was cut in half by the bottom edge. You could not go
        // back, could not end the session, and could barely reach the primary
        // action. `TARGETED_DEVICE_FAMILY = 1` and an iOS 26 floor means the
        // SE 3 is inside the support matrix.
        //
        // So the layout reads the height it was actually given.
        GeometryReader { proxy in
            content(in: proxy.size.height)
        }
    }

    private func content(in available: CGFloat) -> some View {
        VStack(spacing: 0) {
            WorkoutChrome(
                progress: progress,
                step: stepLabel,
                setMarks: setMarks,
                onBack: onBack,
                onEnd: onEnd
            )

            let bay = bayHeight(in: available)
            // "Short screen" means the bay could not have its natural height —
            // whether it shrank to the floor or vanished. One condition, so the
            // things that yield, yield together.
            let cramped = (bay ?? 0) < naturalBayHeight

            // ONE FIXED BLOCK above the rep control.
            //
            // W15 #2, and it is the one Eden was most emphatic about: *"it's
            // position changes based on which exercise screen we're on which is
            // bad, it should always be in the same place like the Done button"*.
            //
            // It moved because everything above it was intrinsically sized — a
            // two-cue push-up pushed it high, a four-cue floor fly pushed it
            // low, and the control you reach for with a knuckle at 6:10am was
            // never twice in the same place. The block is a fixed height now,
            // top-aligned, so whatever it contains the counter lands on the
            // same line. Screens with less to say leave air, which is the price
            // and it is worth paying.
            //
            // The demonstration is the thing that gives way inside it — same
            // argument as `bayHeight`: it illustrates, everything else
            // instructs.
            VStack(spacing: 0) {
                metadata

                if let height = bay {
                    ExerciseMotionBay(
                        treatment: .atmospheric,
                        exercise: setStep.exercise,
                        accent: palette.accent
                    )
                    .frame(maxHeight: height)
                    .padding(.top, Space.step)
                    .layoutPriority(-1)
                }

                cues
                    .padding(.top, Space.step)

                Spacer(minLength: 0)
            }
            .frame(height: upperBlock(in: available), alignment: .top)
            .clipped()

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
                // `Cue.confirm` was composed and never played. The web fires it
                // from exactly this button (`src/screens/Workout.tsx`), and the
                // haptic alone is not the same acknowledgement when the phone
                // is on the floor rather than in your hand.
                Audio.shared.play(.confirm)
                onLog()
            }

            // Dropped under the same condition as the bay, and deliberately
            // not under a second threshold of its own: when there is no room
            // for the illustration there is no room for the footnote either.
            //
            // It is the right thing to lose. Everything else on this screen
            // either instructs or is the control; "13 sets to go" is
            // orientation, and the progress rail two inches above it already
            // says the same thing without words.
            if !cramped {
                Text(setsRemaining == 1 ? "1 set to go" : "\(setsRemaining) sets to go")
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Ink.tertiary)
                    .padding(.top, Space.snug)
            }
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

    /// Two columns, because there were four stacked lines down the left and
    /// nothing at all down the right.
    ///
    /// W15 #1, in Eden's words: *"too cramped in that column… it creates a
    /// werid thing where we have a column on text on the left side then nothing
    /// on the right"*, and *"just the target is important"*.
    ///
    /// So the target moves right and becomes the second-biggest thing on the
    /// screen after the counter — it is the number you are trying to hit, and
    /// it was set in the same grey as the sub-label. The left column keeps what
    /// tells you how to set up: the name, the sub, the load and the position.
    ///
    /// The sub-label stays rather than being cut. "lying on your back" is
    /// redundant on a floor fly and reads as clutter, but the same field says
    /// "deficit — hands on books" on a push-up, which is the whole setup. What
    /// was wrong was not that it existed; it was that four lines were competing
    /// in one column while half the width sat empty.
    private var metadata: some View {
        HStack(alignment: .top, spacing: Space.step) {
            VStack(alignment: .leading, spacing: 2) {
                Text(setStep.exercise)
                    .font(TypeScale.title)
                    .foregroundStyle(Ink.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if let sub = setStep.sub {
                    Text(sub)
                        .font(TypeScale.body)
                        .foregroundStyle(Ink.tertiary)
                        .lineLimit(2)
                }

                Text(positionLine)
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: -1) {
                Text("TARGET")
                    .font(TypeScale.microLabel)
                    .tracking(1.4)
                    .foregroundStyle(Ink.tertiary)
                Text(setStep.target.replacingOccurrences(of: " reps", with: ""))
                    .font(TypeScale.counter(30))
                    .monospacedDigit()
                    .foregroundStyle(Ink.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("reps")
                    .font(TypeScale.microLabel)
                    .foregroundStyle(Ink.tertiary)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Space.snug)
        .overlay(alignment: .bottomLeading) {
            if setStep.straightIntoNext == true {
                Text("No rest after this — straight into the next one.")
                    .font(TypeScale.body)
                    .foregroundStyle(palette.accentText)
                    .offset(y: 20)
            }
        }
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

    /// Four cues need a shorter bay than two, and a short phone needs a shorter
    /// bay than a tall one. The screen never scrolls, so something has to give,
    /// and it is the demonstration rather than the copy — every other element
    /// here either instructs (the cues, the target) or is the control itself.
    /// The bay is the only thing that merely *illustrates*, so it yields first
    /// and it yields alone.
    ///
    /// The floor is 72pt. Below that the figure stops reading as a body and
    /// becomes a smudge, at which point showing nothing would be honester —
    /// but 72pt is enough to fit the worst content on the shortest supported
    /// phone, so that trade never has to be made.
    /// `nil` means there is no room for it at all and it is not drawn.
    ///
    /// That case is real rather than defensive: four cues on a 667pt phone
    /// leaves nothing for a demonstration, and at 72pt the figure has already
    /// stopped reading as a body. Showing a smudge would be worse than showing
    /// nothing, and clipping the Done button to keep the smudge would be worse
    /// than both — which is what the screen did before this.
    /// What the bay wants, before the screen height is taken into account.
    /// Four cues need a shorter one than two.
    private var naturalBayHeight: CGFloat {
        setStep.cues.count >= 4 ? 142 : 178
    }

    /// Everything above the rep control, at a height that does not depend on
    /// the exercise. Sized from what has to sit below it: the control itself
    /// (83), the primary button (68), the footer, and the gaps between them.
    private func upperBlock(in available: CGFloat) -> CGFloat {
        // Piecewise, and the split is real rather than a fudge: a 667pt phone
        // has 207pt less to spend than the 874pt one, and after W15 #4 stepped
        // the type up the lower half needs more of what is left. One formula
        // that fits the SE would take 32pt of breathing room off the Pro — and
        // that room is the fix for "always too close to the text above it".
        let lower: CGFloat = available < 760 ? 306 : 268
        return max(240, available - lower)
    }

    private func bayHeight(in available: CGFloat) -> CGFloat? {
        let base = naturalBayHeight
        // Four cues cost roughly 80pt more than two, so they get charged for it
        // rather than the bay absorbing the difference twice.
        let crowding: CGFloat = setStep.cues.count >= 4 ? 80 : 0
        let room = available - 620 - crowding
        if room < 20 {
            return nil
        }
        return min(base, max(72, room))
    }
}

// MARK: - Chrome

/// Back, where you are, and End. Deliberately quiet: `01-product.md` puts
/// nothing important in the top 15% because the phone is on the floor.
struct WorkoutChrome: View {
    let progress: Double
    let step: String
    /// One tick per set, at its position in the session.
    ///
    /// W15 #3, and it is a restoration rather than an invention: the web build
    /// draws exactly this under its rail (`src/components/Chrome.tsx`) and the
    /// port kept only the bar. Eden noticed — "in the prev app we had more
    /// meaningfull markings on the progress bar that showed more context about
    /// what's left or how many (super/not superset)".
    ///
    /// The ticks answer both halves of that. How many are left is countable at
    /// a glance, and because superset partners sit adjacent with no rest
    /// between them, their ticks bunch — so the shape of the row shows the
    /// structure of the session without a word of explanation.
    var setMarks: [Double] = []
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
                ZStack(alignment: .topLeading) {
                    Capsule().fill(Ink.hairline)
                        .frame(height: 3)
                    Capsule()
                        .fill(DawnPalette(progress: progress).accent)
                        .frame(width: proxy.size.width * progress, height: 3)

                    ForEach(Array(setMarks.enumerated()), id: \.offset) { _, at in
                        Circle()
                            .fill(at <= progress
                                ? DawnPalette(progress: progress).accent
                                : Ink.primary.opacity(0.18))
                            .frame(width: 3, height: 3)
                            .offset(x: proxy.size.width * at - 1.5, y: 7)
                    }
                }
            }
            .frame(height: 13)
        }
        .frame(height: 82)
    }
}
