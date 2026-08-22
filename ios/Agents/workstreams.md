# Workstreams

In order. Each one's **gate** is a hard precondition — if it is not met, the
workstream is not startable. Statuses: `todo` · `in progress` · `done`.

The build order in W4–W10 is not mine, it is `02-design-brief.md §11`:
**Set → Rest → Home → Summary + Daybreak → History → Ledger → Guide → Backup.**
Set and Rest first because they are 80% of the app's on-screen time. If they are
not excellent, nothing else matters.

Every kickoff prompt below is meant to be pasted verbatim.

---

## W0 · Make it compile — `done`

**Gate:** none. This is the first thing anyone does.

Nothing in `ios/` has ever been through a Swift compiler. It was written from the
spec on a machine with no Swift toolchain. This workstream exists so no design
agent loses an hour to a stray comma.

**Scope**

- `./scripts/adopt-xcode-project.sh` if `ios/project.yml` still exists — it
  turns the XcodeGen spec into a plain committed project and deletes itself.
- `./scripts/verify-ios.sh`, which does bootstrap, build, test, lint and format
  in one pass and writes every error to `ios/build/verify-report.txt`.
- Fix syntax and type errors in `Program.swift`, `Schema.swift`, `Seeds.swift`,
  `MorningApp.swift`, `GoldenSteps.swift` and the seven acceptance suites.
- Confirm `GoldenSteps.load()` actually finds `compiled-steps.json` in the test
  bundle, and that `Seed.sixMonths.load()` decodes a `six-months.seed.json` into
  an `AppData` with 125 records.
- Confirm SwiftLint and SwiftFormat pass, and that the pre-commit hook fires.
- Do **not** change any content, any field name, or any of the numbers.

**Done when:** the app launches on an iPhone 16 Pro simulator showing
`ScaffoldView`, `⌘U` reports 53 tests, 53 skipped, 0 failed, and CI is green.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W0 — Make it compile**, in `ios/Agents/workstreams.md`.
> None of the Swift in this repo has ever been compiled. If `ios/project.yml`
> still exists, run `./scripts/adopt-xcode-project.sh` first. Then run
> `./scripts/verify-ios.sh`, read `ios/build/verify-report.txt`, and fix only
> what is actually broken: syntax, types, bundle-resource wiring. Change no content, no field
> names and no numbers — if something looks wrong rather than broken, write it in
> the handoff log as a landmine instead of fixing it. Finish by appending your
> handoff entry and flipping W0 to `done`.

---

## W1 · Research pass and directions — `done`

**Gate:** W0 done. **And you have run the web app and done a full session of A
and a full session of B.** Non-negotiable — `ios-port/README.md` first-session
checklist. You cannot design the replacement for something you have not used.

This is the workstream the whole port hangs on, and the one most likely to be
skipped. `02-design-brief.md §4` and `§5`.

**Scope**

- The screen research pass in `§4`, using publicly inspectable evidence from
  shipped apps: official product/help pages, App Store listing creatives, public
  demos and walkthroughs, Apple design profiles, and platform documentation.
  Eden explicitly chose this method after the available screen-library MCPs
  required paid plans. The table in `§4` says what to search for and what
  question each search answers. Separate observed evidence from interpretation.
- Write `ios-port/research-notes.md` (a skeleton exists). Mechanics, not skins.
  For each screen studied: the mechanic, what they left out, how they handle the
  hard case, one thing you'd steal and one you wouldn't.
- Build **two or three** of the directions in `§5` as **real running screens** —
  the Set screen and the Rest screen, with motion and haptics, on device. Not
  mockups. Throwaway code is fine and expected; hardcode the data.
  - **A · Dawn, done properly** — the sunrise idea at native quality. Read
    `src/lib/sunrise.ts` first; the five OKLCH stops are hand-picked, not
    generated, and the header comment explains why.
  - **B · Instrument** — near-black, one luminous accent, hairlines, tabular
    numerals, mechanical motion.
  - **C · Physical** — depth, translucency, weight; the rep counter is an object
    you move.
  - Or something better the research turns up. Propose it, with reasoning.

