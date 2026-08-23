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
    /// Where each set falls in the session, 0…1. See `WorkoutChrome.setMarks`.
    var setMarks: [Double] = []
    /// True when this exercise appears more than once in the session, so its
    /// sub-label is the only thing telling the two apart. See `factLine`.
    var subDisambiguates = false

    let onAdjust: (Int) -> Void
    let onLog: () -> Void
    let onBack: () -> Void
    let onEnd: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        // NOTHING HERE IS A MEASURED CONSTANT ANY MORE, and that is the fix.
        //
        // The previous version computed the height of everything above the rep
        // control as `available - 268`, from a comment that added up the parts
        // below it. The sum was wrong by 35pt — it counted the 82pt stepper row
        // as the whole rep control and forgot the caption and the comparison
        // line under it — so on a 16 Pro the stack was 35pt taller than the
        // screen and the overflow went where overflow goes: **the Done button
        // ended up 6.7pt from the bottom edge**, sitting on the home indicator.
        // Measured, after I had called the same layout verified.
        //
        // W15 #9, in Eden's words: *"we ruined the done button, it's pinned
        // downstairs"*.
        //
        // So the arithmetic is gone. The block above the control is the only
        // flexible thing in the stack and takes whatever is left over, which
        // means it is impossible for the total to exceed the screen and the
        // control still lands on the same line on every exercise — the thing
        // W15 #2 asked for. That only holds because `RepControl` is a fixed
        // height now; see the note on `RepControl.height`.
        VStack(spacing: 0) {
            WorkoutChrome(
                progress: progress,
                step: stepLabel,
                setMarks: setMarks,
                onBack: onBack,
                onEnd: onEnd
            )

            // The demonstration is what gives way, and `ViewThatFits` is what
            // decides — not a threshold I guessed at per device.
            //
            // The screen never scrolls, so on a short phone something has to
            // go, and it is the bay: every other element here either instructs
            // (the cues, the target) or is the control itself. The bay is the
            // only thing that merely *illustrates*.
            //
            // The first candidate asks for at least 120pt of bay. Below that
            // the figure stops reading as a body and becomes a smudge, so if it
            // cannot have 120 it does not appear at all — which is honester
            // than a smear, and much honester than clipping the Done button to
            // keep one.
            ViewThatFits(in: .vertical) {
                upper(withBay: true)
                upper(withBay: false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            .layoutPriority(-1)

            RepControl(
                reps: reps,
                previous: previous,
                isComparable: isComparable,
                isBeating: isBeating,
                accent: palette.accent,
                stepKey: stepLabel,
                onAdjust: onAdjust
            )
            // W15 #2's other half: *"the number and button of reps is always
            // too close to the text above it"*. The block above is flexible, so
            // this gap is not taken from anywhere — the figure gives it up.
            .padding(.top, Space.section)

            DawnPrimaryButton(title: "Done", treatment: .atmospheric, accent: palette.accent) {
                // `Cue.confirm` was composed and never played. The web fires it
                // from exactly this button (`src/screens/Workout.tsx`), and the
                // haptic alone is not the same acknowledgement when the phone
                // is on the floor rather than in your hand.
                Audio.shared.play(.confirm)
                onLog()
            }
            .padding(.top, Space.step)

            Text(setsRemaining == 1 ? "1 set to go" : "\(setsRemaining) sets to go")
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)
                .padding(.top, Space.snug)
        }
        .padding(.horizontal, Space.gutter)
        // 22, not 9. Nine points put the primary action of the whole app
        // directly on top of the home indicator; see the note on `body`.
        .safeAreaPadding(.bottom, Space.gutter)
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

    /// Everything above the rep control.
    ///
    /// The bay is `layoutPriority(-1)` and the trailing spacer `-2`, so the
    /// slack goes into the FIGURE before it goes into empty space. Before this
    /// the order was the other way round by default and a 16 Pro showed a
    /// 161pt figure above 120pt of nothing.
    private func upper(withBay: Bool) -> some View {
        VStack(spacing: 0) {
            metadata

            if withBay {
                ExerciseMotionBay(
                    treatment: .atmospheric,
                    exercise: setStep.exercise,
                    accent: palette.accent
                )
                .frame(minHeight: 120, maxHeight: 300)
                .padding(.top, Space.step)
                .layoutPriority(-1)
            }

            cues
                .padding(.top, Space.step)

            Spacer(minLength: 0)
                .layoutPriority(-2)
        }
    }

    // MARK: - Parts

    /// DISTILLED, because it was four lines fighting one sentence.
    ///
    /// W15 #14, on the myo set: *"the whole top is sooo cluttered and
    /// ellipsising a lot, so much of that info is unecessary and should be
    /// distilled and minimized."* His photo shows the name cut to "Lateral
    /// rai…", the position line broken across "6.25 kg · set 1 / of 3", and the
    /// right-hand column reading **"TARGET / all-out to failure / reps"**.
    ///
    /// One assumption caused all of it: that a target is always a short numeric
    /// range. Four of the five blocks have one. The myo block's first set is
    /// prose, set at `counter(30)` it needed ~200pt, and it took that width
    /// from the exercise name — which is why the name was the thing ellipsised.
    ///
    /// So the big right-hand column is now for numbers only, and a prose target
    /// goes down the left where a sentence belongs. And "reps" is only hung
    /// under a target that counts reps; "all-out to failure reps" is not
    /// English.
    private var metadata: some View {
        HStack(alignment: .top, spacing: Space.step) {
            VStack(alignment: .leading, spacing: 3) {
                Text(setStep.exercise)
                    .font(TypeScale.title)
                    .foregroundStyle(Ink.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                Text(factLine)
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let prose = proseTarget {
                    Text("Target: \(prose)")
                        .font(TypeScale.bodyEmphasis)
                        .foregroundStyle(Ink.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // LAID OUT, not overlaid.
                //
                // W15 #12. This was an `.overlay(alignment: .bottomLeading)`
                // with a hardcoded `.offset(y: 20)`, which is not a position —
                // it is a guess about how tall the lines above it are. On a
                // superset the guess was short and in Eden's photo the sentence
                // printed **through the top edge of the MOVEMENT box**.
                if setStep.straightIntoNext == true {
                    Text("No rest after this — straight into the next one.")
                        .font(TypeScale.body)
                        .foregroundStyle(palette.accentText)
                        .padding(.top, Space.tight)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let count = countedTarget {
                VStack(alignment: .trailing, spacing: -1) {
                    Text("TARGET")
                        .font(TypeScale.microLabel)
                        .tracking(1.4)
                        .foregroundStyle(Ink.tertiary)
                    Text(count)
                        .font(TypeScale.counter(30))
                        .monospacedDigit()
                        .foregroundStyle(Ink.primary)
                        .lineLimit(1)
                    Text("reps")
                        .font(TypeScale.microLabel)
                        .foregroundStyle(Ink.tertiary)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Space.snug)
    }

    /// "8–15", or nil when the target is a sentence rather than a count.
    ///
    /// A digit is the test, and it is the honest one: every counted target in
    /// the program is a numeric range and the only prose one is "all-out to
    /// failure".
    private var countedTarget: String? {
        let target = setStep.target
        guard target.contains(where: \.isNumber) else { return nil }
        return target.replacingOccurrences(of: " reps", with: "")
    }

    private var proseTarget: String? {
        countedTarget == nil ? setStep.target : nil
    }

    /// ONE line of setup facts, where there were two.
    ///
    /// The sub-label survives only where it distinguishes this set from another
    /// set of the same exercise in the session — the same rule Home's outline
    /// uses. Eden has now twice called the sub-label unnecessary here: *"there's
    /// uneeded text there about the weight 'lying your back'"* and *"so much of
    /// that info is unecessary"*. But "myo-reps" is the only thing separating
    /// the myo lateral raise from the one in the superset above it, and
    /// dropping it everywhere left session B showing the same exercise twice
    /// with no explanation.
    ///
    /// `02-design-brief.md §8` does list the sub-label among what must be on
    /// screen. This narrows it rather than removing it, and the setup detail it
    /// drops — "deficit — hands on books", "lying on your back" — is said again
    /// by the cues six lines below.
    private var factLine: String {
        var parts: [String] = []
        if subDisambiguates, let sub = setStep.sub {
            parts.append(sub)
        }
        if let load = setStep.load {
            parts.append("\(Plates.format(load)) kg")
        } else if setStep.bodyweight {
            parts.append("bodyweight")
        }
        parts.append("set \(setStep.n) of \(setStep.of)")
        if let superset = setStep.superset {
            parts.append("superset \(superset.index)/\(superset.of)")
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
    ///
    /// NOT defaulted. It was, and only `SetScreen` passed it — so the rail grew
    /// ticks on a set and lost them again on every rest and on the warm-up.
    /// Eden: *"when you switch to the rest screens the progress bar at the top
    /// changes to the old style before our recent changes, i don't link any
    /// inconsistancies like this"*. A default value is what let three call
    /// sites disagree, so there is no default now.
    let setMarks: [Double]
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
