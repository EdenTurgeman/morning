# 002 — Blades that move like paper

**Repo:** `/Users/eden.turgeman/Dev/morning` · **Target:** `ios/Morning/Screens/PaperSunrise.swift`
**Run it:** `./scripts/shoot.sh daybreak` · `-tier week-complete` for the wide fan

Scope is the fan only. `Daybreak`'s copy, beats, haptics and dismiss are out.

---

## The finding

The fan opens with `rotationEffect` driven by a strong ease-out. That is a
**rigid** fan — a stack of steel blades on a pin. Every blade is perfectly
straight at every instant, arrives at its angle and stops dead, and all blades
travel at identical rates.

Paper does none of those three things, and the material is the whole point of
this world.

| What paper does | What the code does now |
| --- | --- |
| **Flexes.** A swung leaf's tip lags its root; it bends against the direction of travel, most at peak speed, straightening as it slows | Blades are rigid wedges at every frame |
| **Settles.** Card stock overshoots its rest angle slightly and comes back, damped | Ease-out arrives and stops dead |
| **Drags.** Leaves rub; outer leaves of a fan open slower than inner ones | Stagger only — every blade takes the same 0.85s |

## Why bounce is allowed here, when the doctrine banned it

`DesignMotion.swift`'s `commit` token spells out the rule: start critically
damped, add bounce **only when the gesture itself carried momentum**. A knuckle
tap on a rep control carries none, which is why bounce is off across the app.

**A fan being flicked open carries momentum by definition.** That is the
exception the rule describes, not a violation of it. Keep it small — paper mâché
is pasted layers dried stiff, closer to card than to a leaf.

---

## Steps

### 1. Replace the ease-out ramp with a sampled spring

`Spring` (iOS 17+) can be sampled analytically, which is what a
`TimelineView`-driven animation needs — the whole moment derives from one
elapsed clock and hands nothing to the system.

```swift
private static let leafSpring = Spring(duration: 0.85, bounce: 0.14)
```

`bounce: 0.14` sits inside Emil's 0.1–0.3 band and at the stiff end of it.

Sample position with `value(fromValue:toValue:initialVelocity:time:)`.

### 2. Drive flex from the spring's own velocity

`Spring.velocity(fromValue:toValue:initialVelocity:time:)` gives angular speed
for free. Flex is proportional to it, so the blade bends most while moving
fastest and straightens as it settles — which is what paper does, derived rather
than keyframed.

Signed by the blade's direction of travel: a blade swinging left lags right.

Cap it. Past roughly 14° of tip lag the blade reads as rubber, not paper.

### 3. Bend the blade shape

`FanBlade` currently draws straight radial edges. Add `lag: Double` (degrees at
the tip) and offset the angle by `-lag * r²` where `r` is the fraction of the
way out from the pivot — quadratic, because a cantilever bends more toward its
free end. Both side edges and the torn rim take the same bend.

`FanBlade` must stay `nonisolated` (module default isolation is `MainActor`;
`Shape` conformance needs it — see `MarginTick`).

### 4. Outer blades drag

Scale each blade's spring duration by its rank from the centre: inner blades
0.85s, the outermost ~1.05s. Friction between leaves, and it makes the fan open
as a *material* rather than as a set of independent parts.

Keep the existing 55ms centre-outward stagger — it is inside the 30–80ms band
and it is what makes the fan open from the middle rather than sweeping.

### 5. The rise settles too

The rise is the same object, so it takes the same spring at a longer duration
(~1.5s). One physics for one thing.

### 6. Reduce Motion

Unchanged in behaviour: fully open, fully risen, no flex, no overshoot. Assert
that `lag` is 0 on every blade in that path — a flexed blade frozen mid-bend is
a *broken* shape, not a calm one, and this is exactly the case where "calmer"
degrades into "wrong" if it is not checked.

---

## Verification

1. `./scripts/verify-ios.sh` — seven phases.
2. Film it. No agent tap reaches this simulator, so frames are the only check:

```bash
xcrun simctl io booted recordVideo --codec h264 fan.mp4 &
./scripts/shoot.sh daybreak --no-build --keep --delay 6
swift ios/Tools/frames.swift fan.mp4 out/ 3.0 3.2 3.4 3.6 4.0
```

Look for: blades visibly **curved** in the fast frames and **straight** in the
settled one. If they are curved at rest, the velocity coupling is wrong.

3. Check `-tier week-complete` (11 blades) as well as the default (5). The wide
   fan is where drag and stagger are visible; the narrow one is where a bent
   blade at rest would be obvious.
4. **Frame rate is unverifiable here** — the simulator is not 120Hz and eleven
   bending `Shape` paths plus two `Canvas` textures is the heaviest thing this
   app draws. Flag for the device pass; do not claim smoothness.
