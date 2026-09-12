# R0 · Ground

The output of phase R0 of `ios/Docs/redesign-plan.md`. Written after reading
`spec.md` end to end, `ios-port/01-product.md`, `ios-port/02-design-brief.md`
and the handoff log, and after rendering and looking at every surface.

**No skill runs in R0.** R1 is the first one (`emil-design-eng`).

**Eden's steer, given during this phase and binding on R3:** the redesign is a
reinvention, not a refinement. One of the three R3 directions may be the current
idea done properly; the other two must be fresh. The current app is the
*behaviour* reference and the thing to beat — not the visual starting point.

---

## 1. The harness — what closed, and what is still open

`scripts/shoot.sh` is committed. It builds, boots, installs, launches with
arguments and screenshots, and it takes a target name plus pass-through
arguments as real argv:

```bash
./scripts/shoot.sh set                        # one surface
./scripts/shoot.sh set -slot 4.0.0 --out worst-case
./scripts/shoot.sh all --no-build             # thirteen PNGs in ~65s
```

Three decisions in it are worth knowing before you use it:

- **Script flags are `--long`, the app's are `-short`.** They can never collide,
  so everything after the target is forwarded without a parser that has to know
  the app's flag list.
- **Every launch names a seed.** `-seed` *writes* to the store, so a shot taken
  without one is a shot of whatever the previous launch left behind. Default is
  `six-months`.
- **The 4s delay is not padding.** `simctl launch` returns when the process
  starts, not when a frame exists. Capture early and you photograph a launch
  screen, which looks exactly like a broken surface.

**Still open, and it shapes every phase after this one:** no tap reaches this
app. Verified again by the previous agent through both `simctl` and the iOS
Simulator MCP — `control{action:"tap"}` returns `Tapped at (x, y)` and nothing
happens. The tool reports success for input it never delivers. Every interactive
state is therefore reached by launch flag, and **every motion claim has to come
off a video, not off reasoning.** Two motion bugs in this project compiled, read
correctly, and did nothing; neither was caught by inspection.

---

## 2. Screen inventory — all thirteen, rendered and looked at

Eleven surfaces from `spec.md` §3. Rest is shot three times because it is three
different screens and shooting only the first shows the one with the least on it.

| Target | Surface | Reached by | Looked at |
|---|---|---|:--:|
| `home` | 3.1 Home | no `-screen`; the real `AppRoot` | ● |
| `warmup` | 3.2 Warm-up | `-screen set -step 0` | ● |
| `set` | 3.3 Set | `-screen set` | ● |
| `rest` | 3.4 Rest, 60s, no card | `-screen set -session A -step 2` | ● |
| `rest-card` | 3.4 Rest carrying a card | `-screen set -session A -step 6` | ● |
| `rest-myo` | 3.4 The 20s myo rest | `-screen set -session B -step 17` | ● |
| `daybreak` | 3.5 The completion moment | `-screen summary` | ● |
| `summary` | 3.6 Summary | `-screen summary -skip-daybreak` | ● |
| `history` | 3.7 History | `-screen history` | ● |
| `ledger` | 3.8 Lifetime totals | `-screen ledger` | ● |
| `guide` | 3.9 Guide | `-screen guide` | ● |
| `backup` | 3.10 Backup | `-screen backup` | ● |
| `live-activity` | 3.11 The Live Activity | `-screen live-activity` | ● |

There is deliberately **no `-screen rest`**. Rest is reached through the set host
at a step that is a rest, which is also how the app reaches it.

---

## 3. The frequency map, confirmed against what is on screen

`redesign-plan.md` §6 was written before this render pass. Confirmed as written,
with one correction and one addition.

