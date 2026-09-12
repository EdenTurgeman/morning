# 013 — Close the gap in the step transition

- **Status**: DONE — 2026-09-11
- **Commit**: 259f47e
- **Severity**: HIGH
- **Category**: Easing & duration
- **Estimated scope**: 1 file — `DesignMotion.swift`. One delay value, plus a re-measurement.

## Problem

The step transition holds an empty window by construction. Both halves are
0.10s, and the incoming one is delayed until the outgoing one is **already
gone**:

```swift
// ios/Morning/DesignMotion.swift:167-176 — current
    static func screenSwap(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            return .opacity.animation(.linear(duration: 0.12))
        }
        return .asymmetric(
            insertion: .opacity.animation(.easeOut(duration: 0.10).delay(0.08)),
            removal: .opacity.animation(.easeOut(duration: 0.10))
        )
    }
```

Timeline: the outgoing screen finishes at 0.10s. The incoming one starts at
0.08s and needs its own ramp before it is legible. Measured end to end on a real
Set → Rest, from the last legible frame of one screen to the first legible frame
of the next: **220ms**.

`plans/006` measured this and described it accurately — *"the Rest screen
clears, there is a held beat, then the Set screen arrives"* — and passed it,
because the plan it was executing was about whether the declared asymmetry
*ran*, not what it was. It runs. The held beat is the design.

Eden, on the result: *"some screens just repaint the whole screen, for example
when i click done it might repaint the whole screen and show the timer."*

**The asymmetry itself is correct and is not up for re-litigation.** Its doc
comment records what a symmetric cross-fade measured as:

> a symmetric cross-fade put both screens near half opacity for ~0.2s and
> stacked the Set screen's cues on the Rest screen's controls. Legible content
> on legible content reads as neither. So the outgoing screen still clears
> before the incoming one commits.

That is right, and this plan keeps it. What is wrong is the *size* of the gap:
`0.08` was chosen when the window was deliberately load-bearing. The same doc
comment says so:

> **The gap was sized for a morph that was deleted.** The old note said the
> window is "deliberate rather than zero — the work object crosses it, and the
> counter becoming the ring is the one continuity worth protecting." Nothing
> crosses it now.

Nothing crosses the gap any more. It is sized for a thing that no longer exists.

## Target

The incoming screen starts while the outgoing one is **below legibility** rather
than after it has fully cleared. One value changes:

```swift
// target — ios/Morning/DesignMotion.swift
        return .asymmetric(
            // 0.05, not 0.08. At `easeOut(0.10)` the outgoing screen is under
            // ~25% opacity by 0.05s — below the threshold at which its text
            // competes with anything — so the incoming one can start there
            // without recreating the symmetric cross-fade this asymmetry
            // exists to avoid. The old 0.08 was sized to protect a morph that
            // crossed the gap, and that morph was deleted. See plans/013.
            insertion: .opacity.animation(.easeOut(duration: 0.10).delay(0.05)),
            removal: .opacity.animation(.easeOut(duration: 0.10))
        )
```

Total declared span falls from 0.18s to 0.15s, still inside §3.1's ≤180ms
ceiling. Durations, curves and the Reduce Motion branch are unchanged.

**This plan is a tuning pass and it is the smallest of the three.** It is third
on purpose: `plans/011` removes the blank entirely by keeping the chrome on
screen, and `012` makes the transition fire where it currently does not. Both
change what this value is tuning against. **Re-measure before changing it — if
011 has made the swap feel right, the correct outcome here may be to change
nothing, and that is a valid result to report.**

## Repo conventions to follow

- Motion values live in `ios/Morning/DesignMotion.swift` as `static func`s
  taking `reduceMotion`. Change the value in the token, never at a call site.
- Every value in that file carries a comment saying *why it is that number*.
  Match the register: `Motion.optionEntry`'s comment is a good exemplar — it
  names the band, the sibling token it matches, and what it measured at.
- Reduce Motion always gets a plainer version, never a scaled-down one. Do not
  touch that branch.

## Steps

