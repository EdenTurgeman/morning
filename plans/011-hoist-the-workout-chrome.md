# 011 — Hoist the workout chrome above the step transition

- **Status**: DONE — 2026-09-11
- **Commit**: 259f47e
- **Severity**: HIGH
- **Category**: Physicality & origin
- **Estimated scope**: 4 files — `WorkoutHost.swift`, `SetScreen.swift`, `RestScreen.swift`, `WarmupScreen.swift`. Moves one component; changes no motion values.

## Problem

**Every step change blanks the screen completely for 220ms.**

Filmed at 60fps on a real Set → Rest (`-screen set -session A -seed one-week
-autoplay`), measuring the share of pixels darker than luma 120 across the
content area:

| frame | ink |
|---|---|
| t4.85 | 13.65% — the Set screen |
| **t4.88 → t5.10** | **0.00%** |
| t5.12 | 3.55% — the Rest screen |

Not a dip. **Zero dark pixels for 220ms**: no BACK, no END, no progress rail, no
countdown, no text. Bare stock and halftone. The frame at t5.00 was pulled and
inspected directly to rule out a metric artefact — it is blank paper.

`plans/006` measured this same swap as mean luma **185 → 188 → 185** and passed
it. That reading is not wrong, it is insensitive: the ground fills most of the
frame, so the entire content vanishing moves the mean by three points. **Mean
luma cannot see a blank screen on a light ground. Ink coverage can.**

The cause is structural, not a timing value. `WorkoutChrome` — BACK, the step
label, END, the progress rail and the set marks — is rendered **inside each
screen**, so it is destroyed and rebuilt on every swap even though it is the
same component with near-identical content on both sides:

```swift
// ios/Morning/Screens/SetScreen.swift:66-79 — current
        VStack(spacing: 0) {
            WorkoutChrome(
                progress: progress,
                step: stepLabel,
                setMarks: setMarks,
                onBack: onBack,
                onEnd: onEnd
            )
            // Explicit here because this screen pads its children one by one.
            // `RestScreen` and `WarmupScreen` inherit the same gutter from the
            // padding on their outer stack, so all three rails now measure the
            // same inset.
            .padding(.horizontal, Space.gutter)
```

```swift
// ios/Morning/Screens/RestScreen.swift:162-163 — current
        VStack(spacing: 0) {
            WorkoutChrome(progress: progress, step: stepLabel, setMarks: setMarks, onBack: onBack, onEnd: onEnd)
```

```swift
// ios/Morning/Screens/WarmupScreen.swift:48-49 — current
        VStack(spacing: 0) {
            WorkoutChrome(progress: progress, step: stepLabel, setMarks: setMarks, onBack: onBack, onEnd: onEnd)
```

All three sit inside the `Group` that `WorkoutHost` puts the swap transition on,
so all three fade out and back in, 28 times a session.

**There is already a precedent in this exact file for the fix.** `plans/006`
hoisted the ground out of the transitioning subtree for the same reason and
recorded the result:

```swift
// ios/Morning/Screens/WorkoutHost.swift:114-118 — current
        ZStack {
            Paper.stock
                .overlay(Halftone())
                .ignoresSafeArea()

            Group {
```

The chrome is the other thing that should never have been inside the swap.

## Target

`WorkoutChrome` is rendered **once**, by `WorkoutHost`, as a sibling of the
transitioning `Group` — never inserted, never removed, never faded. The three
screens render only their own content.

The only per-screen input is the label, which `WorkoutHost` computes:

- a timer step (warm-up) → `""`
- a rest step → `"Rest"`
- a set step → `setLabel` (the existing computed property, `"Set 2 / 14"`)
- anything else → `""`

**No motion value changes in this plan.** `Motion.screenSwap` and
`Motion.stage` are untouched. The blank disappears because there is no longer a
frame in which nothing is on screen — the chrome is always there.

Expected measurement after the change: on the same capture, ink coverage never
reaches 0.00% at any frame of the swap. It will dip (the content still fades
through) and the floor will be roughly the chrome's own coverage.

## Repo conventions to follow

- **Hoisting above a transition is how this codebase solves this.** The
  exemplar is `WorkoutHost.swift:94-118` — read its comment block in full
  before starting. It explains why `Paper.stock` is a `ZStack` sibling and ends
  *"A `ZStack` sibling cannot be faded by a transition on its siblings."*
- `WorkoutHost` already computes every value the chrome needs:
  `progressOverride ?? sessionProgress`, `setMarks`, `setLabel`, and the
  `onBack` / `onEnd` closures. Nothing new has to be derived.
