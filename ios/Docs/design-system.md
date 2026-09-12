# Design system

Deliverable 4 of `ios-port/02-design-brief.md §11`. Written **after** the
direction was agreed, which is the point of the ordering.

**Rewritten 2026-09-03, because it described a world that no longer exists.**
Every colour in the Colour section was a stop on a dawn ramp — indigo, violet,
rose — and that ramp, its sky and its shader were deleted when the app became
paper. The document still said "the sky is the material" thirty-two times, and
`CLAUDE.md` pointed every new session at it as the design system. Anything below
that still reads as the old world is a bug in this file, not a feature of the
app.

The code half of this document is the source of truth for values:

| File | Holds |
|---|---|
| `ios/Morning/PaperTokens.swift` | **The world.** Inks, grounds, the paper primitives, the controls, the stamps |
| `ios/Morning/DesignTokens.swift` | Type scale, tracking, spacing, hit targets |
| `ios/Morning/DesignMotion.swift` | Curves, durations, hold-to-repeat, and every reduced-motion form |
| `ios/Morning/DesignHaptics.swift` | The haptic vocabulary, as data |
| `ios/Docs/redesign/01-motion-doctrine.md` | **Whether a thing may animate at all.** Surface by surface. Not re-argued here |

**Every contrast figure in this document was measured on rendered simulator
frames** with `ios/Tools/measure-contrast.py`. It is not calculated from
declared alphas, and it is not estimated by eye. Both were tried first and both
lied. Note that the tool's ZONE ROWS are tuned to a layout two redesigns old —
check its printed row ranges against the frame before quoting it.

---

## Direction

**Paper mâché.** Spot ink on newsprint: a mid-tone stock, pasted plies with torn
edges, a halftone dot over everything, and a slow boil on the shapes that move.

### What it replaced, and what it had to keep

The app was a dawn. Its colour was a function of how far through the session you
were — astronomical twilight to gold — and the load-bearing claim was that **you
could tell how far through the workout you were from across the room without
reading anything.**

That claim is the thing the new world had to answer, not the gradient that
delivered it. It answers it with the **step block** in the workout chrome: every
set in the session printed as a mark, inked as it is finished. A discrete count
you can read at 1.5m, rather than a colour you have to interpret. It is owned by
`WorkoutHost` for exactly the reason the sky was — it must not blink when Set
becomes Rest.

### The one constraint that decides everything else

**This world cannot produce a gradient.** Not "prefers not to" — a duplicator
lays down flat ink or it lays down nothing, and every soft ramp, glow, halo and
coloured shadow in the old system had to be re-answered as a flat mark or
deleted. That is structural, and it is why:

- urgency on the countdown ring is the arc getting **heavier**, not brighter —
  ink cannot glow;
- the completion moment is ~41 flat shapes rising behind a torn horizon, not a
  shader;
- "you passed it" is an **overprint** — orange laid over blue makes plum —
  rather than a highlight.

### What survived the change

`Hit` (68 / 80 / 64pt targets), `Space`, and the tracking values Eden named
unprompted as the thing he liked: `counterTracking -1.5`, `titleTracking -0.4`,
`microTracking 0.6`. Weight-led hierarchy survived too. **This world changed the
ground and the ink, not the typographic discipline.**

---

## Colour

### The ink law

**Three inks, and each has exactly one job on every surface.** A fourth value
exists and is not a fourth ink — it is what two of them make where they
overprint.

| Ink | Job | Value | Measured |
|---|---|---|---|
| `press` | Every glyph being **read**, and the primary action's block | `#2E2B26` | **7.74:1** on stock · **11.35:1** on ply |
| `blue` | Everything **already true** — last time's figure, finished steps, logged history | `#0F3066` | **7.02:1** on stock |
| `orange` | Everything **happening now** | `#E05221` | **2.14:1** as text — see below |
| `overprint` | Orange printed over blue: the crossing, and the stamps | `#572229` | **10.2:1** knocked out in ply |
| `danger` | Destruction, and "you have no copy of this" | `#730D0D` | **6.77:1** on stock |
| `rule` | A hairline that is furniture, never a glyph | `press` at 0.30 | — |