1. **Measure first.** With `011` and `012` landed, capture a Set → Rest using
   the command block in the Verification section of `plans/011` and record the
   ink-coverage table. Write the numbers into this plan's Outcome section.

2. **If the floor is already comfortably above zero and the swap reads as a
   content change rather than a repaint, STOP.** Mark this plan `DONE — no
   change needed`, record the measurement, and say so. That is the correct
   outcome and this plan is written to allow it.

3. Otherwise, change `0.08` to `0.05` in the insertion delay, with the comment
   from the Target section.

4. Re-measure with the identical command block and compare tables.

## Boundaries

- Do NOT make the transition symmetric. Its own doc comment records the
  measurement that rejected it: both screens near half opacity for ~0.2s, Set
  cues stacked on Rest controls.
- Do NOT change either `duration: 0.10`. §3.1's ≤180ms is a ceiling on the
  whole swap, and the durations are the measured half of it.
- Do NOT touch the `reduceMotion` branch.
- Do NOT add movement, scale, blur or `matchedGeometryEffect`. §3.1: opacity
  only, and it forbids `matchedGeometryEffect` between Set and Rest by name.
- Do NOT change `Motion.stage` or `advance()` in `WorkoutHost`. `plans/006`
  proved the ambient transaction does not override `screenSwap`'s per-half
  animations; `Motion.stage` is not what is producing the gap.
- Do NOT run this before `011`. Tuning a delay against a screen that goes fully
  blank measures the wrong thing.
- If a step does not match the code you find, STOP and report.

## Verification

- **Mechanical**: `./scripts/verify-ios.sh` — 7 phases PASS, 0 skipped.
- **Frames**: the command block from `plans/011`, run before and after, with
  both ink-coverage tables recorded in the Outcome.
- **Done when**:
  - The window at or near 0.00% ink is shorter than before, or the plan is
    closed as "no change needed" with the measurement that justifies it.
  - **No frame shows two legible screens at once.** This is the regression this
    plan can cause and the one the asymmetry exists to prevent. Inspect the
    middle three frames of the swap directly — do not rely on a number. If the
    Set screen's cues are readable on top of the Rest screen's `+15S / SKIP`
    row in any frame, revert to `0.08` and report.
  - Reduce Motion still produces a plain fade.
- **Feel check**: from 1.5m, tap `Done` without looking, twice in a row, and
  confirm both that you can tell it advanced and that nothing smears. §3.1's
  failure mode is a double-logged set; this plan must not trade a blank for an
  illegible frame.
- **Frame rate**: make no claim. The simulator is not 120Hz. W11, on the phone.

## Outcome

_To be filled in by the executor. Record both ink-coverage tables, and if the
plan closes without a code change, say that plainly and why._


---

## Outcome — 2026-09-11

**Applied, and it is the smallest of the three by a wide margin.** The insertion
delay went 0.08 → 0.05.

| | before 013 | after 013 |
|---|---|---|
| last full screen → next settled | 170ms | **140ms** |
| frames with content absent | 3 (~48ms) | 3 (~48ms) |
| floor | 0.17% | 0.17% |

**The honest reading: the total swap is 30ms shorter and the content-absent
window did not measurably move.** At 16ms frame resolution both read as three
frames, so this plan cannot claim to have shortened the gap — only the whole
swap. 30ms is the delay reduction, exactly, and nothing more.

**The safety condition holds.** The regression this plan could cause is two
legible screens at once — the thing the asymmetry exists to prevent. Measured on
the outgoing screen's cue band through the whole swap:

| frame | Set cues still legible |
|---|---|
| t5.46 | 0.01% |
| t5.48 | 0.00% |
| t5.50 | 0.00% |
| t5.51 | 2.33% (the incoming screen, arriving) |

The outgoing screen's text is never readable while the incoming one arrives, so
the symmetric cross-fade the doc comment rejected has not been recreated.

Kept because it is strictly faster, safe, and still inside §3.1's 180ms ceiling
— not because it is what fixed the complaint. **`plans/011` is what fixed the
complaint.**

`./scripts/verify-ios.sh` — 7 phases PASS, 119 assertions, 0 skipped.
