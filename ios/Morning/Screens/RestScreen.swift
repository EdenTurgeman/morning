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
    // THE CHROME IS THE HOST'S. `WorkoutHost` draws `WorkoutChrome` once,
    // above the step transition, so the rail, the set marks, BACK and END do
    // not blink when one screen becomes another — `plans/011`. `progress`,
    // `setMarks`, `onBack` and `onEnd` went with it.
    let seconds: Int
    let endsAt: Date
    let next: SetStep?
    let card: Card?
    /// WHICH REST THIS IS. Not the same thing as `endsAt`.
    ///
    /// Everything about the study card — revealed, expanded, stamped, when the
    /// answer is due — belongs to the CARD, and used to be keyed to `endsAt`
    /// instead. `+15s` writes `endsAt`, so adding time to a rest re-ran all of
    /// it: the answer you were reading vanished, the thinking bar went back to
    /// empty and started again, and an open question would have slammed shut
    /// under the thumb that had just tapped +15s. The countdown's own floor
    /// still keys on `endsAt`, because that one SHOULD reschedule.
    let restIndex: Int
    let isMyo: Bool
    let onExtend: () -> Void
    let onSkip: () -> Void
    /// The rest running out. NOT the same as skipping: the web build wires
    /// `useCountdown`'s `onComplete` straight to `onAdvance`, so a rest that
    /// reaches zero moves on by itself. This port did not, and sat on "0 SEC"
    /// until something tapped it.
    let onComplete: () -> Void

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

    /// A question the user has opened. Collapsed, the card is a prompt and the
    /// ring owns the screen; expanded, the question owns it and the ring
    /// shrinks into the card's corner.
    @State private var studyExpanded = false
    /// The answers have been printed.
    ///
    /// Separate from `studyExpanded` because the page has to arrive before
    /// anything can be written on it — see the rows themselves for what
    /// happened when they did not wait.
    @State private var optionsShown = false

    /// The badge's ink has landed.
    ///
    /// Two beats, not one: the FIGURE travels first, alone and still written in
    /// press black, and only when it has arrived does the block stamp under it
    /// and knock it out white. A stamp does not drift into place — it lands —
    /// so it cannot share the flight's spring without becoming something else.
    @State private var badgeStamped = false

    /// ONE namespace, and the figure exists in exactly ONE branch at a time.
    ///
    /// `matchedGeometryEffect` with two live sources is a silent conflict —
    /// SwiftUI picks one and says nothing, which cost this project a whole
    /// debugging session once. The `if !studyExpanded` below is what guarantees
    /// there is never more than one.
    ///
    /// What is matched is the NUMBER, not the timer. The effect used to sit on
    /// the ring's whole `maxHeight: .infinity` container at one end and a 54pt
    /// chip at the other, which asked SwiftUI to interpolate a full-height band
    /// into a badge — and even had the frames agreed, a circle does not become
    /// a rectangle. The figure is the one part that is genuinely the same thing
    /// at both ends, so the figure is the part that travels.
    @Namespace private var timerSpace

    /// The travelling figure. One constant, because two string literals in two
    /// files is how a matched pair silently stops being a pair.
    private static let figureID = "restFigure"

    /// The badge's figure, in points. Shared with the ring so it knows how far
    /// the number has to shrink on its way over.
    private static let badgeFigureSize: CGFloat = 22

    /// The ring's figure, in points, at the size this screen actually draws it.
    ///
    /// The badge's own figure ENTERS at this size and shrinks, mirroring what
    /// the ring's does on the way out. Without that the number pops into
    /// existence small while the big one is still fading, which reads as two
    /// numbers rather than one moving.
    ///
    /// Taken against the ring's ceiling rather than its measured diameter,
    /// which is inside a `GeometryReader` and not knowable from out here. On
    /// this screen the ring is at its ceiling — the band is the whole space
    /// above the card — and where it is not, the error lands on the first frame
    /// of the flight, which is at zero opacity.
    private static let ringFigureSize =
        CountdownRing.maximumDiameter * CountdownRing.figureFraction

    /// The figure's journey — or nothing at all, under Reduce Motion.
    ///
    /// **A number crossing the screen is exactly the movement that setting asks
    /// to stop**, and the old handling only made it faster: `Motion.reveal`
    /// dropped to 0.18s and the figure still flew. Reduce Motion means fewer
    /// and gentler animations, not the same animation hurried.
    ///
    /// So it does not travel. The ring's figure fades where it stands, the
    /// badge fades in where it belongs, and the countdown is legible in both
    /// places throughout — which is the only part of this that `spec.md`
    /// actually requires. Calmer, not broken.
    /// `destinationSize` is the figure's size at the OTHER end, which is why
    /// each end asks for its own: the ring is heading for 22pt, the badge is
    /// arriving from 82. One value shared between them would have made the
    /// scale 1 in both directions — the number teleporting rather than moving.
    private func figureFlight(toward destinationSize: CGFloat) -> FigureFlight? {
        guard !reduceMotion else { return nil }
        return FigureFlight(
            id: Self.figureID,
            namespace: timerSpace,
            destinationSize: destinationSize
        )
    }

    var body: some View {
        VStack(spacing: 0) {
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
            if !studyExpanded {
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
                            accent: Paper.orange,
                            figureMatch: figureFlight(toward: Self.badgeFigureSize)
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
            }

            if isMyo, !studyExpanded {
                // The 20-second rest IS the training stimulus, not a
                // convenience. Amber says urgency without saying failure.
                Text("The 20-second rest IS the mechanism. Don't stretch it")
                    .font(TypeScale.bodyEmphasis)
                    // Amber was off the dawn ramp so it could never collide with
                    // the accent. In this world the same job goes to the
                    // overprint: it is the only ink here that reads as urgent
                    // and still clears the floor as TEXT (6.96:1). Orange would
                    // be the obvious pick and measures 2.14:1.
                    .foregroundStyle(Paper.overprint)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Space.section)
                    .padding(.top, Space.step)
            }

            if let card {
                StudyCard(
                    card: card,
                    revealed: revealed,
                    answerShown: answerShown,
                    accent: Paper.orange,
                    thinkingTime: Deck.revealDelay(forRestOf: seconds),
                    revealAt: revealAt,
                    optionsShown: optionsShown,
                    expanded: studyExpanded,
                    onExpand: { expand() },
                    cornerTimer: studyExpanded ? AnyView(compactTimer) : nil
                ) {
                    // Tapping only brings the answer forward.
                    //
                    // This closure is the BY-HAND path and only the by-hand
                    // path — a factoid tapped open, and a question answered.
                    // The clock reaches `reveal()` through `revealOnSchedule`
                    // instead, which is what keeps "he engaged with this" from
                    // being written for a card that merely ran out in front of
                    // him.
                    Deck.markOpened(card.id)
                    reveal()
                }
                .frame(maxHeight: studyExpanded ? .infinity : nil)
                // THE TIMER, DETACHED.
                //
                // While the question is open the ring is not the screen's
                // subject any more — but a rest timer you cannot see is the one
                // thing `spec.md` will not allow, because that countdown IS the
                // training mechanism. So it shrinks into the card's corner
                // rather than going away, and `matchedGeometryEffect` carries it
                // there as one object instead of cross-fading two.
                .padding(.top, Space.step)
                // AN OPEN CARD MUST NOT TOUCH THE BUTTONS.
                //
                // Collapsed, a `Spacer` and the next-up line hold the card off
                // them. Both are hidden while a question is open and the VStack
                // has zero spacing, so the sheet's bottom edge sat flush against
                // +15s and Skip — no margin at all, which is most of why the
                // card read as overflowing rather than as filling.
                //
                // `gutter`, the same 22pt the page uses at its sides, so an open
                // sheet has one margin the whole way round.
                .padding(.bottom, studyExpanded ? Space.gutter : 0)
            }

            if !studyExpanded {
                Spacer(minLength: Space.section)
                    .layoutPriority(-1)
            }

            // Hidden while a question is open. Eden: the expanded question
            // runs *"upto the buttons and to the workout progress bar"* — the
            // point of expanding is that this is the only thing you are doing.
            if let next, !studyExpanded {
                NextUp(step: next)
                    .padding(.bottom, Space.step)
            }

            HStack(spacing: Space.step) {
                PaperSecondaryButton(title: "+15s", quiet: true) {
                    Haptics.shared.rep()
                    onExtend()
                }
                PaperSecondaryButton(title: "Skip →") {
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
        // ON CHANGE, NOT ON APPEAR. These are all already false when the view
        // is built, so resetting them at appear buys nothing — and it costs
        // something: `-answer` opens and answers the card from `StudyCard`'s
        // own `onAppear`, and a reset racing that from the parent is a coin
        // toss that decides whether the review flag works at all. It came up
        // tails, and cost a round of screenshots that all showed a closed card.
        .onChange(of: restIndex) { _, _ in
            revealed = false
            answerShown = false
            studyExpanded = false
            optionsShown = false
            badgeStamped = false
            revealAt = nil
        }
        .task(id: restIndex) {
            await expandOnScheduleIfRequested()
        }
        // The FIRST deadline of the rest. Opening a question moves it — see
        // `expand(startingTheClock:)` — which is why the countdown to it lives
        // in its own task keyed on the deadline rather than on the rest.
        .task(id: restIndex) {
            guard let card else {
                revealAt = nil
                return
            }
            revealAt = Date().addingTimeInterval(
                Deck.answerDue(
                    isQuestion: card.choices != nil,
                    thinking: Deck.revealDelay(forRestOf: seconds),
                    restRemaining: endsAt.timeIntervalSinceNow
                )
            )
        }
        .task(id: revealAt) {
            guard let revealAt else { return }
            let wait = revealAt.timeIntervalSinceNow
            if wait > 0 {
                try? await Task.sleep(for: .seconds(wait))
            }
            guard !Task.isCancelled else { return }
            revealOnSchedule()
        }
        .task(id: endsAt) {
            completed = false
            lastSpokenSecond = nil
            let wait = max(0, endsAt.timeIntervalSinceNow)
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            finish()
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

    /// The clock reaching the answer.
    ///
    /// **An unopened question opens itself here.** Before this, the reveal
    /// happened underneath a card that still read "Tap to answer" — the prompt
    /// went on inviting an answer that could no longer be given. Whatever else
    /// is true, the card must not lie about what it will do when tapped.
    private func revealOnSchedule() {
        if card?.choices != nil, !studyExpanded {
            expand(byHand: false)
        }
        reveal()
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
    /// The rest timer, shrunk into an open question's corner.
    ///
    /// Same clock, same `finish()`, same spoken countdown — only the diameter
    /// differs. Duplicating the tick logic here would be a second place for the
    /// rest to end, and a rest that can end twice is a rest that can end wrong.
    /// The rest timer as a STAMP, not a ring.
    ///
    /// A shrunken `CountdownRing` floating on the sheet read as a foreign
    /// object pasted on top of the paper — Eden: *"it should look like a small
    /// badge on the top right of the paper."* This world already has the
    /// vocabulary: an inked chip with the figure knocked out, which is exactly
    /// what `PaperStamp` does for ALL OUT and PASSED.
    ///
    /// The countdown still reads two ways. The number is the fact; the orange
    /// rule beneath it DRAINS, so time remaining is legible from across the
    /// room without reading a digit — the same job the ring was doing, in a
    /// mark rather than a shape. Orange lights and never writes, so it is the
    /// rule and never the number.
    private var compactTimer: some View {
        TimelineView(.animation) { context in
            let remaining = max(0, endsAt.timeIntervalSince(context.date))
            let fraction = seconds > 0 ? min(1, max(0, remaining / Double(seconds))) : 0

            VStack(spacing: 0) {
                Text(RestActivityCountdown.clock(remaining))
                    // `PaperType.counter`, the same face the ring's figure is
                    // set in — this IS that figure, smaller. Two different type
                    // stacks at the two ends of a matched geometry effect is a
                    // substitution dressed up as a movement.
                    .font(PaperType.counter(Self.badgeFigureSize)).tracking(TypeScale.counterTracking)
                    .contentTransition(Motion.numeric(reduceMotion: reduceMotion, countsDown: true))
                    // KNOCKED OUT ONLY ONCE THERE IS INK TO KNOCK IT OUT OF.
                    //
                    // `Paper.ply` is near-white. Written before the block lands
                    // it is a white numeral on pale stock — invisible, for the
                    // whole of its flight. So it travels in press black, the
                    // colour it already was inside the ring, and inverts at the
                    // moment the ink arrives underneath it. The inversion is not
                    // decoration; it is what tells you the timer has finished
                    // moving and is now a mark on the page.
                    .foregroundStyle(badgeStamped ? Paper.ply : Paper.press)
                    .padding(.horizontal, Space.snug)
                    .padding(.top, 5)
                    .padding(.bottom, 4)
                    .frame(minWidth: 54)
                    // The other end of the flight, through the same modifier the
                    // ring uses — so "does this travel at all" is answered once,
                    // in `figureFlight`, rather than twice in two files.
                    .modifier(MatchedFigure(
                        match: figureFlight(toward: Self.ringFigureSize),
                        from: Self.badgeFigureSize
                    ))

                GeometryReader { proxy in
                    Rectangle()
                        .fill(Paper.orange)
                        .frame(width: proxy.size.width * fraction)
                }
                .frame(height: 4)
                .opacity(badgeStamped ? 1 : 0)
            }
            .background {
                // The ink. It does not fade in and it does not slide: it is
                // pressed, so it arrives at 0.88 and snaps to size on
                // `Motion.threshold`, the same token the crossing uses on the
                // Set screen. One way of saying "here is the fact", everywhere.
                Rectangle()
                    .fill(Paper.press)
                    .scaleEffect(badgeStamped ? 1 : 0.88)
                    .opacity(badgeStamped ? 1 : 0)
            }
            .onChange(of: Int(ceil(remaining))) { _, value in
                speak(secondsLeft: value)
                if value <= 0 {
                    finish()
                }
            }
        }
        .fixedSize()
        // `press`, not `threshold`. Both are two-beat tokens and using the
        // wrong one cost a third of a second of dead air: `threshold` carries
        // its OWN 0.22s delay — it exists to put a fact after a number — so
        // scheduling it behind `answerDelay` delayed the ink twice and the
        // figure sat there, black on pale paper, for 0.56s before anything
        // happened to it. Filmed at 60fps it reads as a stall.
        //
        // The wait belongs in one place, and it is the schedule. What is left
        // for the animation to do is land, which is `press`: 0.10s, no delay,
        // no easing to speak of. Ink is instant everywhere else in this world
        // and a stamp is the most instant thing in it.
        .animation(Motion.press(reduceMotion: reduceMotion), value: badgeStamped)
    }

    /// `-expand-after <seconds>` opens the question on a timer, for review.
    ///
    /// The transition between the ring and the badge is the whole of this
    /// design and **no synthesised tap reaches this simulator**, so without
    /// this there is no way to look at it in motion at all — `-answer` opens
    /// the card in `onAppear`, before there is a frame to animate from, which
    /// shows the destination and never the journey. Two rounds of "it does not
    /// look good" were spent on a transition nobody could film.
    ///
    /// It calls the same `expand()` a thumb does. Nothing is reproduced.
    private func expandOnScheduleIfRequested() async {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-expand-after"),
              arguments.indices.contains(flag + 1),
              let delay = Double(arguments[flag + 1]),
              card?.choices != nil
        else {
            return
        }
        try? await Task.sleep(for: .seconds(delay))
        guard !Task.isCancelled else { return }
        expand()
    }

    /// Opening a question. The card grows, the figure flies, the ink lands.
    ///
    /// The stamp is scheduled rather than animated alongside, because the two
    /// are different events with different curves — a spring carries the figure
    /// across the screen, and a press does not ease at all. `answerDelay` is the
    /// token for "after the thing has finished moving", which is exactly what
    /// this is waiting for, and it already answers Reduce Motion.
    /// OPENING A QUESTION DOES NOT START A FUSE.
    ///
    /// It used to restart the thinking window from the tap, which sounded
    /// generous and was not: the window is at most 11 seconds, and that is how
    /// long you got to read four two-line options and choose, having already
    /// spent the collapsed time reading the stem. Tested by tapping through it,
    /// the answer arrived first.
    ///
    /// A question's deadline is the same whether it is open or shut: the far
    /// end of the rest, from `Deck.answerDue`. Opening it shows the options and
    /// changes nothing else. The countdown is on screen the whole time as the
    /// badge, so nothing is hidden by giving him the room.
    ///
    /// `byHand` separates the two openings that reach here. It used to be
    /// `startingTheClock`, an unused parameter kept only to DOCUMENT that the
    /// schedule opens the card too. It now does the job it was describing:
    /// opening a card yourself is engagement and is written to the sighting
    /// log; the clock opening it over your head is not, and must not be
    /// recorded as if it were.
    private func expand(byHand: Bool = true) {
        guard !studyExpanded else { return }
        if byHand, let card {
            Deck.markOpened(card.id)
        }
        withAnimation(Motion.reveal(reduceMotion: reduceMotion)) {
            studyExpanded = true
        }
        // Two things follow the page, at their own distances: the answers as
        // soon as it has landed, the ink one beat after that. Both are
        // scheduled here rather than each finding its own way, so there is one
        // place that knows the order they happen in.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Motion.cardSettle(reduceMotion: reduceMotion)))
            // `studyExpanded`, not just cancellation: these are unstructured
            // tasks and the view's lifecycle does not cancel them, so a rest
            // that ends inside the schedule would otherwise land its follow-up
            // on the next rest's card.
            guard !Task.isCancelled, studyExpanded else { return }
            // No `withAnimation`: each row carries its own, staggered by rank.
            optionsShown = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Motion.answerDelay(reduceMotion: reduceMotion)))
            guard !Task.isCancelled, studyExpanded else { return }
            Haptics.shared.rep()
            badgeStamped = true
        }
    }

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
                .foregroundStyle(Paper.press)

            HStack(spacing: 6) {
                Text(step.exercise)
                    .font(TypeScale.bodyEmphasis)
                    .foregroundStyle(Paper.press)
                if let sub = step.sub {
                    Text("· \(sub)")
                        .font(TypeScale.body)
                        .foregroundStyle(Paper.press)
                }
            }

            Text(detail)
                .font(TypeScale.microLabel)
                .foregroundStyle(Paper.press)
        }
        .multilineTextAlignment(.center)
    }

    private var detail: String {
        step.summaryLine
    }
}