### The grounds

| | Value | Why |
|---|---|---|
| `stock` | `#C9BFAC` | Newsprint. **Mid-tone by material** — newsprint is never white, so the direction reset's "no white page" is satisfied without trying |
| `ply` | `#EDE6D8` | The pasted ply, a second sheet laid over the stock |

The ply pays for itself twice. Press black measures **11.35:1** on it against
7.74:1 on the stock, so **the contrast and the material are one decision** — the
surfaces you actually read are the ones made of a second sheet.

### Orange is a MARK, never a glyph

The single most load-bearing rule in this section, and it was measured rather
than chosen. Orange carries text at **2.14:1** on stock — under the house floor
and under WCAG's 3:1 large-text bar. **A 152pt orange numeral was never
available, however good it looked.**

So: **orange lights, press black writes.** On newsprint a giant black numeral is
the bib. Orange is the live tick on the rail, the thinking bar under a question,
the rule draining beneath a timer badge — marks, all of them.

The old world had already learned the same split from the other side, where a
raw accent lit and a lifted one wrote. Here it resolves more simply, because
there is no lifted variant to reach for.

### A mid-tone ground cannot carry three levels of text

Found the hard way and worth stating as a rule. The old system had a three-step
ink hierarchy — primary, secondary, tertiary — carried by opacity. On a mid-tone
stock the third step lands too close to the ground to clear the floor, and the
second is not reliably distinguishable from the first.

**Hierarchy here is carried by size and weight, never by transparency.** A level
recedes by getting smaller or lighter in weight. This is why a 12pt tracked
label under a 112pt number is not also dimmed: it is already ninety points
smaller.

### `danger` is the one exception to the three-job law, and it earns it

Deleting a session must never be confusable with the crossing, and the overprint
already owns the crossing. A pure red against the overprint's plum. The other
half of why this is safe: **they never appear on the same surface.**

---

## Type

SF Pro, properly. The web build shipped Inter only because SF is not available
to web apps.

| Token | Size / style | Used for |
|---|---|---|
| `TypeScale.counter` | 92pt bold rounded | Rep counter, rest timer |
| `TypeScale.counterCompact` | 64pt bold rounded | The timer once a card has taken half the screen |
| `TypeScale.title` | 34pt medium | Exercise name |
| `TypeScale.body` / `bodyEmphasis` | subheadline | Sub-label, cues |
| `TypeScale.question` | 17pt semibold | Study-card question |
| `TypeScale.answer` | 14.5pt | Study-card answer |
| `TypeScale.label` | caption semibold | Chrome, units |
| `TypeScale.microLabel` | caption2 semibold | `MOVEMENT`, topic, badges |
| `TypeScale.action` | headline | The primary action |

- **Tabular numerals** on anything that changes in place — `.monospacedDigit()`
  on every counter and timer, so digits do not jitter as they roll.
- **`.contentTransition(.numericText())`** so counters roll rather than swap,
  and the digit moves in the direction you pushed it. `Motion.numeric` returns
  a plain opacity change under Reduce Motion.
- **Workout screens use fixed sizes on purpose.** `§6` allows it: they are
  already at the top of the scale, and Dynamic Type on a screen that must never
  scroll would break the layout rather than help. Reading screens — Guide,
  cards, History — support the accessibility sizes instead. That split is
  deliberate and is not an accessibility shortcut.
