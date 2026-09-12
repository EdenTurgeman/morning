# R2 · The foundation

Phase R2 of `ios/Docs/redesign-plan.md`, run on `apple-design`, with §16 Craft
as the test: **every value must be one you can defend.** Walk the token system
and for each colour, size, tracking value and spring, say why it is that number
and not the neighbouring one. Anything answered with "it looked about right" is
a default wearing a decision's clothes.

Six were. This is the record.

---

## 1. The gate

**Contrast re-measured on rendered frames with `ios/Tools/measure-contrast.py`,
not calculated and not judged by eye. Both of those have already lied on this
project.**

| Frame | Before | After |
|---|---|---|
| Rest, progress 1.00, next-up meta line | **6.18:1 — UNDER BAR** | **6.92:1** |
| Rest, progress 0.00, weakest | 8.46:1 | 9.85:1 |
| Set, progress 1.00, weakest | 7.05:1 | 6.90:1 |
| Home, weakest | 7.14:1 | 7.14:1 |

**Weakest text on any measured frame: 6.90:1. Floor 6.6:1. Gate passes.**

`./scripts/verify-ios.sh` clean: build, 68 tests, swiftlint, swiftformat,
generators, export format — 7 phases, 0 failures.

**Stated honestly: the floor holds by 0.3.** That is not comfortable. Anything
that darkens ink or brightens the low sky breaches it again, and the next agent
should re-measure rather than assume the margin is still there.

---

## 2. The failure this phase existed to find

`design-system.md` stated *"the weakest text on any screen at any progress is
6.98:1"*. `DesignTokens.swift` stated *"19.05:1 / 9.87:1 / 7.00:1 at its
weakest"*. Both were false.

The Rest screen's next-up meta line — `set 2 of 3 · 8–15 reps` — measured
**6.18:1 at progress 1.00**. It passes at twilight and fails at gold, so it was
wrong for the last third of every session and right whenever anyone checked.

**This is the third time this project has recorded a documented measurement that
quietly stopped being true.** The pattern is identical each time: a figure
measured across the zones that existed, then inherited as a property of the
system. The zone list is not the screen.

### Why the fix was a hierarchy change and not a contrast change

`secondary` was `white 0.78` and `tertiary` was `white 0.72`. Six points apart.

That is the answer to suspicion #1 — **one level with two names** — and R2 gave
it a consequence rather than an opinion: with tertiary pinned to the floor and
secondary six points above it, **there was nowhere to lift tertiary to.** Any
repair collided with the level above. A hierarchy compressed that tight has no
repair strategy, and that is a structural fault, not a taste one.

Now `1.00 / 0.88 / 0.78`. Gaps of twelve and ten points.

**But the real answer is not more alpha, and R3 should not read it as one.**
`apple-design` §15: hierarchy is built from **weight, size and leading as a
set**. A system that separates its text levels by transparency alone is using
the one dimension that also controls legibility, which is why it ran out of room.
Recorded as a standing rule: *a label that needs to recede further than tertiary
recedes by getting smaller or lighter in weight, never by getting more
transparent.*

---

## 3. Material over the sky — ruled against the plan's suggestion

`redesign-plan.md` R2 says the app "currently draws its own scrims and gradients
over the sky. Real `Material` may do this better, and it is the one place the app
has been approximating something the platform ships." It also says to check it
against the measured floor first.

**Checked. Keep the hand-drawn scrims. Material is the wrong tool here**, and
this is the one place the platform's answer loses.

| | |
|---|---|
| **What Material does** | Samples what is behind it and adapts its tint to that content's luminance. §12: material weight encodes hierarchy. |
| **What is behind it here** | A live Metal fragment shader whose luminance is a deliberate function of session progress, walking twilight → gold across twenty minutes. |
| **The collision** | Material's adaptation would track the sky. The contrast under the text would then drift continuously across the session — and *unpredictably*, because the adaptation curve is Apple's, not ours. The 6.6:1 floor is measurable today precisely because the scrim is deterministic: for any progress value it is a known opacity. |
| **The cost of getting it wrong** | Exactly §2 above, except undiagnosable — a floor that fails at some progress values on some frames, with no token to point at. |