// MARK: - The card

/// WHAT A STUDY CARD IS SHOWING, AS A VALUE.
///
/// A card has two independent questions — *is this a question or a factoid*,
/// and *is the answer out* — and they used to be flattened into one `if / else
/// if / else` chain inside `body`. The chain lost a limb: a factoid has no
/// `choices`, so it failed both leading tests and fell into the final `else`,
/// which drew "Tap if you have it" and nothing else. Tapped, timed out, or left
/// alone for the whole rest, it never showed its answer again.
///
/// **Twenty-five of the twenty-six cards in the deck.** The suite stayed green
/// through all of it, and so did every screenshot I took, because the one card
/// the review flags open is the one question — the single card the chain still
/// handled. Eden found it on his phone.
///
/// The chain being unreachable is the actual defect. There is no
/// view-rendering test in this project, so a branch inside a `body` cannot be
/// asserted on and a missing one is invisible until somebody looks at the right
/// card. A value can be asserted on, and every case below is, in
/// `StudyDeckAcceptanceTests`. The next limb that goes missing fails a test.
enum StudyCardBody: Equatable {
    /// A factoid, still closed. "Tap if you have it."
    case prompt
    /// A factoid's prose answer, revealed by a tap or by the clock.
    case answer
    /// A question nobody has opened yet. "Tap to answer."
    case unopened
    /// An open question: the four options, plus the prose once it is answered.
    case options(answered: Bool)

