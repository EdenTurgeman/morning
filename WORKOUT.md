# The workout

Everything about the training itself: what the two sessions are, the rules they
run on, and how to change them without breaking the app.

**`ios/Morning/Program.swift` is the source of truth.** This file explains it;
that file *is* it. If they disagree, the Swift is right and this is stale —
move them in the same commit.

---

## The equipment

| Item | Detail |
|---|---|
| Dumbbell handles | Two, **1.25 kg each empty** |
| Plates, per handle | 2 × 2.5 kg and 4 × 1.25 kg = **10 kg** |
| **Maximum per hand** | **11.25 kg** |
| Smallest step | 1.25 kg per hand |
| Also | A pull-up bar, books used as push-up blocks, a towel, the floor |
| Not owned | No bench, no bands, no cables, no rack |

**The app records PLATES, not the load.** `Program.swift` says `load: 5`; the
weight in your hand is 6.25 kg. Add the handle. Every number below gives both.

Session A runs at **7.5 plates = 8.75 kg per hand**.
Session B runs at **5 plates = 6.25 kg per hand**.

---

## The four rules

**1. One weight for a whole session.** Every loaded movement in a session uses
the same dumbbells. You do not change plates at 6:10am, and the acceptance tests
enforce it.

**2. The load is fixed for weeks. Reps are the only progress signal.** This is
the premise the entire app is built on — the number under each set is what you
did last time, and beating it is the point.

**3. Every working set goes to failure, or one rep short.** Light loads taken to
failure grow muscle as well as heavy ones. Light loads stopped short grow almost
nothing. Effort is the variable, because load isn't.

**4. Reps are only comparable at the same weight.** Change the load and every
delta before it is meaningless. The app says so rather than pretending.

---

## Session A — "Heavy", ~16 min, 13 sets

**7.5 plates = 8.75 kg per hand.**

### Warm-up — 90 s
- 20 arm circles forward, 20 back
- 10 half-effort push-ups
- 10 towel dislocates: grip a towel wide, sweep it overhead and behind you

### Push-up, feet elevated — 3 sets · bodyweight · 8–15 reps · 60 s rest
- 3s down · 1s PAUSE at the bottom · fast up
- Elbows 45° from your torso, glutes squeezed
- Go to failure, or one rep short

### Superset ×3 · 45 s rest after each round
No rest between the two. Rest only after the pair.

**Overhead press, standing strict — 8–15 reps**
- Ribs down. No leg drive, no leaning back
- Start at ear height, finish biceps by your ears

**Curl — 10–18 reps**
- 3 seconds lowering
- FULL arm extension at the bottom of every rep
- That bottom inch is the whole exercise

### Superset ×2 · 45 s rest after each round

**Bent-over row — 15–20 reps**
- Hinge to 45°, flat back
- Pull to your hips and squeeze
- Shoulder insurance. Don't skip it

**Hammer curl — 12–20 reps**
- Palms facing each other
- Full stretch at the bottom

---

## Session B — "Width", ~17 min, 13 sets

**5 plates = 6.25 kg per hand.** The side delt and chest day; A carries the
compounds. Every set is paired with something that does not compete with it, so
the lateral raise gets ~115 s between rounds instead of ~65.

### Warm-up — 90 s
- 20 arm circles forward, 20 back
- 10 half-effort push-ups
- 10 towel dislocates
- Set the dumbbells while you do this

### Superset ×3 · 60 s rest after each round

**Push-up, deficit, hands on books — bodyweight · 8–15 reps**
- Hands on books, chest sinking below them
- 3s down · 1s PAUSE at the bottom · fast up
- Hit 15 and your feet go up next time. Go to failure

**Lateral raise — 6–12 reps**
- Lead with your elbows, stop at shoulder height. No swinging
- Round 1 is the number that counts. Beat it or match it
- At failure → 5–8 partial reps in the bottom third
- Reach 15 here and put another 1.25 kg on each handle

### Lateral raise, myo-reps — 3 sets · 20 s rest
Targets run per set: **all-out to failure**, then **4–6 reps**, then **4–6 reps**.
- Set 1 is all-out. Then 20s rest, 4–6 reps, repeat
- Stop when you can't get 4 clean reps
- The 20-second rest IS the mechanism. Don't stretch it

### Superset ×2 · 60 s rest after each round

**Floor fly, lying on your back — 10–20 reps**
- Elbows slightly bent and locked there: a fly, not a press
- Lower until your triceps touch the floor · 1s PAUSE in the stretch
- Past 20 clean reps? Slow the lowering to 4s. Go to failure

