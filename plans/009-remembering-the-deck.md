# 009 — Remembering the deck

Opened 2026-09-09. The study deck learns who it is talking to.

## What Eden asked for

> I want to start gamifying this. […] I want to start remembering which
> questions i saw, how many times i saw each, so it's always diverse, i wanna
> bring back questions that i got wrong more often so i can iterate and learn
> better. Think of more ways of gamifying the trivia that's not obstructive to
> the workout. also all that needs to be saved in memory so i can export.

Three asks and a boundary. The boundary is his, not mine, and it is the reason
this plan is narrow: **nothing gamified may cost a tap inside a workout.**

## The doctrine this reverses, and how far

`CLAUDE.md`, `spec.md` §register and `PRODUCT.md` principle 2 all said the app
*"is not gamified and must never become gamified"*. Eden reversed it. All three
now record the reversal and its edge:

| Still true | Now allowed |
|---|---|
| No points, XP, badges, levels, or anything unlocked | The deck may remember what he has seen and what he keeps missing |
| Nothing is lost by missing a morning | A card may be marked with what it already is to him |
| Every line states something true and specific | Those facts may be shown while it is still a question, which is what makes answering worth something |
| The workout's eleven celebration tiers stand alone | — |

## The bug this started as

`Deck.draw` was **without replacement**: a cycle set held every card already
shown, and a card left the pool until the whole deck had been seen. Correct at
26 cards. At 300 it is a twenty-week cycle — and it made the mastery bias
*unreachable*, because a card he had just missed was in the seen set by
definition and could not be drawn again until the cycle turned over.

Simulated over a year of five sessions a week against the real deck:

| | old draw | first cut | shipped |
|---|---|---|---|
| distinct cards met in a year | 256 | 296 | **295** |
| median wait before a missed card returns | **57 sessions** (~11 weeks) | 6 days | **4 days** |
| 90th percentile | 124 sessions | 14 days | **6 days** |
| worst case | never | 30 days | **9 days** |
| standing backlog of shaky questions | — | 13 | **4** |
| misses never asked again all year | 20 | 6 | **1** |

Better on both axes at once, which is the only reason to believe the shape is
right rather than merely different.

## How it works

**Two append-only logs**, both in `AppData` and therefore in the backup:

- `studyAnswers` — what he chose, and **what that option said** (`pickedText`).
- `studySightings` — what he was shown, and whether he opened it by hand.
  New. Written inside `Deck.draw` so a future surface cannot forget to.

Everything else is **derived** — `StudyPlan.Encounter` folds both logs, and
`Deck.Mastery` is now a reading of that fold rather than a cached blob beside
it. The old cache is gone; its own comment said *"a reading that can disagree
with its source is a bug waiting to be found"*.

**Each card carries an interval** — `StudyPlan.interval` — and its priority is
how far past that interval it is. In days, not sessions: a week off is a week of
forgetting whether or not you trained.

| state | comes back in |
|---|---|
| missed, unsettled | 2 days |
| one right since the miss | 6 days |
| settled (two right) | 16 days |
| right four times running | 90 days |
| seen, never answered | 5 days |
| a factoid, by showing | 12 → 30 → 70 → 140 days |

Every miss multiplies the interval by 0.72, compounding to a floor at four. A
question missed four times is asked about four times as often as one fumbled
once — Eden's *"more often"*, read literally rather than as a flag.

**Three slots, asked for different things.** `Deck.intent(forCardNumber:)`:
first rest card `.fresh`, second `.review`, the summary's `.open`. This is what
stops coverage and review being a trade — the `fresh` slot's guarantee is
asserted every session of the year-long simulation, not in aggregate.

**And the third slot reviews when he is behind.** Eden, after the first cut
landed at six days: *"i want the median wait for a missed card at 4 days."*

The first cut could not be tuned there, and finding out why was the useful part.
A missed question waited behind a standing backlog of about thirteen, and the
wait was set by **throughput, not by order** — every shaky card is pinned at the
priority ceiling, so sorting the review queue by overdueness, shrinking its
shortlist and halving the bottom of the ladder each moved the median by zero.

| change | median | coverage |
|---|---|---|
| as first shipped | 6.1 d | 297 |
| review queue ordered by overdueness | 6.2 d | 297 |
| review shortlist 24 → 8 | 6.0 d | 296 |
| missed-card interval 2 d → 1 d | 6.0 d | 296 |
| **third slot always reviews** | 5.0 d | 278 |
| **third slot reviews while backlog ≥ 5, repeat guard 8 → 6** | **4.0 d** | **295** |

So: `StudyPlan.reviewBacklog = 5`. Under it the last card of the morning is free
to be anything and coverage is untouched; at it the backlog stops growing, which
is the only thing that shortens the wait. It is also the more honest behaviour —
when he is on top of the deck the last card can be anything, and when he is
carrying five questions he keeps getting wrong, it cannot.