    static func of(_ card: Card, revealed: Bool, expanded: Bool) -> StudyCardBody {
        // A malformed question is a factoid — `Card.choices` is what decides
        // that, and it is deliberately the FIRST thing asked here so the
        // degraded path is the same path a real factoid takes.
        guard card.choices != nil else {
            return revealed ? .answer : .prompt
        }
        // `revealed` beats `expanded`: a question whose answer is out is never
        // a prompt again, whatever the card's open state says. The schedule now
        // opens it too, so this is the belt to that pair of braces.
        guard expanded || revealed else { return .unopened }
        return .options(answered: revealed)
    }
}

/// WHAT THIS CARD ALREADY IS TO HIM.
///
/// A value rather than three `if`s in the masthead, for the reason
/// `StudyCardBody` is one: a branch inside a view body is a branch nothing can
/// test, and this file has already shipped one of those — twenty-five of
/// twenty-six cards stopped showing their answers and no test could see it.
///
/// It is the visible half of what Eden asked for. The scheduler that brings a
/// missed question back sooner is invisible by construction; without a mark on
/// the card, the only way to know any of this is working is to trust it.
///
/// **It never congratulates and never scores.** Each case is a plain fact about
/// what has already happened, in the register `spec.md` sets for every headline
/// in this app: true, specific, and worth reading the twentieth time.
enum StudyMark: Equatable {
    /// A card he has never met, or one with nothing to say.
    case none
    /// He has seen this before. `times` is which showing this one is.
    case returning(times: Int)
    /// He has got this wrong and not yet settled it. THE REMATCH — the mark is
    /// on the card while the question is still a question, so answering it is
    /// worth something before he knows whether he was right.
    case missed(times: Int)
    /// The answer he just gave settled a question he used to miss.
    case settled

