# Morning — functional specification

**What this document is.** Everything the app must *do* and every surface it
must have, written so the entire interface can be thrown away and rebuilt
without anyone reverse-engineering the behaviour out of the old screens.

**What it does not contain.** Layout, hierarchy, colour values, type scales,
spacing, component choices, motion curves, or which control sits where. Those
are yours. Where a rule genuinely constrains the interface it is written as a
requirement on behaviour — *"the countdown must be readable from 1.5 metres"* is
here; *"the countdown is a 232pt ring"* is not.

**If you are rebuilding the UI, read §1, §2 and §3 first.** §1 is why the app is
shaped as it is, §2 is what it must feel like, §3 is the list of surfaces and
what each one owes the user. §4 onward is the machinery behind them.

**Status:** current as of 2026-08-23. A change in behaviour is a change to this
file in the same commit.

---

## 1. The envelope

One user. A 30-year-old man, 60 kg, training at home on the floor with
adjustable dumbbells — 20 kg of plates in total, nothing else. Six mornings a
week, upper body, in a hard 20-minute cap before showering and starting the day.
He is also a sommelier, which is why there is a study deck in a fitness app.

**There will never be a second user.** No onboarding, no empty-state marketing,
no settings screen, no explaining the app to a newcomer.

### The one fact that shapes the entire product

The dumbbells are light and the weight is deliberately fixed for a whole
session. That is a feature of the training program, not a limitation.

> **Reps are the only progress signal that exists.**

Everything follows from it:

- Logging reps is not bookkeeping, it is the core loop.
- Last session's number **for this exact set** must be visible at the moment of
  doing that set — not in a history tab.
- The moment the counter passes last time's number is the emotional centre of
  the whole app. It deserves the best thing you can build.
- Three identical sessions in a row is the most valuable output the app has: it
  means the program needs to change.
- Losing the history destroys all of it, so backup is a first-class feature.

### Context of use

At 6:10am, half awake. Standing, phone on the floor or a shelf, glanced at
between efforts from a metre or two away, sometimes upside down over a push-up.
Sweaty hands, one-handed, sometimes a knuckle. In a hurry — friction costs
minutes out of twenty. Offline: airplane mode must be indistinguishable from
normal.

| Constraint | Requirement, non-negotiable in any design |
|---|---|
| Half awake | One screen shows exactly one thing to do. Never render the workout as a scrollable list. |
| Sweaty hands | Primary targets ≥ 64pt; rep controls ≥ 78pt. The main action is full-width. |
| Glanceable | Exercise name and rep count readable from ~1.5 m. |
| In a hurry | The common case — "I did what it suggested" — is **one tap**. |
| Phone on the floor | Nothing important in the top 15% of the screen during a set. |
| Offline | Zero runtime network dependency. |
| Contrast | Text holds ≥ 6.6:1 against whatever is behind it, everywhere. |

### The eight non-negotiables

A rewrite that loses any of these is worse than a piece of paper.

1. One screen, one action. Never a list of the whole workout.
2. The common case is one tap: reps pre-filled from history, one control advances.
3. Last session's number is on the set screen, beside the counter, always.
4. Rest timers start automatically and signal at zero — the 20-second myo rest
   especially, because that rest *is* the training mechanism.
5. Nothing is lost on a crash, a call, backgrounding, or force-quit mid-session.
6. Works fully offline.
7. Backup is one tap, and restoring reproduces the history exactly.
8. The program is one editable object in one file that the user edits himself.

---

## 2. The vibe

This section is direction, not decoration. A rebuild that satisfies every rule
in §3–§14 and feels wrong has failed.

### The register

**A good instrument — precise, quiet, confident.** Not a consumer fitness app.
The comparison set is Things 3, Flighty, Halide, Oura. Delight comes from craft
and responsiveness, never from cartoon reward.

**Not gamified, and it must never become gamified.** No points, no badges, no
levels, no XP, no mascot, no streak-freeze economy, no "Great job!". Every
headline states something **true and specific** — "Your previous best on A was
148", "Third A at the same total", "Not one set matched last time". That is what
makes a moment land the twentieth time; a generic congratulation is worth
nothing by the third session.

> The reward for finishing is being told exactly what you did, well.

**Restraint is not austerity.** The previous version was sometimes too plain,
and the whole reason for the rewrite is that the phone can do far more. Spend
the budget on **motion, material, depth and response** — the things that make an
app feel alive in the hand — and keep it out of the copy.

