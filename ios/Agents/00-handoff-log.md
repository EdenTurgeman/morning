# Handoff log

Append-only, newest at the top. One agent works this clone at a time; this file
is the only thing standing between the next agent and re-deciding what you
already decided.

The - **The threshold delay had to clear the digit ROLL, not visual fusion.** The
  counter recolours over 0.18s but `contentTransition(.numericText)` is not
  finished until ~0.24s. A 0.09s delay — chosen from the perceptual fusion
  threshold — still put the sentence first. It is 0.22s.
- **Two `matchedGeometryEffect` sources is a silent conflict.** Both the counter
  and the ring declared the default `isSource: true`. SwiftUI does not warn —
  the device log is clean — it just picks one, and it picked the counter, which
  is why exactly one direction morphed. The counter is now the source
  permanently and the ring follows. Verified that a settled Rest screen with no
  source in the tree renders correctly.
- **Daybreak was reviewed frame by frame and needs nothing.** It runs its
  documented choreography exactly: the horizon draws outward from the centre
  with nothing else on screen, then the sun rises and overshoots, the rays
  bloom, the flash lands, the number springs in, the pips stagger, the copy
  follows. The anticipation beat the web version lacked is real and it works.

**Landmines** field is worth more than the summary of what you built.

---

## 2026-08-22 · Quality pass — the Set↔Rest transition · Claude Opus 5

**Workstream:** quality pass over W4/W5, on `ios-port/quality-pass`

**What I did**
- **Built the Set↔Rest transition, which did not exist.** The app swapped the
  two screens instantly. `02-design-brief.md §7` asks for `matchedGeometryEffect`
  by name and the W1 prototype had already proved counter→ring continuity; none
  of it had been wired into the real screens. The rep counter and the rest ring
  now share `WorkObject.id` in a namespace owned by `WorkoutHost`, and every step
  change routes through one `advance(_:)` that wraps the mutation in
  `Motion.stage`.
- **Hoisted `DawnBackdrop` out of `SetScreen` and `RestScreen` into the host.**
- **Added `Motion.screenSwap`,** an asymmetric fade replacing the default
  cross-fade.
- **Found and fixed a stray duplicate `.onAppear` on `WorkoutHost`** that set
  `isIdleTimerDisabled = false` and called `Audio.shared.stop()` immediately on
  arrival. The screen would have slept mid-session and the cues would have been
  silent. Moved to `sessionEnded`. This is exactly the bug the device checklist
  lists as "the screen never sleeps mid-session" — it would have failed, on the
  phone, at 6am, and nothing in the simulator would ever have shown it.
- **Added `ios/Tools/frames.swift`**, `-autoplay` and `-autorep`.
- **Verified Reduce Motion for the first time.**
- **Made crossing last time's number two beats instead of one.** The threshold
  haptic is two events 45ms apart; the screen was firing one. Worse, it fired in
  the wrong order — the sentence underneath the counter was fully legible 0.12s
  BEFORE the digit began to move.
- **Made the work object travel in both directions.** Set→Rest morphed;
  Rest→Set only cross-faded.
- **Stopped the study card's answer landing on top of the question.** Three
  layers of legible text for ~150ms on every card reveal.

- **Made a rest that reaches zero move on, and gave the last five seconds a
  visual.** Two regressions against the web build, found by watching a 20-second
  myo rest run out. The rest sat on "0 SEC" forever waiting for a tap, and the
  screen did nothing over the last five seconds while the audio and the haptics
  both ramped.

- **Built the warm-up screen, which W5 deferred and nobody came back for.** Step
  0 of both sessions is a 90-second warm-up with cues. `WorkoutHost` called
  `goToFirstSet()` past it on every session under a comment saying "until it
  exists" — so the app silently dropped a programmed step. And the step stayed
  reachable: `back()` from the first set landed on it, the `Group` had no branch
  for a timer, and it fell through to a placeholder reading **"Session complete
  / Summary and Daybreak are W7."** A workout that had not started announcing it
  was over, quoting a workstream number, one tap in.
- **Fixed `minutes` flooring at 0 instead of 1.** `src/hooks/useWorkout.ts` does
  `Math.max(1, …)`. A session finished inside thirty seconds recorded a duration
  the web build cannot produce, in a file the web build reads back through
  Restore. Test added.
- **Removed `ScaffoldView`.** Dead — only its own `#Preview` referenced it — and
  its copy said "no screens built yet", which stopped being true at W4.

**Read the web source for behaviour, not just for reasoning.** Both of those
were one grep away the whole time. `src/hooks/useCountdown.ts` wires
`onComplete` to `onAdvance` and carries a `setInterval` beside its rAF loop
specifically so "a rest could [not] hang forever on a phone that decided not to
paint"; `src/components/Ring.tsx` computes an `urgency` term over the last five
seconds and calls it peripheral warning. CLAUDE.md rule 2 says the source wins
on *what*. On the myo rest the port was telling the user "The 20-second rest IS
the mechanism — don't stretch it" while stretching it indefinitely.

**The one bug behind three of those:** `@ViewBuilder` branch swaps do not
animate here. `.transition(.opacity)` on a branch, with or without a delayed
`.animation(_:value:)`, had no effect in either the rep comparison line or the
study card — the new content just appeared, instantly, at full opacity. Both are
now opacity on a view that never leaves the tree, which is the primitive that
honours a delay. **If you add a third conditional that needs to animate, assume
it will not, and measure it.**

**Decisions taken**
- **Motion is now reviewed off video, not screenshots.** Backgrounded
  `simctl io screenshot` calls each take ~0.5s to start, so their timestamps
  drift past whatever you are trying to catch — six of them "0.1s apart" landed
  on six identical frames and I spent a while believing the transition was
  broken when it was the capture that was. `simctl io recordVideo` plus
  `AVAssetImageGenerator` with zero tolerance gives exact frames at exact times.
  There is no ffmpeg on this machine and none is needed.
- **The transition was tuned against two measurements, not taste.** Consecutive
  frame difference locates it; mean luminance across it catches the failure a
  contact strip hides. Three versions:

  | Version | Furniture | Mean luma across the swap |
  |---|---|---|
  | Symmetric cross-fade | both screens legible at ~50% for 0.2s — mush | — |
  | Fade-through, sky per-screen | clean | **47 → 7 → 40. A blackout.** |
  | Fade-through, sky hoisted | clean | 50 → 22 → 40. A breath. |

  The middle row is why the sky moved to the host. Fading the furniture is
  right; fading the sky with it made the whole display blink 25+ times a
  session.
- **The overlap window is deliberate, not sloppy.** Zero overlap reads as a cut
  and kills the morph — the counter has to still be there when the ring starts.
  Insertion is delayed 0.04s over 0.30s against a 0.24s removal: enough
  separation that the cues and buttons never stack legibly, enough overlap that
  14 becomes 60 in one motion.

**Landmines**
- **`-autoplay` was chained and I did not notice for a while.** I had copied the
  block into `.onChange(of: session.stepIndex)` as well as `.onAppear`, so each
  advance scheduled the next and the app walked the session on its own. Fixed —
  it fires once, from `onAppear`. If a future capture seems to skip a step, look
  there first.
- **Reduce Motion is only verified for the swap.** I confirmed the transition
  collapses from ~0.45s to ~0.2s, and the sky honours it in three places
  (`PrototypeSky.swift`). Daybreak, the rep control and the celebration
  choreography under Reduce Motion are still unlooked-at.
- **`-autorep` originally wrapped the change in `withAnimation`, which a tap
  does not.** It was measuring a timing the product never runs. Any harness that
  drives the app has to take the same path a finger would or it measures itself.
- **My first two threshold measurements had both sample bands inside the
  counter**, so "the sentence" I was timing was the digits. Band positions now
  come from a row scan of the actual frame. If a measurement says something
  surprising, check what it is pointing at before believing it.
