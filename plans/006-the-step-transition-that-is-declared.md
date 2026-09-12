# 006 — Make the step transition run the way it is written

- **Status**: DONE — 2026-09-03. The predicted fault was absent; a worse one was found in its place
- **Commit**: 259f47e
- **Severity**: HIGH
- **Category**: Easing & duration · Interruptibility
- **Estimated scope**: 2 files, ~15 lines — but **step 1 is a measurement, and it decides whether steps 3-4 happen at all**

## Problem

Set → Rest → Set fires about 28 times a session. It is the loop's only
transition and `ios/Docs/redesign/01-motion-doctrine.md` §3.1 gives it the
clearest failure mode in the app:

> Two consecutive sets of the same exercise are near-identical screens. Set 2
> of 3 and set 3 of 3 differ by one glyph. With no transition at all, a user
> who taps `Done` with a knuckle, not looking, **has no way to tell whether the
> tap registered.** He looks up at a screen that appears not to have changed and
> taps again — logging the next set with the previous set's reps.

**Two things about how it is wired may not survive contact with SwiftUI.**

### (a) The declared asymmetry may be overridden

`Motion.screenSwap` builds an asymmetric transition, and its doc comment records
that a *symmetric* cross-fade was tried first and measured as wrong:

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

Its own comment, on why the asymmetry exists:

> A symmetric cross-fade was the first attempt and it was wrong. Measured off a
> 60fps capture, both screens sat near half opacity for ~0.2s, which put the Set
> screen's cues and Done button directly on top of the Rest screen's "+15s /
> Skip" and next-up label. Legible content on legible content reads as neither.

But the state change that triggers it is wrapped in its own animation:

```swift
// ios/Morning/Screens/WorkoutHost.swift:351-355 — current
    private func advance(_ change: () -> Void) {
        withAnimation(Motion.stage(reduceMotion: reduceMotion)) {
            change()
        }
    }
```

`Motion.stage` is `.easeOut(duration: 0.18)` — **symmetric, and with no
insertion delay.** If the running `withAnimation` transaction wins over the
per-half `.animation(...)` inside `screenSwap`, then what actually plays is
precisely the symmetric cross-fade the comment above says was measured and
rejected: both screens near half opacity, Set cues on top of Rest controls.

**This is not speculation about SwiftUI in general — it was confirmed on this
screen, in this repo, on 2026-09-03.** Option rows in `RestScreen` were given
`.transition(….animation(reveal.delay(0.18)))` and, filmed twice at 60fps, still
appeared 70ms in, against a declared delay of 180ms. The ambient transaction won.
The fix there was to stop asking the transition and drive the change from state.
See handoff log entry R27, "Amended again".

Whether the same happens here is **unknown until it is filmed**, because the
shape of the two cases differs: there the animated views were inside an inserted
subtree, here the transition is on the branch itself.

### (b) It restarts rather than retargets

Doctrine §3.1 is specific about the mechanism, and gives a reason that is about
interruption rather than taste:

> **SwiftUI**: `.animation(_:value:)` on the step index. **Not**
> `.phaseAnimator` / `.keyframeAnimator` — those restart rather than retarget,
> and this can be triggered rapidly with Back.

The code uses `withAnimation` plus `.transition(...)` on three branches
(`WorkoutHost.swift:105, 123, 141`). A transition driven this way restarts from
its start value when re-triggered mid-flight. Back is reachable from the chrome
on every screen in the loop, and `advance` is also what `Skip →` and a rest
reaching zero call.

## Target

Whatever the measurement says, the end state is the doctrine's:

- Opacity only. No movement. **≤180ms total** including the insertion delay.
- The outgoing screen substantially clear before the incoming one commits —
  no window where both are near half opacity.
- Retargets rather than restarting when `Done`, `Skip` or `Back` is hit again
  mid-transition.
- Under Reduce Motion, the plain 0.12s linear fade `screenSwap` already returns.

## Repo conventions to follow

- **All timing lives in `ios/Morning/DesignMotion.swift`** as `Motion.*`
  functions taking `reduceMotion: Bool`. Do not inline a duration at a call
  site and do not add a parallel token — extend or correct the existing ones.
- Every token carries a doc comment explaining *why* the number is that number,
  usually citing a measurement. `Motion.screenSwap` (line ~140-176) is the
  exemplar; match that density if you change it.