**The repeat guard went 8 → 6**, which is exactly two sessions of three cards.
Eight was a multiple of nothing here and it put a hard floor of *three sessions*
under any return — on a five-day training week that is five days, whatever the
scheduler wants. Six keeps the guarantee that matters (no repeat within a
session or the next one) and lets a miss come back on the third morning.

**Diversity** is that card guard (6) plus a **topic guard** (3), so four
consecutive draws are four different topics out of the deck's ~103.

## What is visible

Almost none of the above is, by construction. So one thing is: **`StudyMark`**,
a label beside the card's topic.

- `2ND TIME` / `3RD TIME` — press black at half weight. The times-seen count he
  asked for.
- `MISSED LAST TIME` / `MISSED 2×` — the pen's red. **On the card while it is
  still a question**, which is the whole mechanic: the rematch.
- `SETTLED` — when the answer he just gave settles a question he used to miss.
- Nothing at all on a first meeting. A mark on every card is furniture.

And the Summary's line, re-based. It counted settled questions against every
question in the deck; at 300 cards that reads "41 of 214 solid" — nineteen
percent — and it would get *worse* every time a writing group added a card. It
now leads with coverage and counts mastery against what he has actually
answered: *"84 of 302 cards met. 41 questions solid, 6 you keep missing."*

## Verified

- `./scripts/verify-ios.sh` — seven phases, **108 assertions, 0 skipped**.
- Four states shot on device at the deck's worst-case masthead (topic
  `Cabernet Sauvignon`, 18 characters): unopened + `MISSED 2×`, answered +
  `SETTLED`, `3RD TIME`, and the full prose answer. Nothing overflows, the
  question does not re-wrap, the options fit above the buttons with room.
- **Eden's own phone export** (`morning-backup-2026-09-05.json`, 12 sessions,
  1607 reps, 11 of 12 with `kg`) decoded against the new schema: both study
  logs read ABSENT, so a restore leaves them standing. Regression test added.

## The confusion pair

Asked for and built after the rest. It was the one thing the logs could compute
and could not safely say.

**The blocker was `picked` being an index.** The deck is rewritten by content
agents who rephrase and reorder options, so index 2 in March is not necessarily
the answer he gave in March — and *"you keep answering Chenin Blanc"* is worth
reading, and worth nothing at all if it might name an option he never chose.
`StudyAnswer.pickedText` carries the words alongside the index: forty bytes an
answer, and the difference between a log that can count and one that can say
what happened.

Everything downstream keys on the **words**, which also means it survives a
card's options being shuffled. Index-keyed counting would have called two
different answers the same confusion the moment that happened.

**Twice is the threshold.** One wrong answer is a slip; the same wrong answer
twice is something he believes, and only the second is worth interrupting a rest
for. It appears only once the answer is out — never while the question is still
a question, because naming the option he usually reaches for would tell him
which one not to pick.

| what just happened | the card says |
|---|---|
| he got it right | `TWICE BEFORE` + the old answer, struck |
| he reached for it again | `THAT ANSWER, 3 TIMES NOW` — no wording; it is already struck four lines up |
| the rest ran out | `TWICE BEFORE` + the old answer, struck |
| he made a *different* mistake | nothing — his old confusion is not what just happened |
| that option is no longer on the card | nothing — a struck line matching nothing above it reads as a bug |

**Two things the render caught that reading did not.** On the deck's worst card
the note wrapped to two lines and took them out of the options above it: all
four rows compressed under their 34pt floor and the first one's descenders were
clipped by its own border — the overflow Eden reported months ago, arriving by a
new route. The struck wording is one line and truncated now; he is not reading
it, he is recognising it. And on a repeat the note printed the identical
sentence the option row had already struck, which reads as a rendering fault
rather than as a memory, so the repeat carries only the count.

**It starts empty.** No answer logged before this has a wording, and those stay
misses the app cannot name — never backfilled from the card's options as they
stand today, which is exactly the lie the field exists to prevent.

## Proposed, not built

Each of these is real and none is decided:

1. **A study surface.** Three hundred and fifty-odd cards across a hundred-odd
   topics — and still growing — with one line on the Summary as the only view of
   it. `plans/004` explicitly ruled out a twelfth surface; that ruling was made
   when the deck held 26 cards.
2. **No study streak.** Deliberately absent, and the argument is `README.md`'s
   own: the program is five days a week, so a consecutive-day streak punishes
   following it correctly. A study streak would also be a second scoring system
   beside the workout's, which `PRODUCT.md` principle 2 forbids. If Eden wants
   one anyway it should be **weekly**, like the workout's, and it should be his
   call rather than mine.
