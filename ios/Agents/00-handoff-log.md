# Handoff log

Append-only, newest at the top. One agent works this clone at a time; this file
is the only thing standing between the next agent and re-deciding what you
already decided.

The **Landmines** field is worth more than the summary of what you built.

---

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