A hand-drawn scrim is not an approximation of Material here. It is the correct
instrument for a background the app itself computes, and `Scrim.atmospheric`
already ramps with progress for this reason.

**What to take from §12 anyway**, none of which requires `Material`:

- **Vibrancy discipline.** Over a translucent or busy background, do not use flat
  grey text — use higher contrast, slightly heavier weight, a small tracking
  bump. This is now the stated reason `microLabel` carries tracking.
- **Bright top edge.** A light catching the top of a raised surface is what makes
  it read as material rather than as a rectangle. `Control.border` at 0.44 does
  some of this; it is uniform, and it could be a gradient.
- **Scroll edge effects, not hard dividers** on the four reading surfaces.
- **`accessibilityReduceTransparency` must be handled by hand.** Material gets
  this free and scrims do not. This is the one real cost of the ruling, and the
  project already reads that environment value — but §14's third signal,
  `colorSchemeContrast` (`prefers-contrast: more`), is **not handled anywhere.**
  Logged as a gap; it is not R2's to fix because it needs per-surface treatment.

---

## 4. The other five defaults wearing a decision's clothes

### 4.1 `label` and `microLabel` were byte-identical — FIXED

Both `Font.caption.weight(.semibold)`. Two names for one value means one of them
was going to be different and never became different.

They are different now, and §15 says how: **tracking is size-specific, and a
fixed letter-spacing is wrong somewhere.** Small text wants slightly positive
tracking; all-caps wants more again, because caps have no ascender/descender
rhythm to separate them. `microLabel` is the level that is always small and
usually caps — `SEC`, `MOVEMENT`, `TARGET` — so it is the level that takes it.

Added `microTracking: 0.6`, and the two values §15 asks for at the other end:
`counterTracking: -1.5` and `titleTracking: -0.4`. **Large display text wants
negative tracking** — letters read too far apart as they grow, and the counter is
92pt. These are declared but **not yet applied at call sites**; applying them is
a screen change and R2 does not touch screens.

### 4.2 `answer = 14.5` — FIXED to 15

A half-point size is not a decision anyone made. SF ships optical sizing and
tracking tables at whole points; asking for 14.5 opts out of them to buy nothing.

### 4.3 The type scale mixes fixed sizes and semantic styles — REAL, NOT FIXED

Suspicion #3, and the answer is: **two systems, but the split is legitimate — the
boundary is just drawn in the wrong place.**

`spec.md` §3.14 already draws the correct line: the three workout surfaces
deliberately clamp Dynamic Type, because they must never scroll and are already
at the top of the scale; every other surface supports the full range. So fixed
sizes on workout surfaces and semantic styles on reading surfaces is right.

What is wrong is that the tokens do not follow that line. `body = .callout`
(scales) is used on the Set screen, which clamps. `question = 17pt` (fixed) is
used on the study card, which is on the Rest screen — also clamped, so that one
is right by accident rather than by rule.

**Not fixed in R2**, because correcting it means auditing every call site and
that is a screen change. Handed to R3 as a constraint: *whichever direction wins,
its type tokens are split by surface class, not mixed per element.*

### 4.4 The space scale is not a system — REAL, DELIBERATELY NOT FIXED

`1, 4, 9, 12, 22, 30`. Ratios `4.0, 2.25, 1.33, 1.83, 1.36`. That is a collection
of values that each solved a local problem, not a scale. `9` and `22` are the
tells.

**Deliberately left alone, and this is a scoping decision rather than an
oversight.** Changing spacing tokens moves layout on every screen, and the
constraint it would put at risk is the one that matters most — *nothing inside a
workout scrolls, ever*. Re-verifying that across every surface, at the longest
exercise name and four cues, for a scale that R3 may restructure anyway, is
effort spent twice.