| Surface | Times seen / session | Tier | Verdict |
|---|---:|---|---|
| Rep +/- adjust | dozens | Tens/day | Near-zero motion. Press feedback under 160ms. |
| Set arrival | ~14 | Tens/day | Reduce hard. |
| Step advance | ~28 | Tens/day | Reduce hard. |
| Rest arrival | ~13 | Tens/day | Reduce hard. |
| Ring completion | ~13 | Tens/day | Reduce. The ring is the information. |
| Study card reveal | 2 | Occasional | Standard. It is a *reveal*; it earns a beat. |
| Home arrival | 1–2 | Occasional | Standard. |
| End-session confirm | rare | Occasional | Slow the deliberate half. |
| The completion moment | 1 | Rare | **The delight budget. Spend it here.** |
| Celebration tiers | weekly / monthly | Rare | Delight. |
| First run, empty states | once | First-time | Delight. |
| The 13 → 14 crossing | rare by design | Rare | **The emotional centre.** |
| History, Ledger, Guide, Backup | rare | Occasional | Standard, restrained. |
| The dawn sky | continuous | not a tier | Ambient. §5.1 — out of the 300ms rule's reach. |

**Correction — the study card is seen twice per session, not "a few".** `Deck`
doses exactly two per session plus one on the summary, and the two are fixed at
the same rest indices every time (A: steps 6 and 15). It is a *known* beat, not
a surprise one, which lowers the motion budget it can justify.

**Addition — the myo rest is its own tier and the map had no row for it.** Three
times per B session, 20 seconds, and `spec.md` §10 forbids a card on it because
the rest *is* the stimulus. It is the one rest whose job is to be
uncomfortable and to end. It should not be the long rest with a smaller number.

---

## 4. What I found by looking that is not in any document

Six things. None are fixed here — R0 touches no production code — and each is a
decision for R3 or R4 rather than a defect to patch into views about to be
replaced.

### 4.1 The blank comparison line on arrival — RAISED AND SETTLED

`RepControl.comparison` renders three ways:

| Counter vs last time | On screen |
|---|---|
| below | "Last time: 14" |
| **equal — the prefilled arrival state** | **nothing** |
| above | "Beating last time's 14" |

The equal branch is two `Text`s in a `ZStack`, both at `opacity: 0`, and I
raised it as a possible violation of `spec.md` non-negotiable #3 — "last
session's number is on the set screen, beside the counter, always".

**Eden ruled on it during R0: "no need to show the last number twice."** The
current behaviour is correct and stays. When the counter is prefilled from
history the counter *is* last time's number; printing it again underneath is
one fact rendered twice, not two facts. **Do not "fix" this.**

One follow-up, wording only: `spec.md` §3.3 and non-negotiable #3 say *always*,
and read literally that contradicts the shipped, now-ratified behaviour — which
is exactly how a future rebuild talks itself into re-adding the line. The
precise statement is that last time's number is never ambiguous and never
absent, and that when the counter carries it, the counter is where it lives.
**Not edited here** — `spec.md` is the binding brief and this is Eden's call to
make, not a tidy-up to slip into a design phase.

### 4.2 `MorningApp.swift`'s header is now false

It opens *"Do NOT build screens from here yet"* and lists research as the first
deliverable. Eighteen workstreams later every screen exists. A file that lies
about the state of the project in its first ten lines is a trap for the next
agent, and this is the entry point — the first file anyone opens.

### 4.3 Summary states the delta twice

`-1 vs your last A` sits above the rep total, and `vs last · -1` sits in the stat
row below it. `spec.md` §3.6 asks for **exactly one** headline that *"adds
something the rep total does not already state"*. Two printings of the same
number is not two facts.

### 4.4 Summary holds a large void while the card thinks

The summary card's answer is on a 14-second delay, so for the first fourteen
seconds there is roughly a third of a screen of empty sky between the question
and the Done button. The previous agent measured this and recorded it as 179pt
once the answer lands, 307pt before. It is not a bug — it is the reveal working
— but it is a composition problem the redesign inherits, and the current answer
is to leave the space empty.

### 4.5 The two unrendered behaviours are both visible as absences now

Confirmed on screen, not just in the audit:

- `Celebration.rays` has no reader. The `daybreak` shot is tier 11 ("Down on last
  time") and it gets the same full radiance a personal best would. `spec.md` §9
  says the emphasis columns are load-bearing and that the bottom five tiers must
  be visibly quieter than the top four. Right now they are identical.
- `SetStep.intense` has no reader. Nothing on the Set screen distinguishes an
  all-out set before you start it.

### 4.6 The Live Activity's third sample is doing real work

`LiveActivityReviewHost` renders `nextExercise == nil`, which `04-rules.md` says
is unreachable because trailing rests are dropped. It degrades to a bare
countdown. Keep that sample — "unreachable" is a claim about today's step
compiler, not about the view.

---

## 4b. What the web app showed that the renders could not

`redesign-plan.md` R0 and `ios-port/README.md` both require running the web
build and doing a full session of A and of B before designing anything. Done:
A start to finish (21 steps), B start to finish (25 steps), then a second A to
reach the threshold crossing, which needs history to exist.

It is also the **only** place interaction can be observed at all — no tap
reaches the simulator, and in this environment browser clicks did not reach the
pane either. The sessions were driven by dispatching events in the page.

**Four things worth carrying into R1–R4:**

1. **The web build shows the last-time line in the arrival state; iOS blanks
   it.** Web reads `Last time: 10 — beat it` at the moment you land on the set.
   That makes §4.1 a *deliberate divergence*, not drift, and Eden ratified the
   iOS behaviour during this phase. Recorded so nobody "restores parity" later.

2. **The crossing works and it fires once.** 10 → 11 flips the line to
   `Beating last time's 10` and it stays there through 12 and 13 — it does not
   re-fire while above. This is `spec.md` §5's "once, on the crossing adjustment
   only", and it is the moment the whole product is built around.

3. **The rep control is driven by pointer events, not clicks.** A synthetic
   `.click()` on `+` does nothing; `pointerdown`/`pointerup` moves it. That is
   hold-to-repeat's doing, and it is the reason the first attempt to observe the
   crossing reported "nothing happens" three times in a row. A control whose
   press path is not its click path is worth knowing before R4 rebuilds it.

4. **The `MYO` badge exists in the web build**, on every myo set: `Lateral raise
   · MYO · myo-reps`. This is `SetStep.intense` rendered, and it is the concrete
   reference for the gap in §4.5 — the iOS port compiles the flag and draws
   nothing.

**One parity check that passed:** the card rests land on the same steps in both
builds — A steps 7 and 16 of 21, one-indexed, never the first long rest.
`Deck.cardRestIndices` and the web dosing agree exactly.

---

## 5. The regression list — what R3 and R4 may not break

`spec.md` §13 is binding in full. These are the ones a *design* phase breaks, as
opposed to a behaviour phase, and they are the ones to re-check on every variant.

1. **Nothing inside a workout scrolls. Ever.** Not at the largest Dynamic Type
   size the workout surfaces claim, not with the longest exercise name, not with
   four cues. If it does not fit, the design is wrong, not the screen.
2. **Rep controls ≥ 78pt, primary actions ≥ 64pt, and the main action is
   full-width.** Sweaty hands at 6:10am. Not a guideline.
3. **The rep controls do not move between exercises.** The control you reach for
   with a knuckle is in the same place every time.
4. **Nothing important in the top 15%** during a set. The phone is on the floor.
5. **Text holds ≥ 6.6:1** against whatever is behind it — measured on rendered
   frames with `ios/Tools/measure-contrast.py`, never calculated. Both
   calculation and eye have already lied on this project.
6. **Exercise name and rep count readable at ~1.5m.**
7. **No gamification.** No points, badges, levels, or "Great job!". Every
   headline states something true and specific.
8. **Exactly one celebration headline**, and it never restates the rep total.
9. **Reps are never compared across a weight change** — say so instead.
10. **Every surface holds at empty, at one week, and at six months.** Day one has
    no data and that is the normal case, not an edge case.
11. **Reduce Motion produces a calmer form, never a static or broken one.**

And the process rule: **`spec.md` moves in the same commit as any behaviour
change.** The redesign should not change behaviour at all — but 4.1 and 4.5 are
places where it might, and if it does, `spec.md` moves with it.

---

## 6. What R1 is handed

- Thirteen PNGs in `ios/build/shots/`, all looked at.
- The frequency map above, corrected in two places.
- The six findings in §4, of which 4.1 and 4.5 are behaviour-adjacent and the
  rest are composition.
- One standing constraint that outranks the skills: **the workout loop gets less
  motion, not more.** The twenty minutes the app is in use is the tier where the
  framework says to remove motion, and the four seconds at the end is where it
  says to spend everything.
