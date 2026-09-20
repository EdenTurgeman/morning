# 015 — Making the teaching smarter

Opened 2026-09-20. Eden: *"plan on how we make the teaching part of the app
smarter, things like the mechanism of which questions to show me, maybe fitting
another question or two in each workout if possible somewhere with 60+ secs."*

**One thing in here is built and shipped; the rest is a plan.** The measurements
below are the point of the document — two ideas that sound obviously right turn
out to be unbuildable against this deck, and knowing why saves the next person
the afternoon it cost tonight.

---

## 1. What already exists — do not re-derive this

The scheduler is not naive and has been through one full rewrite. Before
proposing anything, know that all of this is already true:

**Two raw logs, never summaries.** `studySightings` records every card shown;
`studyAnswers` records every answer *including the wording of the option he
picked*. `StudyPlan.Encounter` folds them per card and is derived, never stored —
"a reading that can be saved is a reading that can disagree with its source".

**Intervals in days, not sessions.** A week off is a week of forgetting whether
or not he trained.

| | ladder (days) |
|---|---|
| Question, by consecutive correct | 2 · 6 · 16 · 40 · 90 |
| Question seen but never answered | 5 |
| Factoid, by times shown | 12 · 30 · 70 · 140 |

**Misses compound, proportionally.** `interval × 0.72^min(misses, 4)`. Missed
once it returns at 72%; missed four times at 27%. Capped at four, because past
that a card is either badly written or genuinely hard and grinding it crowds out
the deck.

**Priority is one axis.** `days since seen ÷ interval`, capped at 4. A card he
has never met is worth 2.5 on that same scale, so novelty and review compete
rather than being traded off by a rule.

**Each slot is asked for something different** — `fresh`, `review`, `open` — and
`open` reviews on its own whenever he is behind. Simulated over a year, that
shape saw more of the deck than the old draw *and* brought a missed card back in
a median of six days rather than eleven weeks. Better on both axes at once.

**A sitting never repeats a card or a topic.**

**Confusion is already tracked and already surfaced.** The exact wrong wording is
kept per card, and both the Rest screen and the Study screen say "you keep
picking this one".

---

## 2. Shipped tonight: a third card, where the session can afford one

Eden's own words, and "if possible" is load-bearing.

A third card goes on a **free rest of 60 seconds or more**, with **at least two
working sets** between it and every card already placed.

- **B gets one** (rests 6, 9, 18 — all 60s). Four cards a session with the
  summary's.
- **A does not.** Its only spare 60-second rest is a single push-up set away from
  a card it already carries. The answer to "can we fit another in" is allowed to
  be no.

The old spacing rule said two carded rests could not be *adjacent in the list of
long rests*. That was a proxy for "far apart in time" which held only while a
session had seven of them; B has four. It now counts **sets between**, which is
what the old rule meant.

### The new slot reviews — and I had this wrong first

It was written as `fresh`, on reasoning that still sounds right: the deck holds
~450 cards, he has met about a quarter, coverage is what another card buys most,
and review is already served by slot 1 and by `open`.

The year-long simulation disagreed. A fresh slot meets new cards, every new card
joins the review pool, and the pool grows faster than the draws that serve it:

| | third card as `fresh` | third card as `review` |
|---|---|---|
| Median days for a missed question to return | **8** | within the ≤5 the suite pins |
| 90th percentile | **28** | within the ≤9 the suite pins |

The `fresh` figures are what the simulation reported when it failed. The
`review` column is what the same assertions accept, which is all the test
prints on success — the thresholds were set against the three-card deck and
still hold, which is the claim that matters.

Coverage up, and the thing Eden actually asked this scheduler for — *"i wanna
bring back questions that i got wrong more often so i can iterate and learn
better"* — measurably worse. **The measurement beat the argument.** Coverage
still improves, because a fourth card is a fourth card and `fresh` still leads
every session; it improves by less, in exchange for not spending a stated
priority to buy it.

**One assertion had to change shape.** At three cards a session the simulation
never finished the deck, so "every session shows something new" could be checked
unconditionally. It finishes now, part way through the year, so the check is
conditional on there being something new left — the extra card working, not the
fresh slot failing.