### The bar

- Every state change is animated with intent. Nothing pops or cross-fades by
  default.
- Every meaningful tap has a haptic **matched to its visual**, not a generic
  light impact sprinkled everywhere.
- 120Hz on ProMotion with no dropped frames while a timer runs.
- Nothing scrolls that shouldn't. During a workout, nothing scrolls at all.
- It reads correctly at arm's length, in a dark room, with one eye open.
- Reduce Motion produces a **calmer** version, never a broken or static one.

### The idea the current design is built on

You may keep this, evolve it, or replace it. **The one thing you may not do is
replace it with nothing.**

> The app's entire colour is a function of how far through the session you are.
> It starts at astronomical twilight — deep indigo — and walks the real phases of
> a dawn as the work happens, arriving at gold as it finishes. The timer, the
> progress rail, the primary action and the sky behind everything all move
> together along that ramp.

Two things make it more than a colour scheme. **You can tell roughly how far
through the session you are from across the room without reading anything.** And
the session literally ends at sunrise, which is when it is happening — so the
completion moment is that sun clearing the horizon, and it is the one moment in
the app allowed to be spectacular.

The current ramp is five hand-picked perceptual stops, interpolated, and
deliberately not generated by a formula: a formula gave an even ramp, it did not
give a sunrise. The completion moment is a Metal shader that computes an
atmosphere — sky colour from scattering against the sun's altitude, crepuscular
rays as light surviving a cloud field — rather than drawing a disc and a fan of
spokes.

### What good looks like

The user should want to open this app. Not because it nags him, but because it
is one of the nicest-feeling things on his phone, and because it tells him true
things about himself that nothing else does.

---

## 3. The surfaces

Eleven of them. "Surface" rather than "screen" on purpose — how many views this
becomes is a design decision. What each one **owes the user** is not.

Three are inside a workout (**Warm-up**, **Set**, **Rest**) and are bound by the
one-screen-one-action rule: no scrolling, nothing hidden, everything operable
with a knuckle. The rest are read outside a session and may scroll.

---

### 3.1 Home

**The question it answers:** *what am I doing, and what do I set up?* — in under
two seconds.

**Must be able to show**

- Which session is next (auto-derived: the opposite of the last one logged; A on
  a fresh install).
- What that session actually is — its name, roughly how long it takes, how many
  sets, and the movements in the order they are performed, with superset
  partners shown as one unit because that is how they are done.
- The working weight for it, **and the plate breakdown** — the answer to "what do
  I set up" is a number of plates, not a weight to do arithmetic on at 6am.
- Where the week stands: sessions done against the target, and one honest line
  about what is left. Silent when there is nothing true and useful to say.
- The current weekly streak and the longest run.
- When the last session was and how many reps it was.

**Must be able to do**

- Start the proposed session. This is the primary action.
- Start the other session instead — quieter, for a skipped day or a repeat, but
  always available.
- Change the working weight, in plate steps, bounded by the plates owned.
- Reach History, lifetime totals, the Guide and Backup.

**States:** empty (no history at all — day one is the normal case, not an edge
case), one week, six months.

---

### 3.2 Warm-up

**The question it answers:** *what do I do for the next ninety seconds?*

The least important surface in the app, and it should not pretend otherwise.

**Must show:** a countdown of the programmed seconds, and the warm-up's
instructions.
**Must do:** advance on its own at zero; allow advancing early; allow going back;
allow ending the session.

---

### 3.3 Set — the most important surface

**The question it answers:** *what am I doing right now, how did I do it last
time, and how do I record what I just did?*

Everything on it competes for the same space. Hierarchy here is the single
hardest problem in the app, and **it must never scroll** — if the longest
possible content does not fit, the design is wrong, not the screen. The stress
case is the longest exercise name with four cues.

**Must be able to show, simultaneously**

- The exercise, and enough setup detail to distinguish it from another set of
  the same exercise in the same session.
- The working weight, or that it is bodyweight.
- Which set this is of how many, and the position within a superset round.
- The form cues, **with the ones carrying the training effect emphasised**.
- The target rep range — which may be a range like "8–15" or a sentence like
  "all-out to failure", and the layout must survive both.
- The rep counter, pre-filled (§5).
- Last time's number for this exact slot, or an honest statement that there is
  no comparison (first time, or a different weight).
- Where the session is up to overall.
- When there will be no rest after this set.

**Must be able to do**