- **Frame capture is the only accepted evidence on this project.** Doctrine §6:
  *"This project has shipped two motion bugs that compiled, read correctly, and
  did nothing on screen… Neither was caught by inspection."* It is three now.

## Steps

### 1. Measure what runs today. Do this before changing anything.

The step transition can be triggered without a tap: launch into a rest, and let
it run out — a rest reaching zero calls `onComplete`, which calls the same
`advance`. `rest-myo` is a 20-second rest, so the swap happens ~20s after
launch. Film it:

```bash
cd /Users/eden.turgeman/Dev/morning
xcrun simctl io booted recordVideo --codec h264 swap.mp4 &
./scripts/shoot.sh rest-myo --keep --delay 26
pkill -INT -f "simctl io booted recordVideo"
# find the swap, then sample it densely
swift ios/Tools/frames.swift swap.mp4 out/ 20.0 22.0 24.0 26.0
```

Once you have located the swap to within a second, sample every 0.03s across it
and answer **one question**: is there a window where the outgoing Rest screen
and the incoming Set screen are **both** visible at roughly half opacity?

- **Both visible at ~50%** → the transaction is overriding `screenSwap`.
  The asymmetry is not running. Continue to step 2.
- **Rest clears, a beat of near-empty, then Set arrives** → the asymmetry IS
  running. **Skip steps 2-3.** Record the finding as resolved in
  `ios/Agents/00-handoff-log.md` and go to step 4.

Save the contact sheet either way — it is the evidence for whichever answer.

### 2. Only if step 1 showed the override: stop the ambient transaction.

In `ios/Morning/Screens/WorkoutHost.swift`, change `advance` so it no longer
supplies an animation of its own:

```swift
// target — WorkoutHost.swift
    /// Advances the session. **Deliberately not wrapped in `withAnimation`.**
    ///
    /// It was, and the transaction that produced overrode the per-half timings
    /// inside `Motion.screenSwap` — so what played was the symmetric
    /// cross-fade that token's own comment records as measured and rejected:
    /// both screens near half opacity for ~0.2s, Set cues on top of Rest
    /// controls. Confirmed on film; the contact sheet is in the R27 handoff.
    ///
    /// The animation now comes from `.animation(_:value:)` on the step index,
    /// which is what `01-motion-doctrine.md` §3.1 prescribes and which also
    /// retargets instead of restarting when Back is hit mid-swap.
    private func advance(_ change: () -> Void) {
        change()
    }
```

### 3. Only if step 2 was done: drive it from the step index instead.

Find the `Group` (or equivalent container) that holds the three branches at
`WorkoutHost.swift:105`, `:123` and `:141` — each carrying
`.transition(Motion.screenSwap(reduceMotion: reduceMotion))`. Attach to that
container, **not to the individual branches**:

```swift
// target — on the container holding the warm-up / rest / set branches
.animation(Motion.stage(reduceMotion: reduceMotion), value: session.stepIndex)
```

Then re-run the step 1 capture. **If both screens are still at half opacity**,
`.animation(_:value:)` is overriding the transition the same way `withAnimation`
did. In that case the asymmetry cannot be expressed through the transition at
all, and the correct fix is to move it into the token: make
`Motion.stage` itself the asymmetric shape by giving the *container* a delayed
opacity rather than relying on `AnyTransition`. **Do not invent a third
approach — STOP and report, with the frames.**

### 4. Check interruption, in every branch of the above.

```bash
./scripts/shoot.sh set --keep
```

Then tap `Done`, and immediately `BACK`, and immediately `Done` again, three
times in under two seconds, filming throughout. Look for: a screen that snaps to
full opacity and restarts, or two screens stacked at once. Neither may happen.

## Boundaries

- Do NOT change the durations. 0.18s total is the doctrine's number and the
  measured one; this plan is about whether it *runs*, not what it is.
- Do NOT add movement. Opacity only — doctrine §3.1: *"Why not a slide:
  movement costs readability, which is the thing being protected."*
- Do NOT reintroduce `matchedGeometryEffect` between Set and Rest. It was built,
  Eden asked for it gone twice, and §3.1 forbids it by name.
- Do NOT touch `Motion.screenSwap`'s Reduce Motion branch.
- Do NOT un-hoist the ground/chrome from `WorkoutHost` to make the swap easier.
  §3.1: fading it per-screen measured 50 → 7 → 40 mean luma, a blackout.