**Done when:** `research-notes.md` is written, two or three prototypes run on a
real iPhone, and **Eden has picked a direction.** Do not proceed past this
without that. Extract patterns, never ship someone's brand.

**Closed 2026-08-22.** `research-notes.md` written; Atmospheric, Precise and
Tactile all run; Eden chose **Atmospheric Dawn**.

One part of the gate could not be met here and was **carried to W11**, not
waived: no physical iPhone has ever been connected to this clone, and no signing
identity is configured, so "run on a real iPhone" — and with it haptic quality
and 120Hz frame pacing — remains unverified. `device-checklist.md` is the right
home for it and already lists those checks. Everything that a simulator *can*
settle was settled and measured; see `ios/Docs/prototype-directions.md`.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W1 — Research pass and directions**. Read
> `ios-port/02-design-brief.md` end to end first; it is the main document and
> this workstream is its §4 and §5. Before you design anything: run the web app
> with `npm run dev` and do a full session of A and a full session of B while
> reading `ios-port/04-rules.md`. Then do the public-evidence research pass,
> write `ios-port/research-notes.md`, and build two or three running direction
> prototypes of the Set and Rest screens with real motion and haptics. Come back
> to Eden with directions to choose between — do not pick one yourself, and do
> not start building the app. Append your handoff entry when you stop.

---

## W2 · Design system — `done`

**Gate:** W1 done and a direction agreed by Eden.

`02-design-brief.md §11` deliverable 4: colour ramp, type scale, spacing,
materials, motion curves, **haptic vocabulary**. One file, written down, the way
`src/index.css` documents the web one.

**Scope**

- Fill in `ios/Docs/design-system.md`.
- Implement it as Swift: tokens, not scattered literals.
- The haptic table is not optional and not an afterthought. `05-platform.md §3`
  lists the minimum vocabulary: rep increment, passing last time's number, set
  logged, the last five seconds, zero, session complete, card reveal. Design them
  as carefully as the visuals — the web app has **no haptics at all**, so this is
  the single largest available improvement in felt quality.
- Contrast: match or beat the web palette's 18:1 / 10:1 / 6.6:1 for its three
  text levels. Tertiary labels included.
- Every animation gets a defined **reduced-motion form** — calmer, not disabled.

**Done when:** the file is written and the tokens exist in code, and the W1
prototypes have been rebuilt on top of them without visual regression.

**Closed 2026-08-22.** `ios/Docs/design-system.md` written; tokens live in
`DesignTokens.swift`, `DesignMotion.swift` and `DesignHaptics.swift`. The
Atmospheric prototypes were rebuilt on them and re-measured: no regression, and
the weakest text zone on any screen at any progress is 7.00:1 against a 6.6:1
bar. The haptic table is complete, including the countdown pulse that was
previously missing and is now wired to every rest timer.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W2 — Design system**. The direction is agreed; the
> handoff log says which. Write `ios/Docs/design-system.md` and implement its
> tokens in Swift: colour ramp, type scale, spacing, materials, motion curves and
> a full haptic vocabulary per `ios-port/05-platform.md §3`. Then rebuild the W1
> prototypes on the tokens. Append your handoff entry when you stop.

---

## W3 · Foundations and the acceptance suite — `done`

**Gate:** W0 done. Can run before or after W1/W2 — it touches no UI.

`07-acceptance.md`: *"Port them to XCTest early — before the UI work, not
after. They will catch a mis-ported rule in seconds that would otherwise show up
as a wrong number six weeks from now."*

**Scope**

- The step compiler: sessions → a flat linear step list. `04-rules.md §1`,
  reference `src/lib/steps.ts`.
- Plate breakdown bounded by inventory. `src/lib/plates.ts`. 7.5 kg is
  `2×2.5 + 2×1.25`, never `3×2.5` — you only own two 2.5s per handle.
