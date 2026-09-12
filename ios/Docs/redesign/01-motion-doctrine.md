# R1 · The motion doctrine

Phase R1 of `ios/Docs/redesign-plan.md`, run on `emil-design-eng`.

**What this is.** The standing answer to *"should this animate at all"* for every
surface, so R4 does not re-argue it eleven times. It is not a list of animations
to build.

**What outranks it.** `spec.md` on any question of behaviour. The measured values
in `redesign-plan.md` §5.2. Eden on anything he has ruled.

---

## 1. The hypothesis, ruled on

> *The twenty minutes the app is in use is the tier where motion should be
> removed, and nearly the whole budget belongs to the four seconds at the end.
> The Set screen should be the least animated thing in the app.*

**Confirmed, and it is not a close call.** The framework's first gate is
frequency, and it is blunt: 100+ times/day gets *no animation, ever*; tens of
times/day gets *remove or drastically reduce*. Six mornings a week, the rep
control is pressed dozens of times per session and `Done` twenty-eight times.
Those are not "frequent UI", they are this app's keyboard shortcuts — actions
performed with a knuckle, half awake, often without looking at the screen. The
framework's rule for keyboard-initiated actions is to remove animation outright,
because animation makes a repeated action feel slow, delayed, and disconnected
from the input. That is precisely the failure mode at 6:10am.

The two Set-screen animations already removed on this reasoning were correct.

**But the hypothesis is stated at the wrong altitude, and that is worth fixing
before R4 inherits it.**

### 1.1 The sharpening: tier the event, not the surface

Frequency is a property of *events*, not screens. The Set screen is a Tens/day
surface that hosts a Rare event — the counter crossing last session's number.
Tiering by surface would strip the single most important moment in the product
because of the company it keeps.

Three events break their surface's tier, and all three are on surfaces the
hypothesis would otherwise silence:

| Event | Its surface's tier | The event's own tier | Consequence |
|---|---|---|---|
| Crossing last time's number | Tens/day (Set) | **Rare** | Gets the best motion inside the workout loop |
| The last five seconds of a countdown | Tens/day (Rest) | **Required by `spec.md`** | Gets motion even though its surface is stripped |
| Study card answer revealing | Tens/day (Rest) | Occasional | Earns a beat; it is a *reveal* |

**Rule: tier the event. A stripped surface may still host a moment.**

### 1.2 The second sharpening: press feedback is not on the frequency ladder

The frequency gate governs *transitions* — motion between states the user is
waiting through. It does not govern a control acknowledging that it was pressed.
Those are different things and conflating them would produce dead 78pt targets.

At 6:10am, with sweaty hands, tapping a phone on the floor with a knuckle and
often not looking at it, **the press response is frequently the only confirmation
that the tap registered at all.** Removing it does not make the app faster; it
makes it feel broken, and it makes the user tap twice — which on `Done` logs the
next set.

**Rule: every pressable surface responds to press, everywhere, no exceptions,
≤160ms. This is exempt from the frequency gate.**

---

## 2. The three exemptions, stated once

Anything not on this list is governed by frequency.

1. **Press feedback.** Mandatory everywhere. ≤160ms. §1.2.
2. **Ambient motion.** The dawn sky is environmental, not on the input path, and
   nobody is awaiting a response from it. The sub-300ms rule does not reach it
   (`redesign-plan.md` §5.1). Neither does the frequency gate — it is not seen
   *n* times, it is simply present.
3. **Motion `spec.md` requires as information.** The last five seconds of a
   countdown must be "perceptible without looking at the screen ... plus a change
   catchable in peripheral vision". That is a functional requirement wearing an
   animation's clothes. It ships regardless of tier.

---

## 3. The per-surface ruling

**"NO MOTION" below means exactly that: no enter transition, no exit transition,
no arrival flourish, no stagger.** Press feedback (§1.2) still applies, and the
shared step transition (§3.1) is not the surface's own motion.

### 3.1 The shared step transition — the one piece of motion the loop keeps

Set → Rest → Set, ~28 times a session. This is the loop's only transition and it
is the one place the hypothesis needs a carve-out, so the reasoning is spelled
out rather than asserted.

**Ruled: it animates.** Not for polish — for a purpose the framework lists
explicitly, *preventing jarring changes*, plus one specific to this app.

Two consecutive sets of the same exercise are near-identical screens. Set 2 of 3
and set 3 of 3 differ by one glyph. With no transition at all, a user who taps
`Done` with a knuckle, not looking, **has no way to tell whether the tap
registered.** He looks up at a screen that appears not to have changed and taps
again — logging the next set with the previous set's reps. The transition is what
makes "it advanced" legible from 1.5m without reading the set counter.

**What it is:** a fade-through of the *furniture only*. The sky stays hoisted
above the swap and does not participate.