- **One divergence inside that split, named rather than left silent.**
  `02-design-brief.md §6` lists **cards** among the reading surfaces. Card text
  does not currently scale, on a rest or on the summary, and there are two
  separate reasons — only one of which is deliberate.

  The deliberate one: the study card lives on the Rest screen, and that screen
  must never scroll. At an accessibility size a seven-line answer would push the
  timer or the controls off the bottom, and `04-rules.md §6` is unambiguous that
  you must never miss the timer because you were thinking. So the rest card is
  clamped with the workout.

  The incidental one: `TypeScale.question` and `TypeScale.answer` are
  `Font.system(size:)` — **fixed points, not text styles** — so they would not
  scale even where nothing clamps them, which is the summary card. Half the
  scale is built on text styles (`body`, `label`, `microLabel`, `action`) and
  scales properly; `counter`, `title`, `question` and `answer` are fixed.

  For counters and titles fixed is right and intended. For the summary card it
  is not, and the fix is not free: `answer`'s 14.5pt is tuned to the seven-line
  stress case on a screen that cannot scroll, and the nearest scaling style
  (`.subheadline`, 15pt) is half a point larger. **Left as it is, deliberately,
  and flagged rather than quietly changed** — moving type on the most
  constrained screen in the app is Eden's call, not a tidy-up.
- **Where the clamps actually are**, because "supports Dynamic Type" and "does
  not clamp" are not the same claim:

  | Screen | Scrolls | Clamp |
  |---|---|---|
  | Set, Rest, Warm-up | never | `.large` |
  | Guide | yes | `…accessibility3` |
  | History, Ledger | yes | none |
  | Home, Summary, Backup | no | none |

  The last row neither scrolls nor clamps, so it relies on the layout holding at
  whatever the system asks for. **Measured, at
  `UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge`:**

  | Screen | Pixels changed vs default | Verdict |
  |---|---|---|
  | Guide | 16.1% | scales, scrolls, fine |
  | Summary | 2.3% | nothing clipped, headroom to spare |
  | Home | 2.0% | nothing clipped |

  Home and Summary are safe — but not because they scale gracefully. They
  barely scale at all, because their type is almost entirely fixed sizes. That
  is the right answer for a rep counter and the wrong one for a card, which is
  the point above.

  To reproduce: append
  `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge`
  to any launch. In zsh, pass the arguments separately — an unquoted variable
  holding the whole string is **not** word-split, and the app silently falls
  back to Home, which is a very convincing way to measure the wrong screen.

---

## Spacing and layout

`Space`: 1 · 4 · 9 · 12 · 22 · 30. The gutter is 22pt.

Two hard minimums, both from `01-product.md`, both about sweaty hands at 6:10am:

| Token | Value | Floor in the brief |
|---|---|---|
| `Hit.repControl` | 82pt | 78pt — they are hit with a knuckle |
| `Hit.primary` | 68pt | 64pt — the main action is full-width |
| `Hit.minimum` | 64pt | Everything else tappable, Back and End included |

And one rule that is a layout constraint rather than a number: **nothing
important lives in the top 15% of the screen during a set**, because the phone
is on the floor.

**No screen inside a workout scrolls. Ever.** If content does not fit, the
design is wrong, not the screen. The stress cases that have to fit are the
longest exercise name, four cues, and a three-line question with a seven-line
answer; all three have deterministic fixtures in the lab.

---

## Material and depth

**The paper is the material.** Four primitives in `PaperTokens.swift`, and
between them they build every surface in the app.

| Primitive | What it is | Numbers that matter |
|---|---|---|
| `PaperGround` | The stock, under one press run | `stock` + `Halftone` overlay |
| `Halftone` | The dot, offset row to row | pitch 5, radius 0.62, alpha 0.16, `press` tint |
| `TornEdge` | A `Shape` whose top and/or bottom is torn | 44 steps, amplitude **3.5pt**, hash-seeded so a sheet's tear is stable |
| `Fibre` | Loose fibres in a pasted sheet | 420 strokes, 3–12pt, xorshift-seeded |
| `Ply` | A pasted sheet: `TornEdge` filled, fibre clipped to it, **a real offset shadow** | `press` at 0.22, radius 3, y +2 |

