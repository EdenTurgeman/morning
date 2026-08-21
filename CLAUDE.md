# CLAUDE.md

Start here. Every session, before anything else.

## What this repo is

Two things:

1. **A finished web app** (`src/`, TypeScript + React + Vite, deployed to
   <https://edenturgeman.github.io/morning/>). An offline-first PWA that runs one
   20-minute morning workout step by step. It works. It is **the behaviour
   specification for the port, and it is not the design ceiling.**
2. **A native iOS port in progress** (`ios/`). SwiftUI, iOS 18+, iPhone only,
   portrait only. This is the work.

The full brief for the port is `ios-port/`. It is 8 documents and they are
binding. `ios-port/02-design-brief.md` is the main one.

## Read in this order — do not skip

| File | What it settles |
|---|---|
| `ios-port/README.md` | The working agreement. Four rules. Read them literally. |
| `ios-port/01-product.md` | One user, one iPhone, 6:10am, sweaty hands. Justifies every UI decision. |
| `ios-port/02-design-brief.md` | **The main document.** Visual direction, the research method, the quality bar. |
| `ios-port/03-program.md` | The training program and how it stays editable. |
| `ios-port/04-rules.md` | Every behavioural rule that must survive the port. |
| `ios-port/05-platform.md` | What native unlocks, and which old constraints are dead. |
| `ios-port/06-data.md` | The storage contract. |
| `ios-port/07-acceptance.md` | What "done" is checked against. |
| `ios/Agents/README.md` | How agents hand work to each other here. |

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
cd ios && xcodegen generate     # after editing ios/project.yml
open ios/Morning.xcodeproj      # ⌘U runs the acceptance suite
```

`verify-ios.sh` never stops at the first failure — it runs every phase and writes
each one's errors to `ios/build/verify-report.txt`. Use it instead of chasing
`xcodebuild` output; hand the report to whoever is fixing things.

`ios/Morning.xcodeproj` is **generated and gitignored**. Never add a file through
the Xcode UI and expect it to stick — sources are declared by directory in
`ios/project.yml`, so adding a Swift file usually needs no edit there at all.
Just re-run `xcodegen generate`.

**Before you write any Swift, run the web app and do a full session of A and a
full session of B.** `ios-port/README.md` puts this in the first-session
checklist for a reason: you cannot design the replacement for something you have
not used.

## What is already scaffolded

| Path | What it is | Trust level |
|---|---|---|
| `ios/project.yml` | XcodeGen spec. App + unit test target. | Never run through XcodeGen. |
| `ios/Morning/Program.swift` | The program, transcribed to Swift literals per `03-program.md`. **This is now the source of truth**, not the JSON. | Machine-transcribed, never compiled. |
| `ios/Morning/Model/Schema.swift` | The v1 storage contract from `06-data.md §3`, terse keys and all. | Hand-written, never compiled. |
| `ios/Morning/Debug/Seeds.swift` | Debug seeder: `-seed six-months`. | Hand-written, never compiled. |
| `ios/Morning/Resources/Seeds/*.seed.json` | empty / one-session / one-week / six-months / one-year, in the exact web schema. | Generated and checked. |
| `ios/Morning/Resources/Content/` | `cards.json`, `guide.json` — verbatim. | Copied. |
| `ios/MorningTests/Acceptance/` | **53 assertions** from `07-acceptance.md`, one test each, all `XCTSkip`. | Generated. |
| `ios/MorningTests/Fixtures/` | `compiled-steps.json` golden fixture + `program.json`. | Copied. |
| `ios/Docs/device-checklist.md` | The 10 device checks that cannot be automated. | — |

**The Swift in this repo has never been through a compiler.** It was written from
the spec on Linux, behind an egress allowlist that refuses `swift.org` — and a
Linux `swiftc` would not have proved much anyway, with no SwiftUI and no iOS SDK.
Assume syntax slips. The first agent's first job is `./scripts/verify-ios.sh`,
then fixing everything in `ios/build/verify-report.txt` — and logging that it
did, in `ios/Agents/00-handoff-log.md`.

## What is deliberately absent

Not oversights. Do not "fix" these without asking:

- **No screens.** `ScaffoldView` is a placeholder. See rule 1.
- **No design system yet.** `ios/Docs/design-system.md` is an empty structure to
  fill *after* a direction is agreed. A palette is not a design system and it is
  not a direction either.
- **No widget, Live Activity or HealthKit target.** `05-platform.md §7`: propose,
  don't assume. Commented stubs are at the bottom of `ios/project.yml`.
- **No history import.** `06-data.md`: v1 ships starting at zero. The web app
  keeps the real history for now. What that costs you is that **empty and
  near-empty states are the normal case on day one, not an edge case.**
- **Swift 5 language mode**, not Swift 6. A deliberate call to keep strict
  concurrency out of the way while the app gets built. Revisit in one pass later.

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
- **`spec.md` is gitignored** ("it describes the person this was built for"), so
  the `ios-port/` docs reference a file you cannot read. Everything binding from
  it has been carried into `ios-port/`. If something seems to be missing, ask
  Eden rather than guessing.

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
