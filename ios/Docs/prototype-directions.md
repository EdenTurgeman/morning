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
-prototype precise-rest
-prototype precise-rest-snapshot
-prototype tactile-myo-rest
```

Appending `snapshot` freezes a Rest at 45 seconds (5 seconds for myo) so
treatments can be compared in the same state rather than at arbitrary capture
times.

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
- MeshGradient sky and restrained breathing horizon light
- unboxed counter, simple controls, strongest environmental glow
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
- Card reveal transfers space from the timer to text instead of flipping a card.
- Reduce Motion freezes environmental breathing and preserves state through
  shorter opacity/light changes.

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

- Atmospheric owns stars, authored horizon position, a visible sun, and a
  lasting environmental change when 13 becomes 14.
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
- Reduced Motion now freezes environmental breathing, removes object tilt and
  numeric travel, and shortens timer/card geometry changes.