| | |
|---|---|
| Duration | ≤180ms total, no movement — opacity only |
| Why not a slide | Movement costs readability, which is the thing being protected |
| Why the sky is hoisted | Fading the sky per-screen measured 50 → **7** → 40 mean luma: a blackout between two screens. Hoisted it is 50 → 22 → 40, a breath. Do not un-hoist it. |
| SwiftUI | `.animation(_:value:)` on the step index. **Not** `.phaseAnimator` / `.keyframeAnimator` — those restart rather than retarget, and this can be triggered rapidly with Back. |
| Cost if absent | Double-logged sets. This is the motion with the clearest failure mode in the app. |

**Explicitly not:** `matchedGeometryEffect` carrying the exercise name or the
counter between Set and Rest. It was built, Eden asked for it gone twice, and it
is gone. Do not reintroduce it — and note that two `matchedGeometryEffect`
sources in one tree is a silent conflict SwiftUI does not warn about.

### 3.2 Surface by surface

| Surface | Event tier | Ruling | What the motion is FOR / what its absence would cost |
|---|---|---|---|
| **Rep +/− control** | Tens/day | **NO MOTION.** Press feedback only. | Absence of press feedback: no confirmation the knuckle landed. The *transition* has no purpose — the number is the information. |
| **Rep digit change** | Tens/day | Numeric roll, ≤120ms, and **per-set identity** so a new set's number never rolls from the previous set's. | Shows direction (up vs down) at a glance. Without identity it reads as a slot machine on every step — a shipped bug, fixed by identity, not by a transaction. |
| **Crossing last time's number** | **Rare** | **The best motion in the workout loop.** Colour, motion, distinct haptic, distinct tone, together on one frame. Fires **once**, on the crossing adjustment only — never continuously while above. | This is the emotional centre of the entire product. Its absence costs the app its reason to exist. |
| **Set screen arrival** | Tens/day | **NO MOTION** of its own. Inherits §3.1. | Nothing. Every frame spent arriving is a frame not readable at 1.5m. |
| **Set screen content** (name, cues, target, figure) | Tens/day | **NO MOTION.** No stagger, no per-element entrance. | Nothing. Fourteen staggered entrances a session is fourteen delays. |
| **`intense` / all-out marker** | Tens/day | **NO MOTION.** Static, and legible *before* the set starts. | It is a warning, not a reward. Currently unrendered — see `00-brief.md` §4.5. |
| **Warm-up** | 1/session | **NO MOTION** beyond the countdown and §3.1. | The least important surface in the app; it should not pretend otherwise. |
| **Rest arrival** | Tens/day | **NO MOTION** of its own. Inherits §3.1. | Nothing. |
| **Countdown ring, steady state** | Tens/day | Continuous, not an animation. Advances every frame from an absolute deadline. | It *is* the information. Linear, no easing — easing a clock makes it lie. |
| **Countdown, last 5 seconds** | **Required** | **Motion ships regardless of tier.** Escalating per-second visual change, catchable peripherally, on the same frame as its tone and haptic. | You are not looking at the screen. Absence costs you the start of your next set. |
| **Ring completion** | Tens/day | **NO flourish** at zero beyond the "go" beat above. | The ring emptying already said it. A completion animation would be a reward for waiting. |
| **The 20s myo rest** | 3/B session | **NO MOTION** beyond the last-5s escalation. It should read as *different* from a long rest — but by colour, type and copy, statically. | Its job is to be uncomfortable and to end. Anything inviting the user to linger breaks the exercise. `spec.md` §10 forbids a card here for the same reason. |
| **Study card reveal** | Occasional | **Animates.** ~200–250ms, ease-out equivalent. The thinking-time indicator is continuous and linear. | It is a *reveal* — the framework's one clearly earned beat. The answer appearing with no transition reads as a glitch. The indicator must be legible without reading, and it must be driven by a clock, not a `withAnimation` in `onAppear` — that exact bug shipped and moved nothing. |
| **Ring yielding space to the card** | Occasional | **Keep the idea.** The ring halving *is* the explanation of where the space went. | Motion carrying meaning — when something shrinks it is giving its space to something else. Absence makes the card feel like it shoved the timer. |
| **Home arrival** | Occasional | Standard. ≤250ms. Stagger permitted but capped at 80ms total across all items. | Seen once or twice a session. A modest entrance is affordable; a long cascade is not, because it delays the one tap the user came to make. |
| **End-session confirmation** | Rare, destructive | **Asymmetric.** Slow the deliberate half, snap the release. Hold-to-confirm is available and appropriate here. | Destruction should cost deliberate effort — it discards every set already logged. Fast where the system responds, slow where the user is deciding. |
| **The completion moment** | 1/session | **The delight budget. Spend it all here.** ~4.4s. Exempt from 300ms. | The one moment allowed to be spectacular. It is the reward, and the reward is the product's tone. |
| **Celebration tiers** | Weekly/monthly | The tier controls the **amplitude** of the completion moment, not whether it plays. Bottom five visibly quieter than top four. | Currently unimplemented — a plateau gets a personal best's radiance. That distinction is the entire reason the tiers exist (`spec.md` §9). |
| **Summary** | 1/session | Standard, restrained. The rep total is the largest fact and it does not need to arrive. | It is read, not watched. It follows a 4.4s spectacle; competing with it is a mistake. |
| **History / Lifetime / Guide / Backup** | Rare | **NO entrance choreography.** Standard scrolling and press feedback only. | Read outside a session, at leisure. Nothing is urgent and nothing is being awaited. |
| **Empty → first data** (year grid, lifetime) | First-time | Delight permitted. Seen once, ever. | Day one is the normal case, not an edge case. "0 tonnes" must read as the beginning of a record. |
| **The dawn sky** | Ambient | Exempt. 12fps, one cloud crossing per ~3 minutes. | It is how you tell progress from across the room without reading. Deleting it deletes the idea the product is built on. |
| **The Live Activity** | Glanced | **NO MOTION** the app controls. A number and what is next. | The system composites it next to other apps' notifications. The dawn belongs to the app. |

