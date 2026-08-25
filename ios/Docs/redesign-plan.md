# The redesign, run on Emil Kowalski's skills

Written 2026-08-25, at Eden's request, before any redesign work starts.

**Who reads this.** The design agent that rebuilds the UI, and Eden. It answers
*how and in what order*. It does not answer *what the app must do* — that is
`spec.md`, and `spec.md` wins on every question of behaviour.

Three documents, three jobs:

| Document | Answers |
|---|---|
| `spec.md` | What the app must do. Behaviour only, no UI. **The brief.** |
| This file | How to run the redesign, with which skill, in what order. **The method.** |
| `ios-port/01-product.md` | Who it is for and why. One user, one iPhone, 6:10am. **The why.** |

---

## 1. Can the skills be used? Answered by testing, not by assuming

**Installed.** All twelve, at `~/.claude/skills/`, cloned from
`github.com/emilkowalski/skills`. They sit beside the `frontend-design` skill
that was already there.

They are **user-level, not in this repo.** A fresh clone on another machine does
not have them. To reinstall:

```bash
npx skills@latest add emilkowalski/skills
```

**Not usable in the session that installed them.** Verified — invoking
`apple-design` immediately after install returned `Unknown skill: apple-design`.
The skill registry is snapshotted when a session starts; files added afterwards
are invisible to the `Skill` tool until the next session.

So:

| | |
|---|---|
| Invoke as `/apple-design` in a **new** session | Yes |
| Invoke in the session that installed them | No — verified |
| Read the `SKILL.md` files directly with `cat` | Yes, always. This is what the tool does anyway. |

**Start a new session for the redesign.** Not only because of the registry —
also because the session that built the port is carrying twenty workstreams of
implementation context, and a redesign wants a clean head and a fresh read of
`spec.md`.

**Three skills never auto-trigger.** `prototype`, `review-animations` and
`pick-ui-library` are marked `disable-model-invocation: true`. Phases R3 and R7
below have to be invoked by name; the agent will not reach for them on its own.

**One operational quirk.** `emil-design-eng` prints only a canned greeting when
invoked with no question attached. Always invoke it with the actual question.

---

## 2. What actually applies — this is a SwiftUI app

Emil's skills are web-first. Nine of the twelve assume CSS, React, or the DOM.
The ideas transfer almost completely; the code transfers almost not at all.
Triaged honestly:

### Use in full — the reasoning and the values both transfer

