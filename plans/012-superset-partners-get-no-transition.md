# 012 — Give superset partners a transition

- **Status**: DONE — 2026-09-11
- **Commit**: 259f47e
- **Severity**: HIGH
- **Category**: Purpose & frequency
- **Estimated scope**: 1 file — `WorkoutHost.swift`. One modifier, plus a test.

## Problem

**Inside a superset, tapping `Done` animates nothing at all.**

Superset partners are emitted back to back with no rest between them:

```swift
// ios/Morning/Model/Steps.swift:158-177 — current
            case let .superset(superset):
                // Partners run back to back; rest comes only after the round.
                for setIndex in 0 ..< superset.sets {
                    for (itemIndex, item) in superset.items.enumerated() {
                        steps.append(.set(SetStep(
                            …
                            straightIntoNext: itemIndex < superset.items.count - 1
                        )))
                    }
                    steps.append(.rest(RestStep(seconds: superset.rest)))
                }
```

So the step list contains adjacent `.set` entries. Both land in the same branch
of `WorkoutHost`:

```swift
// ios/Morning/Screens/WorkoutHost.swift — current
                } else if let set = session.currentSet {
                    SetScreen(
                        setStep: set,
                        …
                    )
                    .transition(Motion.screenSwap(reduceMotion: reduceMotion))
```

SwiftUI gives that branch **one identity**. Moving from partner 1 to partner 2
does not insert or remove anything — it updates properties in place — so
`.transition(…)` never fires. The exercise name, cues, target and figure all
swap with no transition whatsoever.

**This is the precise failure §3.1 exists to prevent, going unserved in the one
place it matters most.** The doctrine's justification, verbatim:

> Two consecutive sets of the same exercise are near-identical screens. Set 2 of
> 3 and set 3 of 3 differ by one glyph. With no transition at all, a user who
> taps `Done` with a knuckle, not looking, **has no way to tell whether the tap
> registered.** He looks up at a screen that appears not to have changed and
> taps again — logging the next set with the previous set's reps.

Every Set → Rest → Set pair gets the transition. The two screens that follow
each other *directly*, with nothing between them, get nothing.

**The model already knows.** `SetStep` carries the flag and no view reads it:

```swift
// ios/Morning/Model/Steps.swift:76-79 — current
    let superset: SupersetPosition?
    /// True when the next partner follows immediately with no rest. Only
    /// meaningful inside a superset, hence optional rather than defaulted.
    let straightIntoNext: Bool?
```

## Target

Every step change swaps, including set → set. The branch's identity is keyed to
the step index, so SwiftUI treats each step as a distinct view and the existing
`.transition(Motion.screenSwap(…))` fires for all of them.

```swift
// target
                } else if let set = session.currentSet {
                    SetScreen(
                        setStep: set,
                        …
                    )
                    // ONE STEP, ONE IDENTITY.
                    //
                    // Without this, superset partners share a branch and
                    // SwiftUI updates in place — so `Done` inside a superset
                    // animated nothing, which is exactly the case
                    // `01-motion-doctrine.md` §3.1 says the transition exists
                    // for. See plans/012.
                    .id(session.stepIndex)
                    .transition(Motion.screenSwap(reduceMotion: reduceMotion))
```

**No motion value changes.** The transition that already runs on Set → Rest is
the one that will now also run on Set → Set.

## Repo conventions to follow

- The transition token is `Motion.screenSwap(reduceMotion:)` in
  `ios/Morning/DesignMotion.swift`. Use it; do not write a transition inline.
- `session.stepIndex` is the existing identity for a step — `RestScreen` already
  keys its own lifecycle to it via `restIndex`, and its doc comment explains
  why the index is the right key and `endsAt` is not (`+15s` rewrites `endsAt`).
  Follow that precedent.
- Acceptance tests live in `ios/MorningTests/Acceptance/`. The step compiler is
  covered by `ProgramCompilerAcceptanceTests.swift` — add the new assertion
  there, beside the other structural claims about the compiled step list.

## Steps

1. **`WorkoutHost.swift`** — add `.id(session.stepIndex)` to the `SetScreen`
   branch, immediately above its existing `.transition(…)`, with the comment
   from the Target section.

2. **Do not add `.id` to the rest or timer branches.** They already change
   identity by changing branch. Adding it there is harmless but it is untested
   churn, and `RestScreen` owns lifecycle state keyed to `restIndex` that an
   extra identity change could reset mid-rest.

