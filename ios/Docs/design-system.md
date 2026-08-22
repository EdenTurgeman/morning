# Design system

Deliverable 4 of `ios-port/02-design-brief.md §11`. Written **after** the
direction was agreed, which is the point of the ordering.

The code half of this document is three files, and they are the source of truth
for values:

| File | Holds |
|---|---|
| `ios/Morning/DesignTokens.swift` | The dawn ramp, ink levels, semantic colour, surfaces, type scale, spacing, hit targets, the legibility scrim |
| `ios/Morning/DesignMotion.swift` | Curves, durations, drift periods, hold-to-repeat, and every reduced-motion form |
| `ios/Morning/DesignHaptics.swift` | The haptic vocabulary, as data |

**Every contrast figure in this document was measured on rendered simulator
frames**, across progress 0.00 → 1.00, using a harness that snaps to the glyph
rows before sampling. It is not calculated from declared alphas, and it is not
estimated by eye. Both of those were tried first and both lied — see
`prototype-directions.md`.

---

## Direction

**A · Dawn, done properly** — the Atmospheric treatment.

Eden reviewed three running native executions of the same load-bearing idea
(Atmospheric, Precise, Tactile; `prototype-directions.md`) and chose
Atmospheric. Precise and Tactile remain runnable in the lab as frozen
comparison artifacts; they are not part of this system and do not constrain it.

The idea being executed is the one `02-design-brief.md §3` describes and which
the web build already proved:

> The app's entire colour is a function of how far through the session you are.
> It starts at astronomical twilight and walks the actual phases of a dawn as
> you work, arriving at gold as you finish.

Two consequences that justify the whole system. You can tell how far through the
workout you are **from across the room, without reading anything**. And the
session ends at sunrise, which is when it is actually happening.

---

## Colour

### The dawn ramp

Five stops, hand-picked from the phases of a real dawn. Not generated — the web
build's `src/lib/sunrise.ts` is blunt about why: *"a formula gave an even ramp;
it did not give a sunrise."* Lightness climbs monotonically because dawn gets
brighter; chroma peaks in the middle, where the sky is genuinely at its most
saturated, then eases back into the golden light.

| t | Colour | Phase |
|---|---|---|
| 0.00 | `#6F80E0` | astronomical twilight — deep indigo |
| 0.26 | `#A974E3` | nautical — violet lifts off the horizon |
| 0.50 | `#ED6BAF` | civil — the rose band, sky at peak chroma |
| 0.74 | `#FF8271` | first light — coral |
| 1.00 | `#FFB440` | sunrise — gold |

Interpolated with `Color.mix(in: .perceptual)`, which is the native equivalent
of the web build's OKLCH walk. A straight line through a perceptual space looks
like a straight line; the same walk in HSL visibly surges and dips.

The accent drives the progress bar, the timer ring, the primary action fill and
the horizon light — all sampling one live value, which is what makes progress
legible without text.

### The rule that took a measurement to find

> **The raw `accent` fills and lights. `accentText` writes.**

The ramp's values are chosen to be a *light source*. Used as small glyphs on a
lit sky, its darker end measures **4.59:1** — barely over AA and far under this
app's own tertiary bar. `DawnPalette.accentText` lifts the live accent 42%
toward white, which reads 7.37:1 at twilight and 8.75:1 at gold while staying
unmistakably accent-family.

This was found by measuring the study card's topic label, not by looking at it.

### The zenith is not the accent

Rayleigh scattering is wavelength-dependent, so the top of a real sky stays deep
blue even at the height of a sunrise; only light coming through the thickest
atmosphere, at the horizon, turns warm. `DawnPalette.zenith` is therefore its
own near-black blue that brightens slightly with progress and never takes the
accent hue.

A sky that takes the accent everywhere reads as a coloured wash rather than as
sky. The web build learned this and said so; the first native port had not read
that comment.

### Ink, and the bar it clears

`02-design-brief.md §6` sets the target: *"The current palette holds 18:1 /
10:1 / 6.6:1 for its three text levels — match or beat that."*

Measured across progress 0.00 → 1.00 on Set, Rest and the study card:

