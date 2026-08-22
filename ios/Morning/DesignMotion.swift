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
            : .easeOut(duration: 0.20).delay(0.22)
    }

    /// Logging a set. A little weight, because something was committed.
    static func commit(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : .spring(duration: 0.32, bounce: 0.24)
    }

    /// Set → Rest and Rest → Set. The work object carries across, so this is
    /// the one that must not feel like a cross-fade.
    static func stage(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.12) : .easeInOut(duration: 0.44)
    }

    /// How a screen leaves and how the next one arrives.
    ///
    /// A symmetric cross-fade was the first attempt and it was wrong. Measured
    /// off a 60fps capture, both screens sat near half opacity for ~0.2s, which
    /// put the Set screen's cues and Done button directly on top of the Rest
    /// screen's "+15s / Skip" and next-up label. Legible content on legible
    /// content reads as neither.
    ///
    /// So: out fast, in late, with only a narrow window where both exist. That
    /// window is deliberate rather than zero — the work object crosses it, and
    /// the counter becoming the ring is the one continuity worth protecting.
    /// A hard cut there would turn a morph back into a swap.
    ///
    /// Under Reduce Motion the geometry no longer travels, so a plain fade is
    /// the calmer answer rather than a degraded version of this one.
    static func screenSwap(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            return .opacity.animation(.linear(duration: 0.12))
        }
        return .asymmetric(
            insertion: .opacity.animation(.easeIn(duration: 0.30).delay(0.04)),
            removal: .opacity.animation(.easeOut(duration: 0.24))
        )
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

    /// How long the card takes to stop moving. `answer` waits this out.
    static func answerDelay(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0.10 : 0.34
    }

    /// The timer resizing as the card takes half the screen.
    static func timerResize(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.18) : .spring(duration: 0.55, bounce: 0.10)
    }

    // MARK: Ambient

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
