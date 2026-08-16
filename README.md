# Morning

A single-user, offline-first PWA that runs one specific 20-minute morning
workout, step by step, and remembers what happened.

Built to a product spec that is kept out of this repo (`spec.md`, gitignored).
The original single-file prototype it replaces is in
[`prototype/`](prototype/) for reference.

**One screen, one action.** The common case — "I did the reps it suggested" —
is a single tap. Last session's number for that exact set sits under the rep
counter, because with a fixed load, reps are the only progress signal there is.

## The streak is weekly, not daily

The program is five to six mornings a week with rest days, so a
consecutive-day streak would punish you for following it properly. Instead a
**week counts when it contains `WEEKLY_TARGET` sessions, on whichever days
they land**. Miss Tuesday, train Saturday — nothing is lost.

The week in progress can never break a streak. It hasn't finished yet, so it
only ever adds: complete it and the count extends, leave it and the streak
simply reads from last week backwards.

Both settings live in [`src/program.ts`](src/program.ts):

```ts
export const WEEKLY_TARGET = 5;
export const WEEK_STARTS_ON = 0; // 0 = Sunday, 1 = Monday
```

`npm run test:week` pins the rules — gaps counting the same as consecutive
days, an unfinished week never resetting the count, over-target weeks still
counting once.

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
| `npm test` | Both verification suites |
| `npm run test:program` | Verify the program compiles to valid steps |
| `npm run test:week` | Verify the weekly-streak rules |
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
through the session you are — walks an actual dawn:

```
t = 0.00   #6f80e0   astronomical twilight, deep indigo
t = 0.26   #a974e3   nautical, violet lifting off the horizon
t = 0.50   #ed6baf   civil, the rose band at peak chroma
t = 0.74   #ff8271   first light, coral
t = 1.00   #ffb440   sunrise, gold
```

Every tinted surface — timer ring, progress bar, primary button, cue markers,
the sky itself — reads the same variables, so progress is legible from across
the room without reading the step counter, and the whole app has one colour
system driven by one number.

Two things make it work:

**It's OKLCH, not HSL.** HSL's "lightness" isn't perceived lightness — at a
fixed L, yellow reads far brighter than indigo, so an HSL ramp visibly surges
and dips on the way round the wheel and goes muddy through the magentas. In
OKLCH a straight line looks like a straight line: the largest perceived
brightness step across the whole ramp is 0.079, and accent-on-background
contrast never drops below 5.5:1.

**The stops are hand-picked, not generated.** A formula gave an even ramp; it
did not give a sunrise. Lightness climbs monotonically because dawn gets
brighter, and chroma peaks in the middle where the sky is genuinely most
saturated.

The channels are registered with `@property`, which is what lets the browser
*interpolate* them — advancing a step drifts the app's colour over ~1.1s
rather than snapping. The sky is layered like a real dawn (vertical gradient,
stars that fade as the sun climbs, the belt of Venus, the sun, drifting cloud)
using only gradients and transforms — no `filter: blur()` on any large layer,
because this screen is held awake for twenty minutes on a phone.

### The Ledger

Lifetime tonnage is the headline number, because this program fixes the load
and treats reps as the only signal — so `reps × load` is the one figure that
turns that signal into something visibly compounding.

Two honesty constraints on it, both deliberate:

- Loaded movements here are two dumbbells and the program's `load` is per
  handle, so a rep moves `2 × load`.
- Bodyweight work contributes **0 kg** rather than a guessed multiplier.
  Counting it would need your bodyweight and an invented coefficient, which
  would make the headline number fiction. Those reps still count toward the
  rep total.

Milestones (tonnage, reps, sessions) are sparse on purpose — one you hit every
fortnight is a chore. Each fires exactly once, detected by diffing the ledger
with and without the session just logged.

### The Year

Fifty-two weeks of days, each painted from the sunrise ramp. Intensity is
scaled to **your own** rep range rather than an arbitrary target, so your
quietest session is pre-dawn indigo and your best is full gold — and a good
month literally looks warmer than a bad one.

### Exercise figures

Original inline SVG in [`src/components/Figure.tsx`](src/components/Figure.tsx),
drawn rather than sourced: the no-runtime-network rule forbids fetching, and
stock fitness art is someone else's copyright. Drawing them also buys
something a photo can't — limbs are `<g>` elements rotated about their joint,
and each keyframe is timed to the cue it illustrates. The push-up spends 3s
lowering, holds 1s at the bottom, then snaps up, so the tempo is *shown*
rather than described.

The name → figure mapping is split into
[`src/lib/figures.ts`](src/lib/figures.ts) so CI can assert every exercise
resolves to artwork, and that "Hammer curl" doesn't fall through to the
generic "curl" rule. An unmapped exercise degrades to no artwork rather than
breaking the set screen.

### Celebrations

The summary screen picks **one** tier, the highest you actually earned — see
[`src/lib/celebration.ts`](src/lib/celebration.ts). Confetti and sun rays are
held back for completing a week and hitting a streak milestone, so they keep
meaning something the twentieth time you see the screen.

Every headline states something true and specific. No points, no badges, no
levels, no "great job!" — the reward for finishing is being told exactly what
you did.

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