    /// `prior` is what the app knew BEFORE this morning's answer, which is the
    /// only reading that can honestly say "last time". `answeredRight` is the
    /// answer he has just given, or nil while the card is still a question.
    static func of(
        _ prior: StudyPlan.Encounter?,
        card: Card,
        answeredRight: Bool? = nil
    ) -> StudyMark {
        guard let prior else { return .none }
        // A right answer that takes the run to the settling point, on a
        // question he has actually missed before. `prior.run + 1` because the
        // answer that does it is not in `prior` yet.
        if answeredRight == true, prior.misses > 0, prior.run + 1 >= StudyPlan.settledRun {
            return .settled
        }
        if prior.misses > 0, prior.run < StudyPlan.settledRun {
            return .missed(times: prior.misses)
        }
        // TIMES HE STUDIED IT, not times it appeared. Eden: *"if i didn't
        // interact and answer then it shouldn't be recorded."* A question that
        // came up twice while he was getting his breath back and was never
        // opened is a question he has met once, and the card saying "3RD TIME"
        // would be the app counting its own furniture.
        //
        // The first meeting says nothing either. There is no fact yet, and
        // "1ST TIME" on every new card is how a mark stops being read.
        let studied = prior.engagements(isQuestion: card.choices != nil)
        guard studied > 1 else { return .none }
        return .returning(times: studied)
    }

    /// Short on purpose: it shares one line with the topic and the rest timer,
    /// and the topic is already up to eighteen characters.
    var label: String? {
        switch self {
        case .none: nil
        case let .returning(times): "\(times)\(Self.ordinal(times)) time"
        case .missed(1): "Missed last time"
        case let .missed(times): "Missed \(times)×"
        case .settled: "Settled"
        }
    }

    /// A miss is the one case drawn in the pen's red rather than press black.
    /// It is the only one that is about a mistake, and this world already marks
    /// mistakes that way — see `PenStrike`.
    var isMiss: Bool {
        if case .missed = self {
            return true
        }
        return false
    }

    private static func ordinal(_ n: Int) -> String {
        switch (n % 100, n % 10) {
        case (11 ... 13, _): "th"
        case (_, 1): "st"
        case (_, 2): "nd"
        case (_, 3): "rd"
        default: "th"
        }
    }
}

/// THE WRONG ANSWER HE KEEPS REACHING FOR.
///
/// The most interesting thing either log holds, and for a while the only one
/// the app computed and never said. `StudyAnswer.picked` is an index and the
/// deck is rewritten by content agents, so naming an option from an index was a
/// sentence that could quietly become false; `StudyAnswer.pickedText` is what
/// made this safe to show.
///
/// **Twice is the threshold.** One wrong answer is a slip. The same wrong
/// answer twice is something he believes, and that is the only version worth
/// interrupting a rest for.
///
/// It appears only once the answer is out — never while the question is still a
/// question, because naming the option he usually reaches for would tell him
/// which one not to pick, and a question you cannot get wrong teaches nothing.
struct StudyConfusion: Equatable {
    /// The wrong answer, as it read when he chose it.
    let wording: String
    /// How many times he has chosen it, including this morning if he just did.
    let times: Int
    /// He reached for it again just now.
    let repeated: Bool

    /// Deliberately NOT the same shape as `StudyMark`'s "3RD TIME" — the two
    /// can be on screen together, one counting showings of the card and the
    /// other counting one particular mistake, and they must not read as the
    /// same fact. Each ends on the word that separates them.
    ///
    /// The repeated case names the answer ("that answer") because it does not
    /// print it — see `showsWording`.
    var label: String {
        if repeated {
            return "That answer, \(times) times now"
        }
        return times == 2 ? "Twice before" : "\(times) times before"
    }

    /// Whether the note prints the words as well as the count.
    ///
    /// **Not when he has just chosen it again.** The option is already struck
    /// through, in the same red, four lines up — printing it a second time put
    /// the identical sentence on the card twice, crossed out twice, which reads
    /// as a rendering fault rather than as a memory. What the card is missing
    /// in that moment is the COUNT, and the count is the label.
    ///
    /// When he got it right, or the rest ran out, nothing else on the card
    /// names the answer he used to give — so the note has to.
    var showsWording: Bool {
        !repeated
    }

    /// `justPicked` is the option he chose this morning, or nil if the rest ran
    /// out and the answer arrived on its own.
    static func of(_ prior: StudyPlan.Encounter?, card: Card, justPicked: Int?) -> StudyConfusion? {
        guard let confusion = prior?.confusion, let choices = card.choices else { return nil }

        // IT MUST STILL BE ON THE CARD.
        //
        // A content agent can rewrite or drop an option between the morning he
        // chose it and the morning he sees this. The words are still what he
        // answered — that is why they are stored — but striking a line that
        // corresponds to nothing above it reads as a bug, so a confusion whose
        // option is gone simply goes unsaid.
        guard choices.contains(confusion.wording) else { return nil }

        guard let justPicked, choices.indices.contains(justPicked) else {
            // Nothing was chosen this morning: the rest ran out. Still true,
            // and still the moment to say it.
            return StudyConfusion(wording: confusion.wording, times: confusion.times, repeated: false)
        }
        if choices[justPicked] == confusion.wording {
            return StudyConfusion(wording: confusion.wording, times: confusion.times + 1, repeated: true)
        }
        // He answered something else. If that something else was RIGHT, this is
        // exactly the moment the loop closes. If it was a different wrong
        // answer, his old confusion is not what just happened and saying it
        // would bury the mistake he actually made.
        guard justPicked == card.correctIndex else { return nil }
        return StudyConfusion(wording: confusion.wording, times: confusion.times, repeated: false)
    }
}