Decisions inside it:

- **The halftone is an overlay, not a background**, so the dot falls across the
  plies too. A duplicator does not stop printing at a pasted edge.
- **The shadow under a ply is an offset and a blur, never a zero-offset halo.**
  What makes a torn edge read as torn is the light under it.
- **One `TornEdge` per sheet, used for both the fill and the clip.** Two
  instances drift apart the moment somebody changes a seed, and then the clip
  stops matching the edge it is supposed to be. `StudyCard.sheet` is the
  exemplar.
- **Ink cannot exist off the paper.** Content is clipped to its sheet. Filmed at
  60fps, an opening study card drew its option rows on the bare stock for ~100ms
  while the sheet was still rising underneath them — an inserted view is placed
  using the layout it is arriving *into*. Clipping is both the fix and the
  truth: a row with no sheet under it yet is simply not printed yet.
- **The ground is a sibling, never a background modifier on a transitioning
  container.** `.paperGround()` on the `Group` in `WorkoutHost` put the stock
  *inside* the subtree the step transition fades, and every Set ↔ Rest swap
  washed the screen to white: mean luma **185 → 241 → 184**. As a `ZStack`
  sibling it measures 185 → 188 → 185, and the peak frame samples exactly
  `Paper.stock`.
- **No Liquid Glass, no `MeshGradient`, no shader.** `Sky.metal` survives only
  because `PrototypeVisuals.swift` is the record of how the direction was
  chosen; `Daybreak.metal` was deleted outright when the completion moment
  became shapes. Paper has no atmosphere, so a shader had nothing to compute.

### The boil

Shapes that move are re-hashed on a coarse clock — the sunrise's rays quantise
their seed at 8fps — so the drawing wobbles the way a hand-cut stencil does.
It is the one ambient motion in the world, and it is **off under Reduce
Motion**: continuous jitter is precisely what that setting exists to switch off,
and the shapes keep their whole form without it.

### The exercise figure

`§7` is direct about this: *"The current figures are SVG stick figures animated
with SMIL and the user has said twice that they need work… They should look like
a body, not a diagram."*

Twice is the part that matters, and the first native pass reproduced the same
problem in Swift — uniform 5pt round-capped strokes and a circle for a head.
What makes that read as a diagram is not the abstraction. It is that every line
is the same width and every joint is a corner.

`PrototypeFigure.swift` draws the same poses as **filled, tapered shapes**:

- Limbs taper from shoulder to hand and from hip to foot, with round joints,
  because there is a bone end inside a joint.
- The torso is a mass with a waist and curved sides, not a line — and it rotates
  on its own axis, so a bent-over row leans as one body.
- The head is an ellipse slightly taller than wide, on a neck. A circle floating
  above the shoulders is exactly the "ball on a stick" read.
- Dumbbells have plates, so they are loaded rather than held rods.

The pose coordinates and the motion model are unchanged from the stroke version.
No assets, no dependency, no anatomy library.

One trap worth recording: the bay is wide and short, so **a normalised x offset
is worth far fewer points than the same number in y**. A stance that looked
hip-width in coordinates rendered as two fused legs. Widths are all derived from
`size.height` for the same reason.

It stays deliberately abstract. This is a movement reminder glanced at from 1.5m
at 6:10am, and detail it does not need would only compete with the rep counter.

---

## Motion

The doctrine is `§9`, and every token in `DesignMotion.swift` is a **function of
`reduceMotion`** rather than a constant with an `if` at each call site. A reduced
form you have to remember to write is one you will forget to write.