- `WorkoutChrome` is declared in `SetScreen.swift:375` and is already used by
  three screens. **Leave it where it is declared.** Moving the type is churn
  this plan does not need.
- Spacing tokens are in `ios/Morning/DesignTokens.swift` — `Space.gutter` is 22.
  Do not introduce a literal.

## Steps

1. **`WorkoutHost.swift`** — add a computed label beside the existing
   `setLabel` property:

   ```swift
   /// The chrome's centre, for whichever step is current.
   ///
   /// The warm-up's is blank on purpose: its own headline directly beneath
   /// already says "Warm-up", and saying it twice 40pt apart is not
   /// orientation. That ruling came from the call site this replaces.
   private var chromeLabel: String {
       switch session.currentStep {
       case .timer: ""
       case .rest: "Rest"
       case .set: setLabel
       }
   }
   ```

   If `Step` is not an enum with exactly those three cases, STOP and report —
   do not guess at a `default`.

2. **`WorkoutHost.swift`** — wrap the existing `Group { … }` in a `VStack` and
   put the chrome above it, inside the `ZStack`, so it is a sibling of the
   ground and a parent of the swap:

   ```swift
   ZStack {
       Paper.stock
           .overlay(Halftone())
           .ignoresSafeArea()

       VStack(spacing: 0) {
           // HOISTED, for the reason the ground above it is hoisted.
           //
           // Inside the swap, the chrome was destroyed and rebuilt 28 times a
           // session — and because it is the only thing on screen during the
           // transition's gap, its absence is what made the swap read as the
           // whole screen repainting. Measured before the hoist: 220ms at
           // 0.00% ink coverage. See plans/011.
           WorkoutChrome(
               progress: progressOverride ?? sessionProgress,
               step: chromeLabel,
               setMarks: setMarks,
               onBack: { advance { session.back() } },
               onEnd: endSession
           )
           .padding(.horizontal, Space.gutter)

           Group {
               // …unchanged…
           }
       }
   }
   ```

   Keep every existing modifier on the `Group` exactly where it is — the
   `.overlay` for `EndSessionConfirm`, the `.animation`, the `onAppear`, the
   `onChange(of: session.endsAt)`. They move with the `Group`, not to the
   `VStack`.

3. **`SetScreen.swift`** — delete the `WorkoutChrome(…)` call at line 67 and
   the `.padding(.horizontal, Space.gutter)` attached to it. Keep the
   surrounding `VStack(spacing: 0)`. Delete the now-unused `stepLabel`,
   `setMarks`, `onBack` and `onEnd` properties **only if nothing else in the
   file reads them** — grep first; `SetScreen` may use `onEnd` elsewhere. If
   any is still used, leave it.

4. **`RestScreen.swift`** — delete the `WorkoutChrome(…)` call at line 163.
   Same rule about the properties: grep before deleting. `RestScreen` is known
   to use `onBack` and `onEnd` nowhere else, but verify rather than trust this
   sentence.

5. **`WarmupScreen.swift`** — delete the `WorkoutChrome(…)` call at line 49.
   Same rule.

6. **Update the call sites in `WorkoutHost.swift`** so the three screen
   initialisers no longer pass the arguments removed in steps 3–5. If a
   property was kept because something else reads it, keep passing it.

7. **`ReviewHost.swift` and any preview/host that constructs these screens
   directly** — update to match the new initialisers. Grep for `SetScreen(`,
   `RestScreen(` and `WarmupScreen(` across `ios/` and fix every call site.

## Boundaries

- Do NOT change `Motion.screenSwap`, `Motion.stage` or any duration, delay or
  curve. That is `plans/013`, and it must be measured *after* this lands.
- Do NOT un-hoist the ground. `01-motion-doctrine.md` §3.1: fading it per-screen
  measured 50 → 7 → 40 mean luma, a blackout.
- Do NOT add movement to the swap. §3.1: *"Why not a slide: movement costs
  readability, which is the thing being protected."*
- Do NOT reintroduce `matchedGeometryEffect` between Set and Rest. §3.1 forbids
  it by name; Eden asked for it removed twice.
- Do NOT move the `WorkoutChrome` type out of `SetScreen.swift`.
- Do NOT give `setMarks` a default value. Its doc comment records exactly what
  went wrong when it had one: three call sites disagreed and the rail changed
  style between screens.
- Do NOT change `WorkoutChrome`'s own body, layout or props.
- If the layout of any screen shifts vertically after the hoist — the content
  was sitting under a chrome that is now a parent — fix it with padding on that
  screen, and say so in the handoff. Do not "fix" it by changing `Space` tokens.