- Persistence: atomic JSON writes to Application Support, the separate
  in-progress session record, lenient parsing that drops malformed entries.
  `06-data.md §4–5`. **Never lose data on a failed write** — surface it. This is
  the one unacceptable failure mode in the app.
- Wire up the debug seeder so `-seed six-months` works.
- **Un-skip and implement: `ProgramCompilerAcceptanceTests` (10) and
  `DataAcceptanceTests` (8 of 10 — the two `testPhase2` tests stay skipped, import
  is not v1).**

**Done when:** 18 of 53 assertions pass, `-seed` works for all five fixtures, and
an export from the app parses in the web app's Restore box.

**Closed 2026-08-22.** 18 of 53 pass, 35 skipped, 0 failures. All five seeds
land in Application Support with the right record counts (0 / 1 / 5 / 125 / 285).

The Restore-box check is **no longer manual**. `scripts/verify-export.ts` imports
the real `parseData` from `src/lib/storage.ts` — not a copy of its rules — runs a
genuine iOS export through it, and fails if a single record is dropped or
altered. `verify-ios.sh` runs it as a phase, so the day the two formats drift, CI
says so instead of a restore quietly losing history.

Three `DataAcceptanceTests` have a UI half belonging to W4/W6/W7. Those assert
the data the screen will rest on and say so in a comment, which is worth more
than a skip: it is the half that can regress silently.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W3 — Foundations and the acceptance suite**. No UI.
> Build the step compiler, the inventory-bounded plate breakdown, and
> persistence per `ios-port/06-data.md`, then implement
> `ProgramCompilerAcceptanceTests` and `DataAcceptanceTests` (leave the two
> `testPhase2` tests skipped). Read `src/lib/steps.ts` and `src/lib/plates.ts` for
> *what*, and `ios-port/04-rules.md` for *why* — where they disagree about why,
> the doc wins. Assert against `compiled-steps.json` as a whole list, not just
> the counts. Append your handoff entry when you stop.

---

## W4 · The Set screen — `todo`

**Gate:** W2 and W3 done.

**The most important screen in the app.** `02-design-brief.md §8`: everything on
it competes for the same space, hierarchy here is the single hardest design
problem in the app, and the web version's answer — fixed header, scrolling
middle, pinned controls — is a DOM compromise, not a good idea to inherit.

**Scope**

- Exercise name, sub-label, load, "set 2 of 3", superset position, form cues with
  the intensity words emphasised, target range, the rep counter pre-filled from
  last time, last time's number, one primary action.
- **The rep control.** `04-rules.md §1`. Reports a **delta**, never an absolute —
  two taps in one update cycle computed from the same stale value and collapsed
  into one increment, and hold-to-repeat accelerates to 60ms so that is reachable
  in normal use. The digit moves in the direction you pushed it.
- **Passing last time's number is the emotional centre of the entire app.** Give
  it everything: haptic detent, colour, motion, sound.
- Prefill priority, in this exact order: this session's own value for the slot →
  last time on this exact set → a plausible default (12 loaded, 10 bodyweight).
  Getting this order wrong is how Back silently ate a correction in an early
  build.
- If last time's reps were at a different working weight, they are not a
  like-for-like target and the control must **say so** rather than quietly
  implying one.
- Targets ≥ 64pt; the rep controls get 78pt, because they are hit with a knuckle.
- The first-run case: no "last time" for any slot. `First time — just go to
  failure`. One session per slot has no comparison at all — make it feel
  deliberate, not broken.
- **Un-skip and implement: `SessionLifecycleAcceptanceTests` (8).**

**Done when:** 26 of 53 assertions pass and the screen meets every box in
CLAUDE.md's definition of done, at empty and at six months.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W4 — The Set screen**, the most important screen in
> the app. Build it on the agreed direction and the W2 tokens. Read
> `ios-port/04-rules.md §1` before you touch the rep control: it reports a delta,
> not an absolute, and the moment it passes last time's number is the emotional
> centre of the whole product. Implement `SessionLifecycleAcceptanceTests`.
> Review the screen at empty, one week and six months of seeded data before you
> call it done. Append your handoff entry when you stop.

