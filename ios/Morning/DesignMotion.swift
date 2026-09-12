import SwiftUI

// ---------------------------------------------------------------------------
//  THE DESIGN SYSTEM — motion
//
//  The doctrine is `02-design-brief.md §9`, and it is four rules:
//
//    · Fast where it's in the way, slow where it's the point. Step transitions
//      are instant because you are mid-workout; the completion moment can take
//      four seconds because it is the reward.
//    · Nothing blocks input. A transition must never gate the next tap on an
//      animation finishing. The web version had exactly this bug and it made
//      the app feel broken.
//    · Motion carries meaning. When something gets smaller, it is because it is
//      giving its space to something else.
//    · Every animation has a reduced form. Calmer, not disabled.
//
//  The last one is why every token here is a FUNCTION of `reduceMotion` rather
//  than a constant with an `if` at each call site. A reduced form you have to
//  remember to write is one you will forget to write.
// ---------------------------------------------------------------------------

enum Motion {
    /// The strong ease-out, as a curve you can evaluate.
    ///
    /// `cubic-bezier(0.23, 1, 0.32, 1)`. SwiftUI's built-in `.easeOut` is the
    /// weak CSS one and lacks the punch that makes a deliberate animation read
    /// as intentional. This exists as a `UnitCurve` rather than an `Animation`
    /// because the completion moment derives every value from one elapsed
    /// clock and needs to SAMPLE the curve, not hand it to the system.
    static let easeOutStrong = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.23, y: 1),
        endControlPoint: UnitPoint(x: 0.32, y: 1)
    )

    // MARK: Interactions you are waiting on

    /// The rep counter changing. Must feel like the digit moved because you
    /// pushed it — so it is quick, and it never gates the next tap.
    static func rep(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.08) : .easeOut(duration: 0.18)
    }

    /// The second beat of crossing last time's number.
    ///
    /// The haptic for this moment is two events 45ms apart, and the reason is
    /// in `DesignHaptics.swift`: the hand reads rhythm far better than it reads
    /// amplitude. The screen was doing the opposite — the digit changing colour
    /// and the sentence underneath arriving in the same frame, one beat where
    /// the hand gets two.
    ///
    /// So the fact lands after the number. The delay is 0.22s, and the number
    /// that matters is not the haptic's 45ms — it is how long the counter takes
    /// to *finish*. The digit rolls under `contentTransition(.numericText)`, so
    /// the new glyph is not fully there until about 0.24s after the tap even
    /// though its colour animation is 0.18s. Measured off a 60fps capture, a
    /// 0.09s delay still had the sentence fully legible while the digit was
    /// mid-roll: the second beat arriving before the first.
    ///
    /// Vision also fuses what touch separates — below roughly 80ms two visual
    /// events read as one — so this could not have been the haptic's 45ms
    /// either. Both constraints point the same way.
    static func threshold(reduceMotion: Bool) -> Animation {
        // The reduced form keeps the delay, shortened. Reduce Motion asks for
        // calmer, not for less information, and the two beats ARE the
        // information here — the number, then what it means. Collapsing them
        // into one frame would be the same mistake this token exists to fix,
        // just for the people who asked for less movement.
        //
        // 0.10s rather than 0.22 because there is no digit roll to clear: the
        // reduced `Motion.numeric` is a plain opacity change. It only has to
        // beat the ~80ms at which two visual events fuse into one.
        reduceMotion
            ? .linear(duration: 0.12).delay(0.10)
            // 0.12, not 0.22. The two beats are still two beats — the comment
            // above names ~80ms as the point at which two visual events fuse,
            // and 120ms clears it — but 220ms of nothing after a tap is not a
            // beat, it is a stall. Eden: *"i click the button, it is stuck for
            // a moment."* The information survives; the wait does not.
            : .easeOut(duration: 0.20).delay(0.12)
    }

    /// A control being pressed.
    ///
    /// The one thing exempt from the frequency gate: at 6:10am, with the phone
    /// on the floor, the press state is often the only proof a knuckle tap
    /// landed. `01-motion-doctrine.md` §1.2 allows up to 160ms and this sits
    /// well inside it — long enough to be felt as movement, short enough that
    /// it never queues behind the next tap.
    static func press(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.06) : .easeOut(duration: 0.10)
    }

    /// Logging a set.
    ///
    /// R2, 2026-08-25 — bounce 0.24 → 0. The old note read "a little weight,
    /// because something was committed", which is a feeling, not a reason.
    /// `apple-design` §4 sets the rule: start at critically damped, and add
    /// bounce **only when the gesture itself carried momentum** — a flick, a
    /// throw, a drag release. Overshoot on something you flicked feels right;
    /// overshoot on something you tapped feels like the UI is editorialising.
    ///
    /// There are no momentum gestures in this app. A knuckle tap on a 82pt
    /// target at 6:10am is the opposite of a flick, and this fires 28 times a
    /// session. A workout instrument that boings is a consumer fitness app.
    ///
    /// Bounce is now off by default across this whole file. The two places it
    /// survives are `reveal` and `timerResize`, and both are the same event —
    /// the ring yielding its space to the card — where a trace of overshoot
    /// reads as the layout settling rather than as a reward.
    static func commit(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : .spring(duration: 0.28, bounce: 0)
    }

    /// Set → Rest and Rest → Set — every step change in the session.
    ///
    /// R2, 2026-08-25 — 0.44s → 0.18s, and the reason is that **the thing this
    /// duration was buying no longer exists.** The comment here used to read
    /// "the work object carries across, so this is the one that must not feel
    /// like a cross-fade", and that was true when a `matchedGeometryEffect`
    /// carried the counter into the ring. Eden asked for that morph gone twice;
    /// it is gone from every shipped screen and survives only in the W1
    /// prototype lab. The morph left and its 0.44s stayed.
    ///
    /// This fires ~28 times per session. `emil-design-eng`'s frequency gate puts
    /// that in the tier where motion is removed or drastically reduced, and
    /// `apple-design` §1 is blunter still: every latency on the input path that
    /// is not essential is a regression. 0.44s × 28 is nine seconds per session
    /// spent watching a screen become itself.
    ///
    /// It is not zero, and R1 §3.1 says why: two consecutive sets of the same
    /// exercise differ by one glyph, so with no transition at all a knuckle tap
    /// you are not looking at has no acknowledgement, and the user taps `Done`
    /// twice. The transition's job is to say "it advanced" — nothing more.
    static func stage(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.12) : .easeOut(duration: 0.18)
    }

    /// How a screen leaves and how the next one arrives.
    ///
    /// A symmetric cross-fade was the first attempt and it was wrong. Measured
    /// off a 60fps capture, both screens sat near half opacity for ~0.2s, which
    /// put the Set screen's cues and Done button directly on top of the Rest
    /// screen's "+15s / Skip" and next-up label. Legible content on legible
    /// content reads as neither.
    ///
    /// So: out fast, in late, with only a narrow window where both exist.
    ///
    /// R2, 2026-08-25 — the SHAPE stays and both NUMBERS change. Two faults:
    ///
    /// 1. **`.easeIn` on the insertion.** On the entering element, which is the
    ///    worst place for it. Ease-in starts slow, so it withholds movement at
    ///    exactly the moment the user is watching most closely, and a 0.30s
    ///    ease-in reads slower than a 0.30s ease-out does. Both skills name this
    ///    explicitly, and `redesign-plan.md` §4 lists "ease-in on anything
    ///    entering" as one of the eight escalation triggers that survive the
    ///    translation to Swift. It was a live instance of a documented trigger.
    ///
    /// 2. **The gap was sized for a morph that was deleted.** The old note said
    ///    the window is "deliberate rather than zero — the work object crosses
    ///    it, and the counter becoming the ring is the one continuity worth
    ///    protecting." Nothing crosses it now. See `stage` above.
    ///
    /// What survives is the reason the window is not zero *now*: a symmetric
    /// cross-fade put both screens near half opacity for ~0.2s and stacked the
    /// Set screen's cues on the Rest screen's controls. Legible content on
    /// legible content reads as neither. So the outgoing screen still clears
    /// before the incoming one commits — it just does it in 0.18s total instead
    /// of 0.34s, and it eases out in both directions.
    ///
    /// Under Reduce Motion, a plain fade rather than a degraded version of this.
    static func screenSwap(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            return .opacity.animation(.linear(duration: 0.12))
        }
        return .asymmetric(
            // 0.05, not 0.08. At `easeOut(0.10)` the outgoing screen is
            // already under ~25% opacity by 0.05s — below the threshold at
            // which its text competes with anything — so the incoming one can
            // start there without recreating the symmetric cross-fade this
            // asymmetry exists to avoid.
            //
            // The old 0.08 was sized to protect a morph that crossed the gap,
            // and that morph was deleted; the note two paragraphs up says so.
            // Measured with the chrome hoisted (`plans/011`), 0.08 left ~80ms
            // in which the chrome was the only thing on screen. See plans/013.
            insertion: .opacity.animation(.easeOut(duration: 0.10).delay(0.05)),
            removal: .opacity.animation(.easeOut(duration: 0.10))
        )
    }

    /// Leaving the completion moment.
    ///
    /// **Faster than the entrance, and it goes back the way it came.** The fan
    /// rose from behind the horizon, so it sinks behind it — an exit that
    /// retraces its entrance is what makes the moment feel like one object
    /// rather than two effects. Paper does not drift off; it goes back where it
    /// came from.
    static func leave(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.20) : .easeOut(duration: 0.42)
    }

    // MARK: Motion that is the point

    /// The study card's answer arriving. The timer yields its space to the
    /// text — one element's shrink IS the other's explanation, so this is
    /// slower than an interaction and allowed to be felt.
    static func reveal(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.18) : .spring(duration: 0.50, bounce: 0.12)
    }

    /// The answer arriving, after the card has finished growing.
    ///
    /// Revealing changes the layout: the timer halves and the card takes the
    /// space, which `02-design-brief.md §9` singles out as the app's example of
    /// motion carrying meaning. That motion should happen immediately — it is
    /// the explanation. The TEXT should not.
    ///
    /// Measured on a 60fps capture, it did. A six-line answer appeared at full
    /// length and full opacity while the question was still travelling to its
    /// new position and "Tap if you have it" was still fading out on top of it:
    /// three layers of legible text at once, for about 150ms.
    ///
    /// So the answer holds its space from the first frame — the card grows on
    /// schedule — and its ink waits for the layout to settle.
    static func answer(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.16) : .easeOut(duration: 0.28)
    }

    /// One of four answers arriving, by its rank down the card.
    ///
    /// **They wait for the page.** An inserted view is laid out where it is
    /// ARRIVING, not where its container currently is, so rows entering while
    /// the card was still rising were drawn at their destination on top of a
    /// question that had not got there yet — the two collided inside the sheet
    /// for about 100ms. Filmed with the stagger removed entirely, the collision
    /// was identical, which is how it is known to be the card's travel and not
    /// the cascade.
    ///
    /// 0.18s is measured, not chosen: `reveal`'s spring is nominally 0.50s but
    /// on a 60fps capture the card's rise is visually finished by frame 12.
    /// Waiting the nominal duration would have cost a third of a second of
    /// staring at an empty page.
    ///
    /// Then 45ms a row — inside the 30–80ms band, the same family as the
    /// sunrise fan's 55ms. The page unfolds, then the answers are written onto
    /// it, and the last of the four lands at about 0.33s.
    ///
    /// **Reduce Motion takes the cascade away, not the entrance.** A cascade is
    /// movement and movement is what was asked to stop; the rows still fade in,
    /// so nothing appears from nowhere.
    static func optionEntry(reduceMotion: Bool, rank: Int) -> Animation {
        guard !reduceMotion else { return reveal(reduceMotion: true) }
        return reveal(reduceMotion: false).delay(Double(rank) * 0.045)
    }

    /// HOME ARRIVING. `01-motion-doctrine.md` §3.2, the one surface where an
    /// entrance is explicitly affordable: *"Standard. ≤250ms. Stagger permitted
    /// but capped at 80ms total across all items."*
    ///
    /// The cap is the whole ruling and it is not a style choice. The doctrine's
    /// own reason: *"a long cascade delays the one tap the user came to make."*
    /// Home is where he presses Start at 6:10am, and every millisecond of
    /// choreography sits between him and that button.
    ///
    /// So: **18ms a rank**, which puts the fifth and last element 72ms behind
    /// the first — inside the 80ms budget with room, and about a third of the
    /// study card's 45ms cascade, because that one is read and this one is
    /// passed through.
    ///
    /// Everything is on screen and tappable by ~0.3s. A `Button` at zero
    /// opacity does not take a tap, which is exactly why the budget is small.
    ///
    /// **Reduce Motion takes the cascade away, not the entrance** — the same
    /// ruling `optionEntry` makes, for the same reason: a cascade is movement,
    /// and movement is what was asked to stop.
    static func homeArrival(reduceMotion: Bool, rank: Int) -> Animation {
        guard !reduceMotion else { return .easeOut(duration: 0.16) }
        return .easeOut(duration: 0.22).delay(Double(rank) * 0.018)
    }

    /// How far a Home element travels on arrival.
    ///
    /// Six points, and DOWNWARD-facing — the element starts low and settles up,
    /// which is the direction paper falls onto a desk rather than the direction
    /// a modal slides. Anything larger reads as a layout shift on a surface
    /// whose whole job is to be legible instantly.
    static let homeArrivalRise: CGFloat = 6

    /// How long the study card takes to finish rising, measured off film.
    ///
    /// `reveal`'s spring is nominally 0.50s, but a spring covers almost all of
    /// its distance early: on a 60fps capture the card's rise is visually
    /// finished by frame 11. Waiting the nominal duration would have cost a
    /// third of a second of staring at an empty page.
    static func cardSettle(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0.10 : 0.18
    }

    /// How long the card takes to stop moving. `answer` waits this out.
    static func answerDelay(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0.10 : 0.34
    }

    /// The timer resizing as the card takes half the screen.
    static func timerResize(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.18) : .spring(duration: 0.55, bounce: 0.10)
    }

    // MARK: Ambient

    /// PROTOTYPE ONLY — no production consumer since the sky was removed.
    ///
    /// `PrototypeSky.swift` is the last reader. The dawn backdrop these periods
    /// paced is gone from every shipped surface, so nothing here paces anything
    /// a user sees. Kept because the prototype is the record of how the look
    /// was chosen and stays runnable; do not read this as a live system.
    ///
    /// The sky's drift periods, in seconds. Two banks at different speeds:
    /// the parallax between them is what reads as depth rather than as a
    /// moving backdrop.
    ///
    /// Under Reduce Motion these do not slow down, they stop. Drifting cloud is
    /// precisely what that setting exists to switch off — and the sky keeps all
    /// its structure, colour and progress reading while still.
    enum Drift {
        static let cloudFar: Double = 200
        static let cloudNear: Double = 128
        static let rays: Double = 150
        /// One meteor per cycle, while the sky is still dark enough to hold stars.
        static let meteorCycle: Double = 11
        static let meteorFlight: Double = 1.15
    }

    // MARK: Hold-to-repeat

    /// `04-rules.md §1`: the rep control reports a delta, never an absolute,
    /// because hold-to-repeat accelerates far enough that two taps land in one
    /// update cycle. These are the numbers that make that reachable.
    enum Hold {
        /// Before the first repeat, so a single deliberate tap never repeats.
        static let firstDelay = 410
        /// The gap between repeats, before acceleration starts eating it.
        static let repeatDelay = 230
        static let acceleration = 0.80
        /// Fast enough that two increments land in one update cycle — which is
        /// exactly why the control reports a delta and never an absolute.
        static let floor = 60
    }

    /// A numeric transition that rolls rather than swaps — and a plain opacity
    /// change when motion is reduced, since a rolling digit is exactly the kind
    /// of movement that setting is asking to be spared.
    static func numeric(reduceMotion: Bool, countsDown: Bool = false) -> ContentTransition {
        reduceMotion ? .opacity : .numericText(countsDown: countsDown)
    }
}