- Adjust reps up and down, including press-and-hold to repeat.
- Log the set and advance. **One tap, and it must be the biggest thing to hit.**
- Go back to the previous step without losing anything.
- End the session, behind a confirmation.

**Hard constraints:** the rep controls do not move between exercises — the
control you reach for with a knuckle must be in the same place every time.
Nothing important in the top 15%.

---

### 3.4 Rest

**The question it answers:** *how long until I go again, and what am I doing next?*

**Must be able to show**

- The remaining time, readable from two metres, counting down continuously.
- What is coming next: the exercise, which set, the weight, the target.
- On qualifying rests, a study card (§10).
- Where the session is up to overall.
- On the 20-second myo rest, that the rest itself is the training mechanism.

**Must be able to do:** add 15 seconds; skip to the next step; go back; end the
session.

**Hard constraint:** the last five seconds must be perceptible without looking at
the screen — escalating sound and haptics, plus a change catchable in peripheral
vision.

---

### 3.5 The completion moment

**The question it answers:** *is it over?*

The one moment in the app allowed to be spectacular, and the only place where
spending the budget on spectacle is correct. The session ends at sunrise; this
is the sun clearing the horizon.

**Must:** be a choreographed sequence, not a static image; run once; hand over to
the summary; have a calmer form under Reduce Motion rather than being skipped;
never delay the summary by more than a few seconds; be dismissible.

---

### 3.6 Summary

**The question it answers:** *what did I just do, and was it better than last time?*

**Must be able to show**

- The rep total for the session, as the largest fact on the surface.
- **Exactly one** headline — the highest tier actually earned (§9) — and it must
  add something the rep total does not already state.
- The supporting statement for that headline: the real number it is comparing
  against.
- Session letter, elapsed minutes, the delta against last time — **absent
  entirely when the working weight changed**, because then there is no honest
  comparison — and where the week now stands.
- One study card.

**Must be able to do:** dismiss, returning to Home.

**States:** first session ever, an ordinary session, a personal best, a plateau,
a week completed, a lifetime milestone, a weight change.

---

### 3.7 History

**The question it answers:** *what have I actually been doing?*

**Must be able to show:** every finished session in reverse-chronological order
with its date, letter, total reps and duration; recent weeks at a glance; and a
**full year at once** — a year view that does not fit on the screen has failed at
its only job.

Intensity in the year view is scaled to the user's own range: his quietest
session is the coldest, his best the warmest, so a good month is visibly
different from a bad one.

**Must be able to do:** delete a session, **behind an explicit edit mode**, never
a swipe — sweaty hands, and an accidental delete is unrecoverable. The
confirmation names exactly what is about to be lost.

**States:** empty, one week, six months, a full year.

---

### 3.8 Lifetime totals

**The question it answers:** *did the last six months actually happen?*

This surface exists to make accumulated work feel real. One staggering true
number leads.

**Must be able to show:** total tonnage (§8), and how it was arrived at, honestly
— including that bodyweight reps contribute no kilos; total reps; total sessions
and the split by letter; total time; the date of the first session; and the next
milestone with the distance to it.

**States:** empty is a real state here and "0 tonnes" is a bad answer to it. It
must read as *the beginning of a record*, not as an error.

---

### 3.9 Guide

**The question it answers:** *why is the program like this?*

Nine short reference entries — the training rationale, the progression ladder,
the nutrition targets — read maybe monthly. Static. It may scroll and support
large text sizes properly.

---

### 3.10 Backup

**The question it answers:** *is my history safe?*

**Must show:** when the last backup happened, or plainly that there has never
been one; how many sessions are at stake.

**Must do:** export to a file; restore from one, validating it, stating the
session-count swap and confirming before replacing; erase everything, confirmed
and visually de-emphasised.

The export path must exist regardless of any sync, because it is the only copy
that survives losing the phone *and* the account.

---

### 3.11 The Live Activity

**The question it answers:** *how long is left?* — without opening the app.

While a rest is running, the countdown appears on the Lock Screen and in the
Dynamic Island with the time remaining and what is coming next. Tapping it
returns to the app at the step the countdown was counting.

**It is not the app.** It is glanced at from across a room, on a surface the app
does not control, next to other apps' notifications. A number, what is next, and
nothing else. The dawn belongs to the app.

Exactly one may exist at a time. It ends when the rest ends, when the session
ends, and when the session is abandoned.