- Do NOT change `SetScreen`, `RestScreen` or `WarmupScreen`.
- If step 1 shows the transition already behaves correctly, **the correct
  outcome of this plan is to change no code.** Say so and close it.

## Verification

- **Mechanical**: `./scripts/verify-ios.sh` — 7 phases PASS, 76 assertions,
  0 skipped.
- **Feel check**: the whole plan is a feel check; step 1 and step 4 are the
  verification. Additionally, at 1.5m from the screen, tap `Done` without
  looking directly at it and confirm you can tell the screen changed. That is
  the actual job of this transition.
- **Frame rate**: **make no claim.** The simulator is not 120Hz and its timing
  is not representative. That is W11, on Eden's phone, and it is still open.
- **Done when**: a contact sheet shows the outgoing screen substantially clear
  before the incoming one commits, rapid Back does not restart or stack, and
  `verify-ios.sh` reports 0 failed phases. Attach the contact sheet to the
  handoff entry — the next person to doubt this will want the frames, not the
  diff.


---

## Outcome — 2026-09-03

**Step 1's measurement disproved this plan's own hypothesis, and found
something worse.**

The asymmetry runs correctly. Filmed at 60fps across a myo rest running out,
there is no frame in which both screens are visible at half opacity — the Rest
screen clears, there is a held beat, then the Set screen arrives. The
`withAnimation` transaction is not overriding `Motion.screenSwap`, and steps 2
and 3 were **not** applied. `advance()` is unchanged.

What the capture showed instead was a **whiteout**. Mean luma across the swap:

| | before | during | after |
|---|---|---|---|
| as shipped | 185 | **241** | 184 |
| after the fix | 185 | **188** | 185 |

The peak frame showed the Rest screen's ring, its copy and its buttons all
ghosted on bare white, with not a halftone dot left. **The ground was fading
with the screens.** `.paperGround()` sat on the `Group` holding the three
transitioning branches, which put the stock and its halftone inside the subtree
the transition fades.

That is the failure `01-motion-doctrine.md` §3.1 names, in this world's colours
instead of the old one's — *"Fading the sky per-screen measured 50 → 7 → 40 mean
luma: a blackout between two screens… Do not un-hoist it."* The sky is gone and
the stock inherited its job; it inherited the trap with it, and the doctrine's
warning did not transfer because nobody re-measured after the world changed.

**Fix**: the ground is a `ZStack` sibling in `WorkoutHost.body`, not a
background modifier on the transitioning `Group`. A sibling cannot be faded by
a transition on its siblings. Re-measured: 185 → 188 → 185, and the peak frame
now samples `(201, 191, 173)` — exactly `Paper.stock`. That beat is the ground
holding while the screens cross, which is the doctrine's own good case: *"a
breath."*

**Step 4, interruption, is closed as NOT TESTABLE from this environment**, and
the reason is worth recording rather than leaving as "still open".

Attempted 2026-09-05. Plain taps do land — filmed, the sequence Done → BACK →
Done advanced the session, went back, and advanced again, ending on the rest
before set 2. But **each tap is issued through a separate tool round trip, and
they arrive seconds apart.** The transition being tested is 0.18s. A sequence
that cannot be issued faster than the animation it is meant to interrupt is not
a test of interruption; it is three unrelated taps. The 45-frame capture across
the attempt is flat, because nothing was ever mid-flight when the next tap
arrived.

Two ways to actually close it, neither taken here:

1. **On the phone.** It is one line on `device-checklist.md`: tap Done and Back
   alternately as fast as you can and watch for a screen that snaps to full
   opacity and restarts, or two screens stacked at once.
2. **A debug flag** that calls `advance()` twice about 100ms apart, in the shape
   of `-demo-crossing`. That is app code written to test app code, which this
   project has accepted before for exactly this reason — no synthesised input
   reaches this simulator fast enough. Worth doing only if the phone check finds
   something.

The theoretical concern remains what doctrine §3.1 states: `withAnimation` plus
`.transition` restarts rather than retargets, and Back is reachable from every
screen in the loop. Nothing here confirms or refutes it.

**The reusable lesson**: the plan was written from a well-evidenced hypothesis
and the hypothesis was wrong. It cost one capture to find out, and the capture
found a defect nobody had hypothesised. Measure first was the whole value of
this plan; had step 2 been applied on the strength of the reasoning, it would
have changed working code and left the real fault untouched.
