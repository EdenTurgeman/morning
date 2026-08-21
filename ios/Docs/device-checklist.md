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

## Notes

<!-- date · device · iOS version · what you saw -->