**Approved integrations are this and nothing else.** Explicitly declined:
home-screen widget, HealthKit, Control Center control, app-icon badge,
notifications.

---

### 3.12 Decision points

Four destructive or irreversible actions. Each needs a confirmation that **names
what will be lost**, not one that asks "are you sure", and each needs a visible
way to say no.

| Action | What the confirmation must say |
|---|---|
| End a session | Nothing will be saved, including sets already logged |
| Delete a session | Which session, when, and how many reps |
| Restore a backup | How many sessions are coming in, how many are going out |
| Erase everything | How many sessions, and that it is permanent |

---

### 3.13 How the surfaces connect

Reachability is behaviour; the transitions between them are yours.

```
Home ──start──► Warm-up ──► Set ⇄ Rest ──► … ──► Completion ──► Summary ──► Home
 │                 └──────── back one step at a time ────────┘
 │                 └──────── end, confirmed, discards ───────► Home
 ├──► History ──► back to Home
 ├──► Lifetime totals ──► back to Home
 ├──► Guide ──► back to Home
 └──► Backup ──► back to Home

Lock Screen / Dynamic Island ──tap──► the step the countdown was counting
```

- The four reading surfaces are **peers of Home**, not of each other, and each
  returns to Home. There is no tab bar and no deep hierarchy; the app has one
  home and one flow.
- **Launching mid-session goes straight back into the session**, at the step it
  was on, with the rest deadline intact. The Live Activity's tap target is
  therefore just "open the app".
- The Summary is not reachable except by finishing a session.
- There is no settings surface. The only preference the app has is the working
  weight, and it lives with the thing it configures.

---

### 3.14 Platform constraints

| | |
|---|---|
| Device | **iPhone 16 Pro.** Other sizes are not a target and an SE regression is not a defect. |
| Orientation | Portrait only. |
| Network | None, ever. Airplane mode is indistinguishable from normal. |
| Dynamic Type | The three workout surfaces **deliberately clamp** — type there is already at the top of the scale and a surface that must never scroll would break rather than help at accessibility sizes. Every other surface supports the full range, scrolling when it must. |
| Reduce Motion | Every animated sequence has a calmer form. Never a static or broken one. |
| Persistence | Local only. No account, no sync, no server. |

---

## 4. The program

Two sessions, **A** ("Heavy", ~16 min) and **B** ("Light", ~19 min), alternating.

**The program is one plainly-structured data object in one file**, with exercise
names, set counts, rest seconds, loads and cues as literal values. The user
edits it himself in a text editor every few months, rebuilds, and installs. No
indirection, no ID lookups, no separate files, no builder UI. Everything else in
the app derives from that object.

A session is a list of blocks of three kinds:

| Block | Fields |
|---|---|
| `warmup` | seconds, title, cues[] |
| `straight` | exercise, sub?, sets, rest, load \| bodyweight, target \| targets[], cues[], intense? |
| `superset` | sets, rest, items[] — each: exercise, sub?, load \| bodyweight, target, cues[] |

**Loads are plates per handle.** Not total, not including the handle. The user
adds the handle weight mentally. Nothing may try to be clever about this.

**Slot identity is `block.item.set` and is load-bearing.** Rep history, the "last
time" lookup and the tonnage table all key off it. Reordering blocks or changing
set counts breaks the match and silently re-attributes history — which is why a
new movement is *appended* to a session rather than inserted.

A compiles to **21 steps**, B to **25**. Assert against the whole compiled list.

**Content is fixed.** Exercise names, sub-labels, cues, target ranges, rest
seconds, study-card text, Guide text and celebration copy are the product. They
are not to be improved, paraphrased or generated. They change when the user
changes them.

---

## 5. The step machine

A session compiles to a **flat, linear list of steps**, traversed one at a time.
Three kinds: `timer` (the warm-up), `set`, `rest`.

- A rest is emitted after every set **except** between superset partners.
- Trailing rests at the end of a session are dropped.
- **Back** returns to the previous step without losing anything logged.
- **End** abandons: confirm first, then save nothing at all — not even sets
  already logged. Both halves are deliberate.
- The step in progress, the log so far, the session key and the rest deadline
  persist independently of the history and restore on launch.

### Rep prefill, in this priority order

1. What was already logged for this slot **in this session** — so going back to
   fix a mistap shows the number actually entered.
2. What was done on this exact slot **in the last session of the same letter**.
   This is the point of the app.
3. A plausible default — 12 loaded, 10 bodyweight — so a first run is still one
   tap.