- Daybreak's first ~100ms is a grey wash when reached by launch argument. That
  is the white launch screen fading out, not Daybreak — arriving from a workout
  the app is already dark. Do not "fix" it.
- The luminance dip is 50 → 22. I believe that reads as a breath rather than a
  flicker, but nobody has seen it on a real display in a dark room. It is on the
  device checklist now.

- **Killed a fault storm in the audio session.** Found by running a whole
  session hands-free and reading the device log: 87 `AVAudioSession Hang Risk`
  faults, two per second, at exactly the five countdown seconds, while
  `TimelineView(.animation)` drives the ring.

  **My first fix was correct and did nothing, and I published a wrong number
  before catching it.** I moved `setCategory`/`setActive` off the main actor —
  right, but not the cause. I then compared a full session's 87 against a single
  rest's 12 and wrote "87 down to 12" into the commit, the PR and two docs.
  Session B, with the fix in, logged **122 over 10 rests — 12.2 per rest against
  A's 12.4.** No change at all.

  The real source is `AVAudioEngine.start()`, which activates the session
  internally on the main thread and was being retried on **every cue**, because
  the headless simulator has no audio route (`error -10879`) so the engine never
  starts and never stops trying. Bounding the retry to one attempt per
  activation: **1 fault per rest.**

  **Normalise before you compare.** Both sessions were sitting there; I used one
  of them and not the other.
- **Handled audio interruptions.** The bounded retry needed it: a phone call
  mid-rest deactivates the session and stops the engine, and without clearing
  the flags the retry latches and the rest of the session is silent. That is a
  device-checklist scenario, so it would have been found — on the phone, at 6am.
- **Added `-autorun`**, which plays a session from Home with no taps: start,
  warm-up, every set and rest, finish, Daybreak, Summary. `07-acceptance.md`
  asks for "a full session of A and a full session of B, start to finish, zero
  glitches" and there had been no way to ask. It only works because the warm-up
  and the rests now advance themselves — the flag and those fixes found each
  other.

