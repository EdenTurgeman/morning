# 05 — Native platform: what changes

Half of this document is about constraints that no longer exist. Read it before
you port anything, because a lot of the web source is scar tissue from working
around problems you do not have.

---

## 1. Constraints that are now dead

| Web constraint | Status on native |
|---|---|
| No runtime network — offline-first PWA with a service worker | **Still true, and now free.** An app bundle is offline by definition. Delete the whole service-worker/caching concern. |
| Bundle size discipline (~550KB JS budget, font subsetting, no audio files) | **Dead.** Ship real audio, real illustration, Rive files, whatever raises quality. |
| "No dependencies, no build step" (from the original `spec.md`) | **Void.** That was written when the target was one HTML file. Use SPM packages freely. |
| No haptics — iOS Safari has no Vibration API | **Dead, and this is the biggest single upgrade.** See §3. |
| Web Audio is muted by the ring switch; claiming a non-ambient session kills the user's music | **Dead.** AVAudioSession does this properly. See §2. |
| `100dvh`, `-webkit-fill-available`, body scroll-lock, inner scroll container, black bars at the bottom | **Dead.** All of it. |
| Manual `env(safe-area-inset-*)` arithmetic | **Dead.** |
| Screen Wake Lock is unreliable in standalone PWAs | **Dead.** One property. See §5. |
| `localStorage` can be evicted; data does not survive deleting the home-screen icon | **Dead.** Real files plus iCloud. See `06-data.md`. |
| No Live Activities, no widgets, no Health, no notifications | **All available now.** See §4, §6, §7. |
| Inter, because SF Pro is not available to web apps | **Dead.** Use SF Pro properly. |
| CSS/DOM animation ceiling | **Dead.** 120Hz, Metal shaders, SpriteKit, real spring physics. |

## 2. Constraints that are still real

- **20 minutes.** The session must fit. This is a product constraint, not a
  technical one.
- **Light dumbbells, fixed weight.** Reps are the only signal.
- **6am, half awake, sweaty hands, phone on the floor.**
- **One user.** No accounts, no sync between people, no sharing.
- **No gamification.** See `01-product.md` §"The tone".

### Old non-goals: which were principle and which were platform

The original spec listed non-goals. Sort them before you assume:

**Still non-goals — these are principle:**
accounts · login · cloud sync of the multi-user kind · social features · streak
badges and points · a workout builder UI · charts and analytics beyond what
exists · multiple users.

**Now open, because they were only ruled out for being impossible on the web:**
notifications · Apple Health · Live Activities · widgets. The user has already
asked about Live Activities specifically. Propose these; don't just build them.

---

## 3. Audio and haptics

### Audio — get the session category right

The web version got this wrong in a way worth understanding, because the same
mistake is available natively. It claimed the equivalent of `.playback` *and*
held a silent looping audio element open for the life of the page, which told
iOS "this is what the user is listening to" — so Music stopped and stayed
stopped. The user reported it as "working, and not letting me play music".

What he asked for, verbatim:

> I want music to seamlessly stop when the app counts down from 5 and come back
> after it's done, same with every sound.

The right shape natively:

- `AVAudioSession` category `.playback` with options `[.mixWithOthers, .duckOthers]`,
  or `.ambient` + `.duckOthers` if you prefer the ring switch to apply.
  `.duckOthers` gives the smooth dip-and-return he described.
- **Activate the session around cues and deactivate after**, with
  `.notifyOthersOnDeactivation` so the other app's audio is restored promptly. An
  always-active session ducks music for the whole twenty minutes.
- **Coalesce the countdown into one duck.** The last five seconds are six
  separate sounds; they must be a single hold that dips the music once at five
  and restores it once after zero, not six pumps. The web build does this with a
  shared release deadline that each cue pushes forward — same idea applies.
- Unlike the web, you can now ignore the ring switch if you choose. Ask the user
  which he prefers rather than deciding for him: hearing the countdown with the
  phone silenced, or never overriding his silent switch.

### The cues

Six sounds, currently synthesised with oscillators. You may bake them as audio
files now — the "no assets" rule was a bundle-size constraint. Keep the design:

| Cue | When | Character |
|---|---|---|
| Countdown tick | Last 5 seconds of every timer | C5 · D5 · E5 · G5 · A5 — ascending, each slightly louder and longer than the last |
| Go | Zero | C6 with C5 underneath — longer and louder than any tick |
| Confirm | A set is logged | Short, dry, quiet — an acknowledgement, not an event |
| Beat it | The rep counter passes last time's number | Two rising notes |
| Chime | Session complete, on Daybreak | A major arpeggio resolving up the octave, with a pad under it |
| — | Study cards | **Silent, deliberately.** See `04-rules.md`. |

The count-in ascends on purpose: a rising line reads as tension building toward
"go"; a falling one reads as winding down, which is the opposite of what you want
two seconds before a set. Each step is louder and longer than the last so you can
tell where you are without listening for pitch — the phone is on the floor and
you are face-down over it.

### Haptics — design these as carefully as the visuals

**The web app has no haptics at all.** Every tap in it is mute to the hand. This
is the largest available improvement in felt quality and it costs very little.

Write a haptic vocabulary down as a table alongside the animation timings. At
minimum:

- **Rep increment / decrement** — a light, crisp transient. It should feel like a
  detent, not a buzz.
- **Passing last time's number** — a distinctly *different*, more satisfying
  event. The user should be able to tell he beat it with the phone face down.
- **Set logged** — a confirming transient with a little weight.
- **Countdown, last five seconds** — a pulse per second, intensifying, so the
  count works with the phone on the floor and the volume off.
- **Zero** — an unmistakable pattern, transient plus a short continuous decay.
- **Session complete** — a designed CoreHaptics pattern choreographed against
  the Daybreak animation, not a canned success notification.
- **Card reveal** — something soft. This is the one place a *sound* is banned but
  a haptic is welcome.

Use CoreHaptics (`CHHapticEngine`) for anything with shape; `UIFeedbackGenerator`
is fine for simple transients but will not get you the good ones. Handle engine
reset and the audio-session interaction — haptics stop when the engine is torn
down by an interruption.

---

## 4. Live Activity and Dynamic Island

The rest timer is close to a perfect Live Activity, and the user has asked about
this before. `Text(timerInterval:)` counts down on the Lock Screen and in the
Dynamic Island with **no updates from the app at all**, which means it costs
essentially nothing.

Worth considering:

- Start an Activity when a rest begins; end it when the rest ends.
- Compact leading: the accent ring or session letter. Compact trailing: the
  seconds. Expanded: what's coming next.
- Possibly one Activity for the whole session showing overall progress, rather
  than one per rest — decide from how it actually feels, and prototype both.

This is the feature most likely to make the app feel native rather than ported.
It is also the one most likely to become annoying if overdone. Prototype, don't
assume.

---

## 5. While a session is running

- `UIApplication.shared.isIdleTimerDisabled = true` for the duration. The screen
  must not sleep mid-set. Release it when the session ends or is abandoned.
- Handle interruptions properly: a phone call, Control Centre, a switch to Music.
  The session state must survive and the timer must still be correct on return —
  compute remaining time from a stored end date, never from a tick counter.
- Consider a local notification if a rest timer expires while the app is
  backgrounded, so you are not left waiting on a screen you can't see. Gate it on
  actually being backgrounded.

---

## 6. Persistence

See `06-data.md` for the schema. Recommended shape:

- A single `Codable` struct written as JSON to Application Support. The dataset is
  a few tens of KB per year — SwiftData and Core Data are overkill and add
  migration cost for nothing.
- Atomic writes. Never lose data on a failed write; surface the failure.
- **iCloud** (`NSUbiquitousKeyValueStore` is too small; use CloudKit private
  database or an iCloud Documents file) turns the backup screen from a chore into
  a background detail. Keep manual export anyway — it is the only thing that
  survives losing the phone *and* the account.
- The in-progress session persists separately so a crash mid-workout costs
  nothing.

## 7. HealthKit and widgets — propose, don't assume

- **HealthKit**: writing each session as a strength-training workout would close
  the user's rings and put the app in the Fitness ecosystem. It was a non-goal
  only because the web could not do it. Ask.
- **Home-screen widget**: the week's pips and which session is next. Small,
  quiet, honest — it fits the app's tone and answers "am I behind?" without
  opening anything. The web version already does a version of this with the app
  icon badge.
- **Control Centre / Action Button**: starting today's session in one press is
  plausibly the single best affordance available on this hardware for a
  20-minute daily habit. Worth prototyping.