| Token | Full | Reduced | Why |
|---|---|---|---|
| `Motion.rep` | easeOut 0.18s | linear 0.08s | Must feel like the digit moved because you pushed it |
| `Motion.commit` | spring 0.32s, bounce 0.24 | linear 0.01s | Something was committed; a little weight — **defined but unused in the product**, see below |
| `Motion.stage` | easeInOut 0.44s | linear 0.12s | Set ↔ Rest, carrying the work object across |
| `Motion.reveal` | spring 0.50s, bounce 0.12 | easeOut 0.18s | The answer arriving |
| `Motion.timerResize` | spring 0.55s, bounce 0.10 | easeOut 0.18s | The timer yielding its space to the card |
| `Motion.screenSwap` | out 0.24s / in 0.30s after 0.04s | opacity 0.12s | How a screen leaves and the next arrives |
| `Motion.threshold` | easeOut 0.20s after 0.22s | linear 0.12s | The second beat of passing last time's number |
| `Motion.answer` | easeOut 0.28s after 0.34s | easeOut 0.16s after 0.10s | The answer's ink, once the card has stopped growing |

**`Motion.commit` is currently only used by the W1 lab.** Logging a set moves
the whole work object instead, which is a bigger gesture than a pulse and does
the same job. The token stays because it is part of the vocabulary and the next
screen that commits something will want it — but the table above would
otherwise be claiming behaviour the app does not have.

### Every reduced form, and the one that was wrong

`Motion.answer` and `Motion.threshold` both keep their **delay** under Reduce
Motion, shortened rather than dropped. That is deliberate and it is the rule the
others should be read against: Reduce Motion asks for less movement, not less
information, and in both cases the gap between the two events *is* the
information — the number then what it means, the card then the words.

`threshold`'s reduced form originally had no delay at all, so the two beats
collapsed into one frame for exactly the people who had asked for calmer. Caught
by measuring rather than by reading it.

### The three that are delays, and why each number is what it is

Every one of these was measured off a 60fps capture rather than chosen, and in
each case the first value I picked from first principles was wrong.

**`screenSwap` is asymmetric because a symmetric cross-fade is mush.** Both
screens sat near half opacity for ~0.2s, which put the Set screen's cues and
Done button directly on top of the Rest screen's controls. The overlap window
is deliberately non-zero, though: the work object crosses it, and the counter
becoming the ring is the continuity worth protecting.

**`threshold`'s 0.22s clears the digit ROLL, not perceptual fusion.** The
counter recolours over 0.18s but `contentTransition(.numericText)` is not
finished until ~0.24s. A 0.09s delay — the figure vision needs to read two
events as separate — still had the sentence fully legible while the digit was
mid-roll.

**`answer`'s 0.34s clears the card's growth.** The layout change is the point,
so the card still grows immediately; only the ink waits.

**None of these will animate from a `@ViewBuilder` branch swap.** `.transition`
on a branch, with or without a delayed `.animation(_:value:)`, does nothing —
the content simply appears. Both the rep comparison line and the study card now
use opacity on a view that never leaves the tree. If you add a fourth, assume
it will not animate and measure it.

### The ground does not participate — and this has now gone wrong TWICE

`DawnBackdrop` belonged to `WorkoutHost`, not to the screens. Owned per-screen
it faded with everything else and mean luminance across a Set → Rest swap went
47 → 7 → 40 — a full blackout, 25+ times a session. Held continuous underneath,
the same swap measured 50 → 22 → 40.

**The sky is gone; the stock inherited its job, and inherited the trap with it.**
`.paperGround()` was applied as a modifier on the `Group` holding the three
transitioning branches, which put the stock and its halftone inside the subtree
the transition fades. Measured 2026-09-03: **185 → 241 → 184** — the paper
world's whiteout in place of the old world's blackout, and the frame at the peak
shows the Rest screen ghosted on bare white with not a halftone dot left.

The ground is a `ZStack` **sibling** now. A sibling cannot be faded by a
transition on its siblings. Re-measured: 185 → 188 → 185, the peak frame
sampling exactly `Paper.stock` — the ground holding while the screens cross.