Getting this order wrong silently eats corrections.

### The rep control

- Reports a **delta**, never an absolute. Two adjustments landing in one update
  cycle, both computed from the same stale value, collapse into one increment,
  and hold-to-repeat makes that reachable in ordinary use.
- Hold-to-repeat: first repeat after a delay, then accelerating to a floor.
- Clamped at zero, no upper bound.
- **Crossing last time's number changes state — once, on the crossing
  adjustment only**, not continuously while above it. Colour, motion, a distinct
  haptic and a distinct sound. This is the emotional centre of the app.
- **If last time's reps were at a different working weight they are not a target
  and the app must say so**, rather than implying a comparison that does not hold.

---

## 6. Session alternation and the working weight

The app proposes the **opposite** of whatever was logged last; a fresh install
proposes A. Starting the other session instead is always possible.

Each letter has its own **working weight**, adjustable in plate steps and bounded
by the plates owned — 2 × 2.5 kg and 4 × 1.25 kg, so the step is 1.25 kg per
handle and there is a maximum. A weight the plates cannot make is reported as
such, never rounded silently.

Changing the weight is expected and correct: the program's numbers are a starting
guess, and reps only measure effort at a weight you can genuinely take to failure.

---

## 7. Logging a session

A finished session writes **exactly one** history record:

| Field | Meaning |
|---|---|
| `d` | ISO date, **local time**, not UTC |
| `s` | session key, "A" or "B" |
| `log` | slot id → reps |
| `min` | elapsed minutes, floored at 1 |
| `reps` | sum of the log |
| `ts` | epoch ms — **the record's identity** |
| `kg` | optional: plates per handle used |

- `ts` is identity. Deletion, previous-session lookups and milestone diffing all
  key off it. Never regenerate it.
- **A missing `kg` is meaningful** — "logged before the weight was adjustable".
  Fall back to the program default when reading; **never backfill it**, because
  that retroactively rewrites tonnage.
- A failed write must surface, never silently drop a session.

---

## 8. The weekly streak, and lifetime totals

### The week

**Measured in weeks, not consecutive days.** The program is six mornings with a
rest day; a consecutive-day streak would punish following it correctly.

- A week counts if it contains **5 sessions**, on whatever days.
- **The week starts on Sunday.**
- **The week in progress can never break a streak.** It has not finished. It only
  ever adds.
- **Longest run is remembered separately** and stays visible after the current
  streak drops to zero — precisely the moment people stop.

Derivable: sessions done, remaining, days left, at-risk, missed, whether today
can be a rest day, and which weekdays a rest day would cost.

### Lifetime

Headline is **tonnage: reps × load**, with three honesty constraints:

- Every loaded movement is **two dumbbells** and the load is per handle, so a rep
  moves 2 × load.
- **Bodyweight work contributes 0 kg** but still counts toward total reps.
  Counting push-ups would need a bodyweight and a guessed multiplier, which would
  make the headline fiction.
- Sessions are valued at **the weight they were actually done at**, so changing
  the working weight never rewrites the past.

**Milestones**, deliberately sparse — one you hit every fortnight is a chore:

- Tonnes: 1, 5, 10, 25, 50, 100, 250, 500, 1000
- Reps: 1k, 5k, 10k, 25k, 50k, 100k
- Sessions: 10, 25, 50, 100, 200, 365, 500, 1000

A milestone fires **exactly once**, on the session that crossed it, computed by
diffing the ledger with and without that session.

---

## 9. The celebration tiers

Exactly **one** headline fires — the highest thing actually earned:

| # | Tier | Fires when |
|---|---|---|
| 1 | lifetime milestone | A ledger threshold was crossed |
| 2 | clean sweep | Every comparable set beat last time (≥3 sets, same weight) |
| 3 | weight changed | Working weight differs from the last same-letter session |
| 4 | streak milestone | Week completed **and** streak hits 2/4/8/12/26/52 |
| 5 | week complete | The week just reached 5 |
| 6 | record | Beat the best ever on this letter |
| 7 | first | First session ever logged |
| 8 | plateau | Third same-letter session on an identical total |
| 9 | improved | More reps than last time |
| 10 | matched | Exactly equal |
| 11 | done | Anything else, including down on last time |

- **Reps are comparable only at the same weight.** "+18 reps" for dropping 2.5 kg
  a side is not progress, and "dead level" at a heavier weight is not a plateau.
  When the weight moves, say so and start a fresh baseline.