---

## W5 · The Rest screen and the study deck — `todo`

**Gate:** W4 done.

**Scope**

- A countdown readable from two metres. What's coming next. Add time, skip.
- Remaining time computed from a stored end date, **never** a tick counter — it
  drifts and stops dead when the app is suspended.
- `isIdleTimerDisabled = true` for the session; released on end or abandon.
- Audio: `AVAudioSession` `.playback` with `[.mixWithOthers, .duckOthers]`,
  **activated around cues and deactivated after** with
  `.notifyOthersOnDeactivation`. The countdown's last five seconds must be **one
  duck**, not six pumps. The web build got this wrong and the user reported it as
  "working, and not letting me play music". `05-platform.md §3`.
- The six cues, per the table in `05-platform.md §3`. The count-in ascends on
  purpose.
- **Ask Eden** whether the countdown should respect the ring switch or override
  it. `05-platform.md §3` says to ask rather than decide.
- The study deck, `04-rules.md §6`. Two cards per session on rests plus one on
  the summary. Only on rests ≥ 45s. **Never on the 20-second myo rest** — that
  rest *is* the training stimulus. Not on the first long rest. Drawn without
  replacement. Auto-reveals, 6.5–11s scaled to rest length; tapping only brings
  it forward. **The card is silent** — haptics on reveal are welcome, sound is
  banned.
- The ring halving when the answer appears is a good existing example of motion
  carrying meaning. Keep the idea.
- **Un-skip and implement: `StudyDeckAcceptanceTests` (7).**

**Done when:** 33 of 53 pass, and on a real phone music from another app ducks
once at five seconds and returns after zero.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W5 — Rest screen and study deck**. Read
> `ios-port/05-platform.md §3` and `ios-port/04-rules.md §6` in full first. The
> audio session and the single-duck countdown are the parts most likely to go
> wrong; the deck dosing numbers are deliberate and not to be rounded off. Ask
> Eden about the ring switch before you implement it. Implement
> `StudyDeckAcceptanceTests`. Verify the ducking on a real phone, not the
> simulator. Append your handoff entry when you stop.

---

## W6 · Home and the week — `todo`

**Gate:** W5 done.

**Scope**

- Answers "what am I doing and what do I set up?" in under two seconds. Which
  session is next (auto-derived — the opposite of what was logged last, A on a
  fresh install), the working weight and its plate breakdown, one large start
  control, a quiet way to start the other session instead, where you are in the
  week, and a way into History / Ledger / Guide / Backup.
- Streaks are measured **in weeks, not consecutive days** — the program has a
  rest day and a consecutive-day streak punishes you for following it correctly.
  Five sessions, any days. Week starts Sunday. The week in progress can never
  break a streak. Longest run is remembered separately and stays on screen.
  `04-rules.md §3`.
- The nudge copy is generated from derived state, and names the correct weekdays.
- **Empty is the day-one case**: no last session, no streak, no week progress, no
  lifetime figures. It still has to answer the two-second question.
- **Un-skip and implement: `WeekAndStreakAcceptanceTests` (8).**

**Done when:** 41 of 53 pass.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W6 — Home and the week**. Read `ios-port/04-rules.md
> §3` for the streak rules; they are counted in weeks, not days, and the week in
> progress can never break one. Note the trap in CLAUDE.md about `weekStartsOn`
> meaning 0 in the web build and 1 in `Program.swift`. Design the empty state
> properly — on day one it is what the screen actually is. Implement
> `WeekAndStreakAcceptanceTests`. Append your handoff entry when you stop.

---

## W7 · Summary, Daybreak and the celebration tiers — `todo`

**Gate:** W6 done.

**Scope**