3. **`ProgramCompilerAcceptanceTests.swift`** — add a test that pins the
   structural fact this plan depends on, so it cannot be silently removed:

   ```swift
   /// SUPERSET PARTNERS ARE ADJACENT, WITH NO REST BETWEEN THEM.
   ///
   /// `Steps.swift`: *"Partners run back to back; rest comes only after the
   /// round."* The step transition in `WorkoutHost` has to handle set → set
   /// because of this — see plans/012 — so if the compiler ever stops emitting
   /// adjacent sets, that `.id` is dead weight and should be reconsidered
   /// rather than left.
   func testSupersetPartnersAreAdjacentSteps() {
       for key in ["A", "B"] {
           let steps = StepCompiler.build(session: key)
           let adjacent = zip(steps, steps.dropFirst()).count { left, right in
               if case .set = left, case .set = right { return true }
               return false
           }
           XCTAssertGreaterThan(
               adjacent, 0,
               "\(key) has no adjacent sets — the set→set transition has nothing to serve"
           )
       }
   }
   ```

   If `StepCompiler.build(session:)` is not the constructor used elsewhere in
   that file, match whatever the neighbouring tests use instead.

## Boundaries

- Do NOT change `Motion.screenSwap`, `Motion.stage`, or any duration or curve.
  That is `plans/013`.
- Do NOT read `straightIntoNext` in the view layer. It is named here only to
  show the model already distinguishes these steps; keying on `stepIndex` is
  simpler and covers every step change, not just superset ones.
- Do NOT add `.id` to `RestScreen` or `WarmupScreen`.
- Do NOT add movement, and do NOT give set → set a *different* transition from
  set → rest. One transition for the loop is §3.1's whole framing.
- Do NOT change `Steps.swift`. The compiler is correct; the view layer is what
  ignored it.
- If `plans/011` has already landed, the chrome is hoisted and will not fade —
  that is expected and correct. Do not "restore" it.
- If a step does not match the code you find, STOP and report.

## Verification

- **Mechanical**: `./scripts/verify-ios.sh` — 7 phases PASS, 0 skipped, and the
  assertion count **up by one** from 118 (119) for the new test.

- **Frames.** A superset partner change must now animate. Session B's superset
  is `Lateral raise + Rear-delt fly`; find the first `.set` step whose successor
  is also a `.set` and land on it:

  ```bash
  UDID=$(xcrun simctl list devices available | grep -F "iPhone 16 Pro (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  xcrun simctl io "$UDID" recordVideo --codec h264 --force /tmp/superset.mp4 & REC=$!
  sleep 2
  # -step lands on a chosen step; pick the first partner of a superset round.
  xcrun simctl launch "$UDID" com.edenturgeman.morning -screen set -session B -step 8 -seed one-week -autoplay
  sleep 9
  kill -INT $REC
  swift ios/Tools/frames.swift /tmp/superset.mp4 /tmp/ss $(python3 -c "print(' '.join(f'{t/1000:.3f}' for t in range(4850,5600,25)))")
  ```

  Confirm the exercise name is legible, then not, then the partner's name is
  legible — rather than the name changing between two consecutive frames. If
  step 8 is not a superset partner, print the compiled list first and pick one;
  do not assume the index.

- **Done when**:
  - A superset partner change shows a transition in the frames, not a cut.
  - Set → Rest is **unchanged** from before this plan. Capture it too and
    compare; this plan must not alter the transition that already worked.
  - Rapid `Back` through a superset does not stack two Set screens or restart
    the transition from full opacity. `.id` changes identity, and §3.1 warns
    that this path *"can be triggered rapidly with Back"*. Film it.
  - The rep counter does not roll from the previous partner's number. §3.2
    requires per-set identity on the digit specifically — *"without identity it
    reads as a slot machine on every step — a shipped bug"*. Adding `.id` to
    the whole screen should preserve that; confirm it did not reintroduce the
    roll.
- **Feel check**: from 1.5m, tap `Done` on the first partner of a superset
  without looking at the screen, and confirm you can tell it advanced. Before
  this plan you cannot, and that is the entire finding.
- **Frame rate**: make no claim. The simulator is not 120Hz.


---

## Outcome — 2026-09-11

**Done.** `.id(session.stepIndex)` on the Set branch, plus
`testSupersetPartnersAreAdjacentSteps` pinning the compiler fact it depends on.

Filmed on session A step 7 — *"Overhead press · superset 1/2 · No rest after
this. Straight into the next one."* — which is exactly the case:

| t | ink | |
|---|---|---|
| t4.95 | 13.72% | partner 1 |
| t4.97 | 12.56% | fading |
| **t4.98 – t5.05** | **0.36%** | chrome only, ~80ms |
| t5.06 → t5.16 | 12.30 → 13.41% | partner 2 arriving |

Before this, a partner change had **no intermediate frame at all** — the content
changed between two consecutive frames. There is now a transition where there
was none, and the floor is the chrome rather than zero, because `plans/011`
landed first.

Confirmed it is a real content swap and not just a flicker, by pixel difference
between the settled frames either side:

- exercise name + sub-line band: **14.89% of pixels changed** — the partner
- chrome band: **1.06%** — only the rail advancing one tick and the label going
  `SET 4 / 13` → `SET 5 / 13`

`./scripts/verify-ios.sh` — 7 phases PASS, **119 assertions** (up one, as the
plan predicted), 0 skipped.
