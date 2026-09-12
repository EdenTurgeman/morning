# R3 · Three directions for the Set screen

Phase R3 of `ios/Docs/redesign-plan.md`, run on the `prototype` skill.

> ## ✅ GATE PASSED — Eden chose **DAWN**, 2026-08-25
>
> Atmosphere carries orientation. The gate is closed and R4 may start.
>
> **What the choice commits to**, so R4 does not quietly re-open it:
>
> - The sky is the **layout**, not wallpaper. The empty region above the content
>   is deliberate and is not to be filled with a card, a figure bay, or a panel.
> - **The progress rail stays deleted.** This was the boldest move in the set and
>   it was chosen with it in. `spec.md` §3.3's "where the session is up to" is
>   still satisfied — by `Set 1 / 13` in the chrome and `12 SETS TO GO` under the
>   action — just not by a rail.
> - The content is a **cluster that belongs to the counter**, not a top-anchored
>   stack. Read and act sit together; the sky is above them.
> - `ALL OUT` renders inline in `Semantic.urgency`, off the dawn ramp so it can
>   never be mistaken for progress.
>
> **The one stated cost R4 owns, and must fix rather than inherit:** at low
> progress the upper screen reads as *emptiness* rather than as *sky*. It was
> named as this direction's weakness when it was offered and choosing the
> direction does not make it go away. The first thing R4 does on this screen is
> make the void legible as atmosphere at progress 0.00 — that is what "the sky
> is the layout" has to earn.
>
> Far Field and Track stay in the lab, runnable, as the record of what was
> considered. `Hard Rule 5` says delete the prototype surface on promotion; they
> are kept deliberately, because this repo's convention is that review hosts
> ship and the W1 lab is still runnable eighteen workstreams later.

Code: `ios/Morning/PrototypeSetVariants.swift`. Production `SetScreen` is
untouched; the only edit outside that file is one routing branch in
`MorningApp`.

---

## How to look at them

```bash
./scripts/shoot.sh set --out v-dawn  -variant dawn       -session A -step 1
./scripts/shoot.sh set --out v-far   -variant far-field  -session A -step 1
./scripts/shoot.sh set --out v-track -variant track      -session A -step 1
```

Swap `-session B -step 16` for the worst content in the program. Any existing
flag still works: `-progress`, `-reps`, `-slot`, `-seed`.

To use them by hand rather than by screenshot, launch with the same arguments
and tap — **your** taps reach the simulator, mine do not.

### The picker is `-variant`, and that is a recorded deviation

The skill's Hard Rule 4 says copy `PICKER.md` verbatim. That file is HTML, CSS
and JS. `redesign-plan.md` R3 overrides it explicitly: this is a SwiftUI app and
the equivalent already exists and is better — the `-screen` review hosts plus
`scripts/shoot.sh`. That satisfies the rule's *intent* (one variant at a time,
full size, realistic context, instant switching) on the right platform.

---

## The three axes

Every direction answers the same question — *what am I doing, how did I do it
last time, how do I record it* — through a **different channel**. That is what
makes them three directions rather than three tints.

| | Direction | Axis — what carries orientation |
|---|---|---|
| 1 | **Dawn** | **Atmosphere.** Colour and the horizon. |
| 2 | **Far Field** | **Type size.** Two committed viewing distances. |
| 3 | **Track** | **Geometry.** Position on a visible spine. |

### What all three hold, because `spec.md` requires it

Verified on rendered frames, not asserted:

- Nothing scrolls, at the worst content in the program.
- The rep control is the same component in the same place in all three. It is
  deliberately **not** a variable — `spec.md` §3.3 says the control you reach for
  with a knuckle is in the same place every time, so the picker compares layout,
  not the counter.
- Rep controls 82pt, primary action full-width.
- Nothing important in the top 15%.
- **All three render `intense`.** `spec.md` §3.3 requires an all-out set to be
  distinguishable *before* you start it. The flag has been compiled into every
  step since W0 and no shipped screen has ever drawn it. Each direction renders
  it in its own channel, which is itself a test of the three axes.
- The threshold crossing fires: counter to `Semantic.threshold`, "Beating last
  time's 15" beneath.

---

## 1 · Dawn — *atmosphere carries orientation*

The existing idea executed as **composition** rather than as wallpaper. Today the
sky sits behind a top-anchored stack. Here the sky is the layout: the empty
region is deliberate, the content is a cluster that belongs to the counter, and
the counter sits where the sky is brightest.

**The progress rail is gone.** In this direction it is a redundant second telling
of what the sky already says, and `spec.md` §2 asks that you read progress across
the room *without reading anything*. A rail is reading.

`ALL OUT` renders inline in `Semantic.urgency` amber — deliberately off the dawn
ramp so it can never be confused with progress.

**Wins when:** the sunrise idea is the product and you want it to be the first
thing anyone notices. It is the only direction where the screen is beautiful.
**Costs:** the least information-dense of the three. Session position is a small
number in the corner, and at low progress the upper screen is a large dark void
that reads as emptiness rather than as sky until the dawn comes up.

## 2 · Far Field — *type size carries orientation*

Built on one observation: today almost everything on the Set screen is
mid-sized, so nothing is comfortably readable at two metres and nothing is
comfortably small. Everything competes at the same volume — which is "the single
hardest problem in the app" restated.

So pick a distance for every element and commit:

- **Far field**, read across a room, one eye open, upside down over a push-up:
  exercise, number, target. Three things. Enormous.
- **Near field**, read only if you pick the phone up: cues, set position, load,
  superset state. Genuinely small, in one block that reads as reference material.

The void between the tiers is doing work — it *is* the distance.

**Wins when:** the 6:10am/1.5m constraint is the thing that actually decides the
design. It is the most legible of the three by a wide margin at a glance.
**Costs:** the cues are honestly harder to read, and they are where the training
effect lives. This is a real bet that cues are consulted once per exercise, not
once per set. If that bet is wrong, this direction is wrong.

## 3 · Track — *geometry carries orientation*

A fixed spine down the left edge, one mark per set: filled behind you, hollow
ahead, a wide bar for the set you are on. The **shape** of the session becomes
visible — three push-ups, a superset of six, the myo block, the finisher.

The claim: "Set 10 / 14" is a number you read and convert. A position on a spine
is a thing you see. It also makes Back legible — you can see what you would be
going back to.

**This is not a list of the workout**, which `spec.md` §1 forbids. It carries no
exercise names, nothing scrolls, and fourteen marks always fit. It shows position
only.

**Wins when:** knowing where you are in the session matters as much as knowing
what to do next — and on a 20-minute cap, "how much is left" is a real question.
**Costs:** the spine takes ~28pt of a 402pt-wide screen permanently, for
information you need occasionally. Visible in the stress shot: cues wrap onto
more lines than in the other two. It is also the busiest of the three, which cuts
against "a good instrument, quiet".

---

## What I am not doing

Not pre-picking a favourite. The choice is Eden's, and the three are genuinely
different bets about what the Set screen is *for* — beautiful, legible, or
oriented. That is a product question, not an aesthetic one.

If two of them turn out to be the same direction once he has used them, the right
move is `riff <name>` — keep the harness, diverge again around the one he
gravitated to.