**Handed to R3.** A 4-based scale (`4, 8, 12, 16, 24, 32`) is the obvious
candidate. §15 also asks that spacing scale *with* text on the surfaces that
support Dynamic Type, which the current fixed CGFloats cannot do.

### 4.5 Bounce on a tap — FIXED

`Motion.commit` was `.spring(duration: 0.32, bounce: 0.24)`, documented as *"a
little weight, because something was committed."* That is a feeling, not a
reason.

§4: start critically damped, add bounce **only when the gesture itself carried
momentum** — a flick, a throw, a drag release. There are no momentum gestures in
this app. A knuckle tap on an 82pt target at 6:10am is the opposite of a flick,
and this fires 28 times a session.

Bounce is now **off by default across the whole motion file**. It survives in
exactly two places, `reveal` and `timerResize`, which are the same event — the
ring yielding its space to the study card — where a trace of overshoot reads as
the layout settling rather than as a reward.

---

## 5. The motion finding: a duration paying for a deleted feature

The largest single value change in R2, and it was found by asking §16 Craft's
question of a number that had a very confident comment beside it.

`Motion.stage` was `.easeInOut(duration: 0.44)`, wrapping **every step change in
the session**, documented as *"the work object carries across, so this is the one
that must not feel like a cross-fade."*

The work object does not carry across. The `matchedGeometryEffect` that made the
counter become the ring was removed after Eden asked twice; it survives only in
the W1 prototype lab. **The morph left and its 0.44s stayed.**

That is 0.44s × 28 advances ≈ **nine seconds per session** spent watching a
screen become itself, on the tier where `emil-design-eng` says to remove motion
and where `apple-design` §1 says any inessential latency on the input path is a
regression.

`Motion.screenSwap` had the same disease plus a second fault:

| | Before | After | Why |
|---|---|---|---|
| `stage` | `.easeInOut(0.44)` | `.easeOut(0.18)` | Paid for a morph that no longer exists |
| `screenSwap` insertion | `.easeIn(0.30).delay(0.04)` | `.easeOut(0.10).delay(0.08)` | **`.easeIn` on the entering element** — a live instance of escalation trigger #2 in `redesign-plan.md` §4 |
| `screenSwap` removal | `.easeOut(0.24)` | `.easeOut(0.10)` | Symmetry with the above |
| `commit` | `.spring(0.32, bounce: 0.24)` | `.spring(0.28, bounce: 0)` | Bounce unearned by any gesture |

**What survives, and why the window is not zero.** A symmetric cross-fade was
tried and measured: both screens sat near half opacity for ~0.2s, stacking the
Set screen's cues onto the Rest screen's controls. Legible content on legible
content reads as neither. The outgoing screen still clears before the incoming
one commits — in 0.18s total instead of 0.34s.

And R1 §3.1's reason it must not be zero: two consecutive sets of the same
exercise differ by one glyph, so a knuckle tap you are not looking at needs *some*
acknowledgement, or `Done` gets pressed twice and the next set is logged with the
wrong reps.

**Not yet verified on video.** These are token values that compile and pass
tests. This project has shipped two motion changes that compiled, read correctly
and did nothing on screen. **R4 films this transition before believing it.**

---

## 6. What R3 inherits

**Settled and not to be re-litigated:**
- Ink `1.00 / 0.88 / 0.78`, floor 6.6:1, weakest measured 6.90:1
- Hand-drawn scrims, not `Material`, over the live sky — §3
- Bounce off by default; earned only by momentum
- Step transition 0.18s, ease-out both directions

**Open, and handed forward deliberately:**
- The space scale is not a system. A 4-based scale is the candidate. §4.4
- Type tokens must be split by surface class (clamped vs Dynamic Type), not
  mixed per element. §4.3
- `counterTracking`, `titleTracking` and `microTracking` are declared and not yet
  applied at call sites
- `colorSchemeContrast` (`prefers-contrast: more`) is handled nowhere in the app
- The 6.6:1 floor now holds by 0.3 at the gold end. Thin.
