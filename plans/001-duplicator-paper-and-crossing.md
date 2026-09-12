# 001 — Duplicator: paper ply, contrast, and the crossing

**Repo:** `/Users/eden.turgeman/Dev/morning` · **Commit:** `259f47e`
**Target file:** `ios/Morning/PrototypeR4Worlds.swift` (`DuplicatorVariant` only)
**Run it:** `./scripts/shoot.sh set -variant duplicator`

Prototype only. `SetScreen` is production and is **not** in scope. `CellarVariant`
in the same file is **not** in scope.

---

## Why

Eden chose Duplicator on 2026-08-27 and asked for three things: animation, more
paper ("paper mâché"), and more contrasting colour. Paper and contrast are one
move — a second, paler ply pasted over the sand ground reads as layered paper
*and* lifts press black from 7.74:1 to ~11.3:1.

Motion is governed by `ios/Docs/redesign/01-motion-doctrine.md`, which is
settled and **must not be re-argued**. It permits exactly two things here.

---

## The doctrine boundary — read before writing any animation

**Animate only these two events:**

1. **The crossing** (`context.isBeating` flipping false→true). Doctrine §1.1
   tiers this as a **Rare** event on a Tens/day surface: *"Gets the best motion
   inside the workout loop."* This is the one place motion is earned.
2. **The rep digit changing.** Uses the existing `Motion.rep` +
   `Motion.numeric` tokens, exactly as the shipped `SetScreen` does.

**Animate nothing else.** Specifically **do not** animate the step block inking
as sets complete, the head, the cues, the keys' layout, or the primary block.
Those fire ~28×/session, which the frequency gate (§1) puts in the tier where
motion is *removed*. A tempting "the sheet fills" beat is exactly the finding
this boundary exists to reject.

**Press feedback stays instant.** `InkedKeyStyle`/`InkedBlockStyle` flip with no
animation. §1.2 requires ≤160ms; instant satisfies it, and an instant ink flip
is what a stamp does. Do not add a duration to it.

**Every animation value comes from `Motion.*` in `ios/Morning/DesignMotion.swift`,
which already takes `reduceMotion` as a parameter.** Never hand-write a duration
or an easing curve in the prototype. Read `reduceMotion` with:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

---

## Steps

### 1. Paper primitives

Add to the Duplicator section:

- `TornEdge: Shape` — a rectangle whose top and/or bottom edge is torn. Segment
  the edge into ~40 steps and offset each perpendicular by a **deterministic**
  pseudo-random amount (hash the segment index with a fixed seed). It must be
  deterministic: a jitter recomputed per frame shimmers, which on a static
  screen reads as a rendering bug.
- `Fibre: View` — a `Canvas` drawing short, low-alpha strokes for paper fibre.
  Deterministic, same reason. Keep it out of any animated subtree.

Both are `nonisolated` if the compiler asks (it does for `Shape` under this
module's `MainActor` default isolation — see `MarginTick` in the same file).

### 2. The pale ply

Add to `enum Riso`:

```swift
/// The pasted ply. A second sheet laid over the stock, which is what makes
/// this paper rather than a background — and it carries press black at
/// ~11.3:1 where the sand ground carried it at 7.74:1.
static let ply = Color(red: 0.929, green: 0.902, blue: 0.847)
```

Lay the head block and the counter block each on their own `ply` sheet with a
torn bottom edge, a fibre overlay, and a **real** drop shadow beneath the torn
edge — offset and blurred, never a zero-offset halo:

```swift
.shadow(color: Riso.press.opacity(0.22), radius: 3, x: 0, y: 2)
```

### 3. The crossing

The counter's ply **overprints**: the pale sheet floods to `Riso.overprint`
(plum) and the numeral knocks out to `Riso.ply`. Plum-on-ply measures ~10.2:1.

Drive it declaratively, **never** with `withAnimation` inside a lifecycle
callback:

```swift
.animation(Motion.threshold(reduceMotion: reduceMotion), value: context.isBeating)
```

The ink arrives as a **wipe**, left to right, not a cross-fade — ink hits paper
from the roller's direction. Implement as a plum rectangle revealed by a mask
whose width goes `0 → geometry.width`, driven off `context.isBeating`.

`Motion.threshold` already carries the two-beat timing (0.22s delay) and its own
reduced form, both documented in `DesignMotion.swift`. Do not re-derive them.

### 4. The digit

```swift
.contentTransition(Motion.numeric(reduceMotion: reduceMotion))
.animation(Motion.rep(reduceMotion: reduceMotion), value: context.reps)
```

### 5. A flag to film it

No agent tap reaches the simulator, so a state change cannot be triggered
interactively and the animation cannot otherwise be verified. Add a debug-only
launch flag `-demo-crossing` that flips the crossing shortly after launch, so
`simctl io recordVideo` plus `ios/Tools/frames.swift` can pull real frames.

---

## Verification

1. `./scripts/verify-ios.sh` — all seven phases green.
2. `./scripts/shoot.sh set -variant duplicator` and again with `-reps 21`.
   Confirm both end states: pale ply, and overprinted plum with a knocked-out
   numeral.
3. `python3 ios/Tools/measure-contrast.py <frame> set` on both. **Check the
   printed row ranges against the frame** — the tool's zone map is tuned to the
   shipped layout and mislabels a new one.
4. **Film the crossing.** `xcrun simctl io booted recordVideo`, launch with
   `-demo-crossing`, then `swift ios/Tools/frames.swift <video> <outDir> <t…>`.
   Confirm the wipe actually moves and the two beats are separate. An implicit
   animation that silently does nothing has cost this project twice; inspection
   never caught it and frame capture did.
5. Feel-check is Eden's — press response cannot be judged from a still.
