# Animation plans

Written by `improve-animations` against `ios/Docs/redesign/01-motion-doctrine.md`,
which is the standing answer to *"should this animate at all"* and is **not to be
re-argued** by any plan here.

| # | Plan | Scope | Status |
|---|---|---|---|
| 001 | [Duplicator: paper ply, contrast, and the crossing](001-duplicator-paper-and-crossing.md) | `DuplicatorVariant` prototype | **DONE** — 2026-08-27 |
| 002 | [Blades that move like paper](002-blades-that-move-like-paper.md) | `PaperSunrise` fan | **DONE** — 2026-08-30 |
| 003 | Full-app audit — five findings, all applied inline | whole app | **DONE** — 2026-08-30, see handoff R12 |
| 004 | [Study questions](004-study-questions.md) | deck, Rest card, Summary | **1-4 DONE** — 2026-09-03; the Summary line is open |
| 005 | [Give every tappable control a press state](005-press-state-on-every-control.md) | `PaperTokens` + 5 screens | **DONE** — 2026-09-03; one human press still owed |
| 006 | [Make the step transition run the way it is written](006-the-step-transition-that-is-declared.md) | `WorkoutHost` | **DONE** — 2026-09-03; found a whiteout, not the predicted fault |
| 007 | [Research and enrich the study deck](007-enrich-the-study-deck.md) | `cards.json` only | **ONGOING** — past 200 and still growing; groups of 20 |
| 008 | [Review the deck as a curriculum](008-curriculum-review.md) | `cards.json` only | TODO — an editorial pass that may rephrase, delete and replace |
| 009 | [Remembering the deck](009-remembering-the-deck.md) | `Deck`, new `StudyPlan`, Rest card, Summary line | **DONE** — 2026-09-09; the scheduler, the two logs, and the mark |
| 010 | [A surface for the deck](010-a-surface-for-the-deck.md) | `StudyReport`, `StudyScreen`, a fifth Home entry | **DONE** — 2026-09-09; the reading, plus an index |
| 011 | [Hoist the workout chrome](011-hoist-the-workout-chrome.md) | `WorkoutHost` + the 3 workout screens | **DONE** — 2026-09-11; floor 0.00% → 0.17%, the blank is gone |
| 012 | [Superset partners get no transition](012-superset-partners-get-no-transition.md) | `WorkoutHost`, one `.id` | **DONE** — 2026-09-11; a transition where there was none |
| 013 | [Close the gap in the swap](013-close-the-gap-in-the-swap.md) | `DesignMotion`, one delay | **DONE** — 2026-09-11; 170ms → 140ms, the smallest of the three |
| 014 | [The iOS app takes the repo](014-the-ios-app-takes-the-repo.md) | whole repo | **BLOCKED** — on the app running on Eden's phone with his history in it |

## Order, and why

**006 before 005.** 006 opens with a measurement that may end in no code change
at all, and it touches the one transition that fires ~28 times a session; 005
touches five screens and will churn the diff underneath it. They are otherwise
independent — no shared files.

Both came out of the 2026-09-03 audit. That audit's third finding — the
completion moment being a still image under Reduce Motion — was **dropped at
Eden's direction**: *"i don't care about accessibiliy, just ui/ux."* It is
recorded here rather than planned so nobody rediscovers it and assumes it was
missed. `PaperSunrise`'s four Reduce Motion guards (`motion(for:)`, `rise`,
`boilSeed`, `sway`) return constants, and `01-motion-doctrine.md` §5 asks for
"a calmer sunrise, not a skipped one, and not a still image".

## Three things the audit found that are NOT defects

Recorded so the next audit does not re-raise them:

- **`PressBlockStyle` presses at 0.985, not the house 0.97.** Documented at
  `PaperTokens.swift:336` — a full-width bar scaled 0.97 reads as the whole
  screen flinching.
- **`Motion.press` is `easeOut(0.10)`, not the doctrine's `.snappy(0.16)`.**
  Documented at `DesignMotion.swift:85` and well inside the §1.2 ceiling.
- **Set, Warm-up, Guide, Ledger and Backup have no motion of their own.** That
  is §3.2's ruling for each of them, not an omission.

## 011 → 012 → 013, in that order

From the 2026-09-11 audit of the workout loop's transitions, run at Eden's
report: *"some screens just repaint the whole screen… when i click done it
might repaint the whole screen and show the timer."*