- **Every headline must add something the rep total does not already say.**
- **Plateau is the app's most valuable output.** It is an instruction to change
  the program and the copy names which rung to move to. It must not read as
  failure.
- The ordinary celebration fires on **every** finished session; the larger
  milestone burst is reserved for week completions and lifetime thresholds.

---

## 10. The study deck

26 cards on wine and tea. Every card teaches a **mechanism**, not a fact. Adding
one is a one-line append with no other edit.

### Dosing — these numbers are deliberate

- **Two cards per session, on rests, plus one on the summary.** Not one per long
  rest: eight cards in twenty minutes turns a workout into homework.
- Only on rests of **45 seconds or more**.
- **Never on the 20-second myo rest.** That rest *is* the training stimulus and
  anything inviting the user to linger there breaks the exercise.
- **Not on the first long rest** — that one is for getting your breath back.
  Taken from roughly the first and third quarter of the long rests.
- Drawn **without replacement**: nothing repeats until the deck has been through,
  with a short-term buffer against a repeat in one sitting.

### The reveal

> The user must never miss the timer because he was thinking.

The answer **auto-reveals**. Interaction only brings it forward for someone who
already has it; nothing is gated behind an action, because at 6am mid-rest he
will not reliably perform one, and a card he never got the answer to is worse
than no card.

Reveal delay scales with rest length, clamped to **6.5–11 seconds**; the summary
card gets **14 seconds** because there is no timer to beat. The remaining
thinking time must be **visible and continuously changing** — legible without
reading.

**The card is silent.** The audio vocabulary is entirely about time; a card
making a noise during the last five seconds of a countdown would be actively
misleading. Haptic acknowledgement on reveal is fine.

---

## 11. Timers

Every countdown derives from an **absolute deadline**, never a tick count. That
is what makes it survive backgrounding, and what lets the system draw a live
countdown with no updates from the app.

- Warm-up and rests both count down and advance on their own.
- A rest must complete **even if the app is not drawing** — a redraw-driven timer
  alone can hang forever on a phone that decided not to paint.
- The screen must not sleep during a session; the lock is released on end or
  abandon.
- The last five seconds escalate in sound and haptics, and change visibly.

---

## 12. Sound and haptics

Both vocabularies are **about time and about crossing a threshold**, and nothing
else. They exist because the phone is on the floor and often face down.

| Event | Signal |
|---|---|
| Rep adjusted | Light haptic |
| Crossing last time's number | Distinct haptic detent **and** a distinct tone |
| Set logged | Confirmation haptic and tone |
| Countdown, last 5 seconds | Escalating per-second tone and haptic |
| Countdown reaching zero | "Go" tone and a stronger haptic |
| Card answer revealed | Haptic only — **never** a sound |
| Session complete | Completion haptic and chime |

Audio ducks other audio rather than stopping it, and the audio session comes up
before a countdown rather than during one.

---

## 13. What must never regress

The list a rebuild is most likely to break, roughly in that order:

1. A session in progress survives force-quit and reboot, including the rest
   deadline.
2. Ending a session saves nothing, after a confirmation that says so.
3. Back does not lose a logged rep, and the prefill priority holds.
4. The rep control reports deltas, so rapid input cannot collapse.
5. Reps are never compared across a weight change.
6. One history record per finished session; `ts` is never regenerated.
7. `kg` is never backfilled.
8. Bodyweight reps are 0 kg of tonnage and still count as reps.
9. A milestone fires once, ever.
10. Exactly one celebration headline, and it never restates the rep total.
11. The week in progress cannot break a streak.
12. No card on the 20-second rest, and the card is silent.
13. Nothing inside a workout scrolls, and the rep controls do not move between
    exercises.
14. Every surface behaves correctly at empty, at one week, and at six months.

---

## 14. Where the details live

This file is the behaviour. When a number is needed rather than a rule:

| For | Read |
|---|---|
| The program's exact numbers and copy | `ios/Morning/Program.swift` |
| The storage contract, field by field | `ios-port/06-data.md` |
| The reasoning behind each rule | `ios-port/04-rules.md` |
| The assertions that check all of it | `ios/MorningTests/Acceptance/` (68) |
| Checks that need a real phone | `ios/Docs/device-checklist.md` |
| Why the **current** UI is the way it is | `ios-port/02-design-brief.md` — and this is the document a UI rebuild is free to disregard |
