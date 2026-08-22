# Device checklist

From `ios-port/07-acceptance.md`. **These cannot be automated and they are not
simulator checks.** Do them on the phone.

Record what you *observed*, not pass/fail — "readable but the sub-label washes
out under 4% brightness" is worth something; a tick is not.

## The ten

- [ ] Airplane mode is indistinguishable from normal.
- [ ] Nothing scrolls on any workout screen, at any content length.
      (Longest exercise name, four cues, a three-line question with a seven-line
      answer.)
- [ ] Exercise name and rep count readable at 1.5 m in a dark room.
      Test it literally: hold the phone at arm's length, then double the distance.
- [ ] Every meaningful tap produces a haptic, and the **"beat your last number"**
      haptic is distinguishable from the ordinary one **with the phone face
      down**. This is the one that matters most — it is the emotional centre of
      the app and the phone is on the floor.
- [ ] Music from another app **ducks once** at five seconds and returns after
      zero. It does not stop, and it does not pump six times.
- [ ] The screen never sleeps mid-session.
- [ ] 120Hz with no dropped frames while a timer runs.
- [ ] Reduce Motion produces a **calmer** app, not a broken one.
- [ ] A full session of A and a full session of B, start to finish, zero glitches.
- [ ] Then do it again for real at 6am. **That is the only test that actually
      counts.**

## Interruptions — do these deliberately

- [ ] Take a phone call mid-rest. The timer is still correct on return.
- [ ] Open Control Centre mid-set, then come back.
- [ ] Switch to Music mid-session, play something, come back.
- [ ] Force-quit mid-workout and relaunch: same step, same logged reps, correct
      remaining time.
- [ ] Let a rest timer expire while the app is backgrounded.

## Before any of this works: Xcode has to match the phone

Eden's iPhone runs an **iOS 27 beta**. Xcode can only install and debug on a
device whose OS it ships device support for, so:

- **Xcode 26 stable cannot deploy to it.** You will get "this iPhone is running
  iOS 27.0, which may not be supported by this version of Xcode". That is a
  tooling mismatch, not a bug in the app.
- Installing on the phone therefore needs the **Xcode 27 beta** (or whichever
  Xcode ships iOS 27 device support). Everything else — building, the whole
  acceptance suite, the simulator, CI — works on Xcode 26 stable and does not
  care what the phone is running.
- **The deployment target stays iOS 26.0 deliberately.** An app built for 26
  runs on 27 perfectly well, and pinning it to 27 would chain the project to a
  beta SDK and break if the phone is ever rolled back. Raise it only if
  something actually needs an iOS-27-only API.

So: if you are an agent and cannot get onto the device, check the Xcode version
before you debug anything else. And if the device pass has to wait for the right
Xcode, say so and stop — do not tick these boxes from the simulator.

## What each check is actually looking for

Written after W1–W10, when every screen exists and the whole session runs. The
list above predates that; this is the same list with the specifics filled in, so
nobody has to reconstruct what "a haptic" means at 6am with a phone in one hand.

### Getting to a state without playing a whole session

The app boots to Home. These launch arguments jump straight to a state, and they
exist because there is no Simulator UI on the development machine — on the phone
you can just use the app, but they are still the fastest way to sit on one
screen and stare at it.

```text
-seed six-months                     replace the history with a fixture
-screen set -progress 1.00           the Set screen at the gold end of the dawn
-screen set -slot 4.0.0              the worst content in the program
-screen set -reps 15                 the counter already past last time
-screen set -step 15                 a carded rest
-screen summary -tier plateau        one celebration tier
-screen ledger | guide | backup | history
-screen lab                          the W1 direction lab, still runnable
```

### The haptic that matters most

`DesignHaptics.swift` is the vocabulary. What to feel for, face down:

| Moment | What it should feel like |
|---|---|
| Ordinary rep | ONE event. A detent, not a buzz |
| **Passing last time** | **TWO events, 45ms apart.** Rhythm, not volume — that is the whole design, because the hand reads rhythm far better than amplitude |
| Set logged | One event with more weight behind it |
| Last five seconds | One per second, climbing in both intensity and sharpness |
| Zero | A hard transient with a short continuous decay under it — it lands, then releases |
| Card reveal | The softest thing in the app. An answer arriving, not an action you took |
| Session complete | Three rising transients then a swell, choreographed against Daybreak's sun |

**The acceptance test is the second row.** If passing last time's number does not
feel obviously different from an ordinary rep with the phone face down on the
floor, the design has failed regardless of how it looks. Nothing about it has
ever been felt — every value is reasoned from `05-platform.md §3`, not tuned.

### The ducking

Start music in another app first, then run a rest to zero.

- It must **dip once** at five seconds and come back once after zero.
- Six dips means the shared release deadline is not working — that is
  `DuckWindow`, and its logic is unit-tested, so a failure here is the session
  activation rather than the timing.
- Music **stopping** rather than ducking means the session category is wrong.
  That is the exact bug Eden reported against the web build: *"working, and not
  letting me play music."*

### Glare, which only the phone can settle

**10.1% of the Set screen sits at code ≥200**, almost all of it the primary
button. Every contrast figure in `design-system.md` was measured on rendered
frames and every one clears the floor — but none of that says whether a
full-width bright bar is comfortable or punishing in a dark room at 6:10am with
auto-brightness near minimum. Look at it, in the dark, and say.

### 120Hz

The app opts into ProMotion (`CADisableMinimumFrameDurationOnPhone` in the built
Info.plist, checked). The things most likely to drop frames, in order:

1. The rest timer's `TimelineView(.animation)` while the sky's cloud banks drift.
2. `CloudTexture` building three 1024×256 noise fields on first access — that is
   CPU work in a `static let`, on the main actor. It has never shown at launch
   on the simulator, which proves nothing.
3. Daybreak, which drives every stage off one clock for 4.4 seconds.

### What has never been exercised at all

Being explicit, because "it built and the tests pass" is not the same thing:

- **No tap has ever reached this app.** The development machine has no
  `Simulator.app`, only the headless runtime, so every screen was reached by
  launch argument. Buttons, the rep control's hold-to-repeat, sheets, the file
  picker and every confirmation dialog are untested by anything but the eye.
- **No haptic has been felt and no cue has been heard.**
- Restore and Erase have never been run. The export *format* is checked on every
  CI run against the web app's own parser; the pickers around it are not.

## Notes

<!-- date · device · iOS version · what you saw -->