- Exactly **one** headline: the highest tier actually earned, from the 11-tier
  priority table in `04-rules.md §5`. Copy verbatim from
  `src/lib/celebration.ts`.
- **Every headline must add something the rendered number does not already say.**
  The summary shows the rep total as a large number above it, so a headline of
  "252 reps." prints the same figure twice. That was a real bug Eden caught.
  Same for eyebrows restating headlines.
- Rep deltas suppressed entirely when the working weight changed.
- `plateau` is the app's most valuable output — three same-letter sessions on an
  identical total means it is time to change the program. It must not read as a
  failure state; the copy says which rung to move to.
- **Ordinary confetti fires on every finished session.** The larger milestone
  burst is reserved for week completions and lifetime thresholds. Eden asked for
  this explicitly — do not gate the ordinary celebration.
- Daybreak: read the header comment in `src/components/Daybreak.tsx` before
  redesigning it. It documents why each beat of the 4.4 seconds exists, and the
  reasoning survives even if the visuals don't. `PhaseAnimator` /
  `KeyframeAnimator` and a CoreHaptics pattern choreographed against it.
- The `first` tier — *"You started."* — fires **exactly once, ever**. It deserves
  real attention for something that will be seen a single time.
- **Un-skip and implement: `CelebrationAcceptanceTests` (6).**

**Done when:** 47 of 53 pass.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W7 — Summary, Daybreak and celebration tiers**. The
> tier table and priority order are in `ios-port/04-rules.md §5` and the copy is
> verbatim from `src/lib/celebration.ts` — do not rewrite a single headline. Read
> the header comment at the top of `src/components/Daybreak.tsx` before
> redesigning the completion moment. Nothing here may congratulate without
> saying something true and specific. Implement `CelebrationAcceptanceTests`.
> Append your handoff entry when you stop.

---

## W8 · History and the year grid — `todo`

**Gate:** W7 done.

**Scope**

- Reverse-chronological: date, session letter, total reps, duration.
- A week strip and a year grid, one cell per day, intensity scaled to the user's
  own range so a good month literally looks warmer.
- **The grid must fit the screen.** A fixed-cell version was wider than a phone
  and pushed recent weeks off the right edge; seeing a year at once is the whole
  point. `04-rules.md §7`.
- Deletion behind an **explicit edit mode**. Never a swipe — sweaty hands, and an
  accidental delete is unrecoverable.
- Empty is real here: "0 tonnes" is a bad answer and so is hiding the screen.
  Design something that reads as *the beginning of a record*.
- `Canvas` is probably the right tool for the grid.

**Done when:** reviewed at empty, one week, six months and one year of seeded
data, and the grid fits at every size.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W8 — History and the year grid**. Read
> `ios-port/04-rules.md §7`. The grid must fit the screen at every size — that
> constraint killed the first web version. Deletion goes behind an explicit edit
> mode, never a swipe. Review at all five seed fixtures, `empty` first. Append
> your handoff entry when you stop.

---

## W9 · Ledger and milestones — `todo`

**Gate:** W8 done.

**Scope**

- Everything ever: tonnage, reps, sessions, hours, next threshold. One
  staggering true number at the top. This screen exists to make the last six
  months feel like they happened.
- Tonnage is `reps × 2 × load` — two dumbbells, load is per handle. Bodyweight
  work is **0 kg** but still counts toward reps. Each session valued at its own
  recorded `kg`. `04-rules.md §4`.
- Milestones are deliberately sparse — "a milestone you hit every fortnight is a
  chore; one you hit twice a year is an event." Tonnes 1/5/10/25/50/100/250/
  500/1000, reps 1k–100k, sessions 10–1000. Each fires **exactly once**, on the
  session that crossed it, computed by diffing the ledger with and without that
  session. Copy verbatim from `src/lib/ledger.ts`.
- Empty is the hardest state on this screen. Design it.
- **Un-skip and implement: `LedgerAcceptanceTests` (4).**