| Skill | Why it applies here |
|---|---|
| **`emil-design-eng`** | The animation decision framework is platform-neutral. Frequency gate, purpose test, asymmetric timing, "when unsure, delete it". The craft bar for the whole programme. |
| **`apple-design`** | The only skill in the set native to this platform. Materials and depth (§12), typography (§15), the eight principles (§16), and a spring model SwiftUI implements *directly*. Highest-value skill in the repo for this app. |
| **`animation-vocabulary`** | Pure language. 100% transferable, and the cheapest win available: it is how Eden says exactly what he wants instead of "it looks goofy". |
| **`write-swift`** | Directly applicable. Note it already agrees with this project — its "stay single-threaded until profiling says otherwise" is `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which is what the project already sets. |

### Use the process, translate the values

| Skill | What transfers | What does not |
|---|---|---|
| **`animate`** | The Build Sequence — should it animate, purpose, cheapest tool, which properties, curve or spring, interruption, reduced motion | CSS transitions, `@starting-style`, WAAPI, Framer Motion |
| **`prototype`** | Divergence discipline: named axes, three real directions, full-size in real context, never touch production code, stop and let the user choose | `PICKER.md` is HTML/CSS/JS. **Do not build it.** See §7 R3. |
| **`find-animation-opportunities`** | The four-question Gate, and the required "rejected candidates" section that keeps it from becoming a wishlist | The grep recipes and CSS values |
| **`improve-animations`** | Recon → audit → vet → self-contained plans. The eight audit categories | The `--ease-*` token values |
| **`review-animations`** | The ten non-negotiables, escalation triggers, the remedial hierarchy, Block/Approve | Roughly half the escalation triggers are CSS-only. See §4. |
| **`animate-expo`** | Read §8 haptics and the device-testing discipline. It is the closest thing in the set to a phone. | Reanimated, Gesture Handler, Expo Router |

### Skip

| Skill | Why |
|---|---|
| **`ask-sonner`** | A React toast library. Nothing in this app is a toast, and there is no React in `ios/`. |
| **`pick-ui-library`** | Curated npm packages. This app has zero third-party dependencies and should keep it that way. |

### Already installed, worth one pass

**`frontend-design`** (Anthropic's, already at `~/.claude/skills/`) is written for
web pages — "the hero is a thesis", type pairing, page-load sequences. Its
*process* is the useful half and it transfers: brainstorm a compact token system
(colour, type, layout, signature), then **critique it against the three looks AI
design defaults to** before writing any code. Run it once, in R2, for the
anti-generic pressure. Ignore its page-layout advice entirely.

---

## 3. Web → SwiftUI, the translation table

Read this before writing a line. Without it, an agent following `animate`
faithfully will put cubic-beziers into SwiftUI where springs belong.

**The headline:** Emil's own recommended spring form is
`{ type: "spring", duration: 0.5, bounce: 0.2 }`, and `apple-design` explains
why — Apple replaced mass/stiffness/damping with two designer-facing parameters.
SwiftUI ships that exact API as `.spring(duration:bounce:)`. The mapping is 1:1,
not an approximation. Prefer it to every cubic-bezier in the skills.

| Web idiom in the skills | SwiftUI | Note |
|---|---|---|
| `{ type: "spring", duration: 0.5, bounce: 0.2 }` | `.spring(duration: 0.5, bounce: 0.2)` | **Identical.** Same model, same numbers. |
| damping `1.0`, response `0.4` | `.spring(duration: 0.4, bounce: 0)`, or `.smooth(duration: 0.4)` | The default. No overshoot. |
| damping `0.8`, response `0.3` (drawer) | `.spring(duration: 0.3, bounce: 0.2)`, or `.snappy` | Bounce only after a gesture carried momentum. |
| `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)` | `.timingCurve(0.23, 1, 0.32, 1, duration:)` | Available, but reach for a spring first. |
| `transition: transform 160ms ease-out` on `:active` | `ButtonStyle` reading `configuration.isPressed`, `.scaleEffect(0.97)`, `.animation(.snappy(duration: 0.16), value:)` | |
| `transform-origin: var(--transform-origin)` | `.scaleEffect(_:anchor:)` with the anchor at the trigger | Same principle, different spelling. |
| `scale(0.95)` + `opacity: 0` entry | `.transition(.scale(scale: 0.95).combined(with: .opacity))` | Never `.scale(scale: 0)`. Same rule. |
| CSS transitions retarget, keyframes restart | `withAnimation` / `.animation(_:value:)` retarget; `.keyframeAnimator` and `.phaseAnimator` restart | **Exactly the same distinction.** |
| "Only animate transform and opacity" | `.scaleEffect`, `.offset`, `.opacity`, `.rotationEffect` — **not** `.frame(width:)`, `.padding()` | Layout properties are expensive in SwiftUI too. |
| `@starting-style` | `.transition(...)` plus a changing `.id()`, or `.onAppear` with a spring | |
| `prefers-reduced-motion` | `@Environment(\.accessibilityReduceMotion)` | Already used in `MetalSky.swift`. |
| `prefers-reduced-transparency` | `@Environment(\.accessibilityReduceTransparency)` | Already used. |
| `prefers-contrast: more` | `@Environment(\.colorSchemeContrast)` | Not yet handled anywhere. Gap. |
| `@media (hover: hover) and (pointer: fine)` | **Nothing. Delete the category.** | iPhone-only app. There is no hover. Every hover rule in every skill is dead here. |
| `backdrop-filter: blur(20px) saturate(180%)` | `.background(.ultraThinMaterial)` / `.regularMaterial` / `.thickMaterial` | The real thing, not the web approximation. Material weight encodes hierarchy — `apple-design` §12. |
| `filter: blur(2px)` to mask a crossfade | `.blur(radius: 2)` | Same trick, same reason. |
| Velocity handoff, `project(v, 0.998)` | `DragGesture.Value.predictedEndTranslation`, or a spring's `initialVelocity` | UIKit's projection is already inside `predictedEndTranslation`. |
| Framer Motion `x`/`y` not GPU-accelerated | Not a thing. No equivalent trap. | Delete the finding class. |
| WAAPI | Not a thing. | |
| CSS variable recalc storms | Not a thing. SwiftUI's equivalent failure is a too-broad `@Observable` dependency causing over-invalidation. | Different mechanism, same category: watch what invalidates. |
| Digit morphing | `.contentTransition(.numericText())` | Already used on the rep counter. |
| `requestAnimationFrame` | `TimelineView(.animation(minimumInterval:paused:))` | Already used for the sky at 12fps. |

**One SwiftUI trap with no web equivalent, and it has already cost this project
twice:** an implicit animation that silently does nothing. `withAnimation` inside
`onAppear` and `.transaction { $0.animation = nil }` placed outside an
`.animation(_:value:)` both compiled, both read correctly, and both did nothing
on screen. Neither was caught by inspection. Both were caught by filming the
simulator and stepping frames. **Every motion change in this redesign gets
looked at in a captured frame, not reasoned about.** `ios/Tools/frames.swift`
exists for exactly this.

---

## 4. Review triggers that do not apply here

`review-animations` lists fourteen escalation triggers. Six are CSS-only and
will produce zero findings in a Swift codebase. Do not go hunting for them, and
do not report their absence as a pass:

`transition: all` · Framer Motion `x`/`y` props · CSS-variable recalc storms ·
`@media (hover: hover)` gating · `@starting-style` · WAAPI

The eight that *do* apply, restated in SwiftUI terms:

1. `.scale(scale: 0)` entrances, or a bare `.opacity` fade with no transform
2. Ease-in on anything entering — SwiftUI's `.easeIn`, or a timing curve that starts slow
3. UI motion over 300ms with no stated reason (**see the carve-out in §5**)
4. Centre anchor on something that should scale from its trigger
5. `.keyframeAnimator` / `.phaseAnimator` on anything triggered rapidly
6. Animating `.frame`, `.padding`, or layout-affecting modifiers
7. Missing `accessibilityReduceMotion` handling on movement
8. Symmetric enter/exit timing on a press-and-release or hold interaction

---

## 5. Settle these before starting

Five places where the skills and this app disagree. Each is resolved here so the
design agent does not resolve it wrongly at 2am.

### 5.1 Ambient motion is not UI motion, and the sub-300ms rule does not reach it

`review-animations` blocks UI motion over 300ms. The dawn sky drifts for twenty
minutes; the Daybreak sequence runs 4.4 seconds. **Neither is UI motion.** They
are environmental — not triggered by the user, not on the input path, not
between the user and a decision. The rule is about the moment a user is watching
for a response, and there is no response being awaited here.

Checked against the one rule that *does* govern ambient motion —
`apple-design` §14, avoid slow looping oscillations near 0.2 Hz — the cloud
strata cross the screen in roughly three minutes, two orders of magnitude
slower. Compliant.

**Do not delete or shorten the sky, Daybreak, or the celebration beats citing a
duration rule.** They are the product.

### 5.2 Measured values outrank the skills' defaults

`improve-animations` Hard Rule 5 says do not re-litigate documented tradeoffs.
Pointing it at the right files, these were measured on rendered frames and are
not opinions:

| Decision | Where the measurement lives |
|---|---|
| Every contrast figure, sampled on real frames with glyph-row snapping | `ios/Docs/design-system.md` |
| The 6.6:1 app floor, and why the calculated figures lied | `ios/Docs/prototype-directions.md` |
| Bone lengths constant within 2% across the phase sweep | `ios/MorningTests/FigureAnatomyTests.swift` |
| The sky's 12fps cap and why the eye cannot tell | `ios/Morning/Screens/MetalSky.swift` header |
| Why the sky is one shader pass, not eight composited layers | `ios/Morning/Shaders/Sky.metal` header |

Change any of them if there is a better answer. Do not change them because a
skill's table suggested a different number.

### 5.3 The workout loop gets *less* motion, not more

This is counter-intuitive against a brief that says "make it beautiful", and it
is the most important conclusion in this document. See §6.

### 5.4 Content is fixed

`CLAUDE.md` rule 3 and `spec.md` both hold. Exercise names, cues, targets, rest
seconds, celebration copy, card text and Guide text are ported verbatim and are
not the design agent's to improve. The copy pass is **done** —
`ios/Docs/copy-pass.md` — and all 59 em-dashes are already resolved. Do not
reopen it.

### 5.5 iPhone 16 Pro only

402x874. Do not boot an SE. Do not treat an SE regression as a defect. Do not
spend effort on device-class responsiveness. Eden was explicit about this twice.

---

## 6. The frequency map — apply Emil's gate to this app

Every skill in the set hinges on one question: *how often will a user see this?*
Answered for Morning, per session of roughly 20 minutes and 14 sets:

| Surface | Times seen | Emil's tier | Verdict |
|---|---:|---|---|
| Rep +/- adjust | dozens per session | Tens/day | **Near-zero motion.** Press feedback only, under 160ms. |
| Set screen arrival | ~14 | Tens/day | **Reduce hard.** A counter that "arrives" is a counter that is late. |
| Step advance (Done) | ~28 | Tens/day | **Reduce hard.** |
| Rest screen arrival | ~13 | Tens/day | **Reduce hard.** |
| Ring completion | ~13 | Tens/day | Reduce. The ring itself is the information. |
| Study card reveal | a few | Occasional | Standard. This one is a *reveal*, so it earns a beat. |
| Home arrival | 1–2 | Occasional | Standard. |
| End-session confirm | rare | Occasional | Standard. Destructive, so slow the deliberate half. |
| The completion moment | 1 | Rare | **The delight budget. Spend it here.** |
| Celebration tiers | weekly / monthly | Rare | Delight. |
| First run, empty states | once | First-time | Delight. |
| The 13 → 14 crossing | rare by design | Rare | **The emotional centre of the product.** |
| History, Ledger, Guide, Backup | rare | Occasional | Standard, restrained. |
| The dawn sky | continuous | *not a tier* | Ambient. See §5.1. |

**What this means.** The twenty minutes the app spends being used is the tier
where Emil's framework says to remove motion, and the four seconds at the end
are where it says to spend everything. Almost all the visible motion budget
belongs to a moment that happens once.

Worth noting because it is not a coincidence: this is the same conclusion the
product brief reached independently, from the other direction — *"the 13 → 14
threshold crossing is the emotional centre"*. The framework and the brief agree.
That is a good sign for both.

**The corollary the design agent will find hardest:** the Set screen, the most
important surface in the app, should be the *least* animated. Its job at 6:10am
with sweaty hands and the phone 1.5m away is to be legible instantly and respond
in the hand. Every frame it spends transitioning is a frame it is not readable.
This project has already removed two Set-screen animations for exactly this
reason (a `matchedGeometryEffect` on the counter, and a counter identity that
re-animated per set) and both removals were improvements Eden noticed.

---

## 7. The phases

Nine, run in order. Numbered **R** to avoid colliding with the `W` workstreams
in `ios/Agents/workstreams.md`, which continue in parallel. They begin after
W18 lands.

Each phase names its skill, its output, whether it may touch production code,
and the gate that ends it.

---

### R0 · Ground, and close the harness gap — *no skill*

**Read first:** `spec.md` end to end, `ios-port/01-product.md`,
`ios-port/02-design-brief.md`, `spec.md` §13 ("what must never regress"), and
`ios/Agents/00-handoff-log.md`.

**Then run the web app** and do a full session of A and a full session of B.
`ios-port/README.md` puts this in the first-session checklist and it is still
right: you cannot design the replacement for something you have not used.

**Then close the one real tooling gap.** The Swift side of the review harness is
committed and good — `-screen set | summary | figures | sky | metal |
live-activity | lab`, the reading screens by their `HomeDestination` name, and
flags like `-session B -step 15 -progress 0.62`. Note there is **no
`-screen rest`**: rest is reached through the set host at a step that is a rest,
which is also how the app reaches it. The *driver* that builds, boots, launches and screenshots is
not. It has been re-derived as an ad-hoc shell function in every session that
needed it, and it broke once already because zsh does not word-split
(`shoot history "-screen history"` passed one argument, and four screens
silently rendered Home).

Commit it as `scripts/shoot.sh`, taking a screen name and passing the rest
through. Every later phase depends on being able to look at things cheaply, and
R3 cannot run at all without it.

**Output:** `ios/Docs/redesign/00-brief.md` — the screen inventory, the frequency
map from §6 confirmed or corrected, and the regression list.
**Touches production code:** no.
**Gate:** `scripts/shoot.sh` renders all eleven surfaces from `spec.md` §3 into
PNGs, and the agent has looked at every one.

---

### R1 · The motion doctrine — `emil-design-eng`

Invoke it *with a question*, not bare.

Pose the app to it: the frequency map from §6, the eleven surfaces, the
6:10am/sweaty-hands/1.5m context. Ask it to rule, surface by surface, on what
animates and what must never.

The output is not a list of animations to build. It is a **doctrine** — the
standing answer to "should this animate at all" for each surface, so that R4
does not re-argue it eleven times.

**Output:** `ios/Docs/redesign/01-motion-doctrine.md`.
**Touches production code:** no.
**Gate:** every surface in `spec.md` §3 has a tier and a verdict, and the
doctrine states explicitly which surfaces get *no* motion.

---

### R2 · The foundation — `apple-design`, then `frontend-design`

The visual system: materials and depth, typography, colour, the spring
vocabulary. Two skills, in this order, because they pull in opposite and
complementary directions.

**`apple-design` first**, for platform correctness:

- §12 materials — the app currently draws its own scrims and gradients over the
  sky. Real `Material` may do this better, and it is the one place the app has
  been approximating something the platform ships. *Check it against the
  measured contrast floor before adopting it; §5.2 applies.*
- §15 typography — size-specific tracking, leading that tracks size inversely,
  hierarchy from weight rather than size alone. The app has a `TypeScale` today;
  this is the standard to hold it to.
- §4 springs — establish the two-value house style (`duration` + `bounce`) and
  put it in `DesignMotion.swift`, replacing anything expressed as a raw curve
  that would read better as a spring.
- §16 the eight principles — the names to reason with for the rest of the
  programme.

**`frontend-design` second**, for one thing only: its critique step. Take the
token system and ask whether any part of it is the generic default rather than a
choice made for *this* brief. Ignore everything it says about page layout and
heroes.

**Output:** an updated `ios/Docs/design-system.md` (655 lines today, already
real — this revises it, it does not replace it), plus `DesignTokens.swift` and
`DesignMotion.swift`.
**Touches production code:** tokens only. No screens.
**Gate:** every contrast figure re-measured on rendered frames with
`ios/Tools/measure-contrast.py`, floor still 6.6:1. Not calculated. Not
estimated by eye. Both of those were tried on this project and both lied.

---

### R3 · Three directions for the Set screen — `prototype` — **HARD GATE**

This is `ios-port/README.md` rule 1 and workstream W1 restated: design before
you build, get agreement on the look first, and it is the first deliverable
rather than the last.

**One screen. The Set screen.** It is roughly 70% of the time the app is open,
it is the surface `spec.md` calls "the most important", and every other screen
inherits from whatever it settles.

**The picker.** `prototype`'s Hard Rule 4 says copy `PICKER.md` verbatim. That
file is HTML, CSS and JS. **Do not build it.** The equivalent here already
exists and is better: `-screen` review hosts plus `scripts/shoot.sh` from R0.
Add `-variant quiet|<name>` alongside the existing flags. This satisfies the
rule's *intent* — one variant at a time, full size, in realistic context,
instant switching — on the right platform. Note the deviation in the handoff log
so the next agent does not think it was an oversight.

Everything else in the skill holds, and holds hard:

- **Three variants, each on a named axis.** Not three tints. If two would differ
  only in accent colour, they are one direction; replace one.
- **Real content.** Real exercise names, real weights, a real rep history, the
  longest possible name, four cues.
- **Never touch production code.** Variants live in the lab.
- **Present the table, then stop.** The choice is Eden's.

Sell each honestly: one line on when it wins, one on what it costs. Do not
pre-pick a favourite in the table.

**Output:** three running variants plus the tradeoff table.
**Touches production code:** no.
**Gate:** Eden picks one. **Nothing downstream starts until he does.**

---

### R4 · Build it — `animate` for sequence, `apple-design` for values, `write-swift` for code

Screen by screen, in this order — most-used first, so the thing that matters
most gets the most iterations:

1. **Set** — the chosen direction, promoted out of the lab
2. **Rest** — including the study deck reveal
3. **Home** — including the week meter
4. **The completion moment and Summary** — where the delight budget is spent
5. **Warm-up**
6. **History, Lifetime totals, Guide, Backup** — the reading screens

Use `animate`'s Build Sequence as the per-decision checklist (should it animate,
purpose, cheapest tool, which properties, spring or curve, interruption, reduced
motion), and take every actual value from the §3 translation table rather than
from the skill's CSS.

**Two things `spec.md` specifies that have never been rendered.** Both were
deliberately left for this rebuild rather than patched into views that were
about to be replaced. Neither is a design choice — both are specified behaviour
that is currently missing:

- `Celebration.rays` has no reader, so a plateau currently looks identical to a
  personal best
- `SetStep.intense` has no reader (the web build shows a MYO badge)

**Read `animate-expo` §8 before doing haptics.** It is the only haptics guidance
in the set, and `apple-design` §13 sets the bar: the visual, the sound and the
haptic must fire on the *same frame*, or the illusion breaks.

**Every motion change gets filmed.** `xcrun simctl io recordVideo`, then
`ios/Tools/frames.swift` to pull exact frames. See the trap in §3.

**Output:** the rebuilt app.
**Touches production code:** yes. This is the build.
**Gate:** the ten-item "definition of done" in `CLAUDE.md`, all of it, per
screen. Plus: nothing scrolls inside a workout, ever.

---

### R5 · What did we leave flat — `find-animation-opportunities`

Read-only. Runs on the *rebuilt* UI, not the old one.

Its value is the filter, not the finder. Capped at 5–7 for the whole app, and
**Part 2 is required** — two to five places deliberately rejected, each with the
gate question that killed it. A run of this skill that produces no rejections
has been run wrong.

Given §6, expect most candidates to die on frequency. That is the correct
outcome, not a failure.

**Output:** the opportunities table, the rejected table, and a one-paragraph
verdict.
**Touches production code:** no.

---

### R6 · Audit and plans — `improve-animations`

Recon, audit against the eight categories, vet every finding at its `file:line`,
present ordered by leverage, then write self-contained plans into `plans/`.

Two adjustments for this repo:

- Audit categories 1–4, 6–8 apply as written. **Category 5, Performance, needs
  rewriting for SwiftUI** — see §4. The web failure modes are not this app's
  failure modes.
- Hard Rule 5, do not re-litigate settled decisions: point it at the file list
  in §5.2.

Plans are written for an executor with zero context and zero taste. Exact paths,
exact values, exact excerpts. And every plan gets a **feel-check step** — slow
motion or frame-by-frame — because none of this can be judged from code.

**Output:** `plans/NNN-*.md` plus `plans/README.md` with execution order.
**Touches production code:** no, by hard rule. `improve-animations execute
<plan>` does the applying.

---

### R7 · The merge gate — `review-animations`

Must be invoked explicitly; it will not trigger on its own.

Run against the whole diff. Findings table with Before/After/Why, then a verdict
grouped by impact tier, then **Block or Approve**.

Approval is earned. Use §4's list so the review is run against the eight
triggers that exist in Swift rather than the fourteen that exist in CSS.

**Output:** the table and an explicit verdict.
**Touches production code:** no.
**Gate:** Approve. A Block sends specific items back to R4.

---

### R8 · Code health — `write-swift`

A sweep over everything R4 wrote: value types, Swift 6 data-race safety,
`some` vs `any`, API clarity, ARC, and Swift Testing.

Consult it *during* R4 as well. It is at the end because it is a sweep, not
because it is an afterthought.

One note: the project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
deliberately, and the skill agrees with that choice. Add `nonisolated` only
where the compiler asks. Never `@unchecked Sendable` or `nonisolated(unsafe)` to
silence it.

**Output:** a clean `./scripts/verify-ios.sh`.
**Touches production code:** yes.

---

## 8. Standing, not a phase — `animation-vocabulary`

The one skill Eden should read himself rather than have an agent run.

It is a reverse-lookup glossary: describe a motion vaguely, get the exact term.
"The bouncy thing when a popover opens" → *Pop in*. "The iOS rubber-band scroll"
→ *Rubber-banding*.

Its value here is specific and practical. Feedback like *"the overhead press
animation is terrible"* and *"the rep number animates wildly"* both turned out
to be right and both cost a round trip to diagnose. The vocabulary is how the
next one arrives already diagnosed.

---

## 9. What must never regress

`spec.md` §13 is the list and it is binding. The three the design agent is most
likely to break while making things beautiful:

1. **Nothing scrolls inside a workout. Ever.** Not at the largest Dynamic Type
   size it claims to support, not with the longest exercise name, not with four
   cues.
2. **Rep controls stay at or above 78pt; primary actions at or above 64pt.**
   Sweaty hands, 6:10am. This is not a guideline.
3. **No gamification.** No points, no badges, no levels, no "Great job!". Every
   headline states something true and specific. The reward for finishing is
   being told exactly what you did, well.

And one that is about this document rather than the app: **`spec.md` is updated
in the same commit as any behaviour change.** The redesign should not change
behaviour at all — but if it does, `spec.md` moves with it, or the next rebuild
starts from a lie.

---

## 10. Summary

| Phase | Skill | Output | Code | Gate |
|---|---|---|---|---|
| R0 | none | Brief, inventory, `scripts/shoot.sh` | no | All eleven surfaces render |
| R1 | `emil-design-eng` | Motion doctrine | no | Every surface has a verdict |
| R2 | `apple-design`, `frontend-design` | Design system, tokens | tokens | Contrast re-measured, floor 6.6:1 |
| R3 | `prototype` | Three Set-screen directions | no | **Eden picks** |
| R4 | `animate`, `apple-design`, `write-swift` | The rebuilt app | yes | `CLAUDE.md` definition of done |
| R5 | `find-animation-opportunities` | Opportunities + rejections | no | Rejections present |
| R6 | `improve-animations` | `plans/` | no | Plans self-contained |
| R7 | `review-animations` | Verdict | no | **Approve** |
| R8 | `write-swift` | Code health | yes | `verify-ios.sh` clean |

Two skills skipped, with reasons: `ask-sonner`, `pick-ui-library`.
One hard gate: **R3**. Nothing visual proceeds until Eden has picked a direction.
