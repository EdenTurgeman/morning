# Morning — functional specification

**What this document is.** Everything the app must *do*, with no statement about
how it should look. It exists so the interface can be thrown away and rebuilt
from scratch without anyone having to reverse-engineer the behaviour out of the
old screens.

**What it deliberately does not contain.** Screens, layout, hierarchy, colour,
type, spacing, motion, materials, which control goes where, or how many views
there are. Those are all replaceable. Where a rule constrains the interface it
is stated as a *requirement on behaviour*, not as a design — "the countdown must
be readable from 1.5 metres" is here; "the countdown is a 232pt ring" is not.

**How to read it if you are rebuilding the UI.** §1 is the constraint envelope —
read it first, it explains why several rules that look arbitrary are not. §2–§12
are the capabilities. §13 is what must never regress. Anything not written here
is yours to decide.

**Status:** current as of 2026-08-23. Maintained alongside the code — a change
in behaviour is a change to this file in the same commit.

---

## 1. The envelope

One user, one iPhone, one workout a day at around 6:10am, six mornings a week.
He is half awake, his hands are sweaty, and the phone is on the floor roughly
1.5 metres away for most of the session. He is not looking at it while lifting;
he glances at it between efforts.

Five consequences that constrain behaviour, not just appearance:

1. **Nothing inside a workout may require scrolling or precise aim.** Any state
   reachable during a session must be complete on one screen and operable with a
   knuckle.
2. **Anything critical must be legible from 1.5 metres** — the rep count, the
   rest countdown, and what is coming next.
3. **Every action must acknowledge itself without being looked at.** The app has
   a haptic and audio vocabulary (§11) because the phone is frequently face down
   or out of focus.
4. **A session must never be lost.** Crash, phone call, force-quit, reboot: the
   workout in progress survives all of them. This is the one unacceptable
   failure mode.
5. **Empty is the normal case on day one**, not an edge case. Every capability
   must have a defined behaviour with no history at all, and with one week of it.

**The app is not gamified and must never become gamified.** No points, no
badges, no levels, no streak economy, no "Great job!". Every statement the app
makes must be true and specific. This is a behavioural rule, not a tone
preference: a headline that congratulates without saying something the user did
not already know is a defect.

---

## 2. The program

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
| `superset` | sets, rest, items[] — each item: exercise, sub?, load \| bodyweight, target, cues[] |

**Loads are plates per handle.** Not total, not including the handle. The user
adds the handle weight mentally. Nothing in the app may try to be clever about
this.

**Slot identity is `block.item.set` and is load-bearing.** Rep history, the
"last time" lookup and the tonnage table all key off it. Reordering blocks or
changing set counts breaks the match and silently re-attributes history. This is
why a new movement is *appended* to a session rather than inserted.

Session A compiles to **21 steps**, B to **25**. These counts are a fixture, not
a coincidence — assert against the whole compiled list.

### Content is fixed

Exercise names, sub-labels, cues, target ranges, rest seconds, study-card text,
Guide text and celebration copy are the product. They are not to be improved,
paraphrased or generated. They change only when the user changes them.

---

## 3. The step machine

A session compiles to a **flat, linear list of steps**, traversed one at a time.
Three kinds: `timer` (the warm-up), `set`, `rest`.

- A rest is emitted after every set **except** between superset partners.
- Trailing rests at the end of a session are dropped.
- **Back** returns to the previous step without losing anything already logged.
- **End** abandons the session: it must confirm first, and then save nothing at
  all — not even sets already logged. Both halves are deliberate.
- The step in progress, the log so far, the session key and the rest deadline
  persist independently of the history and restore on launch.

### Rep prefill, in this priority order

1. What was already logged for this slot **in this session** — so going Back to
   fix a mistap shows the number actually entered.
2. What was done on this exact slot **in the last session of the same letter**.
   This is the point of the app.
3. A plausible default (12 loaded, 10 bodyweight), so a first run is still one
   tap.

Getting this order wrong silently eats corrections.

### The rep control

- Reports a **delta**, never an absolute. Two adjustments landing in one update
  cycle, both computed from the same stale value, collapse into one increment.
  Hold-to-repeat accelerates, so this is reachable in ordinary use.
- Hold-to-repeat: first repeat after a delay, then accelerating to a floor.
- Value is clamped at zero and has no upper bound.
- **Crossing last time's number must change state**, once, on the crossing
  adjustment only — not continuously while above it. This is the emotional
  centre of the app and it gets colour, motion, a distinct haptic and a distinct
  sound.
