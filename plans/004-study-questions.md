# 004 — Study questions and mastery

Opened 2026-09-01. Feature design + implementation around ONE made-up question.
Content comes later from a separate authoring agent; this plan is the mechanism.

## What Eden asked for

Some factoids become 4-answer questions. Picking tells you right or wrong. The
app remembers which you got wrong and later got right, and progress is
trackable. All existing factoids stay; some are sometimes questions.

## Two init decisions this reverses, and how far

Both were settled in the `init` interview and recorded in `PRODUCT.md`. Neither
is being drifted past — both were put back to Eden and answered.

| Decision at init | Now |
|---|---|
| *"warmer voice only — no points, no badges, no levels, no XP, no new things to earn"* | **Mastery, stated as fact.** Spaced repetition only. Progress reads as a true statement about knowledge — "19 of 26 solid, 4 you keep missing" — never as a score. No points, no levels, no badges, **no streak**. |
| *"the study deck stays a rest filler — no surface of its own, no tracked progress"* | **Tracked, but still a rest filler.** Progress surfaces as ONE LINE on the Summary. No twelfth surface, no nav entry. |

The narrow reading matters: mastery is *knowledge state*, not a reward economy.
It is the one reading that does not put a second scoring system beside the
workout's celebration tiers, which were deliberately built never to congratulate
without saying something true.

## Behaviour

- A card with `options` is a **question**; a card without is a **factoid**. Both
  keep working; the deck is mixed.
- Questions appear only where cards already appear: a rest of at least
  `Deck.minimumRestForCard` (45s). **The 20-second myo rest never gets one** —
  that rest IS the training stimulus.
- Tap an answer → it says right or wrong immediately, and reveals the same prose
  answer a factoid would have shown.
- **If the rest ends before you answer: reveal the answer, record nothing.**
  Eden's call. Nothing is ever written that he did not actually choose, and a
  slow morning must not be recorded as ignorance.
- **Mastery drives the draw.** A question you missed comes back sooner. A
  question you get right twice running goes quiet.

## Storage — and one honest limitation

Study results live in `UserDefaults` beside the existing
`morning.cards.seen.v1`, **not** in `AppData`.

**Why not `AppData`:** the export is asserted byte-compatible with the web app
(`testExportedJsonIsByteCompatibleWithTheWebAppFormat` pins the exact key set),
and the web build's `parseData` narrows to its own shape — so a key it does not
know is dropped. Round-tripping a backup through the web app would silently
delete study progress. Silent data loss on a file whose whole job is not losing
things is the worst possible outcome.

**The limitation, stated rather than hidden: study progress is NOT in the
backup.** Losing it costs re-studying 26 cards, not history. Putting it in the
export later is a deliberate schema change that needs a matching web-side
update, and should be done as its own piece of work.

## Colour, in the world's existing law

- **Right → `Paper.blue`.** The ink for *already true*. It fits exactly.
- **Wrong → `Paper.danger`.** Already the legislated ink for a bad outcome, and
  it never appears on the same surface as the crossing's overprint.
- No new ink is introduced.

## Voice

Right/wrong is stated, never celebrated. No "Correct!", no "Great!". The
answer's prose is the reward, which is the same rule the celebration tiers
follow: the reward for finishing is being told exactly what you did.

## Scope of this pass

1. `Card` gains optional `options` / `correct` — existing cards decode unchanged
2. A mastery store, and a draw that prefers due questions
3. The question UI inside the rest card
4. **One made-up question** in `cards.json`
5. The Summary line — second step, needs plumbing through `WorkoutHost`

**State on 2026-09-03.** 1–4 are built and verified. 5 is the only one left.

The question UI took three rounds of Eden's review after it first shipped, and
what came out of them belongs here rather than in the log alone:

- A question is a **prompt** until it is opened — "Tap to answer", the shape the
  factoid's "Tap if you have it" already established. It does not become a
  different kind of object until you engage with it.
- Open, it **fills the band** from the rail to the buttons, and the unanswered
  options spread to fill the sheet. The blank paper under an answered card is
  not waste; it is where the prose lands, and reserving it is why answering does
  not move anything.
- The right answer is an **inked block**, never blue. The wrong pick is struck
  through. The card is monochrome plus the orange rule and one struck red.
- The rest timer becomes a **stamp** in the card's masthead, and what travels
  between the ring and the stamp is the **figure** — not the ring, which cannot
  become a rectangle, and not the container. See `MatchedFigure`.

**Any further work on this screen must be FILMED.** Three separate defects in
the transition were invisible in stills and obvious at 60fps. `-expand-after
<seconds>` exists so it can be.