---

## 4. House values, in SwiftUI

The framework's recommended spring is `{ duration: 0.5, bounce: 0.2 }`, and
SwiftUI ships that exact model as `.spring(duration:bounce:)`. It is a 1:1
mapping, not an approximation. **Prefer a spring to every cubic-bezier in the
skill.**

| Purpose | Value | Note |
|---|---|---|
| Press feedback | `.snappy(duration: 0.16)`, `.scaleEffect(0.97)` | Scale from the trigger, not from centre |
| Step transition (§3.1) | `.easeOut(duration: 0.18)`, opacity only | Retargets; survives rapid Back |
| Card reveal | `.spring(duration: 0.25, bounce: 0)` | A reveal, not a bounce |
| Ring yielding to card | `.spring(duration: 0.3, bounce: 0.1)` | The one place a trace of bounce is earned |
| The crossing | `.spring(duration: 0.22, bounce: 0.15)` + haptic + tone **on the same frame** | The threshold delay must clear the digit roll (~0.24s), not visual fusion. Measured at 0.22s. |
| Anything entering | Never `.easeIn`. Never `.scale(scale: 0)`. | Start at 0.95 with opacity. Nothing in the world appears from nothing. |
| Never animate | `.frame`, `.padding`, layout modifiers | Use `.scaleEffect`, `.offset`, `.opacity`, `.rotationEffect` |

**Bounce is off by default.** It is earned after a gesture carried momentum, and
there are almost no gestures in this app. A workout instrument that boings is a
consumer fitness app.

---

## 5. Reduce Motion

The rule is *calmer, not absent*. Keep opacity and colour; remove movement.

| Surface | Reduced form |
|---|---|
| Step transition | Already opacity-only. Unchanged — it is the reduced form. |
| The crossing | Colour and haptic and tone hold. Drop the scale. **Never drop this one entirely** — it is the product. |
| The completion moment | A calmer sunrise, not a skipped one, and not a still image. |
| The dawn sky | Pause the timeline. The sky stays; it stops drifting. |
| Card reveal | Opacity only. |
| Last 5 seconds | **Unreduced.** It is information, not decoration, and the user may not be looking. |

---

## 6. How any of this gets verified

**Not by reading the code.** This project has shipped two motion bugs that
compiled, read correctly, and did nothing on screen: a `withAnimation` inside
`onAppear`, and a `.transaction { $0.animation = nil }` placed outside an
`.animation(_:value:)` where it could not reach. Neither was caught by
inspection. Both were caught by filming the simulator and stepping frames.

- Every motion change is looked at in a captured frame. `xcrun simctl io
  recordVideo`, then `ios/Tools/frames.swift`.
- Anything driven by a clock exposes a value you can print. A fraction of two
  dates is checkable; a `withAnimation` either happened or it did not and no
  screenshot can tell you which.
- Review it the next day, and in slow motion. Timing faults invisible at speed
  are obvious at 4×.

**One claim this machine cannot make.** The bar includes 120Hz with no dropped
frames during a timer. The simulator does not run at 120Hz and its timing is not
representative. **No frame-rate claim may be made from this environment** — that
is W11, on Eden's phone, and it is still open.

---

## 7. The short version

Nine surfaces get **no motion of their own**: the rep control, the Set screen and
everything on it, the warm-up, the Rest screen's arrival, the ring's completion,
the myo rest, the four reading surfaces, and the Live Activity.

Four things animate inside the workout: **the step transition**, because without
it a knuckle-tap has no acknowledgement and sets get double-logged; **the last
five seconds**, because the user is not looking; **the card reveal**, because it
is a reveal; and **the crossing**, because it is the whole point of the product.

Everything else the app has to spend, it spends on four seconds that happen once.