- **If last time's reps were done at a different working weight, they are not a
  target and the app must say so** rather than implying a comparison that does
  not hold.

---

## 4. Session alternation and the working weight

The app proposes the **opposite** of whatever was logged last; a fresh install
proposes A. Starting the other session instead must always be possible, for a
skipped day or a repeat.

Each session letter has its own **working weight**, adjustable by the user, in
plate steps, bounded by the plates actually owned (2 × 2.5 kg and 4 × 1.25 kg,
so 1.25 kg per handle is the step and there is a maximum). The app must show the
**plate breakdown** for the chosen weight — the answer to "what do I set up" is a
number of plates, not a weight to do arithmetic on at 6am.

A weight the plates cannot make must be reported as such rather than rounded
silently.

Changing the working weight is expected and correct: the program's numbers are a
starting guess, and reps only measure effort if the weight is one you can
genuinely take to failure.

---

## 5. Logging a session

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

- `ts` is identity. Deletion, "previous same session" lookups and milestone
  diffing all key off it. It is never regenerated.
- **A missing `kg` is meaningful** — it means "logged before the weight was
  adjustable". Fall back to the program default when reading; **never backfill
  it**, because that retroactively rewrites tonnage.
- A failed write must surface, never silently drop a session.

---

## 6. The weekly streak

**Measured in weeks, not consecutive days.** The program is six mornings with a
rest day; a consecutive-day streak would punish following it correctly.

- A week counts if it contains **5 sessions**, on whatever days.
- **The week starts on Sunday.**
- **The week in progress can never break a streak.** It has not finished. It
  only ever adds: if already complete it extends the count, otherwise the streak
  reads from last week backwards.
- **Longest run is remembered separately** and stays visible after the current
  streak drops to zero. That is precisely the moment people stop.

Derived state the app must be able to answer: sessions done, remaining, days
left, at-risk, missed, whether today can be a rest day, and which weekdays a
rest day would cost. The week's guidance copy is generated from these and must
stay silent when there is nothing true and useful to say — including on a fresh
install, where the arithmetic is correct but the message is wrong.

---

## 7. Lifetime totals

Headline is **tonnage: reps × load**, with three honesty constraints:

- Every loaded movement is **two dumbbells**, and the load is per handle, so one
  rep moves 2 × load.
- **Bodyweight work contributes 0 kg** but still counts toward total reps.
  Counting push-ups would need a bodyweight and a guessed multiplier, which
  would make the headline fiction.
- Sessions are valued at **the weight they were actually done at**, from their
  own record, so changing the working weight never rewrites the past.

Also tracked: total reps, total sessions, per-letter session counts, total time,
and the date of the first session.

### Milestones

Deliberately sparse — one you hit every fortnight is a chore.

- **Tonnes:** 1, 5, 10, 25, 50, 100, 250, 500, 1000
- **Reps:** 1k, 5k, 10k, 25k, 50k, 100k
- **Sessions:** 10, 25, 50, 100, 200, 365, 500, 1000

A milestone fires **exactly once**, on the session that crossed it, computed by
diffing the ledger with and without that session. The app must also be able to
name the next threshold and the distance to it.

---

## 8. The end-of-session summary

Exactly **one** headline fires — the highest thing actually earned, in this
priority order:

| # | Tier | Fires when |
|---|---|---|
| 1 | lifetime milestone | A ledger threshold was crossed |
| 2 | clean sweep | Every comparable set beat last time (≥3 sets, same weight) |
| 3 | weight changed | Working weight differs from the last same-letter session |
| 4 | streak milestone | Week completed *and* streak hits 2/4/8/12/26/52 |
| 5 | week complete | The week just reached 5 |
| 6 | record | Beat the best ever on this letter |
| 7 | first | First session ever logged |
| 8 | plateau | Third same-letter session on an identical total |
| 9 | improved | More reps than last time |
| 10 | matched | Exactly equal |
| 11 | done | Anything else, including down on last time |

Rules the tiers encode:

- **Reps are comparable only at the same weight.** "+18 reps" for dropping
  2.5 kg a side is not progress and "dead level" at a heavier weight is not a
  plateau. When the weight moves, say so and start a fresh baseline.
- **Every headline must add something the rep total does not already say.** The
  summary states the total; a headline repeating it is a defect.
- **Plateau is the app's most valuable output.** It is an instruction to change
  the program, and the copy names which rung to move to. It must not read as a
  failure state.
- The summary also reports: session letter, elapsed minutes, the delta against
  last time (absent entirely when the weight changed), and where the week stands.

---

## 9. The study deck

