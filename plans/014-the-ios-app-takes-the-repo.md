# 014 — The iOS app takes the repo

Opened 2026-09-11. **A plan, not a deletion.** Eden: *"I think the new version
of the app is now ready to take over the repo, we can remove the old version and
make this the cannonical one."*

## The gate this is blocked on, and it is not technical

**The iOS app has never run on Eden's phone.** Checked today: `DEVELOPMENT_TEAM`
is unset in `project.pbxproj`, no device is paired to this Mac, and the
conversation that established this was the previous one.

Meanwhile the web app is what he opens at 6:10am, it is deployed and live from
`main` via `.github/workflows/deploy.yml`, and his training history exists in
exactly two places: that deployment's local storage, and
`morning-backup-2026-09-05.json` on his Desktop.

So deleting it now removes **his only working tool** and **the canonical
definition of his data format**, before the replacement has ever launched on the
device it was built for. Everything below is safe once he has trained on the
iOS app for a week with his history imported. None of it is safe before.

## What actually breaks — the non-obvious one

`scripts/verify-export.ts:16`

```ts
import { parseData } from "@/lib/storage";
```

`verify-ios.sh`'s **`export format`** phase imports the web app's own parser and
runs the iOS app's exported JSON through it. That is not a lint — it is the
proof that a file the iOS app writes can still be read by the thing that holds
his six months of history. `scripts/alias-hook.mjs` exists solely to let plain
`node` resolve `@/...` into `src/`.

Delete `src/` and that phase dies with it.

**It can be retired, but only after the data has moved.** Until then it is the
last automated statement that his history survives the port.

## What does NOT break

- `ios/Tools/gen-seeds.mjs` — node, but self-contained. The `generators` phase
  survives untouched.
- `ios-port/` — the brief. Referenced by comments and copied verbatim into
  `GoldenSteps.swift`; no runtime dependency.
- Everything under `ios/`. The Swift build, the 119 acceptance assertions, the
  shoot and frame tooling: all independent of `src/`.

## The order

**0. Commit.** 61 files are uncommitted on `ios-port/redesign-plan` — the
scheduler, the study surface, the transition work, the Set screen, the year
grid. Git is the safety net for every step below and right now it is not
holding this session at all. Nothing else in this plan should happen first.

**1. Get it on the phone.** Set the team on both targets, install, import the
backup, and train on it. `plans/README.md` and `device-checklist.md` have 21
checks that have never been run on hardware; several of them — 120Hz, the
crossing haptic through the floor, music ducking — can only fail there.

**2. Merge to `main`.** The branch is 2 ahead, `main` is 0 ahead. A clean
fast-forward.

**3. Retire the web app.** In this order, so each step leaves the repo working:

   a. Decide the fate of the byte-compat check — **vendor** `parseData` into
      `ios/Tools/` as a frozen copy of the format, or **delete** the phase and
      record in `06-data.md` that the format is now whatever `Schema.swift`
      says. Vendoring is the safer of the two and costs one file.
   b. Delete `src/`, `index.html`, `vite.config.ts`, `tsconfig*.json`,
      `components.json`, `public/`, `prototype/`.
   c. Trim `package.json` to the scripts that still have a subject — `test:deck`
      and the verification helpers — and drop `dev`, `build`, `preview`,
      `deploy`.
   d. Delete `.github/workflows/deploy.yml`. Retarget `ios.yml`'s path filter,
      which currently only fires on `ios/**` and `ios-port/**`.
   e. **Take the PWA off GitHub Pages.** Outward-facing and Eden's call alone;
      the deployment outlives the source.

**4. Rewrite the documents that describe a two-app repo.** `CLAUDE.md` opens
with *"Two things:"* and calls the web app *"the behaviour specification for the
port"*. `README.md`, `spec.md` §, and `PRODUCT.md` all assume it exists. These
are the files every new session reads first, and a stale one has already cost
this project real time — see the R29 entry on a design system that described a
deleted world.

**5. Keep `ios-port/`.** It is the brief the whole port was built against and
half the code comments cite it by section. Renaming it to `docs/` would break
those citations for no gain.

## What this plan will not do

- Delete anything before step 1 is done and reported.
- Un-deploy the live site without Eden saying so explicitly.
- Rewrite history or force-push.