Also widened with it: `recentLimit` 6 → 7 (B's four plus A's three, the largest
consecutive pair) and `recentTopicLimit` 3 → 4 (else B's fourth card could
repeat its first's topic).

---

## 3. Two ideas that do not work, and the measurements that killed them

### 3a. Teach him the thing he is confusing it with — **dead, 0% coverage**

The idea: he keeps answering a Melon de Bourgogne question with "Chenin Blanc",
so raise the priority of the card that *teaches* Chenin Blanc. The data is
already there — `wrongWordings` keeps the exact text he picked.

Measured against the real deck:

```
wrong options that are ANOTHER card's correct answer:  0 / 1077   (0%)
wrong options that name a card's topic:                0 / 1077   (0%)
```

**Zero, not "few".** The reason is the deck's format: options are bespoke
explanatory sentences with a median length of 58 characters — *"Gravel drains
fast and holds heat; clay stays cool and damp"* — not entity names. A distractor
is written for one question and exists nowhere else in the deck, so there is
nothing to link it to.

This would have been a day's work and would have fired never. **Do not build it
unless the card format changes.**

### 3b. Schedule around topic weakness — **too thin, median 2 cards a topic**

The idea: if he keeps missing Bordeaux questions, show more Bordeaux.

```
447 cards across 127 topics
cards per topic: median 2, mean 3.5, max 16
48 topics hold exactly one card
only 69 of 120 question-topics hold two or more questions
```

For half the deck, "more from this topic" means one other card or none. The
signal exists but there is almost nothing to spend it on.

**It becomes viable if the deck's shape changes** — 4+ questions per topic on the
topics that matter. That is a content job, not a scheduler job, and it is the
prerequisite to reopening this.

---

## 4. The real headroom, ranked

### 4a. A right answer might be a guess — **the one genuine scheduling defect**

Four options is a 25% floor. A lucky guess is indistinguishable from knowledge
and advances the ladder: **one guess takes a card from 2 days to 6, two in a row
takes it to 16.** Nothing ever revisits that conclusion, so "settled" silently
accumulates cards he cannot actually answer.

Cheapest honest fix: **a first correct answer on a card he has never answered
should not earn a full rung.** Either insert a short step (2 · 4 · 10 · 26 · 60)
or require the second correct answer before the interval leaves single digits.
It is a tuning change, it changes what he sees every morning, and it should be
his call rather than mine — which is why it is proposed and not done.

### 4b. Record how long he took — **costs one field, opens everything above**

The app records *what* he answered and never *how fast*. Response time is the
best available proxy for confidence against a guess, and it is the missing input
for 4a: a correct answer at two seconds and a correct answer at eleven are not
the same event, and right now they are stored identically.

It is one number on `StudyAnswer`. It unlocks a real fix for 4a later and costs
nothing to start collecting now — and collecting it now means that when it is
wanted there is already a year of it. **Recommend doing this next, before the
tuning in 4a**, so the tuning can be made against evidence.

### 4c. Factoids carry no signal at all

A factoid cannot be got wrong, so its only input is how many times it has been
shown. Eighty-eight of them are on a pure exposure ladder. The fix is not in the
scheduler: it is to convert the factoids worth knowing into questions. Content
work, and `plans/008`'s review is the precedent.

### 4d. Leave alone

Cross-session topic spacing (the within-sitting rule already covers the morning),
leech detection (`troubleCeiling` and the Study screen's "you keep missing"
already handle it), and any second scoring system — `CLAUDE.md` is explicit that
the deck may keep score of what he **knows** and never of what he **earns**.

---

## 5. Order, if this is picked up

1. **4b** — record response time. One field, no behaviour change, starts the
   clock on having data.
2. **Content** — raise the question count on the topics that carry weight. This
   is what unblocks 3b, and it improves the deck on its own terms regardless.
3. **4a** — retune the early ladder, once 4b has enough data to check it against.
4. **3b** — reopen only if step 2 actually changes the distribution.