The lesson generalises past this one modifier: **a ruling written about the sky
did not transfer to the thing that replaced it, because nobody re-measured after
the world changed.** Every claim in `01-motion-doctrine.md` that names the sky is
worth re-reading against the paper.

### The countdown's last five seconds

`urgency` ramps 0 → 1 over the final five seconds. It drove the ring's glow
(opacity 0.20 → 0.65) and its shadow (8 → 22px); **both were a gradient and a
coloured drop shadow, and neither survived the move to paper.** It now drives
the arc's LINE WIDTH, `stroke + urgency * 6`, because ink cannot glow — urgency
is carried by the mark getting heavier. Ported from
`src/components/Ring.tsx`, which names what it is for: peripheral warning. The
audio and the haptics both ramped over this window and the screen did nothing,
which is backwards — the phone is 1.5m away and the ring going hot is the part
caught out of the corner of the eye.

**Fast where it's in the way, slow where it's the point.** Rep and stage
transitions are quick because you are mid-workout. Reveal and resize are slower
because the motion *is* the explanation: the timer shrinking is what tells you
the answer has taken its space. That is the one existing example `§9` singles
out as motion carrying meaning, and it survives into this system.

**Nothing blocks input.** No transition gates the next tap on an animation
finishing. The web version had exactly this bug and it made the app feel broken.

### Hold-to-repeat

`04-rules.md §1` requires the rep control to report a **delta**, never an
absolute, because acceleration makes two taps in one update cycle reachable in
normal use. `Motion.Hold`: first repeat at 410ms, then 230ms accelerating by 0.80× to
a 60ms floor.

### Ambient drift

`Motion.Drift` — cloud banks at 200s and 128s, rays at 150s, a meteor cycle of
11s with a 1.15s flight. The two cloud speeds are what produce parallax; one
speed reads as a moving backdrop.

Under Reduce Motion these do not slow down, they **stop**. Drifting cloud is
precisely what that setting exists to switch off. Verified: with Reduce Motion
on, **0.00% of pixels change over six seconds**, and every layer's structure,
colour and progress reading survives. Calmer, not broken.

---

## Haptics

**The web app has no haptics at all** — its `buzz()` is a silent no-op on iOS.
Every tap in the shipped app is mute to the hand, which makes this the single
largest available improvement in felt quality.

**The primary action's haptic lives in the primary button component**
(`PaperPrimaryButton`, formerly `DawnPrimaryButton`) **, not at its call
sites.** It used to be written out by each caller and four of the five
remembered; Guide's Export did not, so the one primary action that opens a file
picker was the one that said nothing to the hand. Tapping the summary card had
the same shape of bug from the other direction — its closure set state directly
instead of calling `reveal()`, so only the fourteen-second auto-reveal ever
produced the reveal haptic, and the one case where it genuinely *is* an action
you took was the silent one.

The W1 lab opts out with `haptic: false`, because it fires its own
treatment-varying haptic and two at once would make every treatment feel
identical.

The vocabulary is data in `DesignHaptics.swift`, separate from the engine that
plays it, so the design can be read without reading playback code.

| Event | Pattern | Why |
|---|---|---|
| **Rep ± ** | one transient · 0.52 / 0.42 | A detent, not a buzz. One event, so the threshold is unmistakably different |
| **Passing last time** | two transients 45ms apart · 0.85/0.62 then 0.95/0.86 | The emotional centre. Rhythm, not volume |
| **Set logged** | one transient · 0.62 / 0.42 | Confirming, with a little weight |
| **Countdown, last 5s** | one per second, 0.35→0.75 intensity, 0.50→0.80 sharpness | Felt as a ramp rather than counted |
| **Zero** | transient 0.90 / 0.62 + continuous 0.38 / 0.24 for 0.18s | Lands, then releases |
| **Session complete** | three rising transients then a 0.85s swell | Choreographed against Daybreak, not a canned success |
| **Card reveal** | one transient · 0.20 / 0.26 | Softest thing in the vocabulary. An answer arriving, not an action you took |

