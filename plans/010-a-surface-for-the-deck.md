# 010 — A surface for the deck

Opened 2026-09-09. Planned, then **built** the same day — Eden picked this as
where the design investment goes.

## Why this is now open when `plans/004` closed it

`plans/004` ruled, and was right at the time:

> *"the study deck stays a rest filler — no surface of its own, no tracked
> progress"* → **Tracked, but still a rest filler.** Progress surfaces as ONE
> LINE on the Summary. No twelfth surface, no nav entry.

That was decided against a deck of **26 cards**. The deck is **356 and still
growing** — fifteen writing groups, a curriculum review, and a review agent
still running. One line on a screen seen once a session is now the entire view
of a body of knowledge it took a programme to build.

**What changed is the ratio, not the principle.** The principle stands: a
workout is not a study app, and nothing here may cost a tap inside a session.
This surface lives entirely outside one.

## The question this surface answers

Not "how am I doing" — that is a score, and `009` settled that the app states
knowledge rather than keeping score. The question is:

> **What do I know, what am I getting wrong, and what have I not met yet?**

Everything below is judged against that sentence. Anything that does not answer
it is decoration.

## What the data can already say

All of it is derived from the two logs, needs no new capture, and is exportable
today. This is the argument for building the surface *now* rather than
instrumenting first.

| Fact | Where it comes from |
|---|---|
| Cards met, of the whole deck | `Standing.met` / `.cards` |
| Questions solid, and questions he keeps missing | `Standing.settled` / `.shaky` |
| Per **topic**: how many cards, how many met, how many solid | `Encounter` folded by `Card.topic` |
| Per **subject** (wine / tea) the same | `Card.subject` |
| The wrong answers he keeps reaching for | `Encounter.confusion` |
| Cards he has been shown and never opened | `sightings` vs `engagements` |
| When a card is next due | `StudyPlan.interval` |
| The whole answer history, oldest first | `Deck.answers()` |

**One gap worth naming:** nothing records *when he stopped* studying a topic, or
how long an answer took. Neither is needed for the question above.

## Three shapes, and a recommendation

### A. The map — one screen, topics as a grid
Every topic a cell; the cell is inked in proportion to what he has settled.
Reads at arm's length, answers all three parts of the question at once, and the
year grid on History already establishes the vocabulary of a grid you read
rather than scroll.

**Against:** 111 topics is a lot of cells, and most hold one or two cards. A map
where most cells are one card is a map of the deck's shape, not of his
knowledge.

### B. The list — topics ordered by what needs him
Topics sorted by shaky first, then unmet, then solid. Each row: the topic, its
count, and its state as a sentence.

**Against:** a list ordered by "what needs you" is a to-do list, and a to-do list
of things you are bad at is the closest thing to a score in this whole plan.

### C. **The reading — one screen, three sections, no interaction** ← recommended
1. **The standing**, in the largest type: what the Summary line says, given room.
2. **What you keep missing** — the shaky questions, each with its card's question
   and the wrong answer he keeps reaching for, struck through. This is the
   confusion pair given the space it never got on a rest card.
3. **Where the deck is thin for you** — the topics he has met least, as a plain
   sentence rather than a chart: *"You have not met a card in Rioja, Alsace or
   Champagne."*

**For:** it answers the question in one screen, in the app's own voice, with no
control to operate at 6:10am or any other time. It is a *reading*, which is what
this app does — see the Summary and the celebration tiers. And it is the only
one of the three that shows the confusion pair, which is the most interesting
thing either log holds and currently gets one truncated line.

**Against:** it does not scale past a screenful. That is a real limit and the
answer is to cap each section rather than to add scrolling chrome.

## The three open questions, answered in the build

1. **Where it hangs:** a fifth `HomeDestination`, "Study", beside History, All
   time, Guide and Backup. That admits the deck is no longer only a rest filler,
   which it is not.
2. **Whole deck or only what he has met:** both, at different scales. Coverage
   is against the whole deck (*"119 of 356 cards met"*), and every detail below
   it is only about what he has actually studied. Showing 356 unmet cards would
   be showing him a library.
3. **Mid-workout:** unreachable, because Home's nav row is. No rule needed.

## What shipped, and what the build changed

**Recommendation C, plus the index from A.** The plan rejected the topic grid
because 111 mostly-single-card cells map the deck rather than his knowledge —
but an INDEX solves the same problem the grid could not: it is *supposed* to be
long, it is read by looking things up, and leader dots carry the eye across a
gap a grid would have to fill with a cell. So the page is the reading (headline,
then what he keeps missing) with the index under it.

Three things the render changed that the plan had wrong:

- **It was set straight on the stock.** The same mistake `RestScreen` records
  against the study card: bare text on the ground reads as a gap in the world.
  Both sections are pasted plies now, which also buys the contrast this screen
  needs more than any other — press black is 11.35:1 on ply against 7.74:1 on
  stock, and this is a screen of nothing but reading.
- **"YOU SAY" was inline and cost a line.** Beside the struck answer it ate
  enough width to push all five to three lines, and three lines of red is the
  section shouting. Above it, they land in two.
- **The index sorted tea before wine**, because `"tea" < "wine"`. Nobody decided
  that. `StudyReport.subjectOrder` declares it now.

**Verified:** `verify-ios.sh` green, **116 assertions, 0 skipped**. The populated
page, the index and the empty state all shot on device. `-study-seed` writes a
synthetic half-year through `Deck.restore*` and reads it back through
`StudyReport.current()`, so what is on screen came down the real pipeline — the
fold, the engagement rule, the confusion filter — rather than from a hand-built
fixture that would prove only that the layout compiles.

## What this plan does NOT propose

- **No charts.** A chart of settled-over-time is a score with a line through it.
- **No per-card browsing.** A deck browser turns the app into a flashcard app,
  and the whole design of the deck is that cards find him.
- **No editing.** Content is `cards.json` and agents write it.
- **No streak.** `009` and `README.md` both, unchanged.
