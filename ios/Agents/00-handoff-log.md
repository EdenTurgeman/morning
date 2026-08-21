# Handoff log

Append-only, newest at the top. One agent works this clone at a time; this file
is the only thing standing between the next agent and re-deciding what you
already decided.

The **Landmines** field is worth more than the summary of what you built.

---

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
- **Swift 5 language mode, not Swift 6.** Strict concurrency is a wall to walk
  into on day one of a UI-heavy port. Revisit as one deliberate migration later.
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

1. **None of the Swift has ever been compiled.** No Swift toolchain was available
   where this was written — `download.swift.org` is blocked from that
   environment. `Program.swift`, `Schema.swift`, `Seeds.swift`,
   `MorningApp.swift`, `GoldenSteps.swift` and the seven test suites are all
   unverified. Expect syntax slips. This is why **W0 exists and comes first.**
2. **The screensdesign MCP is not connected**, and it is not in the public
   connector registry either. `02-design-brief.md §4` requires it for the
   research pass. **W1 cannot be done as specified until Eden connects it** —
   that is a blocker to raise, not a step to improvise around.
3. **The app icon is a 2× upscale** of `public/icon-512.png` to 1024. It will
   look soft. Fine for the simulator, replace before installing on the phone.
4. **`DEVELOPMENT_TEAM` is empty** in `ios/Local.xcconfig` (gitignored, created
   by bootstrap). Simulator builds work; installing on the phone needs the team
   id filling in.
5. **CI pins `macos-15` and an `iPhone 16 Pro` simulator by name.** If GitHub's
   runner image stops shipping that device the workflow fails on the destination,
   not on the code.
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

**Next:** W0 — `./scripts/bootstrap.sh`, then make it compile.

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