/// Attaches `PenStrike` only to the option that was tapped.
///
/// A `ViewModifier` rather than an inline `if`, so the branch lives in one
/// place and the reason for it travels with the code. See the call site in
/// `optionRow` for why the gate is `picked` and not `isWrongPick`.
private struct PenStrikeIfTapped: ViewModifier {
    let tapped: Bool
    let struck: Bool

    func body(content: Content) -> some View {
        if tapped {
            content.textRenderer(PenStrike(progress: struck ? 1 : 0, ink: Paper.danger))
        } else {
            content
        }
    }
}

/// Crosses out every LINE of a wrong answer, not the box it sits in.
///
/// `Text.Layout` hands back the real typographic line boxes, which is the only
/// way to strike text whose line count is not known in advance. `.strikethrough`
/// would also land correctly, but it appears in one frame — and this stroke is
/// meant to read as a pen moving, which is the whole reason it is drawn.
private struct PenStrike: TextRenderer {
    /// 0…1, left to right across each line.
    var progress: Double
    var ink: Color

    /// So the sweep interpolates rather than snapping.
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            context.draw(line)
        }

        guard progress > 0 else { return }

        for line in layout {
            let box = line.typographicBounds.rect
            // Through the middle of the glyphs, not the middle of the line box:
            // a line box includes leading, and a stroke placed at its centre
            // sits low on the text.
            let y = box.midY
            context.fill(
                Path(CGRect(x: box.minX, y: y - 1, width: box.width * progress, height: 2)),
                with: .color(ink)
            )
        }
    }
}

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
    /// True once the page has landed and the answers may be printed on it.
    let optionsShown: Bool
    /// True once the question has been opened.
    ///
    /// Owned by `RestScreen` rather than here, because opening a question also
    /// moves the timer — one piece of state with two effects, and splitting it
    /// would let the card and the ring disagree about whether it is open.
    let expanded: Bool
    let onExpand: () -> Void
    /// The shrunken rest timer, for this card's masthead row.
    ///
    /// Passed IN rather than positioned from outside. Aligning it to the card's
    /// `.topTrailing` from the Rest screen put it half on the stock above the
    /// paper, because an expanded card's layout frame is TALLER THAN ITS
    /// VISIBLE SHEET — `maxHeight: .infinity` makes it fill — so the corner
    /// being aligned to was not the corner anyone can see.
    let cornerTimer: AnyView?
    let onReveal: () -> Void

    /// Which option was tapped, or nil while it is still a question.
    ///
    /// Local because it is the only state that belongs to the card itself —
    /// the Rest screen owns `revealed`, which a pick triggers through
    /// `onReveal`. One source for "is the answer showing", two for "did he
    /// choose", which is the split that keeps the timer path and the tap path
    /// from disagreeing.
    @State private var picked: Int?

    /// WHAT THE APP KNEW ABOUT THIS CARD BEFORE THIS MORNING.
    ///
    /// Captured once, on appear, and never re-read. It has to be the state
    /// BEFORE the answer he is about to give: `Deck.record` writes the moment
    /// he taps, so a mark computed from a live read would say "you missed this"
    /// about the miss he just made, which is not what "last time" means.
    ///
    /// The sighting for THIS showing is already in it — `Deck.draw` logs it —
    /// so `sightings == 1` is a first meeting and `2` is the second time.
    @State private var prior: StudyPlan.Encounter?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isQuestion: Bool {
        card.choices != nil
    }

    /// The rematch mark. Recomputed as he answers, so a question he settles
    /// says so on the same beat the ink lands.
    private var mark: StudyMark {
        StudyMark.of(prior, card: card, answeredRight: verdict?.right)
    }

    /// The wrong answer he keeps reaching for, if there is one worth saying.
    private var confusion: StudyConfusion? {
        StudyConfusion.of(prior, card: card, justPicked: picked)
    }

    /// The sheet. One shape, used to fill the paper AND to clip what is printed
    /// on it — if these were two `TornEdge`s the seed would eventually drift and
    /// the clip would stop matching the edge it is supposed to be.
    private var sheet: TornEdge {
        TornEdge(tornTop: true, tornBottom: true, seed: 53)
    }

    var body: some View {
        // A FACTOID REVEALS; A QUESTION OPENS.
        //
        // Collapsed, a question is a prompt — the same shape the factoid's
        // "Tap if you have it" already established. The card behaves the way
        // this deck has always behaved, and a question does not become a
        // different kind of object until you choose to engage with it.
        Button(action: {
            if !isQuestion {
                onReveal()
            } else if !expanded {
                onExpand()
            }
        }) {
            VStack(alignment: .leading, spacing: Space.snug) {
                // THE MASTHEAD. Topic left, timer right, on one line.
                //
                // The timer used to be an OVERLAY on this sheet, with the
                // question given `.padding(.trailing, 66)` to keep out of its
                // way. That padding is a layout change, and filmed at 60fps it
                // was the ugliest thing in the transition: the question re-wrapped
                // from two lines to three at the moment the card opened, and
                // SwiftUI cross-dissolved the two wrappings — the same sentence
                // printed twice, at two different line breaks, sliding over each
                // other for a third of a second.
                //
                // A row reserves the space instead of stealing it. Nothing
                // re-wraps, because the question's width never changes.
                HStack(alignment: .top, spacing: Space.step) {
                    // The topic and the mark are ONE label, set closer to each
                    // other than either is to the timer. At `Space.step` apart
                    // they read as two competing headings, and the gap was
                    // coming straight out of the topic — which is the only
                    // thing in the row that can compress.
                    HStack(alignment: .firstTextBaseline, spacing: Space.snug) {
                        Text(card.topic.uppercased())
                            .font(TypeScale.microLabel)
                            .tracking(1.8)
                            // Press black. A category label earns its place by being
                            // small and tracked, not by being a different colour —
                            // `Ink`'s rule, and it leaves the card monochrome except
                            // the orange thinking bar and a struck red.
                            .foregroundStyle(Paper.press)
                            // ONE LINE, TRUNCATING. The mark shares this row, the
                            // longest topic in the deck is eighteen characters, and
                            // a topic that wrapped would push the question down and
                            // re-wrap it — the exact defect the row was built to
                            // stop. A clipped category label costs nothing; the
                            // question underneath carries the meaning.
                            .lineLimit(1)
                            .truncationMode(.tail)

                        if let label = mark.label {
                            Text(label.uppercased())
                                .font(TypeScale.microLabel)
                                .tracking(1.8)
                                .foregroundStyle(mark.isMiss ? Paper.danger : Paper.press.opacity(0.5))
                                // Never compressed and never wrapped: it is four to
                                // sixteen characters and it is the whole reason the
                                // row was changed.
                                .fixedSize()
                                .transition(.opacity)
                        }
                    }

                    Spacer(minLength: 0)

                    cornerTimer
                }

                Text(card.q)
                    .font(TypeScale.question)
                    .foregroundStyle(Paper.press)
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
                            .fill(Paper.press.opacity(0.22))
                            .frame(height: 1)

                        if revealed {
                            Rectangle()
                                .fill(Paper.press.opacity(0.22))
                                .frame(width: proxy.size.width, height: 1)
                        } else {
                            // SCALED, NOT RESIZED. A clock-driven `frame`
                            // is a layout pass every frame — here, inside the
                            // card that is itself growing, at 120Hz. The
                            // fourth time this swap has been the fix in this
                            // codebase; see `RepControl.crossingPly`.
                            TimelineView(.animation) { context in
                                Rectangle()
                                    .fill(accent)
                                    .frame(width: proxy.size.width, height: 2)
                                    .scaleEffect(
                                        x: filled(at: context.date),
                                        y: 1,
                                        anchor: .leading
                                    )
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 2)

                // Every case, decided by `StudyCardBody` and asserted in the
                // suite. See that type for why it is not a chain of `if`s.
                switch StudyCardBody.of(card, revealed: revealed, expanded: expanded) {
                case .unopened:
                    Text("Tap to answer")
                        .font(TypeScale.body)
                        .foregroundStyle(Paper.press)

                case let .options(answered):
                    // THE OPTIONS STAY, AND THE VERDICT MARKS THEM IN PLACE.
                    //
                    // They used to vanish the instant you tapped, replaced by a
                    // separate "Right."/"Not that one." line. That is a hard cut
                    // AND it moves the answer away from where you were already
                    // looking — you lose the connection between the thing you
                    // chose and the verdict on it. Spatial consistency: mark the
                    // option, do not relocate the news.
                    //
                    // `?? []` never fires: `.options` is only ever produced for a
                    // card that HAS choices.
                    let choices = card.choices ?? []
                    // THE OPTIONS ARE SIZED, NOT STRETCHED.
                    //
                    // They had `maxHeight: .infinity` so they would fill the
                    // sheet the open card had just claimed. Eden, looking at it
                    // on the phone: *"i think it's overflowing, the card."* He
                    // was right twice over — the four rows grew to about 100pt
                    // each, which made them four mostly-EMPTY boxes with a line
                    // of text floating in the middle, and it drove the last of
                    // them hard against the paper's torn bottom edge.
                    //
                    // `Hit.minimum` is already 64pt. A sweaty thumb at 6am was
                    // never the problem this solved; the problem it solved was
                    // blank paper, and blank paper at the foot of a page is not
                    // a defect. It is also not blank for long — it is where the
                    // prose answer lands, and reserving it is the reason
                    // answering does not shove the card around.
                    VStack(spacing: Space.tight) {
                        ForEach(choices.indices, id: \.self) { index in
                            optionRow(choices[index], index: index)
                                // WRITTEN DOWN THE PAGE, NOT STAMPED AT ONCE.
                                //
                                // Four rows in one frame is a wall, and they
                                // arrived while the card was still rising — an
                                // inserted view is laid out where it is ARRIVING,
                                // so they were drawn at their destination on top
                                // of a question that had not got there yet, and
                                // the two collided inside the sheet for about
                                // 100ms. Filmed with the cascade removed
                                // entirely the collision was identical, which is
                                // how it is known to be the card's travel and not
                                // the stagger.
                                //
                                // **A `.transition`'s own `.animation` could not
                                // fix it.** With a `withAnimation` transaction
                                // running for the card, the rows kept the
                                // transaction's timing and ignored the delay —
                                // filmed twice, they still appeared 70ms in
                                // against a delay of 180. So the entrance is
                                // STATE, gated on `optionsShown`, which is
                                // scheduled the same way the badge's ink is and
                                // for the same reason: a thing that must happen
                                // after another thing has to be told when, not
                                // asked nicely.
                                //
                                // 8pt, not 0. Sliding a short distance reads as
                                // arriving; appearing in place reads as a cut.
                                .opacity(optionsShown ? 1 : 0)
                                .offset(y: optionsShown || reduceMotion ? 0 : 8)
                                .animation(
                                    Motion.optionEntry(reduceMotion: reduceMotion, rank: index),
                                    value: optionsShown
                                )
                        }
                    }

                    if answered {
                        answerProse
                            .padding(.top, Space.snug)

                        if let confusion {
                            confusionNote(confusion)
                                .padding(.top, Space.snug)
                        }
                    }

                case .answer:
                    answerProse

                case .prompt:
                    Text("Tap if you have it")
                        .font(TypeScale.body)
                        .foregroundStyle(Paper.press)
                }
            }
            // AN OPEN QUESTION FILLS THE BAND IT WAS GIVEN.
            //
            // `maxHeight` has to be INSIDE the sheet, above `.background`, or it
            // stretches the layout frame and leaves the paper hugging its text —
            // which is what it did: the card floated in the middle of the band
            // with the stock showing above and below it, while its invisible
            // frame ran the whole way. Eden asked for the question to open
            // *"upto the buttons and to the workout progress bar"*.
            //
            // The empty paper below the options is not waste. It is where the
            // prose answer lands, and reserving it now is why answering does not
            // shove the card around underneath the thumb that just tapped.
            .frame(
                maxWidth: .infinity,
                maxHeight: expanded ? .infinity : nil,
                alignment: .topLeading
            )
            // A PASTED PLY, like everything else inside a workout.
            //
            // This was the last thing in the workout without the material — bare
            // text sitting straight on the stock while the head, the counter and
            // the horizon were all sheets with torn edges. It read as a gap in
            // the world rather than as a quiet element.
            //
            // It also pays the same dividend the other plies do: press black
            // measures 11.35:1 on the ply against 7.74:1 on the stock, and this
            // is the one surface in a workout you actually READ rather than
            // glance at from a metre away.
            .padding(Space.step)
            // INK CANNOT EXIST OFF THE PAPER.
            //
            // Filmed at 60fps, opening a question drew the four option rows on
            // the STOCK — above the sheet's torn top edge, floating on the
            // background — for about 100ms while the paper was still rising
            // underneath them. An inserted view is placed using the layout it is
            // arriving INTO, so the rows were at their destination while the
            // card that contains them was still in transit.
            //
            // Clipping is the fix and it is also the truth: a row with no sheet
            // under it yet is simply not printed yet. It costs nothing, it needs
            // no sequencing, and it cannot come apart again the next time
            // something inside this card is inserted or removed.
            //
            // Before the background, so the sheet's own drop shadow is outside
            // the clip and survives.
            .clipShape(sheet)
            .background {
                sheet
                    // ONE SHAPE CASTS THE SHADOW, AND THERE IS NO GROUP.
                    //
                    // This read `.overlay { Fibre() }.compositingGroup()
                    // .shadow(...)`, and the group was there for a real reason:
                    // with the fibre already overlaid, an ungrouped shadow is
                    // applied to every leaf, so it blurred 420 hairline strokes
                    // as well as the sheet.
                    //
                    // It fixed that by making it worse. `compositingGroup`
                    // forces an OFFSCREEN RENDER PASS, and **this is the one
                    // sheet in the app that resizes** — it grows from its
                    // natural height to the full screen as a question opens or a
                    // factoid reveals. So every frame allocated a new offscreen
                    // texture at a new size, drew the sheet and its fibre into
                    // it, and Gaussian-blurred the result. Nothing about that
                    // can be cached, because the size is different every frame.
                    //
                    // Eden reported this screen twice — *"opening a factoid lags
                    // as it's revealing the text"*, then *"happens both in
                    // question cards and in factoids"* — and it is the same
                    // defect as the `drawingGroup` regression that came before
                    // it: **an offscreen buffer whose size is animating cannot
                    // be reused, so asking for one costs a full re-render every
                    // frame instead of saving one.**
                    //
                    // Ordering solves both problems and costs nothing. The
                    // shadow goes on the bare fill — one closed path, which Core
                    // Animation can satisfy with a shadow path rather than a
                    // render pass — and the fibre is printed over the top
                    // afterwards, where it casts nothing and needs no group.
                    .fill(Paper.ply)
                    .shadow(color: Paper.press.opacity(0.22), radius: 3, x: 0, y: 2)
                    .overlay { Fibre().clipShape(sheet) }
            }
            .contentShape(Rectangle())
        }
        // THE CARD ITSELF IS A CONTROL, and it had no press state.
        //
        // The option rows inside it were given one months ago, with a comment
        // naming this as the third time the defect had appeared here. The card
        // they sit on — the thing you tap to reveal a factoid, which is the
        // primary interaction on this screen — was missed in the same pass.
        .buttonStyle(PressSheetStyle())
        // AN OPEN QUESTION IS NOT A BUTTON.
        //
        // The card is a `Button` because a collapsed one is tappable — a
        // factoid reveals, a question opens. Once a question IS open its action
        // is a no-op, and the sheet is the biggest thing on the screen, so
        // VoiceOver was offering a full-screen button that does nothing while
        // the four things you can actually press sit inside it.
        //
        // The trait goes rather than the `Button`. Swapping the wrapper for a
        // plain view at the moment it expands would change the card's identity
        // mid-transition, and re-introduce the cross-dissolve that took two
        // rounds to get rid of.
        .accessibilityRemoveTraits(isQuestion && expanded ? .isButton : [])
        .accessibilityLabel(accessibilityText)
        .onAppear {
            prior = reviewEncounter() ?? Deck.encounter(for: card.id)
            applyReviewAnswerIfRequested()
        }
    }

    /// The prose answer. ONE view, used by both kinds of card.
    ///
    /// It was written out twice and then only once, which is how the factoid
    /// lost it. A single stored view means there is no second copy to forget.
    private var answerProse: some View {
        Text(card.a)
            .font(TypeScale.answer)
            .foregroundStyle(Paper.press)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(answerShown ? 1 : 0)
    }

    /// The wrong answer he keeps reaching for, crossed out.
    ///
    /// Under the prose rather than beside the option, because it is about the
    /// PAST and the marks above it are about this morning. Struck in the same
    /// pen and the same red as a wrong pick — this world crosses things out one
    /// way, and the app crossing out something he used to believe is the whole
    /// image.
    private func confusionNote(_ confusion: StudyConfusion) -> some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            Text(confusion.label.uppercased())
                .font(TypeScale.microLabel)
                .tracking(1.8)
                .foregroundStyle(Paper.press.opacity(0.5))

            if confusion.showsWording {
                Text(confusion.wording)
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press.opacity(0.55))
                    // Full sweep, arriving with the prose rather than animating on
                    // its own: this is a footnote to the answer, not a second
                    // event, and two pens moving at different times on one card
                    // would read as two different things having happened.
                    .textRenderer(PenStrike(progress: answerShown ? 1 : 0, ink: Paper.danger))
                    // ONE LINE, TRUNCATING — A FOOTNOTE MAY NOT COST THE ANSWER.
                    //
                    // Unbounded, this wraps to two lines, and on the deck's worst
                    // card — longest question, longest prose, longest wrong option
                    // — those two lines came out of the options above it: filmed at
                    // the worst case, all four rows compressed under their 34pt
                    // floor and the first one's descenders were clipped by its own
                    // border. That is the overflow Eden reported months ago
                    // arriving by a new route.
                    //
                    // He is not reading this line, he is RECOGNISING it — it is the
                    // answer he gave, and he gave it. Half of it struck through is
                    // enough to know which one, and it makes the note exactly two
                    // lines tall whatever the deck does next.
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .opacity(answerShown ? 1 : 0)
    }

    /// One answer.
    ///
    /// Three states: untouched, marked right, marked wrong. The marks are the
    /// world's own — an inked block for the right answer, a struck line for a
    /// wrong pick — rather than a colour swap, because this world writes with
    /// ink and crosses things out with a pen.
    @ViewBuilder
    private func optionRow(_ text: String, index: Int) -> some View {
        let correct = card.correctIndex
        let isAnswer = revealed && index == correct
        let isWrongPick = revealed && picked == index && index != correct
        // Options nobody chose, once the answer is out. They recede by LOSING
        // WEIGHT, not by fading: `Ink`'s rule is that a level recedes by size or
        // weight, never by going more transparent.
        let spent = revealed && !isAnswer && !isWrongPick

        Button { pick(index) } label: {
            Text(text)
                .font(TypeScale.body)
                .foregroundStyle(isAnswer ? Paper.ply : Paper.press)
                // THE PEN STROKE. A wrong pick gets crossed out, drawn left to
                // right the way a pen moves, rather than simply recoloured.
                //
                // It used to be an overlay on the ROW, positioned at
                // `proxy.size.height / 2`. On a one-line option that is the
                // middle of the text and it worked. On a TWO-LINE option the
                // row's centre is the gap BETWEEN the lines, so the stroke
                // crossed nothing and — inside the red border a wrong pick also
                // gets — read as a divider splitting the option into two cells.
                //
                // It was invisible while the deck held one question whose
                // options all fitted on one line. The first twenty cards of real
                // content put two-line options on the screen and it became the
                // most obvious thing on the card.
                //
                // A `TextRenderer` gets the actual line boxes, so the stroke
                // goes through every line's own centre however many there are,
                // and still sweeps left to right.
                // ONLY ON THE ROW HE ACTUALLY TAPPED.
                //
                // A custom `TextRenderer` opts text out of SwiftUI's cached
                // glyph path: it forces `Text.Layout` to resolve and a bespoke
                // draw to run every frame. This was attached to ALL FOUR rows
                // at all times, including while the card was still opening and
                // no row was struck — four custom renderers animating in, for
                // a stroke none of them were drawing.
                //
                // Eden: *"still some choppyness when opening the question card
                // at the end of the animation."* The end of that animation is
                // exactly when the four rows arrive.
                //
                // Gated on `picked` rather than on `isWrongPick` so the SWEEP
                // survives: `pick` sets `picked` a frame before `revealed`, so
                // the renderer is already attached at progress 0 when the ink
                // starts moving. Gating on `isWrongPick` would attach it with
                // progress already at 1 and the pen would simply appear.
                .modifier(PenStrikeIfTapped(tapped: picked == index, struck: isWrongPick))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Space.step)
                // A SPENT CONTROL DOES NOT NEED A TOUCH TARGET.
                //
                // Before it is answered every row is `Hit.minimum` tall because
                // it is a thing you have to hit with a sweaty thumb. Once
                // `revealed` they are `.disabled` — nothing can be tapped — so
                // the height is only ever holding text, and holding it at 64pt
                // each crushed the countdown ring to a sliver. `spec.md` makes
                // that ring the training mechanism and requires it readable, so
                // the card giving back the space is not a nicety.
                .padding(.vertical, revealed ? Space.tight : Space.snug)
                // 34, not 0. At zero the rows collapsed into each other and
                // the text overlapped — verified on a frame. Enough to hold two
                // lines of `body`, and less than half of what a live target
                // needs.
                .frame(minHeight: revealed ? 34 : Hit.minimum, alignment: .leading)
                // PRESS BLACK, NOT BLUE.
                //
                // Blue is this world's ink for "already true", which read as the
                // right semantic for a right answer — but a saturated navy block
                // is the coldest thing on a warm paper page and it looked
                // foreign. Eden: *"i'm not a fan of the blue colors… they don't
                // fit the app."*
                //
                // A solid inked block is the strongest affirmative this world
                // has and it is already the vocabulary of `DONE`. It also puts
                // maximum distance between the right answer and the struck red
                // of a wrong pick, where blue-vs-red was two colours competing.
                .background(isAnswer ? Paper.press : Color.clear)
                .overlay {
                    Rectangle().strokeBorder(
                        isWrongPick ? Paper.danger : Paper.press.opacity(spent ? 0.18 : 0.45),
                        lineWidth: isWrongPick ? 2 : 1.5
                    )
                }
        }
        .buttonStyle(PressSheetStyle())
        .disabled(revealed)
        // One token, one rhythm: the same `threshold` used by the crossing on
        // the Set screen, so the app has ONE way of saying "here is the fact".
        .animation(Motion.threshold(reduceMotion: reduceMotion), value: revealed)
    }

    private var verdict: (right: Bool, chosen: Int)? {
        guard let picked, let correct = card.correctIndex else { return nil }
        return (picked == correct, picked)
    }

    /// The verdict is carried VISUALLY by the marks on the options, so it is
    /// stated here rather than printed a second time. A sighted reader sees
    /// which option was inked and which was struck through; a VoiceOver reader
    /// has to be told.
    private var accessibilityText: String {
        guard revealed else {
            return isQuestion ? "\(card.q). Four answers." : "\(card.q). Reveal answer."
        }
        guard let verdict else { return "\(card.q) \(card.a)" }
        return "\(verdict.right ? "Right." : "Not that one.") \(card.a)"
    }

    /// `-answer <index>` pre-picks an option, for review.
    ///
    /// A question has three states — unanswered, right, wrong — and no
    /// synthesised tap reaches this simulator, so without this only the first
    /// could ever be looked at. Same reason `-tier`, `-card` and
    /// `-demo-crossing` exist.
    ///
    /// It deliberately does NOT call `Deck.record`: reviewing a screen must
    /// never write mastery. The flag reproduces the LOOK of an answer, never
    /// its consequence.
    private func applyReviewAnswerIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-answer"),
              arguments.indices.contains(flag + 1),
              let index = Int(arguments[flag + 1]),
              let choices = card.choices, choices.indices.contains(index)
        else {
            return
        }
        // Opens the card as well as answering it. A pick that did not expand
        // reproduced a state the app can never actually be in — collapsed and
        // answered — which is a worse lie than no review flag at all.
        onExpand()

        // `-answer-after <seconds>` waits before picking, so the VERDICT can be
        // filmed and not just photographed. Without it the answer is applied in
        // `onAppear`, before there is a frame to animate from — the same gap
        // `-expand-after` exists to close, one beat later in the flow.
        let delay = arguments.firstIndex(of: "-answer-after")
            .flatMap { arguments.indices.contains($0 + 1) ? Double(arguments[$0 + 1]) : nil }

        guard let delay else {
            picked = index
            onReveal()
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            picked = index
            onReveal()
        }
    }

    /// `-seen <n>` and `-missed <n>` fake a history, for review.
    ///
    /// A fresh install has met nothing, so every state `StudyMark` can be in is
    /// unreachable in a screenshot — and this app has shipped a state nobody
    /// could reach before. Same reason `-card`, `-answer` and `-tier` exist.
    ///
    /// It fabricates the READING, never the log: nothing is written, so
    /// reviewing a screen still cannot alter what the deck believes.
    private func reviewEncounter() -> StudyPlan.Encounter? {
        let arguments = ProcessInfo.processInfo.arguments
        func value(_ flag: String) -> Int? {
            guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
                return nil
            }
            return Int(arguments[index + 1])
        }
        let seen = value("-seen")
        let missed = value("-missed")
        let run = value("-run")
        // `-confused <index>`: he has chosen that option wrongly before. The
        // count comes from `-missed`, floored at the two it takes to be a
        // confusion rather than a slip.
        let confused = value("-confused")
        var wordings: [String: Int] = [:]
        if let confused, let choices = card.choices, choices.indices.contains(confused) {
            wordings[choices[confused]] = max(2, missed ?? 2)
        }
        guard seen != nil || missed != nil || run != nil || confused != nil else { return nil }
        // `-run` is needed to reach `.settled` at all: a card missed twice with
        // no run since needs TWO more rights, so `-missed 2 -answer` correctly
        // stays a miss. Without the flag the settled mark is a state nobody can
        // photograph, which is the thing this app keeps shipping.
        return StudyPlan.Encounter(
            sightings: seen ?? 1,
            lastSeen: Date(),
            answered: (missed ?? 0) + (run ?? 0),
            misses: missed ?? 0,
            run: run ?? 0,
            wrongWordings: wordings
        )
    }

    /// Records the answer and reveals it.
    ///
    /// **Only ever called from a tap.** When the rest runs out unanswered the
    /// Rest screen reveals the card on its own timer and this never fires, so
    /// nothing is written that Eden did not actually choose — his ruling, and
    /// the reason a slow morning cannot be recorded as ignorance.
    private func pick(_ index: Int) {
        guard picked == nil, let correct = card.correctIndex,
              let choices = card.choices, choices.indices.contains(index)
        else {
            return
        }
        picked = index
        // The WORDS, not just the index. See `StudyAnswer.pickedText`: an index
        // into a deck that content agents rewrite cannot safely be read back as
        // "you answered X".
        Deck.record(card.id, picked: index, right: index == correct, wording: choices[index])
        Haptics.shared.logged()
        onReveal()
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
