# 005 — Give every tappable control a press state

- **Status**: DONE — 2026-09-03, with one verification gap (see below)
- **Commit**: 259f47e
- **Severity**: HIGH
- **Category**: Purpose & feedback
- **Estimated scope**: 5 files, ~40 lines

## Problem

Seven controls in the shipped app have **no press feedback at all**. Six use
`.buttonStyle(.plain)`, which in SwiftUI means "draw the label and nothing
else" — no highlight, no scale, no ink. One pair has no button style at all.

`ios/Docs/redesign/01-motion-doctrine.md` §1.2 puts press feedback outside the
frequency gate that removes almost every other animation in this app, and says
why: at 6:10am with the phone on the floor, the press state is often the only
proof a knuckle tap landed. This is **not** a polish item — it is the one
category of motion the doctrine refuses to trade away.

This exact defect has already been found and fixed twice in this codebase, and
both fixes left comments saying so — `RepStepper` carried it for months, and
`ios/Morning/Screens/RestScreen.swift:617` records the second:

> The rows had `.buttonStyle(.plain)` and therefore NO press state at all —
> the same defect `RepStepper` carried for months, on a control where a missed
> tap costs you the question.

The seven that were missed:

```swift
// ios/Morning/Screens/RestScreen.swift:926 — current
// The study card itself. Tapping it reveals a factoid or opens a question:
// the primary interaction on the Rest screen.
        .buttonStyle(.plain)
```

```swift
// ios/Morning/Screens/SummaryScreen.swift:241 — current
// The Summary's study card. Same component role.
        .buttonStyle(.plain)
```

```swift
// ios/Morning/Screens/HomeScreen.swift:123-130 — current
// The loadout row — a ~60pt target that opens the weight editor.
            Button {
                withAnimation(Motion.reveal(reduceMotion: reduceMotion)) {
                    editingLoad.toggle()
                }
            } label: {
                loadout
            }
            .buttonStyle(.plain)
```

```swift
// ios/Morning/Screens/HomeScreen.swift:453-464 — current
// The weight +/- keys. 62x62, and they draw their own rounded border.
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .frame(width: 62, height: 62)
                .foregroundStyle(enabled ? Paper.press : Paper.press)
                .background(Color.clear, in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Paper.press, lineWidth: 2.5)
                }
        }
        .buttonStyle(.plain)
```

```swift
// ios/Morning/Screens/HistoryScreen.swift:222-229 — current
// The delete key on a history row.
                        Button {
                            confirming = record
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Paper.danger)
                        }
                        .buttonStyle(.plain)
```

```swift
// ios/Morning/Screens/SetScreen.swift:404-410 — current
// BACK and END in the workout chrome. No button style at all, and
// `.foregroundStyle(Paper.press)` is applied to the enclosing VStack at
// line 417, which may suppress the system's default press tint.
                    Button("BACK", action: onBack)
                        .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .leading)

                    Spacer()

                    Button("END", action: onEnd)
                        .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .trailing)
```

## Target

Three shapes of control, three treatments. All three are 0.10s `easeOut` with
no delay, which is this app's existing press timing.

**1. Sheet-sized surfaces** (both study cards, the loadout row) — an ink wash
plus a small scale. A new shared style, promoted from the private one that
already exists in `RestScreen.swift`:

```swift
// target — ios/Morning/PaperTokens.swift
/// A large surface being pressed: a card, a row, a sheet.
///
/// An ink WASH rather than a fill, because these surfaces carry text that has
/// to stay readable while the thumb is down. `scale` is a parameter because
/// the right factor depends on how wide the thing is: 0.97 on a 68pt key reads
/// as a press, 0.97 on a full-width sheet reads as the whole screen flinching.
struct PressSheetStyle: ButtonStyle {
    var scale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Paper.press.opacity(0.14) : Color.clear)
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}
```