26 cards on wine and tea. Every card teaches a **mechanism**, not a fact.
Adding a card must be a one-line append with no other edit.

### Dosing — these numbers are deliberate

- **Two cards per session, on rests, plus one on the summary.** Not one per long
  rest: eight cards in twenty minutes turns a workout into homework.
- Only on rests of **45 seconds or more**.
- **Never on the 20-second myo rest.** That rest *is* the training stimulus and
  anything inviting the user to linger there breaks the exercise.
- **Not on the first long rest** — that one is for getting your breath back.
  Taken from roughly the first and third quarter of the long rests, so they land
  spread out.
- Drawn **without replacement**: nothing repeats until the deck has been
  through, with an additional short-term buffer against a repeat in one sitting.

### The reveal

> The user must never miss the timer because he was thinking.

So the answer **auto-reveals**. Interaction only brings it forward for someone
who already has it; nothing is gated behind an action, because at 6am mid-rest
he will not reliably perform one, and a card he never got the answer to is worse
than no card.

Reveal delay scales with the rest length, clamped to **6.5–11 seconds**. The
summary card gets **14 seconds**, because there is no timer to beat.

The remaining thinking time must be **visible and continuous** — the user has to
be able to see how long is left without reading anything.

**The card is silent.** The audio vocabulary is entirely about time; a card
making a noise during the last five seconds of a countdown would be actively
misleading. Haptic acknowledgement on reveal is fine.

---

## 10. Timers

Every countdown derives from an **absolute deadline**, never a tick count. This
is what makes a timer survive backgrounding, and it is what lets the system draw
a live countdown with no updates from the app.

- The warm-up counts down its programmed seconds and advances on its own.
- A rest counts down and advances on its own; **+15 s** extends it and **skip**
  ends it early.
- A rest must complete even if the app is not drawing — a redraw-driven timer
  alone can hang forever on a phone that decided not to paint.
- The screen must not sleep during a session, and the lock must be released when
  the session ends or is abandoned.
- The last five seconds are signalled by escalating audio and haptics, and by a
  visual change perceptible in peripheral vision.

### Live Activity

While a rest is running, the countdown appears on the Lock Screen and in the
Dynamic Island, showing the time remaining and what is coming next. Tapping it
returns to the app at the step the countdown was counting.

Exactly **one** activity may exist at a time. It ends when the rest ends, when
the session ends, and when the session is abandoned.

Approved integrations are this and nothing else. **Explicitly declined:**
home-screen widget, HealthKit, Control Center control, app-icon badge,
notifications.

---

## 11. Sound and haptics

Both vocabularies are **about time and about crossing a threshold**, and nothing
else. They exist because the phone is on the floor and face down.

| Event | Signal |
|---|---|
| Rep adjusted | Light haptic |
| Crossing last time's number | Distinct haptic detent **and** a distinct tone |
| Set logged | Confirmation haptic and tone |
| Countdown, last 5 seconds | Escalating per-second tone and haptic |
| Countdown reaching zero | "Go" tone and a stronger haptic |
| Card answer revealed | Haptic only — never a sound |
| Session complete | Completion haptic and chime |

Audio must duck other audio rather than stopping it, and the audio session must
be brought up before a countdown rather than during one.

---

## 12. History, backup and the record

**History** lists finished sessions in reverse-chronological order with date,
session letter, total reps and duration. It also shows recent weeks and a full
year at once — a year view that does not fit on the screen has failed at its one
job.

Intensity in the year view is scaled to the user's own range: his quietest
session is the coldest and his best is the warmest, so a good month is visibly
different from a bad one.

**Deleting a session sits behind an explicit edit mode.** Never a swipe: sweaty
hands, and an accidental delete is unrecoverable. The confirmation names what is
about to be lost.

**Backup** exports JSON that reproduces the history exactly when restored.
Restore validates the file, states the session-count swap, and confirms before
replacing. Erase-everything is destructive and confirmed. The export path must
exist regardless of any sync, because it is the only copy that survives losing
the phone *and* the account.

The app must also state when the last backup happened, and say plainly when
there has never been one.

**A Guide** holds nine short reference entries — the training rationale, the
progression ladder, and the nutrition targets. Read maybe monthly.

---

## 13. What must never regress

The list a rebuild is most likely to break, in the order it is most likely to
break it:

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
12. No card on the 20-second rest; the card is silent.
13. Nothing inside a workout scrolls.
14. Every screen behaves correctly at empty, at one week, and at six months.

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
| Why the current UI is the way it is | `ios-port/02-design-brief.md` — **and this is the document a UI rebuild is free to disregard** |
