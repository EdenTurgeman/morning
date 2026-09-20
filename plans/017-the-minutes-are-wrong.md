# 017 — The recorded minutes are wrong, and the Ledger's hours are mostly fiction

Opened 2026-09-20, from a routine backup taken before an overnight install.
**Not fixed. It needs a decision that is Eden's, and §4 is that decision.**

---

## 1. The measurement

His 22 logged sessions, against a programme that says A is ~16 minutes and B ~17:

```
2026-09-05  A     52 min   (0.9 h)
2026-09-14  A     53 min   (0.9 h)
2026-09-16  A   1240 min  (20.7 h)
2026-09-19  A   2869 min  (47.8 h)
2026-09-19  B    337 min   (5.6 h)

the other 17 sessions: min 4, median 23, max 27
```

The Ledger's lifetime **hours** is a sum of this column.

```
as recorded:                        81.9 h
excluding the five implausible:      6.0 h
```

**Roughly 92% of his recorded training time never happened.** The number on the
all-time screen is not a measurement of anything.

---

## 2. The cause

`WorkoutSession.swift`:

```swift
let elapsed = Double(Int(now.timeIntervalSince1970 * 1000) - startedAt) / 60000
let minutes = max(1, Int(elapsed.rounded()))
```

Wall-clock from `startedAt` to the moment Done is pressed on the last set, with a
floor of one minute and **no ceiling**.

And `startedAt` deliberately survives a resume:

```swift
startedAt = saved.startedAt   // restoring an in-progress session
```

That line is correct and should stay — durability is a stated requirement, and a
session in progress has to survive a force-quit with its rest deadline intact.
The defect is that **the same field is doing two jobs**: identifying when the
session began, and measuring how long it took. Those stop being the same number
the moment a session is left and come back to.

The evidence fits exactly. An in-progress session was observed on the phone on
18 September, started 17 September at 18:28 and never finished. The record
logged on 19 September reads 2869 minutes — 47.8 hours — which is the wall-clock
gap, not a workout.

---

## 3. What is and is not wrong

- **The rep log is fine.** Every slot, every rep, every weight is true. This
  touches one field.
- **`min` is wrong on 5 of 22 records**, and wrong by three orders of magnitude
  on two of them.
- **The Ledger's hours is wrong** and is the only surface that reads this field
  in aggregate. The Summary's "Minutes" is wrong on those sessions too.
- **Nothing else keys off it.** Not the streak, not tonnage, not the deck.

---

## 4. The decision, which is Eden's

Two questions, and the fix follows from the answers.

**Q1. Should a session paused with the app CLOSED count the gap?**
Obviously not. This is the whole bug.

**Q2. Should a session paused with the app OPEN count the gap?** Less obvious.
Sitting on the Rest screen for ten minutes talking to someone is time the workout
took. Sitting there for six hours is not. There is no principled line, which is
why this is a decision rather than a fix.

### The minimal fix, if Q1 alone is answered

Persist a `lastActiveAt` alongside `startedAt` in the in-progress file, written
on every step move (`persist()` already runs there). On restore, shift the start
forward by the gap:

```swift
startedAt = saved.startedAt + (now - saved.lastActiveAt)
```

Time while the app was closed stops counting, `startedAt` keeps its meaning for
everything else, and a file written before the change has no `lastActiveAt` and
simply behaves as it does today. One optional field, backward compatible.

It does **not** fix Q2. If the phone sits with the app foregrounded all night,
the number is still wrong.

### The existing records

**Do not rewrite them.** `06-data.md` and `CLAUDE.md` are unambiguous that a
logged session records what actually happened and is not edited to suit a later
build — it is the same rule that forbids backfilling `kg`. Two options that do
not involve editing history:

- **Leave them.** The Ledger's hours stays wrong for five sessions forever.
- **Have the Ledger ignore implausible durations** and say so — *"hours exclude
  5 sessions with no usable duration"*. True, specific, and consistent with how
  this app already talks about a missing `kg`.

The second is better and is what I would build, but it is a product decision
about a surface Eden reads, so it waits for him.

---

## 5. Why this was not fixed overnight

Eden was asleep and asked for work to continue without approval. This was left
because **every available fix changes what gets written into his training
record**, and Q2 has no right answer that can be derived from the code. The
measurement is the part he needs to decide; the patch is twenty minutes once he
has.