**2. Key-sized targets** (the weight +/- keys, the history delete key) — the
same style at `scale: 0.97`. They already draw their own borders, so
`PressKeyStyle` is the wrong tool: it would stamp a square border on top of a
rounded one.

**3. Text-only chrome** (BACK, END) — the visible thing is a ~10pt word, so a
scale is below the perceptual threshold and opacity carries it:

```swift
// target — ios/Morning/PaperTokens.swift
/// A bare word being pressed, where there is no shape to flip.
///
/// Opacity, not a wash: the chrome sits on the stock, and a rectangle of ink
/// appearing behind a word floating on the background reads as a rendering
/// fault rather than as a press. The scale is present but small — it is the
/// opacity doing the work at this size.
struct PressLabelStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.45 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}
```

## Repo conventions to follow

- **Shared button styles live in `ios/Morning/PaperTokens.swift`**, alongside
  `PressKeyStyle` (line ~296) and `PressBlockStyle` (line ~330). Put both new
  styles immediately after `PressBlockStyle`.
- **The exemplar to imitate** is `PressKeyStyle` at
  `ios/Morning/PaperTokens.swift:304-319`. Note its shape: `makeBody` reads
  `configuration.isPressed`, changes ink and scale, and ends with a single
  `.animation(.easeOut(duration: 0.10), value: configuration.isPressed)`.
- **The scale factors are already reasoned about in this repo and must not be
  re-picked.** `PressKeyStyle` uses 0.97 on a key; `StudyOptionStyle`
  (`RestScreen.swift:619-634`) uses 0.98 on a full-width row and says why;
  `PressBlockStyle` uses 0.985 on the full-width primary bar and says why.
- The module builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. These are
  `ButtonStyle`s, not `Shape`s, so **no `nonisolated` is needed** — do not add
  it. (Only `Shape` conformances in this codebase need it; see `MarginTick`.)
- Every new type gets a doc comment saying *why*, not *what*. That is the house
  style throughout `PaperTokens.swift`; match its density.

## Steps

1. In `ios/Morning/PaperTokens.swift`, immediately after the closing brace of
   `PressBlockStyle`, add `PressSheetStyle` and `PressLabelStyle` exactly as
   written in **Target** above, doc comments included.

2. In `ios/Morning/Screens/RestScreen.swift`, delete the now-duplicated private
   `StudyOptionStyle` (lines ~614-634, including its doc comment) and change
   its one use site at line ~1026 from
   `.buttonStyle(StudyOptionStyle())` to `.buttonStyle(PressSheetStyle())`.
   **Carry the explanation of the 0.98 factor across** into `PressSheetStyle`'s
   doc comment if it is not already covered — it is the record of why that
   number is not 0.985.

3. In `ios/Morning/Screens/RestScreen.swift:926`, change `.buttonStyle(.plain)`
   to `.buttonStyle(PressSheetStyle())`.

4. In `ios/Morning/Screens/SummaryScreen.swift:241`, change
   `.buttonStyle(.plain)` to `.buttonStyle(PressSheetStyle())`.

5. In `ios/Morning/Screens/HomeScreen.swift:130`, change `.buttonStyle(.plain)`
   to `.buttonStyle(PressSheetStyle())`.

6. In `ios/Morning/Screens/HomeScreen.swift:464`, change `.buttonStyle(.plain)`
   to `.buttonStyle(PressSheetStyle(scale: 0.97))`.

7. In `ios/Morning/Screens/HistoryScreen.swift:229`, change
   `.buttonStyle(.plain)` to `.buttonStyle(PressSheetStyle(scale: 0.97))`.

8. In `ios/Morning/Screens/SetScreen.swift`, add
   `.buttonStyle(PressLabelStyle())` to both `Button("BACK", ...)` (line 405)
   and `Button("END", ...)` (line 410), after their existing `.frame(...)`.

## Boundaries

- Do NOT touch `PressKeyStyle` or `PressBlockStyle`. Their scale factors are
  documented decisions.