The constraint that shapes all of it, from `05-platform.md §3`: passing last
time's number must be tellable from an ordinary rep **with the phone face
down**. That rules out patterns differing only in intensity — the hand reads
rhythm and sharpness far better than amplitude — which is why a rep is one event
and the threshold is two.

The countdown fires on **every** timer, the 20-second myo rest included. That
rest *is* the training stimulus, so knowing where you are in it matters more
there, not less.

CoreHaptics for anything with shape; `UIFeedbackGenerator` only for simple
transients. One app-owned engine, with capability checks, reset recovery,
prepared-player caching and one retry of the triggering event.

**Session complete is defined here but not yet wired to a screen.** It belongs
to W7, whose job is the Daybreak choreography it has to land against.

---

## Sound

Six cues, from `05-platform.md §3`. Not yet implemented — they belong to W5,
with the Rest screen — but the design is fixed and recorded here.

| Cue | When | Character |
|---|---|---|
| Countdown tick | Last 5 seconds of every timer | C5 · D5 · E5 · G5 · A5, each slightly louder and longer |
| Go | Zero | C6 with C5 underneath — longer and louder than any tick |
| Confirm | A set is logged | Short, dry, quiet |
| Beat it | The counter passes last time's number | Two rising notes |
| Chime | Session complete, on Daybreak | A major arpeggio resolving up the octave |
| — | Study cards | **Silent, deliberately** |

The count-in **ascends on purpose**: a rising line reads as tension building
toward "go", a falling one as winding down, which is the opposite of what you
want two seconds before a set. Each step is louder and longer than the last so
you can tell where you are without listening for pitch — the phone is on the
floor and you are face-down over it.

### What separates sound from haptics

> Sound is for events you might not be looking at. Haptics confirm something you
> just did.

The study card is where that line is drawn sharpest: a haptic on reveal is
welcome, and sound is **banned**. The app's audio vocabulary is entirely about
time, so a card making a noise during the last five seconds of a countdown would
be actively misleading.

### The audio session

`.playback` with `[.mixWithOthers, .duckOthers]`. Activated around cues and
deactivated after with `.notifyOthersOnDeactivation` — an always-active session
ducks music for the whole twenty minutes, which is exactly the bug Eden reported
against the web build as *"working, and not letting me play music"*.

**The session comes up when the workout opens, not when a cue plays.** A full
hands-free session run produced this the first time a cue sounded:

    AVAudioSession Hang Risk — this method can lead to UI unresponsiveness
    if called on the main thread.

`activate()` was running `setCategory` and `setActive` on the main actor on
*every* cue — five times per rest — and the moment it landed on was the worst
available: the last five seconds of a rest, while `TimelineView(.animation)`
drives the ring. `07-acceptance.md` asks for no dropped frames while a timer
runs, and this was a synchronous IPC call into `mediaserverd` in exactly that
window.

`Audio.prepare()` now runs once when a workout opens, and the session work
happens off the main thread.

**That alone changed nothing measurable, and it took a second full session to
notice.** Session A logged 87 faults over 7 rests; session B, with the fix,
logged 122 over 10 — 12.4 per rest against 12.2. The dominant source was never
our own session calls. It was `AVAudioEngine.start()`, which activates the
session internally, on the main thread, and was being retried on **every cue**
because the headless simulator has no audio route (`error -10879`) so the engine
never starts and never stops trying.

Bounding that retry to one attempt per activation takes it to **1 fault per
rest**. On a device the engine starts once and there should be none.

An interruption — a phone call mid-rest — clears the flags so the next cue
rebuilds session and engine, because otherwise a bounded retry latches and the
rest of the session goes silent.

**The countdown's last five seconds must be one duck, not six pumps.** Six cues
share a release deadline that each one pushes forward, so the music dips once at
five and returns once after zero.

Eden chose countdown reliability over respecting the silent switch.
