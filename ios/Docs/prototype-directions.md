# W1 native Dawn prototypes

Running comparison build for Set and Rest. These are direction tests, not the
application architecture and not finished screens.

## Open the lab

Run the app normally to choose:

- Atmospheric Dawn
- Precise Dawn
- Tactile Dawn
- Set or Rest
- hardcoded comparison state
- session progress

Launch arguments open deterministic states directly:

```text
-prototype atmospheric-set
-prototype atmospheric-set-beating
-prototype precise-set
-prototype precise-set-beating
-prototype tactile-set
-prototype tactile-set-beating
-prototype atmospheric-rest
-prototype atmospheric-rest-snapshot
-prototype atmospheric-card
-prototype atmospheric-card-snapshot
-prototype atmospheric-card-menu
-prototype precise-rest
-prototype precise-rest-snapshot
-prototype tactile-rest-snapshot
-prototype tactile-myo-rest
-prototype tactile-myo-rest-snapshot
-prototype atmospheric-set-long-content
```

Appending `snapshot` freezes a Rest at 45 seconds (5 seconds for myo) so
treatments can be compared in the same state rather than at arbitrary capture
times. Appending `autoplay` to a Set launch value advances it into Rest after
1.2 seconds for transition review.

## Shared contract

Every treatment uses the same fixed product behaviour:

- one screen and one primary action
- 82pt rep controls
- bodyweight first-run default 10; loaded default 12
- same-slot/same-weight previous value adjacent to the counter
- a deterministic 13 → 14 threshold-crossing state
- changed-weight history explicitly non-comparable
- automatic absolute-time Rest
- `+15s` and `Skip →`, no invented Rest control
- automatic silent card reveal at 9.6 seconds on a 60-second Rest
- 20-second myo Rest with no study card
- no scrolling inside Set or Rest

The lab includes first run, comparable, changed weight, superset, myo, longest
Set content, plain Rest, longest card answer, and myo Rest fixtures.

## Atmospheric Dawn

Hypothesis: progress is fastest to understand when the environment itself gets
lighter.

- authored five-stop perceptual sunrise interpolation
- MeshGradient sky whose luminance and stars change only with session progress
- unboxed counter and simple controls with no broad bloom behind content
- ring remains supporting evidence around a dominant number

Watch for atmosphere making text feel soft or visually noisy.

## Precise Dawn

Hypothesis: Morning can retain warmth while making the previous-set threshold
feel exact.

- the same sunrise is quieter behind the content
- calibration rail and threshold notch under the rep count
- squared hairline controls and dashed timer depletion
- progress reads through illumination as well as hue

Watch for the interface becoming cold or generic.

## Tactile Dawn

Hypothesis: object continuity and physical response create the largest native
upgrade.

- one lit counter object becomes the Rest timer
- interactive Liquid Glass only on controls touched by the user
- opaque reading surfaces and stable contrast for content
- pressure, numeric travel, ordinary detent, and double threshold haptic

Watch for unnecessary skeuomorphism or material effects competing with the
exercise.

## Motion and haptics

- Rep changes use directional numeric transitions.
- Hold repeat accelerates from 380ms to a 60ms floor.
- Ordinary rep, passing last time, logging, and card reveal have distinct Core
  Haptics patterns.
- The manipulated work object uses matched geometry between Set and Rest:
  an unboxed number becomes a ring, a calibrated number becomes timer ticks,
  and the tactile counter becomes the tactile timer.
- Atmospheric changes dissolve, Precise changes use a short 12pt calibrated
  translation, and Tactile changes use a restrained spring.
- Card reveal transfers space from the timer to text instead of flipping a card.
- Reduce Motion preserves state through short opacity changes, without
  matched-geometry travel, and shows static start/end exercise positions.

The simulator proves layout, timing, material, and compilation. Haptic quality
still requires the physical iPhone 16 Pro.

## Current evidence

- All three Set treatments fit the iPhone 16 Pro without scrolling.
- Plain Rest, longest revealed card, and myo Rest fit with controls visible.
- The counter, exercise, and Rest time remain the dominant distant-reading
  elements.
- `./scripts/verify-ios.sh` remains green with 53 acceptance assertions present
  and 53 intentionally skipped at W1.

## Second-pass corrections

The first visual review rejected the prototypes as one shared layout with three
skins. The second pass changed the concepts rather than polishing that result:

- Atmospheric originally added an authored horizon and sun; the focused lead
  pass below later removed both after they stopped earning their space.
- Precise removes the sky entirely. Its grid, relative threshold rail, and timer
  ticks correspond to real values.
- Tactile reduces glass to the manipulated control layer. The counter/timer
  object compresses, tilts, seats a rim detent, and uses an opaque primary
  action.
- Previous reps moved into every counter rather than remaining a subtitle.
- Passing the threshold now uses semantic mint, deliberately outside the Dawn
  progress ramp.
- Compact card timers increased to 64pt inside a 136pt ring.
- Low-contrast labels were raised and dashboard-like uppercase tracking reduced.
- Myo mechanism copy uses separate amber urgency; `+15s` remains 64pt but is
  visually subordinate.
- Reduced Motion removes object tilt and numeric travel and shortens timer/card
  geometry changes.

## Interaction-audit corrections

A separate code audit then exercised the prototypes as controls rather than
screens:

- The app explicitly opts into ProMotion through
  `CADisableMinimumFrameDurationOnPhone`; the built Info.plist is checked.
- Rest zero and Skip now advance into the next Set. Zero plays a shaped
  transient-plus-decay pattern; Skip confirms without impersonating zero.
- `+15s` extends from the later of the saved end date or now, so an expired
  timer never remains stuck at zero.