| Level | Token | Used for | Measured span |
|---|---|---|---|
| Primary | `Ink.primary` | Exercise name, rep count, timer | **12.15 – 19.00:1** |
| Secondary | `Ink.secondary` | Sub-label, load, set position, cues | **7.65 – 11.41:1** |
| Tertiary | `Ink.tertiary` | `Reps`, `MOVEMENT`, footer, meta lines | **6.90 – 9.04:1** |
| On accent | `Ink.onAccent` | The primary action's label | **5.84 – 6.98:1** — see below |

**Where this does and does not beat the web palette, stated honestly.** The web
figures are measured against a flat near-black background. This sky is lit at
the bottom by design, so pure white reads 19.00:1 at the top of the screen and
**12.15:1 over the rep counter**, which sits on the brightest region. Primary
therefore beats the web's *secondary* bar everywhere but does not reach 18:1 at
the counter, and it never will while the sky carries progress. That is the trade
the direction makes.

What matters more, and what does hold everywhere: **the weakest text on any
screen at any progress is 6.98:1**, against a 6.6:1 floor — and the three levels
stay clearly separated, which is what makes the hierarchy readable rather than
just compliant.

Scoring elements against per-level bars was tried and abandoned: it turns into
moving an element between levels until it passes. One floor, plus the range each
level actually spans, is the honest report. `ios/Tools/measure-contrast.py`
prints exactly that.

`Ink.hairline` is furniture only — rails and dividers. It never carries glyphs.

**One correction worth recording, because the mistake is easy to repeat.**
`Ink.tertiary` was first written down as `white 0.62`, taken from the
prototype's measured results — without checking what the prototype was actually
using. Its labels were at 0.72 and had never been switched to the token, so the
number in this table had been measured against a value the token did not have.

Built on the real Set screen, `0.62` delivered **5.98:1** against a 6.6:1 floor.
The token is now 0.72 and the screen measures 6.90:1 at its weakest, at gold.

A token that does not deliver the figure recorded beside it is worse than no
token, and only building the real screen on it exposed the gap. Rebuilding the
prototypes on the tokens was supposed to catch exactly this and did not, because
the prototype kept its literals in the places that mattered.

### The one measured exception

The primary button label reads **5.84:1 at progress 0.00**, rising to 6.98:1 by
mid-session. At twilight the accent is a mid-lightness indigo, so black-on-accent
cannot reach 6.6:1 there.

Left alone deliberately. 6.6:1 is the bar for *tertiary body text*; this is a
68pt filled control whose label clears WCAG AA for large text nearly twice over.
The alternative — lightening the accent at low progress — would distort a ramp
whose five stops are hand-picked and load-bearing. Damaging the app's central
idea to move a button label from 5.84:1 to 6.6:1 is the wrong trade.

### Semantic colour, kept off the ramp

`§6` requires these to live outside the accent ramp so they can never collide
with whatever the accent happens to be at that moment.

| Token | Colour | Means |
|---|---|---|
| `Semantic.threshold` | `#59E0AD` mint | You passed last time's number |
| `Semantic.urgency` | `#FFC257` amber | The 20-second myo rest — which *is* the training stimulus |

Mint was lifted from `#33D399` after measurement: as a 92pt numeral it read
6.03:1 — comfortably fine for text that size, but under this app's own floor.
Ten percent more luminance clears it at 6.95:1 without the colour becoming
anything other than mint, which is better than carrying a second documented
exception.

Mint is worth a second note. Held at 2m, the words *"Beating last time's 13"* have gone
soft while the mint is still unmistakable. Colour outliving text is the correct
order for this to degrade in, because the state matters more than the sentence.

### The legibility scrim

A richer sky costs contrast — the exact risk `§5` names for this direction:
*"the risk is mush — atmosphere fighting legibility at 6am."*

The scrim sits **behind** content, so it lowers background luminance without
touching the glyphs. That is what makes it buy contrast rather than cost it: a
veil over both would make things worse.

It is a function of progress, because the sky it holds back is. A fixed scrim
that cleared the bar at twilight let the cue text, `Reps` and the footer fall to
6.2–6.5:1 by the time the palette reached gold.