- Do NOT change any `.frame`, padding, hit target, colour, or layout. Motion
  and press state only.
- Do NOT change what any button *does* — no action closures are in scope.
- Do NOT add press feedback to anything not listed in Steps 3-8. In particular
  the step block, the rail marks and the countdown ring are not buttons and
  must stay static.
- Do NOT add dependencies.
- If a line number does not match what you find (the file has drifted since
  commit `259f47e`), locate the same construct by its surrounding code and
  proceed; if you cannot find it, STOP and report rather than guessing.

## Verification

- **Mechanical**: `./scripts/verify-ios.sh` — expect all seven phases PASS,
  76 assertions, 0 skipped. It runs build, tests, SwiftLint and SwiftFormat and
  writes every error to `ios/build/verify-report.txt`.

- **Feel check.** `mcp__Claude_Code_iOS_Simulator__control` can drive taps in
  the simulator, or hand the build to Eden. For each control, press and hold and
  confirm the state appears *while the finger is down* and clears on release:

  ```bash
  ./scripts/shoot.sh rest-card --keep -card w-madeira-estufagem   # study card
  ./scripts/shoot.sh home --keep                                  # loadout, weight keys
  ./scripts/shoot.sh history --keep                               # delete key (tap Edit first)
  ./scripts/shoot.sh set --keep                                   # BACK / END
  ```

  - The study card darkens under the thumb and springs back — **the text stays
    readable throughout**. If the wash swallows the question, the opacity is
    too high; it is 0.14 and must not go above it.
  - The weight keys move visibly. At 62pt a 0.97 scale is ~1.9pt on each edge;
    if you cannot see it, the style did not apply.
  - BACK and END dim clearly. This is the check most likely to fail, because
    `.foregroundStyle` is applied by an ancestor — if the words do not dim, the
    style is being overridden and the fix is to move
    `.foregroundStyle(Paper.press)` from the VStack at `SetScreen.swift:417`
    onto the two `Text`s that are not buttons.

- **Frame capture, for anything you cannot judge by eye.** Inspection has three
  times passed an animation on this project that did nothing on screen, so a
  press state that "looks applied" in the diff is not evidence:

  ```bash
  xcrun simctl io booted recordVideo --codec h264 press.mp4 &
  # press and hold the control
  swift ios/Tools/frames.swift press.mp4 out/ 2.0 2.1 2.2
  ```

- **Done when**: all seven controls show a visible change within 100ms of touch
  down, `verify-ios.sh` reports 0 failed phases, and no layout has moved —
  compare a before/after screenshot of Home and the Rest card at rest and
  confirm they are identical.


---

## Outcome — 2026-09-03

All eight steps applied. `verify-ios.sh`: 7 phases PASS, 76 assertions, 0
skipped.

**The feel check could not be completed, and the reason is worth recording.**
The simulator control tool's `tap` lands (a plain tap on the rep `−` key moved
the count 14 → 13 and brought up the "Last time: 14" line, filmed), but its
long-press variant — `duration: 1.4` — reports success and **never reaches the
app**: the same `−` key did not decrement, and a 6-second capture of the whole
screen was byte-identical in every frame.

That leaves no way from here to hold a control down. An injected tap is
down-and-up inside a single event, so `isPressed` may never survive to a drawn
frame: filmed at 20fps across the study card's own tap, the card region held
209.58 luma through every frame until the answer's reveal began at 5.75s. **No
press wash was captured — and that is equally consistent with "it works and
lasted under a frame".** It is not evidence either way, and it must not be
written up as if it were.

The same limitation was checked against a control whose press state is known
good — `RepStepper`'s, which has shipped for months — and it filmed identically
blank. So the method is what failed, not the styles.

**Outstanding: one human press of each control.** The live simulator panel is
the place to do it. Watch for the card darkening under the thumb with the text
still readable, the weight keys visibly moving, and BACK/END dimming.
