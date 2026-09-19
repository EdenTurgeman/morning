# Morning

A native iOS app that runs one 20-minute morning workout, step by step, and
records what was actually done.

**One user, and there will never be a second.** It is built for a specific
person, a specific pair of dumbbells, and 6:10am — half awake, standing, phone
on the floor, sweaty hands, fully offline. Every design decision follows from
that and none of it generalises.

**The load is deliberately fixed for a whole session, so reps are the only
progress signal that exists.** Logging reps is not bookkeeping, it is the core
loop. Last session's number for this exact set is visible at the moment of doing
that set, and the moment the counter passes it is the point of the whole thing.

---

## Where to start

| If you want to | Read |
|---|---|
| Change the workout | **[`WORKOUT.md`](WORKOUT.md)** — the sessions, the rules, and what breaks |
| Work on the app | **[`CLAUDE.md`](CLAUDE.md)** — read first, every session |
| Know what it must do | [`spec.md`](spec.md) — behaviour only, no UI |
| Know why it exists | [`PRODUCT.md`](PRODUCT.md) |
| Touch anything that moves | [`ios/Docs/motion-performance.md`](ios/Docs/motion-performance.md) |
| Pick up where the last session stopped | [`ios/Agents/00-handoff-log.md`](ios/Agents/00-handoff-log.md) |

---

## Running it

```bash
./scripts/bootstrap.sh
```

Idempotent, run it first on any machine. Then:

```bash
./scripts/verify-ios.sh
```

Build, test, lint, format-check and the doc checks — **eight phases, and it
never stops at the first failure.** Every phase's errors land in
`ios/build/verify-report.txt`.

Look at a screen without playing a workout through a simulator that cannot
receive taps:

```bash
./scripts/shoot.sh set -session B -slot 1.1.0
```

Put it on the phone:

```bash
./scripts/refresh-device.sh
```

Signed with a free Apple ID, the provisioning profile lasts **seven days** —
on day eight the app refuses to open until it is re-signed, which is a rebuild.
That script is that rebuild, and `scripts/refresh-device.plist` runs it on a
timer. A newly issued certificate has to be trusted once on the device itself:
Settings → General → VPN & Device Management.

---

## The shape of the repo

| Path | What it is |
|---|---|
| `ios/Morning/` | **The app.** SwiftUI, iOS 26, Swift 6, iPhone 16 Pro, portrait only |
| `ios/Morning/Program.swift` | **The workout.** Swift literals, hand-edited, the source of truth |
| `ios/MorningTests/Acceptance/` | The acceptance suite. None skipped |
| `ios/MorningWidgets/` | The Live Activity |
| `ios/Docs/` | Design system, motion performance, technical decisions, device checklist |
| `ios/Agents/` | The handoff log and the workstreams |
| `ios-port/` | The eight-document brief the port was built from. Historical, still binding on intent |
| `plans/` | Numbered plans, opened and closed |
| `scripts/` | Verification, screenshots, device install |
| `src/`, `prototype/`, `public/` | **The retired web build.** See [`WEB-BUILD.md`](WEB-BUILD.md) |

### The web build is not gone yet, on purpose

`src/` is the PWA this replaced. It is still deployed, and
`scripts/verify-export.ts` still imports its parser to prove that the JSON the
iOS app writes can be read by the thing that held the history. Retiring it is
sequenced in [`plans/014`](plans/014-the-ios-app-takes-the-repo.md) and taking
the deployment down is a decision, not a chore.

---

## Things that will catch you

Every one of these has already cost somebody something. The full list is in
`CLAUDE.md`; these are the two that bite hardest.

**Slot ids are `block.item.set` and they are load-bearing.** Rep history is
matched by that string and nothing else — it has no idea which exercise a slot
belonged to. Reorder a block and every slot in it silently changes meaning.
`WORKOUT.md` has the whole story.

**Animating a width or a height in this codebase is a bug.** It has been found
five separate times. Use a transform. `ios/Docs/motion-performance.md` explains
why, with measurements.