```
location  0.00   0.30
location  0.38   0.14 + 0.04·progress
location  0.58   0.20 + 0.08·progress
location  0.78   0.48 + 0.08·progress
location  1.00   0.64 + 0.07·progress
```

Near-black and faintly blue (`Surface.ink`), never pure black — pure black
flattens the night out of the sky.

### Control boundaries

WCAG 2.1 SC 1.4.11 asks for **3:1 on the boundary of a UI component**, and the
first Atmospheric rep control measured **1.18:1** — a `white 0.07` fill behind a
`white 0.1` hairline, over a lit sky. Its glyph was fine at 9.71:1, so the
symbol was doing all the work and the button had no shape at all.

That matters more here than the number suggests: this is the control a
half-awake person hits with a knuckle from a metre away, and an 82pt target is
worth nothing if you cannot see where it is. It only surfaced because the
control was measured as a *component* rather than as text — the text harness had
been giving it a clean bill of health all along.

| Token | Value | For |
|---|---|---|
| `Control.surface` | `white 0.10` | Quiet enough to sit under a 92pt counter |
| `Control.border` | `white 0.44`, 1.5pt | The edge that makes the target findable |
| `Control.quietBorder` | `white 0.30` | A deliberately subordinate control — `+15s` beside `Skip` |

Measured after: rep control **3.51:1**, Rest's `+15s` / `Skip` **4.10:1**. The
surface stays at ~1.3:1 against the sky, which is the point — the design goal
was "quiet", and it was never "invisible".

The `−` and `+` glyphs also went from 34pt medium to 38pt semibold. At 1.5m the
old ones were the first thing to disappear.

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

The sky is the material. `PrototypeSky.swift`, eight layers:

| Layer | Carries | Motion |
|---|---|---|
| Base + `MeshGradient` | The dawn palette; zenith blue, horizon warm | with progress |
| Ozone band | The purple-pink band between blue zenith and warm ground | opacity peaks mid-session on a sine |
| Haze | Atmosphere is denser near the ground | with progress |
| Stars | How early it still is | twinkle on individual phases; thin out with progress |
| Meteor | That the sky is not a loop | one per ~11s while stars are visible |
| Crepuscular rays | The sun, without a sun — strengthening with progress | 150s drift |
| Two cloud banks | Depth, through parallax | 200s and 128s |
| Grain | Stops the gradients banding on OLED | static, deliberately |

Decisions inside it:

- **Cloud noise is baked once** into a tiling `CGImage`, then translated. Live
  noise across a screen held awake for twenty minutes is not affordable; a
  translated bitmap is free. The web build makes the same call.
- **The streak ratio is the trick.** Low frequency across x, high down y. The
  first attempt inverted it and produced vertical streaks, which read as screen
  noise rather than cloud.
- **One tile covers the band vertically.** A vertically repeating tile reads as
  banding — the opposite of cloud.
- **No sun disc and no bottom halo.** Both were removed as decoration competing
  with the copy and they stay removed. The rays are the sun's presence without
  its body.
- **Liquid Glass is a control layer, never a content background.** It is limited
  to controls the user actually manipulates, grouped in one
  `GlassEffectContainer`, and Reduce Transparency replaces it with opaque
  bordered surfaces.

No third-party animation dependency. `MeshGradient`, `Canvas`, `TimelineView`
and baked `CGImage` tiles cover all of it — the gates are in
`technical-decisions.md` and nothing has cleared them.

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
| `Motion.commit` | spring 0.32s, bounce 0.24 | linear 0.01s | Something was committed; a little weight |
| `Motion.stage` | easeInOut 0.44s | linear 0.12s | Set ↔ Rest, carrying the work object across |
| `Motion.reveal` | spring 0.50s, bounce 0.12 | easeOut 0.18s | The answer arriving |
| `Motion.timerResize` | spring 0.55s, bounce 0.10 | easeOut 0.18s | The timer yielding its space to the card |

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

**The countdown's last five seconds must be one duck, not six pumps.** Six cues
share a release deadline that each one pushes forward, so the music dips once at
five and returns once after zero.

Eden chose countdown reliability over respecting the silent switch.