**The measurement that found it.** A Set → Rest filmed at 60fps, scored by **ink
coverage** — the share of pixels darker than luma 120 — rather than mean luma:
13.65% → **0.00% for 220ms** → 3.55%. Not a dip: no chrome, no ring, no text,
bare stock. `plans/006` measured the same swap as mean luma 185 → 188 → 185 and
passed it, because on a light ground the entire content vanishing moves the mean
by three points. **Mean luma cannot see a blank screen here. Use ink coverage.**

- **011 first, and it is the one that actually fixes it.** The chrome lives
  inside each screen, so it is destroyed and rebuilt 28 times a session. Hoisted
  — the ground's own precedent from 006 — the screen can never be blank.
- **012 is independent and arguably worse**, since there the transition is
  absent rather than badly timed: superset partners are adjacent `.set` steps
  sharing one branch, so `Done` inside a superset animates nothing. That is
  §3.1's named failure mode going unserved exactly where two near-identical set
  screens follow each other.
- **013 last, and it may close with no code change.** It tunes the 0.08s
  insertion delay, which was sized to protect a morph that has since been
  deleted. Tuning it before 011 would be measuring the wrong screen.

## The three doctrine-sanctioned gaps — all closed 2026-09-09

Three places §3.2 permitted motion and the app had none. All three are built,
and all three were verified on film rather than by looking at them:

- **The end-session confirmation** was a system `.alert` with "End and discard"
  at equal weight beside "Keep going", for the one action that throws away every
  set already logged. Now `EndSessionConfirm`: keeping is a tap and answers
  instantly, ending is a **1.4s hold** whose fill is linear and **snaps rather
  than drains** on release. `-hold-end` drives it, because no synthesised long
  press reaches this simulator.
- **Empty → first data.** The Ledger's first number now arrives with a rule
  drawing itself left to right beneath it — a ledger page being ruled, which is
  the object the screen is named after. Claimed once ever through
  `FirstRecord`; `-first-record` forgets the claim so it can be filmed.
  Measured: 0 → 25 → 60 → 86 → 100% over 0.75s.
- **Home arrival.** Five elements, 18ms apart, 0.33s end to end — inside §3.2's
  80ms total stagger budget.

**The Home arrival is the entry worth reading twice.** The first version
compiled, looked right, and did nothing: `withAnimation` overrode every per-rank
delay, and at 60fps all four bands rose in exact lockstep — 24/24/24/23%, then
41/39/41/41, then 60/60/60/60. Removing it gave 6/11/12/18% → 16/29/30/42%.
That is the third animation on this project inspection passed and frame capture
caught. `ios/Tools/frames.swift`; use it.

## What 001 settled, for anyone writing 002

The audit found only **two** events in the Duplicator Set screen that may
animate, and the boundary matters more than the animations do:

- **The crossing** — doctrine §1.1 tiers it Rare on a Tens/day surface and gives
  it the best motion in the workout loop. Built as an ink wipe.
- **The rep digit** — via the existing `Motion.rep` / `Motion.numeric` tokens.

**Everything else on that screen is deliberately static**, including the step
block inking as sets complete. It fires ~28×/session, which the frequency gate
puts in the tier where motion is removed. That temptation is the finding the
boundary exists to reject — do not "improve" it in a later plan.

**Press feedback stays instant.** §1.2 requires ≤160ms and an instant ink flip
is what a stamp does.

## How motion gets verified here

No agent tap reaches the simulator, so a state change cannot be triggered
interactively. 001 added a debug-only `-demo-crossing` launch flag that drives
the app's real `adjustReps` a beat after launch, so the event can be recorded:

```bash
xcrun simctl io booted recordVideo --codec h264 out.mp4 &
xcrun simctl launch booted com.edenturgeman.morning -screen set -variant duplicator -demo-crossing -seed six-months
swift ios/Tools/frames.swift out.mp4 frames/ 4.90 4.96 5.05
```

The wipe was confirmed mid-flight at ~55% and ~88% coverage. **Inspection has
twice passed an animation on this project that did nothing on screen; frame
capture is the only check that has ever caught it.**


## 002's one reusable idea

**Drive the deformation from the animation's own velocity, not from a keyframe.**
`Spring` can be sampled for both position and velocity, so a blade's flex is the
spring's speed rather than a second curve someone has to keep in sync. It bends
while it moves and straightens when it settles, for free, and there is no way
for the two to drift apart.

The check that proves it: a frame mid-swing shows curved blades, the settled
frame shows straight ones. **Curved at rest means the coupling is inverted** —
that is the single failure mode and it is visible in one screenshot.
