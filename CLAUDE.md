# CLAUDE.md

Start here. Every session, before anything else.

## What this repo is

Two things:

1. **A finished web app** (`src/`, TypeScript + React + Vite, deployed to
   <https://edenturgeman.github.io/morning/>). An offline-first PWA that runs one
   20-minute morning workout step by step. It works. It is **the behaviour
   specification for the port, and it is not the design ceiling.**
2. **A native iOS port in progress** (`ios/`). SwiftUI, iOS 26, Swift 6 mode,
   iPhone only, portrait only. This is the work.

The full brief for the port is `ios-port/`. It is 8 documents and they are
binding. `ios-port/02-design-brief.md` is the main one.

## Read in this order — do not skip

| File | What it settles |
|---|---|
| `spec.md` | **What the app must do.** Behaviour only, no UI. The one to read if you are changing or rebuilding anything. |
| `ios-port/README.md` | The working agreement. Four rules. Read them literally. |
| `ios-port/01-product.md` | One user, one iPhone, 6:10am, sweaty hands. Justifies every UI decision. |
| `ios-port/02-design-brief.md` | **The main document.** Visual direction, the research method, the quality bar. |
| `ios-port/03-program.md` | The training program and how it stays editable. |
| `ios-port/04-rules.md` | Every behavioural rule that must survive the port. |
| `ios-port/05-platform.md` | What native unlocks, and which old constraints are dead. |
| `ios-port/06-data.md` | The storage contract. |
| `ios-port/07-acceptance.md` | What "done" is checked against. |
| `ios/Agents/README.md` | How agents hand work to each other here. |
| `ios/Docs/redesign-plan.md` | **If you are rebuilding the UI:** which skill runs when, and the web→SwiftUI translation table. |

Then pick up a workstream from `ios/Agents/workstreams.md`.

## The four rules that get broken first

From `ios-port/README.md`, restated because they are the ones an agent will
violate on instinct:

1. **Design before you build.** Do not port screens one by one. Research pass,
   then two or three *running* direction prototypes of the Set and Rest screens,
   then agreement with Eden, then build. Getting agreement on the look is the
   first deliverable, not the last. Workstream **W1** is a hard gate on
   everything visual.
2. **Port the reasoning, not the code.** The web source is full of workarounds
   for problems iOS does not have — `100dvh`, safe-area arithmetic, scroll-lock,
   StrictMode guards, a three-band fixed/scrolling/pinned layout. `04-rules.md`
   separates intent from scar tissue. Where the source and `ios-port/` disagree
   about *why*, `ios-port/` wins. About *what*, the source wins — go read it.
3. **Content is fixed; form is yours.** Exercise names, cues, targets, rest
   seconds, celebration copy, card text and Guide text are **not yours to
   improve** — port them verbatim from `ios-port/content/*.json`. Layout,
   hierarchy, colour, type, material, motion, sound, haptics and which screens
   exist entirely are.
4. **Ask rather than assume** on anything touching the training program, and on
   the four things `05-platform.md` says to propose rather than build:
   notifications, Apple Health, Live Activities, widgets.

And one more, because it is the whole tone of the product: **this app is not
gamified and must never become gamified.** No points, no badges, no levels, no
"Great job!". Every headline states something true and specific. The reward for
finishing is being told exactly what you did, well.

## Getting the environment up

```bash
./scripts/bootstrap.sh          # idempotent; run it first, every machine
./scripts/verify-ios.sh         # build + test + lint + format, all errors in one report
npm run dev                     # the web app — the behaviour spec
open ios/Morning.xcodeproj      # ⌘U runs the acceptance suite
```

`verify-ios.sh` never stops at the first failure — it runs every phase and writes
each one's errors to `ios/build/verify-report.txt`. Use it instead of chasing
`xcodebuild` output; hand the report to whoever is fixing things.

`ios/Morning.xcodeproj` is an ordinary committed Xcode project. There is no
project-generation tooling in this repo — open it and work in it. If the Morning
and MorningTests groups have been converted to folders (see the handoff log),
adding a file on disk needs no project edit at all.

**Before you write any Swift, run the web app and do a full session of A and a
full session of B.** `ios-port/README.md` puts this in the first-session
checklist for a reason: you cannot design the replacement for something you have
not used.

## Where the port actually is

Eighteen workstreams in. **The Swift compiles, the tests run, and every surface
in `spec.md` §3 is built and on screen.** An older version of this file said the
code had never been through a compiler and that there were no screens; both were
true in W0 and neither has been true for months.

| Path | What it is | State |
|---|---|---|
| `ios/Morning/Screens/` | Eighteen files. Every surface in `spec.md` §3, including the Live Activity. | Built, shipped, **about to be redesigned.** |
| `ios/Morning/Program.swift` | The program as Swift literals per `03-program.md`. **The source of truth**, not the JSON. | Compiled and tested. |
| `ios/Morning/Model/Schema.swift` | The v1 storage contract from `06-data.md §3`. | Compiled and tested. |
| `ios/Morning/Shaders/` | `Sky.metal` (the workout sky) and `Daybreak.metal` (the completion moment). | Built. Read their headers before touching them. |
| `ios/MorningWidgets/` | The Live Activity target. | Built. |
| `ios/MorningTests/Acceptance/` | 68 tests from `07-acceptance.md`. Two still skipped. | Passing. |
| `ios/Docs/design-system.md` | 655 lines. Every contrast figure measured on rendered frames, not calculated. | Real. Revise it, do not start it. |
| `ios/Docs/redesign-plan.md` | **How the UI rebuild is run**, phase by phase, on Emil Kowalski's skills. | The method for the next programme. |
| `ios/Docs/device-checklist.md` | The 10 device checks that cannot be automated. | W11, still blocked on the phone. |

Run `./scripts/verify-ios.sh` first anyway. It never stops at the first failure
and writes every phase's errors to `ios/build/verify-report.txt`.

## What is deliberately absent

Not oversights. Do not "fix" these without asking:

- **No HealthKit.** `05-platform.md §7`: propose, don't assume.
- **No history import.** `06-data.md`: v1 ships starting at zero. The web app
  keeps the real history for now. What that costs you is that **empty and
  near-empty states are the normal case on day one, not an edge case.**
- **No concurrency annotations anywhere.** Not an omission — with
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` the whole module is main-actor
  isolated by default, which is correct for a single-user app with no background
  work. Add `nonisolated` only where the compiler actually asks for it, and never
  reach for `@unchecked Sendable` or `nonisolated(unsafe)` to silence it.
- **Two things `spec.md` specifies that are built but never rendered.**
  `Celebration.rays` has no reader, so a plateau looks identical to a personal
  best; `SetStep.intense` has no reader, where the web build shows a MYO badge.
  Both were left for the redesign rather than patched into views about to be
  replaced. See `ios/Docs/redesign-plan.md` R4.


## Traps

Every one of these has already cost someone something.

- **`weekStartsOn` changed meaning.** The web build stores `0` for Sunday
  (JS convention). `Program.swift` stores `1` (Foundation convention). Same day,
  different number. Do not "fix" either one to match the other.
- **`d` is a LOCAL date, `ts` is epoch ms.** Parsing `d` as UTC shifts sessions
  across day and week boundaries and quietly corrupts the year grid. Parse as
  local, or at local noon.
- **`ts` is a record's identity.** Deletion, "previous same session" lookups and
  milestone diffing all key off it. Never regenerate it.
- **A missing `kg` is meaningful** — "logged before the weight was adjustable".
  Fall back to the program default. **Never backfill it**; that retroactively
  rewrites tonnage.
- **Two slot-key shapes.** A record's `log` is keyed by the bare slot
  (`"2.1.0"`). The ledger's internal load table keys by `"A:2.1.0"`. Keep them
  straight or imported history mis-values.
- **Slot ids are `block.item.set` and load-bearing.** This is why the floor fly
  in session B was *appended*, not inserted — inserting it would have shifted
  every later id and handed it the myo block's rep history.
- **One history record per finished session.** The web build briefly wrote two.
- **Reps are only comparable at the same weight.** If the working weight moved,
  every delta is meaningless. Say so honestly; do not show a comparison that
  isn't one.
- **Bodyweight reps are 0 kg of tonnage** but still count as reps.
- **`spec.md` is now the functional specification and it IS tracked.** It was
  gitignored, and absent from every clone, because the original described the
  person this was built for. The one in the repo now describes only what the app
  must *do* — no UI, no UX, no screens — and it exists so the interface can be
  rebuilt from scratch without reverse-engineering the behaviour out of the old
  one. **Read it before changing behaviour, and update it in the same commit
  when behaviour changes.** Anything personal goes in `spec.private.md`, which
  is still ignored.

## Definition of done, for any screen

From `02-design-brief.md §12`. All of it, not a selection:

- [ ] Does it beat the web version, obviously, to someone glancing at both?
- [ ] Held at arm's length in a dark room, is the one thing you need to know the
      first thing you see?
- [ ] Does every tap answer in the hand as well as on screen?
- [ ] Does anything scroll that shouldn't? (Inside a workout: nothing. Ever.)
- [ ] Does the longest possible content still fit — longest exercise name, four
      cues, a three-line question with a seven-line answer?
- [ ] Does it hold at **empty**, at one week, and at six months of data?
- [ ] Does it hold at the largest Dynamic Type size it claims to support?
- [ ] Does Reduce Motion produce a calmer version rather than a broken one?
- [ ] Is there any copy that congratulates without saying something true?
- [ ] 120Hz, no dropped frames, during a running timer?

## Before you finish a session

Write your handoff entry in `ios/Agents/00-handoff-log.md`. One agent works at a
time in this clone; that file is the only thing standing between the next agent
and re-deciding what you already decided.