- Loaded first run, superset partner two, myo set two, four-cue stress content,
  and the longest card answer have deterministic fixtures and launch arguments.
- Rep controls expose VoiceOver activation; Back and End have 64pt hit regions;
  workout typography is intentionally clamped at the fixed `.large` size.
- Reduce Transparency replaces interactive glass with opaque, bordered control
  surfaces.
- Haptic sharpness, timing, hold acceleration, and numeric motion differ by
  treatment while retaining the same product semantics.
- Core Haptics now prewarms, handles stop/reset, caches prepared players, and
  retries the triggering event once after recovery.
- A live 20-second myo Rest was observed auto-advancing to the 4–5 rep Set with
  the exact program cue.

## Third-pass contrast and restraint

Eden rejected the remaining low-contrast areas and decorative halo vocabulary.
The third pass treats light as state, not decoration:

- All treatments now share a stable dark luminance veil behind the title, cues,
  comparison, next-exercise copy, and controls.
- Secondary text moved from 58–68% white to 68–78% white according to role.
  A simulator PNG audit composited the declared text alpha over median 5×5
  background samples at eight representative text zones. The measured range
  was 7.79:1–11.38:1; the worst sampled zone was the Atmospheric footer.
- The Atmospheric threshold bloom was removed. This pass briefly retained a
  small sun and horizon; the focused lead pass below removes them entirely.
- The Atmospheric timer ring shadow is 6pt and supporting, not a second light
  source.
- Tactile removes the large Set ellipse entirely and limits background accent
  to 10% in the MeshGradient. Its threshold is the counter rim and detent.
- Tactile timer and counter accent shadows were reduced to 8pt and 7pt. Precise
  remains essentially shadowless.
- The duplicate `Rest` label below `Rest · 9 / 21` was removed. Set and Rest now
  retain only content that changes the next action.
- Liquid Glass is grouped with `GlassEffectContainer` and remains limited to
  manipulated Tactile controls. The primary action is opaque.

Controlled final captures in ignored `ios/build/` use one iPhone 16 Pro state:

```text
w1-final-atmospheric-set.png
w1-final-precise-set.png
w1-final-tactile-set.png
w1-final-atmospheric-rest.png
w1-final-precise-rest.png
w1-final-tactile-rest.png
w1-final-card-revealed.png
w1-final-myo-rest.png
w1-final-four-cue-set.png
```

The final matrix was checked for centering, distant hierarchy, overflow,
overloaded labels, text backing luminance, and non-semantic glow. The longest
revealed card, four-cue Set, and 5-second myo Rest keep controls visible without
scrolling.

## Animation dependency decision

Native SwiftUI now demonstrates the required treatment-specific motion with
`matchedGeometryEffect`, numeric text transitions, `MeshGradient`, `Canvas`,
`GlassEffectContainer`, and interactive `glassEffect`.

- Pow was reviewed, but its stock effects would add a generic delight
  vocabulary without solving a current prototype problem.
- Lottie requires authored After Effects assets; no such asset currently beats
  the native sunrise.
- Rive remains conditional on a future interactive exercise figure or state
  machine that demonstrably outperforms native code.
- Hero is view-controller oriented and is not a fit for this SwiftUI app.
- Vortex could be reconsidered for a later completion moment, not for Set or
  Rest.
- `PhaseAnimator`, `KeyframeAnimator`, and shaders remain available natively,
  but adding them without a state they clarify would only add motion.

No third-party animation package was added.

## Focused Atmospheric lead pass

Eden now prefers Atmospheric Dawn, without formally choosing it or closing W1.
The lab marks it as `LEADING`; Precise and Tactile remain runnable comparison
treatments.

- Atmospheric removes the previous-rep badge above the number. An equal,
  prefilled comparable Set shows `13` without repeating “Last time: 13”.
- Crossing to `14` remains unmistakable through semantic mint, the explicit
  “Beating last time's 13” line, numeric motion, and the threshold haptic.
- First-run Sets still say “First time — just go to failure”. Changed-weight
  Sets still explain that the old reps were logged at a different weight.
- The fixed target moved into the exercise/meta hierarchy. It is no longer a
  second comparator above the counter.
- The decorative bottom horizon, line, and sun were deleted. Atmospheric light
  now communicates only session progress through the palette interpolation and
  fading stars.
- Every Set reserves a 142–178pt native movement bay. App-owned Canvas figures
  animate real fixed exercises: overhead press, push-up, lateral raise, floor
  fly, bent-over row, and curl. No placeholder package or asset was added.
- Full-motion figures interpolate between honest start and finish positions.
  Reduce Motion overlays those two positions statically.
- The four-cue fixture uses the 142pt bay, compact 16pt cue setting, full 82pt
  rep controls, and the same 68pt primary action. It remains no-scroll.
- Seven representative rendered text zones measured 6.88:1–12.03:1 using the
  declared white alpha over median simulator background samples. The quiet
  `MOVEMENT` label is the weakest sampled zone.
- The prototype menu replaces the easy-to-miss Rest picker with visible Timer
  only, Question → answer, and Myo choices. The card row says that its fun fact
  reveals automatically, and the selected prototype's Open action stays visible.
- Carded Rest still reveals silently at 9.6 seconds, keeps a 64pt compact timer,
  and fits the longest fixed answer with both controls visible.

Controlled captures in ignored `ios/build/`:

```text
w1-lead-atmospheric-equal.png
w1-lead-atmospheric-beating.png
w1-lead-atmospheric-long.png
w1-lead-atmospheric-rest.png
w1-lead-atmospheric-card-question.png
w1-lead-atmospheric-card-answer.png
w1-lead-atmospheric-menu.png
w1-lead-precise-set.png
w1-lead-tactile-set.png
```