**What the behaviour diff found, and what it cleared.** I went through every
`useEffect`, timer and listener in `src/` against the port. Cleared: `back()` is
guarded (the port's `move(to:)` clamps to `steps.indices`), a double-tap on the
final Done cannot write two records (`AppRoot.finish` guards and runs to
completion on the main actor), the status bar needs no tint because the zenith
stays dark at every progress, and `unlockAudio` is a web-only autoplay
workaround. Still open, and Eden's call rather than mine: the web sets an **app
icon badge** with the sessions still owed this week (`setWeekBadge`). The native
equivalent needs notification permission, which `05-platform.md §7` says to
propose. **That belongs in W12.**

The one deliberate divergence I left: the web's `progress` is `i / steps.length`
and the port's is `stepIndex / (count - 1)`, so the port's dawn actually
completes on the final step instead of stopping at 0.95. That is form, and the
brief wants the dawn to finish.

**Assertions:** 55 of 57 passing (2 skipped — both device-only)

**Both sessions now run start to finish.** `-autorun` plays one from Home with
no taps at all. A took 450s and finished on "Same as your last A / 209 reps /
Dead level."; B took 518s and "Same as your last B / 249 reps / Dead level."
Zero SwiftUI or layout complaints across 1,683 lines of device log. That is the
first time this app has run end to end, and it is only possible because the
warm-up and the rests now advance themselves.

**Next:** W11 is the device pass and is still blocked on hardware — but the
checklist is now much more specific about what to look for, and three items on
it are new because of this pass. W12 needs Eden's yes per item, and it has one
more candidate than it did: the web's app-icon badge.

**Two things waiting on Eden, both written up above rather than decided here:**
the app-icon badge (needs notification permission, `05-platform.md §7` says
propose), and whether card text should scale with Dynamic Type given that
`answer`'s 14.5pt is tuned to the seven-line stress case on a screen that cannot
scroll.


## 2026-08-22 · Figures, control boundaries, accessibility verification · Claude Opus 5

**Workstream:** post-W2 refinement on the agreed direction.

**What I did**
- **Rebuilt the exercise figures as bodies.** The brief notes Eden has flagged
  the web stick figures twice; the first native pass reproduced the same problem
  in Swift. `PrototypeFigure.swift` draws the same poses as filled, tapered
  shapes — limbs thinning toward the extremity with round joints, a torso with a
  waist that rotates on its own axis, a head on a neck, dumbbells with plates.
  Pose coordinates and the motion model are unchanged.
- **Found and fixed a real control defect by measuring the rep control as a
  *component* rather than as text.** Its boundary read 1.18:1 against WCAG's 3:1
  floor — a `white 0.07` fill behind a `white 0.1` hairline. The glyph was fine
  at 9.71:1, so the symbol was doing all the work and the button had no shape.
  Added `Control` tokens; boundary now 3.51:1, and 4.10:1 on Rest's controls.
- Took the `−` / `+` glyphs from 34pt medium to 38pt semibold. At 1.5m the old
  ones were the first thing to disappear.
- Verified the **Dynamic Type clamp**: medium vs accessibility-extra-extra-
  extra-large differ by 1.59% of pixels, and that is cloud drift, not text.
  Workout typography genuinely does not scale, so the no-scroll layout cannot be
  broken by a text size.
- Verified **Reduce Transparency**: every text zone holds, weakest 6.98:1.
- Re-verified the four-cue stress case fits with no scrolling after the larger
  glyphs and thicker borders.
- Ran `./scripts/verify-ios.sh`; every phase passes. Opened PR #2.

**Decisions taken**
- Figures stay deliberately abstract. This is a movement reminder glanced at from
  1.5m at 6:10am; detail it does not need would compete with the rep counter.
- Control surfaces stay quiet (~1.3:1 against the sky) and the **boundary**
  carries the contrast. The design goal was "quiet", not "invisible".

**Landmines**
- **The bay is wide and short, so a normalised x offset is worth far fewer
  points than the same number in y.** A stance that looked hip-width in
  coordinates rendered as two fused legs. Every figure width now derives from
  `size.height`. Anyone editing poses will hit this.
- The text-contrast harness passed the rep control for its entire life. **Text
  measurement does not cover components**; boundaries need measuring separately.
- The exercise → figure mapping is still keyed off the exercise *name* string.
  It must grow with the real program in W4.

**Assertions:** 0 of 53 passing (53 skipped)

**Next:** W3 — foundations and the acceptance suite. No UI; gate long met.

## 2026-08-22 · W9 Ledger screen, W10 Guide and Backup · Claude Opus 5

**Workstream:** W9 and W10 (done). Every screen in `02-design-brief.md §11` now
exists.

**What I did**
- `Screens/LedgerScreen.swift` — one staggering true number, its provenance
  under it, the facts, and the next threshold.
- `Screens/GuideScreen.swift` — the nine entries verbatim, plus `BackupScreen`
  and the export document.
- Wired all four reading screens into Home behind one quiet row, and
  `-screen history|ledger|guide|backup` for review.

**Decisions taken**
- The Ledger's headline is TONNAGE, not sessions or reps: load is fixed and reps
  are the only signal, so tonnage is the number that makes that signal compound.
  The provenance sits under it because a number that size is only worth
  something if you can see where it came from.
- Empty says "Nothing moved yet". A zero at 76pt is a number pretending to be an
  achievement.
- Guide takes Dynamic Type through the accessibility sizes. The workout screens
  clamp; this one is read monthly and scrolls by design.
- Restore names BOTH session counts in its confirmation, because replacing 120
  sessions with 3 is the mistake that dialog exists to prevent.
- **iCloud was not built.** `05-platform.md §6` says propose, not assume.

**Landmines**
- `BackupDocument` carries pre-encoded `Data`, not an `AppData`. `FileDocument`'s
  members are nonisolated while this module's `Codable` conformances are
  main-actor by default; encoding at the call site is simpler than fighting it.
- **None of the sheet, file-picker or confirmation paths have been exercised.**
  There is no Simulator UI here, so every screen was reached by launch argument
  and no dialog has ever been opened. The export FORMAT is covered by CI; the
  pickers are not covered by anything.
- The Ledger's `since` date and `weeks` derive from `Date()`. Nothing pins them,
  so a test asserting them would drift.

**Assertions:** 56 of 58 (unchanged — W9's assertions landed with W7)

**Next:** W11, the device pass. It is the only workstream left, and everything
in it needs the hardware this clone has never had.

## 2026-08-22 · W8 History and the year grid · Claude Opus 5

**Workstream:** W8 — History and the year grid (done). W7 merged.

**What I did**
- `Screens/HistoryScreen.swift` — reverse-chronological sessions, the year grid,
  and an explicit edit mode for deletion.
- Wired History into Home, and `-screen history` for review.
- Reviewed at empty, one week, six months and one year.

**Decisions taken**
- **The grid fits by construction.** Cell size is derived from the width the
  `Canvas` is given, so it has no dimension to overflow into — the constraint
  that killed the first web version cannot recur here.
- It is **self-sizing on a 53:7 aspect**, not pinned to a height. My first
  version fixed 132pt and the grid only needed 47, leaving it floating in dead
  space: the cell size follows the width, so the height is not a free choice.
- Deletion keys off `ts`, never an index.
- Month labels omitted. At ~5pt cells they crowd what they label.
- Empty shows the grid EMPTY rather than hiding it, so the shape of what is
  coming is visible from day one.

**Landmines**
- The year grid's colour scale is relative to the user's OWN range — quietest
  session indigo, best gold. With one session everything is gold, which is
  correct and looks odd; do not "fix" it with an absolute scale.
- `HistoryScreen` is presented as a sheet from Home. There is no tap in this
  environment, so the sheet path itself has never been exercised — only
  `-screen history`, which builds the same view directly.

**Assertions:** 56 of 58 (unchanged — W8 has no assertions of its own)

**Next:** W10 — Guide and Backup. Then W11, the device pass.

## 2026-08-22 · W7 Summary, Daybreak and the tiers · Claude Opus 5

**Workstream:** W7 — Summary, Daybreak and celebration tiers (done), plus W9's
logic. W6 merged.

**What I did**
- `Model/Ledger.swift` — tonnage, milestones, next threshold. All four
  `LedgerAcceptanceTests` pass.
- `Model/Celebration.swift` — the eleven tiers, copy verbatim, priority order
  from `04-rules.md §5`. All six `CelebrationAcceptanceTests` pass.
- `Screens/Daybreak.swift` — the web build's choreography, ported beat for beat.
- `Screens/SummaryScreen.swift`, wired into `AppRoot`.
- `-screen summary -tier <name>` for review.

**Assertions: 56 of 58.** Only the two `testPhase2` tests remain, and those are
deliberately out of v1.

**Decisions taken**
- Daybreak derives every stage from ONE elapsed value off an absolute start
  date. That is the native equivalent of the web's "CSS keyframes with delays,
  cannot half-play if a frame is dropped": stages cannot desynchronise when
  there is only one clock.
- The completion haptic fires once, at the sun's rise, so its three transients
  land across the bloom and flash and its swell carries the number in.
- The summary is mounted UNDER Daybreak, as the web build does, so dismissing
  the celebration reveals numbers that are already there.

**Landmines**
- **Two of my own tests were wrong, not the copy.** I asserted an eyebrow must
  share no words with its headline, which failed "Best A yet" over "A personal
  best." — the rule is that it must ADD something. And my content-word filter
  dropped tokens under three characters, concluding "-10 vs your last A" adds
  nothing to "Down on last time." when the 10 is the entire point. When a
  verbatim-copy test fails, suspect the test.
- **Daybreak's first layout put the sun directly behind the rep total and the
  headline.** The horizon is at 0.82 and the copy is centred in the space above
  it, not on the screen. Anything added to that column has to respect it.
- The Daybreak review path synthesises history for a tier rather than faking a
  `Celebration`, so what you look at is what the real tier logic produces.

**Next:** W8 — History and the year grid. Then W10, then the device pass.

## 2026-08-22 · W6 Home and the week · Claude Opus 5

**Workstream:** W6 — Home and the week (done). W5 merged.

**What I did**
- `Model/Week.swift` — weeks, streaks, longest run and the nudge, ported from
  `src/lib/week.ts`. All eight `WeekAndStreakAcceptanceTests` pass.
- `Screens/HomeScreen.swift`, `Screens/AppRoot.swift` — **Home is the app root
  now**, and a workout in progress resumes on launch.
- `WorkoutHost` takes an injected session; `AppRoot` owns the lifecycle.
  `ReviewHost` keeps the launch-argument entry points for review.
- Reviewed Home at empty, one week and six months.

**Decisions taken**
- **The day-one nudge is suppressed.** With no history the arithmetic says
  "this week's out of reach", which is true and the wrong first sentence for
  someone who has not started. The subtitle already says what day one is.
- **The contrast exception is gone.** Home sits at the ramp's dark end
  permanently, so its button measured 5.99:1 every time rather than only at the
  start of a session. A second screen inheriting an exception means the
  exception was wrong. `accentFill` lifts the accent 12% for fills that carry a
  label; every screen now clears the floor at every progress, weakest 7.00:1.
- Finishing saves the record BEFORE clearing the in-progress file.

**Landmines**
- **`weekStartsOn` means a different number in each build** — 1 here
  (Foundation, Sunday = 1), 0 in the web (JavaScript). The offset arithmetic is
  identical *because* of that. Neither should be "fixed" to match the other.
- Every date in the week tests is fixed and the calendar pinned to
  Europe/London. A test reading `Date()` passes for eleven months and then
  fails in the week the clocks change.
- **The measurement tool snapped onto the week pips and reported 4.65:1** for a
  label that holds 10:1. The pips are filled accent furniture, not glyphs. The
  `home` zones are now taken from a row profile of the rendered screen.
- History, Ledger, Guide and Backup have no way in yet. Home has the space for
  it; W8–W10 own the screens.

**Assertions:** 46 of 58 passing (12 skipped, 0 failures)

**Next:** W7 — Summary, Daybreak and the celebration tiers.

## 2026-08-22 · W5 Rest and the study deck · Claude Opus 5

**Workstream:** W5 — Rest screen and study deck (done). W4 merged.

**What I did**
- `Model/Cards.swift`, `Model/Deck.swift` — the 26 cards and the rotation.
  All seven `StudyDeckAcceptanceTests` pass.
- `Model/Audio.swift` — the six cues, synthesised, and the audio session.
- `Screens/RestScreen.swift` — countdown, next exercise, `+15s` / `Skip`, and
  the study card whose reveal halves the timer and takes its space.
- Wired Rest into `WorkoutHost` and **removed the rest-skipping** the previous
  handoff flagged. Added `-step` so any step can be reached.
- `isIdleTimerDisabled` held for the session and released on end, abandon and
  completion.

**Decisions taken**
- The audio session is activated around cues and deactivated after, never held
  for the workout. `DuckWindow` is a separate type so the one-duck rule can be
  tested without a device.
- The card is drawn on step CHANGE, never inside `body`.
- No ring-switch question for Eden: `technical-decisions.md` already records
  that he chose countdown reliability over the silent switch.

**Landmines**
- **Mutating `@State` from a computed property read during `body` silently does
  nothing.** The card was drawn that way and never appeared, and there was no
  error — just no card. If something renders as absent rather than wrong, look
  for a write during view update.
- **I asserted card rest indices from arithmetic I did in my head and was
  wrong** — [6, 12] rather than the real [6, 15], because both sessions have
  seven long rests, not six. The exact indices are now asserted, so the next
  change to the fraction maths fails a test instead of silently moving a card.
- Music ducking is implemented and **unheard**. No device, and nothing else
  playing on the simulator.
- `RestScreen` fires countdown cues from `onChange` of the displayed second. If
  the view is ever not on screen while a timer runs, they will not fire.

**Assertions:** 38 of 58 passing (20 skipped, 0 failures)

**Next:** W6 — Home and the week. Its gate (W5) is now met.

## 2026-08-22 · W4 the Set screen · Claude Opus 5

**Workstream:** W4 — The Set screen (done). W3 merged.

**What I did**
- Built `WorkoutSession`, the session state machine, and implemented all eight
  `SessionLifecycleAcceptanceTests` against it. All eight are about the machine
  rather than SwiftUI, which is why it is a plain observable object.
- Built the real screen: `Screens/SetScreen.swift`, `Screens/RepControl.swift`,
  `Screens/WorkoutHost.swift`, on the W2 tokens and on real persisted history.
- Promoted the haptic engine out of prototype code into `Model/Haptics.swift`.
  `PrototypeHaptics` is now a per-treatment sharpness tilt over the one engine.
- Added `-screen set`, `-slot` and `-session` so any state can be reviewed.
- Ran `./scripts/verify-ios.sh`; every phase passes.

**Decisions taken**
- Bodyweight sets are ALWAYS comparable. A push-up has no load, so the session's
  dumbbell weight has nothing to do with it. Locked in with a test.
- The step label counts sets, not steps. "Set 2 / 25" included the warm-up and
  every rest.
- Cue emphasis uses `intensityWords`, already transcribed in `Program.swift`.
  My first version guessed at "contains a shouted word" and silently missed
  "Go to failure" and "mechanism" — the two that matter most.

**Landmines**
- **There is no `Simulator.app` on this machine** — only the headless `simctl`
  runtime. Screenshots and launches work; synthesized touches have nothing to be
  delivered to, so a HOME press changes 0.9% of pixels and every tap is a no-op.
  I nearly attributed that to a bug in the rep control. Interaction is verified
  through the model in `SessionLifecycleAcceptanceTests`; the SCREEN for a given
  state is reached with `-reps`, `-slot` and `-progress` instead of by tapping.
- **A token can record a number it does not deliver.** `Ink.tertiary` was
  written down as 0.62 from measurements of a prototype that was using 0.72 in
  the places that mattered. Rebuilding the prototypes on the tokens was supposed
  to catch that and did not, because the prototype kept its literals. Measure
  the REAL screen, not the thing the token was derived from.
- `measure-contrast.py` snapped onto the primary button's edge and reported
  4.96:1 for a footer that holds 8:1. It now anchors bottom-pinned zones from
  the bottom of the frame and warns when the ink it found touches the window
  edge. Read the warning; do not silence it by narrowing the window.
- `WorkoutHost` walks past rests because Rest is W5. The moment W5 lands, that
  skip must go or rests will be silently invisible.
- The warm-up timer step has no screen. `WorkoutHost` jumps past it.

**Assertions:** 27 of 54 passing (27 skipped, 0 failures)

**Next:** W5 — Rest and the study deck. Its gate (W4) is now met. Delete the
rest-skipping in `WorkoutHost` as the first thing it does.

## 2026-08-22 · W3 foundations and the acceptance suite · Claude Opus 5

**Workstream:** W3 — Foundations and the acceptance suite (done). W1 and W2 merged.

**What I did**
- Ported `src/lib/steps.ts` and `src/lib/plates.ts` as reasoning, not code.
  `Model/Steps.swift`, `Model/Plates.swift`.
- Implemented all 10 `ProgramCompilerAcceptanceTests` against the **whole**
  golden fixture rather than the counts. A compiles to exactly 21 steps and B to
  25, every field matching, slot ids identical and unique.
- Implemented persistence: `Model/Store.swift`, atomic writes to Application
  Support, a separate in-progress file, and every write able to throw. Reads are
  lenient, writes are loud — that asymmetry is deliberate.
- Added `Model/History.swift` for the derived reads: previous-same-set lookup
  that returns the WEIGHT alongside the reps, load resolution that falls back
  without backfilling, and local dates parsed at noon.
- Implemented 8 of 10 `DataAcceptanceTests`; the two `testPhase2` stay skipped.
- **Automated the Restore-box check.** `scripts/verify-export.ts` imports the
  real `parseData` from the web source and runs a genuine iOS export through it.
  Verified it fails on a deliberately corrupted export.
- Wired `-seed`, and confirmed all five fixtures land in Application Support
  with the right record counts.
- Ran `./scripts/verify-ios.sh`; every phase passes.

**Decisions taken**
- Test classes are `@MainActor`. The app module builds with
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which is correct for a
  single-user app; running the tests there is honest, and scattering
  `nonisolated` through `Program.swift` to satisfy a test target is not.
- Three data tests whose subject is a screen assert the data that screen rests
  on, with a comment naming the workstream that owns the rest. A skip would
  have hidden a regression that a wrong number would not.
- `previousSet` returns the weight, not just the reps, because the caller cannot
  decide whether it is a target without it.

**Landmines**
- **`TEST_RUNNER_`-prefixed variables must be in xcodebuild's ENVIRONMENT.**
  Passed as an argument they become a build setting and the test never sees
  them — the export check silently skipped for two runs before I noticed the
  message was the old one.
- `NSTemporaryDirectory()` inside the simulator is in its own container. Any
  file a test hands to a host-side script needs an explicit path passed in.
- `add-source-file.py` double-nested subgroup paths (`Morning/Model/Model/…`).
  Fixed — the group carries the directory, the reference carries the filename.
- `Seed.load()` reads `Bundle.main`, which is the test bundle under XCTest. The
  data tests fall back to `Bundle(for:)` and then `Bundle.main`.
- The `-seed` seeder writes on launch and the prototype lab does not read it
  yet. Nothing consumes seeded history until W4/W6.

**Assertions:** 18 of 53 passing (35 skipped, 0 failures)

**Next:** W4 — the Set screen, on the W2 tokens. Its gate (W2 and W3) is now met.

## 2026-08-22 · W2 design system · Claude Opus 5

**Workstream:** W2 — Design system (done). W1 closed.

**What I did**
- Wrote `ios/Docs/design-system.md` in full: direction, colour, ink with
  measured contrast, semantic colour, the scrim, type, spacing, hit targets,
  material, motion with every reduced form, the complete haptic table, and the
  sound design carried forward from `05-platform.md §3`.
- Implemented it as three token files — `DesignTokens.swift`,
  `DesignMotion.swift`, `DesignHaptics.swift` — and rebuilt the Atmospheric
  prototypes on them. Re-measured: no regression.
- Added `ios/Tools/add-source-file.py`. The project uses classic file references,
  so a new file needs four correct pbxproj entries; doing that by hand is how a
  project file gets corrupted.
- Deleted the duplicate `DawnPalette`, `Color.morningSuccess`, the per-treatment
  haptic profile structs and the scattered colour literals they fed.
- **Wired the countdown haptic**, which the vocabulary required and nothing was
  playing: one pulse per second through the last five, intensifying, on every
  timer including the 20-second myo rest.
- Ran `./scripts/verify-ios.sh`; every phase passes. CI green.

**Decisions taken**
- **Tokens record what the design is, not what I assumed.** My first
  `Motion.Hold` and `Motion.rep` values were invented and did not match the
  running prototypes. Corrected the tokens to the implemented Atmospheric values
  rather than changing behaviour to match a guess — and fixed the two figures
  `prototype-directions.md` had already stated wrongly.
- The haptic vocabulary is one set of events; the three W1 treatments differ by
  a sharpness tilt only. Product meaning is identical across them.
- Precise and Tactile are frozen comparison artifacts. They keep their own
  literals and the gentler scrim, and they do not constrain the system.
- **W1's device gate is carried to W11, not waived.** See the landmine below.

**Landmines**
- **The device gate is still open and I could not close it.** No physical iPhone
  has ever been connected to this clone and no signing identity is configured,
  so `devicectl` and `xctrace` see simulators only. Haptic quality and 120Hz
  frame pacing are unverified. Every haptic pattern in `DesignHaptics.swift` is
  designed but has never been felt — the numbers are reasoned, not tuned.
- `HapticVocabulary.complete` is defined and deliberately not wired to anything.
  It belongs to W7, against the Daybreak choreography it has to land on.
- `CloudTexture` builds three 1024×256 noise fields on first access, on the main
  actor. Fast enough not to show at launch here; still CPU work in a `static
  let` and worth profiling on device.
- `add-source-file.py` finds a group by `path = <name>;`. There is no `Design`
  group — the token files sit flat in `Morning/`. Adding a nested group needs a
  PBXGroup by hand first.

**Assertions:** 0 of 53 passing (53 skipped) — W3 is where that changes.

**Next:** W3 — foundations and the acceptance suite. It has no UI and its gate
(W0) is long met, so it can start immediately.

## 2026-08-22 · W1 living dawn sky · Claude Opus 5

**Workstream:** W1 — Research pass and directions (in progress)

**What I did**
- Ran `bootstrap.sh --check` and `verify-ios.sh` on the inherited tree: all green.
- Built a registration-tolerant contrast harness that snaps to the actual glyph
  rows before measuring. The previous hand-placed bands drifted onto a gradient
  and a ring arc, reporting 1.3:1 and 4.87:1 for zones that actually measure
  6.6:1 and 7.7:1. Do not trust a fixed y-band on a screen whose layout moves.
- Simulated arm's-length and dark-room legibility from physics rather than by
  eye: acuity-limited sheets at 0.6/1.2/1.5/2.0 m (1 arcminute at the iPhone 16
  Pro's 460 ppi), and a low-brightness black-crush model.
- **Rebuilt the Atmospheric sky after Eden rejected it as boring.** It was one
  static mesh, 34 fixed dots and a scrim; the web `Sky.tsx` it was meant to
  succeed has eight layers and four animations. New `PrototypeSky.swift` carries
  ozone band, haze, twinkling stars, meteors, progress-carrying crepuscular
  rays, two parallax cloud banks and anti-banding grain.
- Reshaped the legibility scrim, which was ramped backwards, and made it scale
  with progress. Every text zone now clears the brief's 6.6:1 tertiary bar
  across the whole session; weakest is 7.00:1, up from 5.33:1.
- Fixed three under-bar elements: primary button label to full black, MOVEMENT
  to white 0.62, superset warning line lifted 42% toward white.
- Added a `-progress` launch argument and captured the full dawn walk.
- Ran `./scripts/verify-ios.sh`; every phase passes.

**Decisions taken**
- Atmospheric Dawn is the direction. Eden said "proceed to W2", which is gated on
  a chosen direction, and he had already named Atmospheric as his preference.
  Flagged to him in-session so he can correct it.
- The sky's structure is ported from the web build's *reasoning*, not its code.
  Zenith never takes the accent hue; cloud noise is baked once and translated.
- The scrim is a function of progress. A fixed scrim that cleared the bar at
  twilight let three elements fall below it by the time the palette reached gold.
- The primary button label at 5.84:1 at progress 0.00 is a deliberate exception,
  recorded with its reasoning. Lightening the accent to fix it would distort a
  hand-picked ramp for a figure that already clears AA-large twice over.
- Still no third-party animation dependency. Native `MeshGradient`, `Canvas`,
  `TimelineView` and baked `CGImage` tiles cover all of it.

**Landmines**
- **Physical-device work remains impossible here.** `devicectl` and `xctrace`
  show simulators only, and no development team is set for signing. Haptic
  quality and 120Hz frame pacing are therefore still unverified — the two W1
  items nobody can close without Eden's phone.
- The distance and dark-room simulations model *spatial acuity* and *low-brightness
  black crush*. They do not model glare, dark adaptation or panel calibration.
  10.1% of the Set frame sits at code ≥200, almost all of it the primary button —
  the glare candidate at 6am, and only the real phone can settle it.
- `CloudTexture` builds three 1024×256 noise fields on first access, on the main
  actor. It is fast enough not to show at launch here, but it is CPU work in a
  `static let` and worth profiling on device.
- The offline replica of the noise algorithm lives in the scratchpad, not the
  repo. If `CloudTexture.make` changes, that replica silently stops matching.

**Assertions:** 0 of 53 passing (53 skipped)

**Next:** W2 — design system. The sky's constants (palette, scrim ramp, drift
periods, contrast bars) are the first tokens it should absorb.

## 2026-08-22 · W1 Atmospheric lead refinement · GPT-5.6 Sol

**Workstream:** W1 — Research pass and directions (in progress)

**What I did**
- Treated Atmospheric Dawn as Eden's leading candidate without removing Precise
  or Tactile or closing the W1 gate.
- Removed Atmospheric's previous-rep badge and the redundant equal-state “Last
  time” subtitle. First-run, changed-weight, and 13 → 14 honesty remain.
- Moved the fixed target into the exercise metadata hierarchy and deleted the
  decorative bottom horizon, line, and sun.
- Added a 142–178pt app-owned native Canvas movement bay to every Set. It maps
  the fixed exercise name to overhead press, push-up, lateral raise, floor fly,
  bent-over row, or curl motion without a package or placeholder asset.
- Added a static start/end Reduced Motion form and retained 82pt rep controls,
  the 68pt primary action, no scrolling, and full four-cue content.
- Measured seven representative Set/card/menu text zones at 6.88:1–12.03:1;
  the quiet movement-bay label is the weakest sampled zone.
- Replaced the easy-to-miss Rest picker with visible Timer only, Question →
  answer, and Myo rows; made the lab's Open action persistent at the bottom.
- Rechecked plain Rest and carded Rest before and after the silent auto-reveal;
  the 64pt compact timer, longest answer, next exercise, and both controls fit.
- Captured the focused Atmospheric matrix plus Precise/Tactile comparison Sets
  in ignored `ios/build/`.
- Ran `./scripts/verify-ios.sh`; every phase passes.

**Decisions taken**
- Atmospheric is marked `LEADING`, not selected. W1 stays open and W2 does not
  begin until Eden explicitly chooses.
- The sunrise atmosphere now expresses session progress only through authored
  palette interpolation and fading stars. Threshold comparison belongs at the
  counter, not in the background.
- A native schematic is enough to test movement-bay layout and motion language.
  Rive or Lottie still needs a demonstrated final asset/state-machine advantage
  before it can enter the project.

**Landmines**
- The movement figures are app-owned layout/motion prototypes, not final
  anatomical illustrations. Their exercise mapping must grow with the real
  program if this direction is chosen.
- Physical-device frame pacing, haptics, and 1.5m dark-room legibility remain
  unverified because no signed device is connected.

**Assertions:** 0 of 53 passing (53 skipped)

**Next:** Let Eden compare the revised Atmospheric equal/crossing/long-content
states and card flow. Keep W1 open until he explicitly chooses; do not start W2.

## 2026-08-22 · W1 contrast and motion pass · GPT-5.6 Sol

**Workstream:** W1 — Research pass and directions (in progress)

**What I did**
- Reworked all three Set/Rest treatments after Eden rejected low contrast and
  decorative halo effects.
- Added stable dark luminance zones, raised secondary text to role-based
  68–78% white, and measured eight representative simulator text zones at
  7.79:1–11.38:1.
- Removed the Atmospheric radial threshold bloom and large Tactile Set ellipse.
  Atmospheric now has one small sun and horizon; Tactile state lives in its rim
  and detent; Precise remains shadowless.
- Reduced timer, counter, and primary-button accent shadows; removed the
  duplicate Rest label; kept all hard-case fixtures visible without scrolling.
- Added Set-to-Rest work-object continuity with `matchedGeometryEffect`,
  treatment-specific screen transitions, grouped Liquid Glass controls, and
  opacity-only Reduced Motion transitions.
- Captured identical 13 → 14 Sets, frozen 45-second Rests, the longest revealed
  card, a frozen 5-second myo Rest, and the four-cue Set in `ios/build/`.
- Evaluated native animation APIs and popular packages, documented the gates,
  and added no dependency.
- Ran `./scripts/verify-ios.sh`; every phase passes.

**Decisions taken**
- Light must communicate progress or state. Background atmosphere may establish
  Morning's identity, but it cannot become a second focal object behind copy.
- Native SwiftUI already covers the demonstrated motion: matched geometry,
  numeric transitions, MeshGradient, Canvas, and Liquid Glass. Pow, Lottie,
  Rive, Hero, and Vortex do not currently solve a proven prototype problem.
- W1 remains a three-direction comparison. This pass does not choose for Eden
  and does not start W2.

**Landmines**
- PNG contrast sampling validates the rendered simulator composition, not
  physical-device 1.5m dark-room legibility.
- Frame pacing and haptic quality still require a signed build on Eden's
  physical iPhone; no signing identity or device is connected.
- Final review captures are intentionally under ignored `ios/build/`, not source
  control.

**Assertions:** 0 of 53 passing (53 skipped)

**Next:** Show Eden the restrained controlled matrix, then tune on the physical
phone and wait for his W1 direction decision. Do not begin W2 beforehand.

## 2026-08-22 · W1 interaction audit · GPT-5.6 Sol

**Workstream:** W1 — Research pass and directions (in progress)

**What I did**
- Applied a severity-ranked interaction audit after the second visual pass.
- Added an explicit app Info.plist and verified
  `CADisableMinimumFrameDurationOnPhone = true` in the built bundle.
- Made Rest zero and Skip advance to the next Set, fixed extension after expiry,
  and added a distinct zero haptic.
- Added loaded-first-run, superset-partner-two, myo-set-two, four-cue, longest
  answer, and deterministic launch fixtures.
- Added VoiceOver activation, 64pt Back/End hit areas, fixed workout Dynamic
  Type, Reduce Transparency fallbacks, and fuller Reduce Motion behavior.
- Parameterized hold acceleration, numeric motion, and haptic shape by treatment.
- Added Core Haptics stop/reset recovery, prepared-player reuse, and one retry of
  the triggering event.
- Observed a real 20-second myo Rest automatically advance to the 4–5 rep Set.
- Ran `./scripts/verify-ios.sh`; every phase passes.

**Decisions taken**
- Workout screens deliberately clamp Dynamic Type to `.large`; reading screens
  later support accessibility sizes.
- Skip confirms but does not play the zero pattern. Automatic expiry does.
- ProMotion support is a committed product setting, not a profiler-only tweak.

**Landmines**
- Physical-device frame pacing and haptics remain unverified because no signing
  identity or physical iPhone is connected.
- Four-cue Set content is a stress harness assembled from fixed program copy,
  not a new product exercise.

**Assertions:** 0 of 53 passing (53 skipped)

**Next:** Physical-device comparison and Eden's direction decision.

## 2026-08-22 · W1 second visual pass · GPT-5.6 Sol

**Workstream:** W1 — Research pass and directions (in progress)

**What I did**
- Submitted the first running prototypes to a strict visual review. The review
  correctly rejected them as one Dawn composition with three component skins.
- Rebuilt the backgrounds and threshold mechanics so the concepts now diverge:
  Atmospheric has authored horizon/sun light, Precise has a functional grid and
  real-value instrumentation with no sky, and Tactile has one transforming
  object with a restrained glass control layer.
- Added a deterministic 13 → 14 state. Previous reps now live inside every
  counter and crossing changes environment, marker, or physical rim.
- Added semantic mint for threshold success and amber for myo urgency, both off
  the Dawn progress ramp.
- Increased compact Rest time to 64pt, raised low-contrast labels, removed faux
  calibration language, added real timer tick segments, and made `+15s`
  subordinate during myo Rest.
- Added reduced-motion forms for numeric changes, object tilt, card reveal,
  timer resizing, and environmental breathing.
- Split visual background/chrome code into `PrototypeVisuals.swift` and added
  frozen-time launch states for controlled comparisons.
- Ran `./scripts/verify-ios.sh`; every phase passes.

**Decisions taken**
- Product hierarchy can stay consistent while the concepts differ in what
  carries meaning: environment, measurement, or object.
- The 13 → 14 moment is the comparison state; equality screenshots do not
  evaluate the product's emotional centre.
- Success remains a semantic state rather than borrowing the current Dawn hue.

**Landmines**
- Still awaiting physical-device haptic tuning and Eden's direction choice.
- The simulator screenshots prove composition, not 1.5m dark-room legibility.
- The app has no signing identity configured on this Mac yet.

**Assertions:** 0 of 53 passing (53 skipped)

**Next:** Run identical Set/Rest states on the physical phone, tune haptics and
distance contrast, then ask Eden to choose the execution to formalize in W2.

## 2026-08-21 · W1 simulator prototypes · GPT-5.6 Sol

**Workstream:** W1 — Research pass and directions (in progress)

**What I did**
- Replaced `ScaffoldView` as the active root with a running direction lab.
- Built Atmospheric Dawn, Precise Dawn, and Tactile Dawn Set/Rest treatments
  over one shared hardcoded state harness.
- Added first-run, comparable, changed-weight, superset, myo, longest-content,
  plain Rest, carded Rest, and myo Rest scenarios.
- Added accelerated hold-to-repeat, directional numeric transitions, interactive
  Liquid Glass controls, perceptual five-stop sunrise interpolation, absolute
  countdowns, automatic card reveal, and distinct Core Haptics patterns.
- Added deterministic `-prototype` launch arguments and documented the
  comparison in `ios/Docs/prototype-directions.md`.
- Captured and inspected all three Set treatments plus plain, carded, and myo
  Rest states on the iPhone 16 Pro simulator. Nothing scrolls.
- Ran `./scripts/verify-ios.sh`; every phase passes.

**Decisions taken**
- All three treatments retain the dawn. Precision and physicality are execution
  layers, not replacement identities.
- The native palette uses SwiftUI's perceptual `Color.mix`; direct RGB
  interpolation was rejected before the milestone.
- Tactile glass is limited to buttons. The rep/timer object remains an opaque,
  high-contrast content object.
- Study cards use stable question → rule → answer geometry, not a 3D flip.

**Landmines**
- Simulator review cannot judge Core Haptics. W1 remains open until physical
  iPhone testing and Eden's direction choice.
- The prototype lab is intentionally hardcoded and is not W3/W4 application
  architecture.
- `PrototypeGallery.swift` is long but below the configured error threshold;
  split it when the chosen treatment becomes product code rather than spending
  W1 on throwaway structure.

**Assertions:** 0 of 53 passing (53 skipped)

**Next:** Select the development team, run the three treatments on the physical
iPhone 16 Pro, tune haptics/legibility, and put the direction choice in front of
Eden.

## 2026-08-21 · W1 research milestone · GPT-5.6 Sol

**Workstream:** W1 — Research pass and directions (in progress)

**What I did**
- Completed full web sessions A and B, including Back correction, both study
  card placements, myo rests, Daybreak, and Summary.
- Replaced the unavailable paid screen-library requirement, by Eden's explicit
  decision, with public shipped-app evidence: official documentation, App Store
  creatives, public demos, Apple profiles, and platform guidance.
- Wrote `ios-port/research-notes.md` with observed mechanics, rejected patterns,
  hard cases, sources, and the implications for every question in the brief.
- Wrote `ios/Docs/technical-decisions.md`: native Observation, atomic Codable
  JSON, Core Haptics, one ducked playback audio session, native rendering and
  motion, and zero baseline runtime dependencies.

**Decisions taken**
- The sunrise remains Morning's identity. W1 compares Atmospheric Dawn, Precise
  Dawn, and Tactile Dawn as native executions of one idea rather than unrelated
  app brands.
- SmartGym contributes only the focus mechanic — one set and one action. Its
  generic dashboard, editable-program clutter, prediction, tables, and messaging
  are explicitly rejected.
- Liquid Glass is reserved for sparse interactive controls above the content
  layer. It is not the sky, timer face, cue card, or app identity.
- Countdown audio uses `.playback + .duckOthers`, always audible, with one duck
  from five through zero. Eden chose this over silent-switch compliance.

**Landmines**
- Public App Store creatives establish visible composition, not interaction.
  Behavioural claims in the notes rely on public demos or documentation.
- The web Summary starts animations and its 14-second card reveal while hidden
  under Daybreak. Native timing begins only when Summary is perceptible.
- A physical-device signing team still needs selecting before haptic direction
  testing; simulator work can continue.

**Assertions:** 0 of 53 passing (53 skipped)

**Next:** Build a shared hardcoded Set/Rest state harness, then three running
native Dawn treatments with real motion and Core Haptics.

## 2026-08-21 · W0 compile baseline · GPT-5.6 Sol

**Workstream:** W0 — Make it compile

**What I did**
- Replaced the XcodeGen spec with a normal committed-project layout at
  `ios/Morning.xcodeproj`; removed `project.yml`, the inert xcconfig pair, and
  generation steps from bootstrap, verification, and CI.
- Installed and selected Xcode 27 beta 5, installed the iOS 27 simulator
  runtime, and created the target iPhone 16 Pro simulator.
- Kept the app module MainActor-isolated while overriding the XCTest target to
  `nonisolated`, fixing Swift 6's inherited `XCTestCase` initializer mismatch.
- Confirmed app/test source membership and resource phases. A temporary smoke
  test loaded `compiled-steps.json` as A=21/B=25 and decoded the six-month seed
  to 125 records through the real test/app bundles, then was removed.
- Fixed CI's missing-`xcpretty` double test run and its overcounted skip report.
- Excluded ignored DerivedData from SwiftFormat and formatted the two scaffold
  files the checked-in rules required.
- Ran `./scripts/verify-ios.sh`: build, 53 tests/53 skipped/0 failed, SwiftLint,
  SwiftFormat, and deterministic seed generation all pass.
- Installed and launched `ScaffoldView` on the iPhone 16 Pro simulator.

**Decisions taken**
- The application remains `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; only the
  XCTest target defaults to `nonisolated`, matching XCTest's base classes
  without unsafe annotations.
- Both targets explicitly remain iPhone-only and disable Mac/Catalyst support.
- Generated build products stay under `ios/build` and are excluded from
  formatting; generated Swift is never rewritten.

**Landmines**
- No development team is set in the project yet. Simulator builds are clean;
  physical-device W1 prototypes need Eden's team selected in Signing &
  Capabilities.
- Xcode 27 is beta tooling because Eden's phone runs iOS 27 beta. The app target
  intentionally remains iOS 26.
- GitHub Actions initially lacked a pre-created iPhone 16 Pro, so CI now creates
  that device against the runner's newest installed iOS runtime. PR #1 passed.

**Assertions:** 0 of 53 passing (53 skipped)

**Next:** W1 research notes and native Dawn Set/Rest prototypes. Eden has
explicitly chosen to keep Morning's sunrise identity while rethinking its
execution rather than copying the web layout.

## 2026-08-21 · Environment scaffold · Claude (Cowork)

**Workstream:** pre-W0 — environment setup only. No app code, by design.

**What I did**

- Cloned `EdenTurgeman/morning` to `~/Dev/morning`, 18 commits, branch
  `ios-port/scaffold` off `main`.
- Read all eight `ios-port/` documents and `content/*.json` end to end.
- Set up XcodeGen (`ios/project.yml`) rather than a checked-in `.xcodeproj`, so
  the project spec merges like code. `Morning.xcodeproj` is gitignored.
- Transcribed `content/program.json` into `ios/Morning/Program.swift` as Swift
  literals, per `03-program.md`'s hard requirement — one editable object, one
  file, no JSON resource at runtime. Generator: `ios/Tools/gen-program-swift.mjs`,
  one-shot, **do not re-run it over hand edits.**
- Wrote `ios/Morning/Model/Schema.swift` from `06-data.md §3`, terse keys
  preserved (`d`, `s`, `ts`, `min`) with lenient decoding that drops malformed
  records.
- Generated **53 acceptance assertions** from `07-acceptance.md` into seven
  XCTest suites, all `XCTSkip`. Generator: `ios/Tools/gen-acceptance-tests.mjs`.
  It refuses to overwrite a suite whose `@generated-scaffold` banner is gone.
- Generated five seed fixtures (`empty`, `one-session`, `one-week`,
  `six-months`, `one-year`) in the exact v1 schema, anchored to 2026-08-21.
  Generator: `ios/Tools/gen-seeds.mjs`. `six-months` contains a plateau, a
  personal best, a missed week and a working-weight change; `one-year` sits at
  768 t with the 1000 t milestone about to cross.
- Tooling: SwiftLint, SwiftFormat, a `.githooks/pre-commit` that formats and
  lints staged Swift, a macOS CI workflow that builds, tests and prints the
  remaining skip count, and `scripts/bootstrap.sh`.
- Wrote `CLAUDE.md`, `ios/Agents/README.md` and `ios/Agents/workstreams.md`
  (W0–W12).

**Decisions taken**

- **XcodeGen over a checked-in project.** A `.pbxproj` cannot be reviewed or
  merged; sources are declared by directory, so adding a Swift file needs no spec
  edit at all.
- ~~**Swift 5 language mode, not Swift 6.**~~ **Reversed** — see the third
  amendment below. Swift 6 mode with approachable concurrency, which is what
  Xcode 26 gives a new project.
- **`weekStartsOn` translated from 0 to 1.** The web build uses the JS convention
  (0 = Sunday); `Program.swift` uses Foundation's (1 = Sunday). Same day,
  different number, documented at both ends. Do not "fix" either to match.
- **`intensityWords` is an array, not a regex.** `03-program.md` asks for the
  word list to sit next to the program where it can be edited; a `[String]` with
  a case-sensitive `contains` is equivalent to `/failure|PAUSE|FULL|mechanism/`
  and more editable than a Swift regex literal.
- **No widget, Live Activity or HealthKit target.** `05-platform.md §7` says
  propose, don't assume. Commented stubs at the bottom of `project.yml`.
- **Seed timestamps are noon UTC**, not 6:10am, so the local calendar day of `ts`
  matches `d` in every timezone. `06-data.md` suggests exactly this ("parse as
  local, or at local noon").
- **No screens, no design system content.** `ios-port/README.md` is explicit that
  design comes before building, and a scaffolded screen is a design decision made
  by the wrong party.

**Landmines**

1. **None of the Swift has ever been compiled.** The environment it was written
   in has an egress allowlist that permits `archive.ubuntu.com`, `pypi.org`,
   `registry.npmjs.org` and `github.com`, and refuses `swift.org`,
   `download.swift.org`, `apt.llvm.org` and `codeload.github.com` with
   `X-Proxy-Error: blocked-by-allowlist`. Ubuntu's repos carry OpenStack Swift,
   not the language. A Linux `swiftc` would not have helped much anyway — no
   SwiftUI, no iOS SDK, no `XCTest` bundle loading — so `xcodebuild` on the Mac
   is the only real check. `Program.swift`, `Schema.swift`, `Seeds.swift`,
   `MorningApp.swift`, `GoldenSteps.swift` and the seven test suites are all
   unverified. **This is why W0 exists and comes first**, and why
   `scripts/verify-ios.sh` exists: it collects every error from every phase in
   one pass into `ios/build/verify-report.txt`.
2. **The screensdesign MCP is connected on Eden's side, but not in every
   client** — it is not in the public connector registry, so it will not appear
   automatically. Run W1 wherever it is configured, and check you can see its
   tools before starting. Do not improvise the research pass from memory.
3. **The app icon is a 2× upscale** of `public/icon-512.png` to 1024. It will
   look soft. Fine for the simulator, replace before installing on the phone.
4. **No development team is set.** Simulator builds work; installing on the
   phone needs Morning target -> Signing & Capabilities -> Team.
5. **CI pins an `iPhone 16 Pro` simulator by name** — deliberately, because that
   is the actual device this app is for. If GitHub's runner image stops shipping
   that device the workflow fails on the destination, not on the code. Override
   locally with `IOS_DEST=... ./scripts/verify-ios.sh`.
6. **`spec.md` is gitignored** — "it describes the person this was built for" —
   so the `ios-port/` docs reference a document no agent can read. Everything
   binding appears to have been carried into `ios-port/`, but I could not verify
   that. If something seems to be missing, ask Eden rather than inferring it.
7. **`.claude/launch.json` had a hardcoded Windows npm path** (`C:\Users\edmx0\
   ...\npm.cmd`), so it could never have worked on a Mac. I replaced it with a
   plain `npm` invocation.
8. **The seed fixtures are plausible, not real.** Rep counts are modelled from
   the program's target ranges — a first session lands at ~177 reps against the
   163 in `06-data.md`'s example — with a saturating progression, roughly +14% by
   six months. Good enough to design against; not Eden's actual numbers.

**Next:** W0 — `./scripts/verify-ios.sh`, then fix what the report lists.

### Amended, same day

Four things found by static review before the first real build, all fixed here
so W0 does not waste a cycle on them:

- **Test names lost their underscore.** `func test_fooBar` trips SwiftLint's
  `identifier_name` (underscores are not alphanumeric); Xcode only needs the
  `test` prefix. Now `func testFooBar`, and `gen-acceptance-tests.mjs` throws if
  a name is ever not lowerCamelCase alphanumeric.
- **`--strict` removed from SwiftLint** in the hook, CI and the verify script.
  It promotes every warning — `line_length` at 120, `force_unwrapping` — into an
  error, which would block commits on cosmetics through exactly the phase of work
  where long view bodies are normal. Rules with `error` severity still fail.
- **`v` added to `identifier_name.excluded`**, because `AppData.v` is one
  character and the web schema's field name is not ours to rename.
- **`AppData.CodingKeys` declared explicitly.** Swift only synthesises
  `CodingKeys` while it is synthesising `init(from:)` or `encode(to:)`; this type
  hand-writes `init(from:)`, so the day someone hand-writes `encode(to:)` too,
  the synthesised enum vanishes and the decoder stops compiling.

Also added `scripts/verify-ios.sh`. Expect `swiftformat --lint` to be the one
phase that fails first time — the fix is `swiftformat --config ios/.swiftformat
ios`, not an edit.

### Amended again, same day — XcodeGen dropped

Eden asked whether any of this was a workaround rather than a standard setup. It
was, in one place, and it has been reversed.

**XcodeGen is out.** The reason given for it was pbxproj merge conflicts, but
Xcode 16 buildable folders largely solve those, and with one developer running
agents *sequentially* the argument barely applied at all. The unstated reason was
that the scaffolding agent could not produce a valid `.xcodeproj` from Linux and a
hand-written pbxproj would have been far riskier than YAML — which is a fact about
that agent, not about this project.

`scripts/adopt-xcode-project.sh` performs the swap in one command: generates the
project once, commits it, strips the generator out of `.gitignore`, `bootstrap.sh`,
`verify-ios.sh` and CI, deletes `project.yml` and the `Local.xcconfig` pair, and
then deletes itself. **Nothing about the generator survives.** Signing moves to
the target's Signing & Capabilities tab, which is where it normally lives.

Two optional things in Xcode afterwards, both in the script's closing output:
convert the `Morning` and `MorningTests` groups to folders (30 seconds, and it is
the one thing XcodeGen was actually buying), and set the team if you want to
install on the phone.

Also cleaned out of `project.yml` before generating, so none of it reaches the
committed project: `ENABLE_USER_SCRIPT_SANDBOXING` and `DEAD_CODE_STRIPPING`
(already Xcode defaults), `SWIFT_STRICT_CONCURRENCY` (redundant under Swift 5
mode), and `EXCLUDED_SOURCE_FILE_NAMES: "*.seed.json"` — that setting is for
sources, not resources, and 150KB of DEBUG-gated fixtures is not worth an
off-label trick. `ios/Tools/gen-program-swift.mjs` was deleted too: one-shot
transcription tool, dead weight now that `Program.swift` is the source of truth.

**One real bug found in the process:** `verify-ios.sh` counted assertions with
`grep 'func test_'`, which stopped matching when the tests were renamed earlier
the same day. It would have reported 0 assertions and nobody would have noticed.

### Amended a third time, same day — current versions

Eden asked why the scaffold was not on current versions, and installed Swift 6.3
locally. Both bumps were overdue.

- **iOS 18.0 -> iOS 26.0.** `05-platform.md` says "iOS 18+" and one device, an
  iPhone 16 Pro. 26 satisfies "18+", the phone runs it, and there is no
  back-compatibility burden — aiming at a two-year-old floor was giving up APIs
  for nothing, in a port whose entire justification is that the phone can do
  more. **Consequence: the phone must be on iOS 26 to install.**
- **Swift 5 mode -> Swift 6 mode**, with `SWIFT_APPROACHABLE_CONCURRENCY = YES`
  and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. All three together are what
  Xcode 26 gives a new project, and the combination is the whole point: Swift 6
  *without* them is the wall people complain about; with them, a single-user app
  with no background work needs almost no annotations.
- `.swiftformat` moved to `--swiftversion 6.0` so it stops rewriting valid
  Swift 6 syntax, and CI moved from `macos-15` to `macos-latest`.

**Eden's phone is on an iOS 27 beta.** This does not affect the deployment
target — an app built for iOS 26 runs on 27 — and it does not affect the
simulator, the test suite or CI at all. It affects exactly one thing: installing
on the device needs an Xcode that ships iOS 27 device support, i.e. the Xcode 27
beta. Xcode 26 stable will refuse the device with "may not be supported by this
version of Xcode", which is a tooling mismatch and not a bug. Written up at the
top of `ios/Docs/device-checklist.md` so W11 does not lose an hour to it. The
target stays at 26.0 on purpose: pinning to 27 would chain the project to a beta
SDK and break on a rollback.

**Predicted friction, so W0 is not surprised.** Under
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` every global in `Program.swift`
becomes main-actor isolated. That is harmless today because nothing runs off the
main actor, but the moment something does — a background write, a
`Task.detached`, a `nonisolated` helper — reading `program` from it is an error.
The right fix then is `nonisolated` on those globals, since they are immutable
Sendable data with no UI dependency. **Do not** reach for `@unchecked Sendable`
or `nonisolated(unsafe)`. I left the annotations off deliberately rather than
guessing at them without a compiler.

The other thing to watch: an `XCTestCase` subclass in a MainActor-by-default
module is itself MainActor-isolated, and a MainActor override of `XCTestCase`'s
`nonisolated` `setUp`/`tearDown` is an error. The generated suites override
nothing, so this is clean now — it will bite the first agent that adds a
`setUp`.

---

## Template

Copy this for your entry.

```markdown
## YYYY-MM-DD · <workstream> · <agent/model>

**Workstream:** W<N> — <name>

**What I did**
- …

**Decisions taken**
- <chose X over Y because Z>

**Landmines**
- <what you found and did not fix, what you half-fixed, what you are suspicious of>

**Assertions:** <n> of 53 passing (<n> skipped)

**Next:** <the next workstream, and anything its agent needs from you>
```
