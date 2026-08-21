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
