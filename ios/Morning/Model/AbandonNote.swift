import Foundation

/* ===========================================================================
 *  WHAT THE APP SAYS WHEN YOU END A SESSION
 *  ---------------------------------------------------------------------------
 *  It said nothing. `AppModel.abandon()` cleared the session and Home appeared,
 *  in silence, as though the morning had not happened — and `04-rules.md §1`
 *  means the sets already logged went with it.
 *
 *  Eden asked for this and set its register in the same sentence: *"not make it
 *  all sad."*
 *
 *  ── the rule this follows ────────────────────────────────────────────────
 *  `PRODUCT.md` principle 3: **on a bad morning, the truth leads and the warmth
 *  follows.** So the first clause is the loss, plainly, and the second is the
 *  only warm thing that is also true — that nothing beyond this morning went
 *  with it.
 *
 *  ── and what it must not be ──────────────────────────────────────────────
 *  Not encouragement, not "you'll get it tomorrow", and **not a repeat of the
 *  week meter** sitting directly beneath it. "Three more this week" was the
 *  first draft and it is the meter's own number read aloud. *"The week is where
 *  it was"* says something the meter cannot: that he has not gone backwards.
 * ======================================================================== */

struct AbandonNote: Equatable {
    /// Reps that were in the session when it was discarded.
    let reps: Int

    /// **Two lines, and the difference is whether anything was actually lost.**
    ///
    /// Telling him "nothing saved" when he had logged nothing implies he lost
    /// something, which is the one way a line this short can be untrue. He
    /// pressed End before the first set as often as after the fifth.
    var line: String {
        reps > 0
            ? "Nothing saved. The week is where it was."
            : "Ended. The week is where it was."
    }
}