**Done when:** 51 of 53 pass — everything except the two `testPhase2` import tests.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W9 — Ledger and milestones**. Read
> `ios-port/04-rules.md §4`. The two honesty constraints on tonnage are
> non-negotiable: 2 × load per rep, and bodyweight reps contribute zero kg.
> Milestone copy is verbatim from `src/lib/ledger.ts`. The empty state is the
> hard one — "0 tonnes" is a bad answer. Implement `LedgerAcceptanceTests`.
> Append your handoff entry when you stop.

---

## W10 · Guide and Backup — `todo`

**Gate:** W9 done.

**Scope**

- Guide: nine short entries, verbatim from `ios-port/content/guide.json`. A
  static reference read maybe monthly. Dynamic Type through the accessibility
  sizes.
- Backup: export to a file via the share sheet, restore with validation and a
  confirmed session-count swap, erase everything destructive and visually
  de-emphasised.
- Exported JSON must be **byte-compatible with the web app's format** — open it
  in the web app's Restore box and confirm it parses. This is also the code path
  the eventual import will reuse.
- **Propose iCloud rather than assuming it.** `05-platform.md §6`: CloudKit
  private database or an iCloud Documents file would turn this screen from a
  chore into a background detail — but manual export stays regardless, because it
  is the only copy that survives losing the phone *and* the account.

**Done when:** export → wipe → restore reproduces the history exactly, and an
export opens in the web app.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W10 — Guide and Backup**. Guide text is verbatim
> from `ios-port/content/guide.json`. For Backup, the export must be
> byte-compatible with the web app's format — verify by pasting it into the live
> web app's Restore box. Propose an iCloud approach to Eden rather than building
> one. Append your handoff entry when you stop.

---

## W11 · The device pass — `todo`

**Gate:** W10 done.

`ios/Docs/device-checklist.md` — the ten checks that cannot be automated and
must be done on the phone, not the simulator. Airplane mode, legibility at 1.5m
in a dark room, the "beat your last number" haptic distinguishable with the phone
face down, music ducking once, the screen never sleeping, 120Hz with no dropped
frames, Reduce Motion calmer rather than broken.

**Done when:** every box ticked, then a full session of A and a full session of B
start to finish with zero glitches — and then again for real at 6am, which is
the only test that actually counts.

**Kickoff prompt**

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.
>
> You are doing workstream **W11 — The device pass**. Work through
> `ios/Docs/device-checklist.md` on a real iPhone 16 Pro, not the simulator.
> Record what you observed against each box, not just pass/fail. Append your
> handoff entry when you stop.

---

## W12 · Propose the system integrations — `todo`, ask first

**Gate:** W11 done, and **Eden has said yes to each item individually.**

`05-platform.md §4` and `§7` are explicit that these are to be **proposed, not
built**. They were non-goals on the web only because they were impossible there.

- **Live Activity / Dynamic Island** for the rest timer. `Text(timerInterval:)`
  counts down on the Lock Screen with no updates from the app at all, so it costs
  essentially nothing. Eden has asked about this specifically. It is the feature
  most likely to make the app feel native rather than ported — and the one most
  likely to become annoying if overdone. Prototype one-per-rest *and*
  one-for-the-session and decide from how it feels.
- **Home-screen widget**: the week's pips and which session is next. Small,
  quiet, honest.
- **HealthKit**: each session as a strength-training workout, closing the rings.
- **Control Centre / Action Button**: starting today's session in one press is
  plausibly the best affordance available on this hardware for a 20-minute daily
  habit.

Each of these is a new target, added in Xcode once it is agreed.

---

## Later, not now

**Importing the web history.** `06-data.md §6`. Not v1 — v1 ships starting at
zero and the two apps run side by side for a couple of weeks while Eden decides
whether the native one wins. The acceptance test when it lands is that five
derived numbers match the web app's Ledger on the same device: tonnage, total
reps, session count, current streak, longest run, and the year grid. The two
`testPhase2` tests in `DataAcceptanceTests` are that workstream's entry point.