**Rear-delt fly — 8–15 reps**
- Hinge until almost parallel to the floor
- Open your arms wide like a curtain, squeeze the blades

---

## The progression ladder

In order. Exhaust each rung before the next.

1. **Add reps.**
2. **Slow the eccentric** to 4–5s and add a 2s pause in the stretch.
3. **Add post-failure partials** in the bottom third.
4. **Add weight.** The smallest step is 1.25 kg a side and reps restart from a
   fresh baseline. **The trigger is written into the set itself:** 15 reps on
   B's first lateral raise and another 1.25 kg goes on each handle. Put every
   future trigger where the set is, not in a document — this one sat in the
   Guide unread for a month while the condition to fire it was met repeatedly.
5. **Switch to a variant with no ceiling** — pike push-ups, Z-press, archer
   push-ups, chin-ups.

**When the app says a movement has not moved for three sessions, that is the
ladder telling you to climb it.** The Summary names the movement.

---

## Volume, per week

At the weekly target of 5 sessions, strictly alternating, roughly 2.5 of each.

| Muscle | Weekly direct sets |
|---|---|
| Chest | ~20 |
| Side delts | ~15 |
| Biceps | ~12.5 |
| Rear delts | ~7.5 |
| Lats / mid-back | ~5 |
| Triceps | 0 direct, ~11 counted fractionally as a synergist |
| Legs | 0 — **deliberate.** Covered by cycling and yoga. Not an oversight. |

---

## Changing the workout

### Where

`ios/Morning/Program.swift`, and nowhere else. It is Swift literals rather than
a JSON resource on purpose: you edit it, rebuild, install. There is no builder
UI and no second file to keep in sync.

`ios-port/content/program.json` and `src/program.ts` are **frozen snapshots of
the retired web build.** They are not read at runtime. Do not sync them.

### The three block shapes

Anything you write has to be one of these.

- **`.warmup`** — a countdown with cues. Auto-advances at zero.
- **`.straight`** — N sets of one exercise, one rest value between them. Pass
  `targets` (one string per set) instead of `target` when the sets differ; that
  is how the myo block says "all-out to failure" and then "4–6 reps" twice.
- **`.superset`** — N rounds of 2+ exercises back to back, **no rest between
  partners**, one rest after each round.

No circuits, no timed sets, no EMOM, no drop sets as a first-class shape.

### The one thing that will bite you

**"What did I do last time on this exact set" resolves against a slot id of the
form `blockIndex.itemIndex.setIndex` — a string match, with no idea which
exercise it belonged to.**

Reorder a block and every slot in it silently changes meaning. B was
restructured on 2026-09-19 and the floor fly would have inherited the myo
block's numbers, announcing a set that was never done.

Adding or editing **cues, names, loads, targets and rest seconds is always
safe.** Moving blocks is not.

If you move something anyway, extend `History.bSlotMoves` — it maps old slots to
new at read time, and stored records are never rewritten, because a logged
session is a record of what was actually lifted. That only works while the
movements survive the edit. **Delete one and its history has nowhere to go:**
append instead, or accept the loss knowingly and say so.

### After any change

```bash
./scripts/verify-ios.sh
```

Seven phases, every error in one report. The golden fixture in
`ios/MorningTests/Fixtures/compiled-steps.json` pins what each session compiles
to, step by step — **regenerate it deliberately when the program changes**, and
check the diff says what you meant.

Then put it on the phone:

```bash
./scripts/refresh-device.sh
```

---

## Where the programming came from

Session B was reviewed against the hypertrophy literature in September 2026 —
22 sources, meta-analyses and RCTs, with EMG studies and acute-response studies
explicitly excluded as evidence of growth.

**The brief and the review live outside this repository**, at
`~/Dev/morning-workout-review/`, because they contain training history and this
repo is public.

Three findings worth not re-deriving:

- **The dumbbell lateral raise does not need replacing.** Larsen 2025 ran it
  against cable raises within-participant for 8 weeks, matched for range of
  motion, and found Bayesian support for *no* difference — the cable being
  exactly the "fix the resistance profile" change anyone would propose. The
  authors had predicted the opposite.
- **Myo-reps are equal, not better** — and equal-but-faster is a win under a
  20-minute cap, so the block stays.
- **Volume's returns flatten; they do not stop.** The claim that ~20 sets a week
  is where extra volume stops paying is not what the literature says.