- If a step does not match the code you find, STOP and report rather than
  improvising.

## Verification

- **Mechanical**: `./scripts/verify-ios.sh` — 7 phases PASS, **118 assertions,
  0 skipped**. Anything less than 118 means a test was lost, not that a test
  was wrong.
- **Frames — this is the point of the plan, and inspection will not substitute
  for it.** This project has passed three animations by eye that did nothing or
  the wrong thing on screen.

  ```bash
  UDID=$(xcrun simctl list devices available | grep -F "iPhone 16 Pro (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  xcrun simctl io "$UDID" recordVideo --codec h264 --force /tmp/swap.mp4 & REC=$!
  sleep 2
  xcrun simctl launch "$UDID" com.edenturgeman.morning -screen set -session A -seed one-week -autoplay
  sleep 9
  kill -INT $REC
  swift ios/Tools/frames.swift /tmp/swap.mp4 /tmp/sw $(python3 -c "print(' '.join(f'{t/1000:.3f}' for t in range(4850,5600,25)))")
  ```

  Then measure **ink coverage**, not mean luma:

  ```python
  from PIL import Image
  import glob, os
  for f in sorted(glob.glob('/tmp/sw/*.png')):
      im = Image.open(f).convert("L"); w, h = im.size
      px = [im.getpixel((x, y))
            for y in range(int(h*0.09), int(h*0.95), 4)
            for x in range(0, w, 4)]
      print(os.path.basename(f), round(sum(1 for v in px if v < 120)/len(px)*100, 2))
  ```

- **Done when**:
  - **No frame of the swap reads 0.00% ink.** That single number is the plan.
  - The chrome's own pixels — the rail, BACK, END — are present in *every*
    frame of the capture, including the middle of the swap.
  - The label still changes: `"Set 2 / 14"` → `"Rest"` → `"Set 3 / 14"`.
  - The warm-up's chrome centre is still empty.
  - The progress rail and set-mark ticks are identical in inset and style on all
    three screens. `WorkoutChrome.setMarks`' doc comment records Eden reporting
    exactly this regression before: *"when you switch to the rest screens the
    progress bar at the top changes to the old style"*.
  - `./scripts/shoot.sh set`, `shoot.sh rest-card` and `shoot.sh warmup` each
    still render a complete screen with its chrome.
- **Feel check**: from 1.5m, tap `Done` without looking directly at the screen
  and confirm you can still tell it advanced. That is §3.1's actual job and the
  reason the transition exists at all; the chrome staying put must not cost it.
- **Frame rate**: make no claim. The simulator is not 120Hz. That is W11, on
  Eden's phone, still open.


---

## Outcome — 2026-09-11

**Done. The blank is gone.** Same capture, same metric, before and after:

| | before | after |
|---|---|---|
| floor during the swap | **0.00%** | **0.17%** |
| duration at the floor | 220ms | ~48ms |
| last full screen → next settled | 220ms+ | 170ms |

0.17% is the chrome, alone, and it is on screen in **every frame** of the swap.
The frame that used to be bare paper now shows BACK, END and the rail at full
opacity with the Rest screen fading in beneath them.

### One defect the hoist introduced, caught on film

Mid-swap, the chrome's centre printed **"SEREST13"** — `"SET 2 / 13"` and
`"REST"` cross-dissolving in the same place. Once the chrome persists it is one
`Text` whose string changes inside `advance()`'s `withAnimation`, so SwiftUI
animated between two different strings.

Fixed with `.contentTransition(.identity)` and `.animation(nil, value: step)` on
that label — the same ruling §3.2 already makes for the rep digit, *"per-set
identity so a new set's number never rolls from the previous set's"*. A fact
that smears is unreadable.

**This is a deviation from the plan's own boundary** ("do NOT change
`WorkoutChrome`'s body"). The boundary existed to stop scope creep; this was a
defect the hoist caused, so it was fixed with it.

### Also deviated from the plan

The `EndSessionConfirm` overlay moved from the `Group` to the new `VStack`. The
plan said to keep every modifier on the `Group`; that was wrong — left there,
the confirmation's dim would have covered everything except the chrome.

### Bonus, unasked for

The progress rail now animates its advance **through** the swap, because the
step change already runs inside `withAnimation(Motion.stage)` and the rail no
longer dies with the screen. That was listed as a missed opportunity in the
audit and it arrived for free.

### Verified

`./scripts/verify-ios.sh` — 7 phases PASS, 118 assertions, 0 skipped. Set, Rest
and Warm-up each shot statically and intact; the warm-up's chrome centre is
still deliberately empty.
