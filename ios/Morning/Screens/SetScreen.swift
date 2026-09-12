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
    /// THE CHROME IS THE HOST'S. `WorkoutHost` draws `WorkoutChrome` once,
    /// above the step transition, so the rail, the set marks, BACK and END do
    /// not blink when one screen becomes another — `plans/011`. `progress`,
    /// `setMarks`, `onBack` and `onEnd` went with it.
    let setStep: SetStep
    /// Kept after the chrome left: the rep counter keys its numeric-roll
    /// identity to this, so a new set's number never rolls from the last
    /// set's. See `stepKey` below.
    let stepLabel: String
    let reps: Int
    let previous: History.PreviousSet?
    let isComparable: Bool
    let isBeating: Bool
    /// True when this exercise appears more than once in the session, so its
    /// sub-label is the only thing telling the two apart. See `factLine`.
    var subDisambiguates = false

    let onAdjust: (Int) -> Void
    let onLog: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            // The ply HUGS its content and the slack falls on the stock below
            // it. Sized to fill instead, the sheet kept the leftover space
            // INSIDE itself — a pasted sheet with a void in the middle, which
            // is the exact "lot of empty space" that got R3 rejected.
            Ply(tornBottom: true, seed: 11) {
                upper(withBay: false)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.horizontal, Space.gutter)
                    .padding(.bottom, Space.gutter)
            }

            // The diagram is PRINTED ON THE STOCK, below the pasted sheet,
            // rather than boxed inside it. It is the one element here that
            // merely illustrates — everything else instructs or is the control
            // — so it is the one that gives way: below 120pt the figure stops
            // reading as a body and becomes a smudge, so it leaves rather than
            // smears.
            //
            // NO SPACERS AROUND IT. A Spacer either side claimed the slack
            // before `ViewThatFits` was proposed anything, so it was measured
            // against ~0pt and silently chose the empty branch on every screen
            // — the bay simply never appeared. This container takes the
            // leftover itself and hands the real figure to the decision.
            ExerciseMotionBay(
                treatment: .precise,
                exercise: setStep.exercise,
                accent: Paper.press,
                paper: true,
                // 1.3, at Eden's report: *"i think the person animation size is
                // too little maybe now we'll have extra space for it"*. The bay
                // takes the leftover height and the sets-to-go line below gave
                // some of it back, but the figure never used what it had — a
                // pose spans well under the full unit, so a taller bay drew the
                // same small body with more paper around it.
                // 1.15, not more. The `Canvas` clips at its bounds, so past
                // this the pose's extremities are cut rather than drawn: at 1.3
                // the measured figure grew only 11% because the rest was
                // outside the box. The real constraint is that a figure-unit
                // IS the bay's height, so a wide, short bay under-uses its own
                // width — fixing that means fitting the pose's bounding box,
                // which is a change to `FigureRenderer`, not a number here.
                figureScale: 1.35
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            RepControl(
                reps: reps,
                previous: previous,
                isComparable: isComparable,
                isBeating: isBeating,
                accent: Paper.orange,
                stepKey: stepLabel,
                onAdjust: onAdjust
            )
            .padding(.horizontal, Space.gutter)
            // W15 #2's other half: *"the number and button of reps is always
            // too close to the text above it"*. The block above is flexible, so
            // this gap is not taken from anywhere — the figure gives it up.
            .padding(.top, Space.section)

            // TALLER THAN THE HOUSE PRIMARY, on this screen only.
            //
            // Eden: *"the done button is a little too high… we can enlarge the
            // Done a little"*. It is the single most-pressed control in the
            // app, hit with a knuckle, on a phone on the floor. Home's "Start"
            // keeps `Hit.primary` — it is pressed once a session, sitting down.
            PaperPrimaryButton(title: "Done", height: 78) {
                // `Cue.confirm` was composed and never played. The web fires it
                // from exactly this button (`src/screens/Workout.tsx`), and the
                // haptic alone is not the same acknowledgement when the phone
                // is on the floor rather than in your hand.
                Audio.shared.play(.confirm)
                onLog()
            }
            // ROOM ABOVE IT. Eden: *"space it from the number card above it so
            // movement and it have more space around them"*. 12pt put the
            // primary action right against the rep sheet's torn bottom edge,
            // so the two read as one block rather than as a card and the
            // control that commits it.
            .padding(.top, Space.gutter)
            // FIXED, NOT STRETCHED. As the VStack's last child the button's
            // block grew to 136pt against a declared 78 — measured — and ran
            // flush to the bottom edge, under the home indicator. The trailing
            // "sets to go" line used to absorb that slack; with it gone the
            // button has to refuse it.
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, Space.snug)
        }
        // NO GROUND HERE. `WorkoutHost` paints the stock and the halftone as a
        // ZStack sibling, above the step transition, and this screen is drawn
        // inside that transition — so painting it again meant **a second
        // full-screen halftone canvas, 14,175 dots, alive inside the subtree
        // that animates on every Done.** `RestScreen` and `WarmupScreen` never
        // did this; only this screen.
        //
        // NOT a double exposure, though it looks like one on paper: the ground
        // paints an OPAQUE stock behind its halftone, so this screen's copy
        // covered the host's rather than compounding it. Measured across the
        // bare margin, mean luma 192.0 before and 191.0 after — the dots shift
        // phase because the grid is now aligned to the screen instead of to
        // this view, and that is the whole visual difference.
        //
        // So this is a pure cost removal, not a fix to how it looks.
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
    private func upper(withBay _: Bool) -> some View {
        VStack(spacing: 0) {
            metadata

            cues
                .padding(.top, Space.step)

            // The trailing Spacer that used to live here is gone. It existed to
            // push content up when this block FILLED the screen; inside a ply
            // that hugs its content it did the opposite — it inflated the sheet
            // from within and left a void between the cues and the torn edge.
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
                HStack(alignment: .firstTextBaseline, spacing: Space.snug) {
                    Text(setStep.exercise)
                        .font(PaperType.title)
                        .tracking(TypeScale.titleTracking)
                        .foregroundStyle(Paper.press)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    // `SetStep.intense`, RENDERED — for the first time in this
                    // app's life.
                    //
                    // `spec.md` §3.3 has required since W0 that a set you are
                    // meant to take past failure be distinguishable BEFORE you
                    // start it, and the flag has been compiled into every step
                    // with nothing reading it. The R4 prototype drew it, Eden
                    // approved that prototype, and the port kept the palette
                    // and dropped the stamp — the same way the crossing wipe
                    // was lost. Second instance of that pattern in two days.
                    if setStep.intense {
                        PaperStamp(text: "All out")
                    }
                }

                Text(factLine)
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press)
                    .fixedSize(horizontal: false, vertical: true)

                if let prose = proseTarget {
                    Text("Target: \(prose)")
                        .font(TypeScale.bodyEmphasis)
                        .foregroundStyle(Paper.press)
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
                    Text("No rest after this. Straight into the next one.")
                        .font(TypeScale.body)
                        .foregroundStyle(Paper.blue)
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
                        .foregroundStyle(Paper.press)
                    Text(count)
                        .font(TypeScale.counter(30))
                        .monospacedDigit()
                        .foregroundStyle(Paper.press)
                        .lineLimit(1)
                    Text("reps")
                        .font(TypeScale.microLabel)
                        .foregroundStyle(Paper.press)
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
    /// drops — "deficit, hands on books", "lying on your back" — is said again
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
                        .fill(carriesEffect(cue) ? Paper.orange : Paper.press.opacity(0.35))
                        .frame(width: 5, height: 5)
                        .padding(.top, 8)

                    Text(cue)
                        .font(carriesEffect(cue) ? TypeScale.bodyEmphasis : TypeScale.body)
                        .foregroundStyle(Paper.press)
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
                    // Both carried no button style at all, and the VStack
                    // below sets `.foregroundStyle(Paper.press)` over the top,
                    // which suppresses whatever tint the system would have
                    // given them. So the two controls in the corner of every
                    // workout screen — one of which discards the session —
                    // acknowledged nothing.
                    Button("BACK", action: onBack)
                        .buttonStyle(PressLabelStyle())
                        .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .leading)
                        // THE WHOLE TARGET IS TAPPABLE, NOT JUST THE GLYPHS.
                        // A `.frame(min…: Hit.…)` on a Button reserves the layout space and does
                        // NOT extend its hit region — SwiftUI still hit-tests the rendered label.
                        // With `alignment: .leading` the text is then pinned to one edge of a 68pt
                        // box, so most of the target was dead paper.
                        //
                        // Eden, on the phone: *"seems like the clickable area is the text of the
                        // button not the button itself, this feels bad to click."* At 6:10am with a
                        // knuckle this is the difference between a control and a dare.
                        .contentShape(Rectangle())

                    Spacer()

                    Button("END", action: onEnd)
                        .buttonStyle(PressLabelStyle())
                        .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .trailing)
                        // THE WHOLE TARGET IS TAPPABLE, NOT JUST THE GLYPHS.
                        // A `.frame(min…: Hit.…)` on a Button reserves the layout space and does
                        // NOT extend its hit region — SwiftUI still hit-tests the rendered label.
                        // With `alignment: .leading` the text is then pinned to one edge of a 68pt
                        // box, so most of the target was dead paper.
                        //
                        // Eden, on the phone: *"seems like the clickable area is the text of the
                        // button not the button itself, this feels bad to click."* At 6:10am with a
                        // knuckle this is the difference between a control and a dare.
                        .contentShape(Rectangle())
                }

                // THE LABEL CHANGES; IT DOES NOT CROSS-FADE.
                //
                // Introduced by `plans/011`. Once the chrome is hoisted it
                // persists across the step swap, so the step change — which
                // runs inside `advance()`'s `withAnimation` — started
                // cross-dissolving two different strings in the same place.
                // Filmed mid-swap it printed **"SEREST13"**: "SET 2 / 13" and
                // "REST" on top of each other.
                //
                // Exactly the family of bug §3.2 already rules on for the rep
                // digit — *"per-set identity so a new set's number never rolls
                // from the previous set's… without identity it reads as a slot
                // machine on every step"*. This label is a fact about which
                // step you are on, and a fact that smears is unreadable.
                Text(step.uppercased())
                    .contentTransition(.identity)
                    .animation(nil, value: step)
            }
            .font(PaperType.micro)
            .tracking(TypeScale.microTracking)
            .foregroundStyle(Paper.press)

            StepBlock(marks: setMarks, progress: progress)
            // The 2pt press-black rule that used to close this block is gone.
            //
            // It sat directly on the head ply's torn top edge — a hard printed
            // rule butting into torn paper, which is TWO separator vocabularies
            // stacked on one seam. The tear and the shadow under it already
            // separate the chrome from the sheet, and they do it in the world's
            // own language.
        }
        // NO HORIZONTAL PADDING HERE — THE CALLER OWNS IT.
        //
        // This used to inset itself by `Space.gutter`. `SetScreen` pads its
        // children individually so the chrome got exactly one gutter, but
        // `RestScreen` and `WarmupScreen` wrap their whole stack in another
        // one — so the rail was 22pt in from the edge on a set and **44pt on a
        // rest**, and it visibly changed width every time the workout advanced.
        //
        // Eden has reported this exact class of thing on this exact component
        // before (W15: *"when you switch to the rest screens the progress bar
        // at the top changes… i don't like any inconsistancies like this"*),
        // which is why the fix is structural rather than a negative padding:
        // one gutter, applied once, by whoever places it.
        .padding(.bottom, Space.snug)
    }
}
