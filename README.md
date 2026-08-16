# Morning

A single-user, offline-first PWA that runs one specific 20-minute morning
workout, step by step, and remembers what happened.

Built to a product spec that is kept out of this repo (`spec.md`, gitignored).
The original single-file prototype it replaces is in
[`prototype/`](prototype/) for reference.

**One screen, one action.** The common case — "I did the reps it suggested" —
is a single tap. Last session's number for that exact set sits under the rep
counter, because with a fixed load, reps are the only progress signal there is.

---

## Changing the workout

Everything is in **[`src/program.ts`](src/program.ts)** — one object, literal
strings, no indirection. Edit it, then:

```bash
npm run build
```

Push to `main` and it deploys itself.

Blocks run top to bottom and come in three kinds — `warmup`, `straight` and
`superset`. The file documents each one at the top. Run `npm run test:program`
after editing: it checks the structural rules the spec cares about (no rest
between superset partners, a rest after every round, nothing dangling at the
end, unique slot ids). CI runs it too and blocks the deploy on failure.

### The one caveat

"What did I do last time on this exact set" is resolved by a slot id of the
form `blockIndex.itemIndex.setIndex`. Reordering blocks or changing set counts
makes old slots stop matching, and the rep counter falls back to a default.
**Session totals and history are never lost** — only the per-set prefill
resets. Editing names, cues, loads and targets is always safe.

---

## Running it

```bash
npm install
npm run dev
```

| Command | Does |
|---|---|
| `npm run dev` | Dev server |
| `npm run build` | Typecheck + production build to `dist/` |
| `npm run preview` | Serve the built output |
| `npm run test:program` | Verify the program compiles to valid steps |
| `npm run check` | Typecheck only |

---

## Deploying

Pushing to `main` runs [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml),
which typechecks, verifies the program, builds and publishes to GitHub Pages.

The site is served from `/morning/`, set by `BASE` in
[`vite.config.ts`](vite.config.ts). **If you rename the repo, change that one
line.** On a custom domain or a `<user>.github.io` repo it becomes `"/"`.

### Installing on the iPhone

Open the Pages URL in Safari → Share → **Add to Home Screen**. It must be
launched from the home-screen icon, not a Safari tab, for two reasons:

- Home-screen web apps are exempt from Safari's 7-day clearing of
  script-writable storage, so history survives indefinitely.
- `display: standalone` only applies from the icon.

After that it works with no signal at all.

---

## Architecture

```
src/
  program.ts        ← the workout. the only file you need to edit
  lib/
    steps.ts        compiles a session into a flat list of steps
    storage.ts      localStorage, validation, derived queries
    sunrise.ts      the accent-colour ramp
    audio.ts        oscillator beeps + the iOS gesture unlock
    wakelock.ts     screen wake lock, re-acquired on visibilitychange
  hooks/
    useWorkout.ts   the step machine, persisted on every change
    useCountdown.ts wall-clock countdown
    useAppData.ts   the history, and the only writer of it
  components/       Button, Card, Ring, RepDial, Sky, Cues, …
    ui/             off-the-shelf Magic UI components
  screens/          Home, Workout, Summary, History, Guide, Backup
```

### Design — "Sunrise"

The app is called Morning, so the backdrop *is* one. A single number — how far
through the session you are — drives the accent hue along a linear ramp:

```
t = 0.0  →  252°  indigo    pre-dawn
t = 0.5  →  322°  magenta   first light
t = 1.0  →   32°  amber     sunrise
```

The sun rises from below the horizon as you progress, and every tinted surface
(timer ring, progress bar, primary button, cue markers) reads the same three
CSS variables. So progress is legible from across the room without reading the
step counter, and the whole app has one colour system driven by one variable.

The three accent channels are registered with `@property`, which is what lets
the browser *interpolate* them — advancing a step drifts the app's colour over
~900ms rather than snapping.

### Two deliberate deviations from the obvious approach

**Step transitions and the rep digit use CSS keyframes, not Motion.** An
`AnimatePresence mode="wait"` pair gates mounting the next step on the previous
one finishing its exit animation. If a frame stalls, you tap Done and nothing
happens — or worse, on the rep counter, the number you're reading isn't the
number you're about to log. CSS animations run on the compositor and can't
block. Motion is still used where it earns its keep: button press springs, the
progress bar, staggered entrances.

**The countdown has a `setInterval` floor under its `requestAnimationFrame`
loop.** rAF stops dead in a backgrounded tab and gets throttled in low-power
mode. The interval guarantees a rest still ends. Both read an absolute
`endsAt` timestamp rather than counting ticks, so backgrounding the app cannot
silently stretch a rest — which matters most for the 20-second myo-rep rest,
where the duration *is* the training stimulus.

---

## Known deviations from the spec

**The spec's acceptance checklist says Session B expands to 21 steps. It's
25.** Session B has 14 sets to A's 13, and the myo-rep block contributes 5 sets
plus 4 interleaved rests: 1 warm-up + 14 sets + 10 rests = 25. The checklist
line predates the myo block being added to the program section.
`src/program.ts` is the source of truth; the real number is pinned in
`scripts/verify-program.ts`.

**The spec asks for no build step**, which a React app can't honour. Every
non-negotiable still holds — it works fully offline with no runtime network
dependency, the program is one editable object in one file, and nothing is lost
on refresh. The cost is that editing the program means `npm run build` rather
than saving an HTML file.
