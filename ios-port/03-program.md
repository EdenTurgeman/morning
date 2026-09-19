# 03 — The training program

Machine-readable in `content/program.json`. Source of truth in the repo at
`src/program.ts`. **Port the numbers and strings verbatim.** They are the result
of a lot of deliberation and some of them are load-bearing in non-obvious ways.

---

## Hard requirement: one editable object, one file

From the original spec, and still binding:

> The user will change this program — new exercises, different weights, harder
> variants — every few months, and he will do it himself in a text editor. Keep
> the entire program as one plainly-structured data object at the top of one
> file, with exercise names, set counts, rest seconds, loads and cues as literal
> strings. No indirection, no ID lookups, no separate files.

In Swift this means a single `Program.swift` containing literal values, with the
same explanatory header comment the TypeScript version has. **Do not** put the
program in a JSON resource, a plist, Core Data, or a builder UI. The user edits
Swift literals, rebuilds, and installs. That is the intended workflow.

Everything else in the codebase must derive from that object — the step list,
the plate breakdown, the tonnage table, the loadout card.

---

## Structure

> **Session B was rebuilt on 2026-09-19 and the tables below were updated with
> it.** `ios/Morning/Program.swift` is the source of truth and `WORKOUT.md` is
> the explanation; this file covers the STRUCTURE — the block kinds, the plate
> convention, supersets, trailing rests — which is unchanged. If a session's
> content here and in `WORKOUT.md` ever disagree, that one is right and this is
> stale.

Two sessions, **A** ("Heavy") and **B** ("Width"), alternating. The app always
proposes the opposite of whatever was logged last. Each session is a list of
blocks, of three kinds:

```
warmup   { seconds, title, cues[] }
straight { exercise, sub?, sets, rest, load | bodyweight, target | targets[], cues[], intense? }
superset { sets, rest, items: [ { exercise, sub?, load|bodyweight, target, cues[] }, ... ] }
```

**Weights are PLATES PER HANDLE.** Not total, not including the handle. The user
adds handle weight mentally. Do not try to be clever about this.

## Session A — "Heavy", ~16 min, 7.5 kg per handle

| Block | Exercise | Sets | Load | Target | Rest |
|---|---|---|---|---|---|
| 1 | Warm-up | — | — | 90 s | — |
| 2 | Push-up (feet elevated) | 3 | bodyweight | 8–15 | 60 s |
| 3 | Overhead press (standing, strict) + Curl | 3 rounds | 7.5 kg | 8–15 / 10–18 | 45 s after each round |
| 4 | Bent-over row + Hammer curl | 2 rounds | 7.5 kg | 15–20 / 12–20 | 45 s after each round |

Compiles to **21 steps.**

## Session B — "Width", ~17 min, 5 kg per handle

| Block | Exercise | Sets | Load | Target | Rest |
|---|---|---|---|---|---|
| 1 | Warm-up | — | — | 90 s | — |
| 2 | Push-up (deficit — hands on books) + Lateral raise | 3 rounds | bodyweight / 5 kg | 8–15 / 6–12 | 60 s after each round |
| 3 | Lateral raise (myo-reps) | 3 | 5 kg | per-set targets | **20 s** |
| 4 | Floor fly (lying on your back) + Rear-delt fly | 2 rounds | 5 kg | 10–20 / 8–15 | 60 s after each round |

Compiles to **21 steps.**

### Why B is shaped like this — and what was wrong with the old shape

B is the side-delt and chest day; A carries the compounds. Two things were
wrong with the version this replaced, and both are worth not reintroducing.

**The rep targets were never grounded.** It asked for 15–25 on a lateral raise
the user does seven or eight of, so nothing in the session was ever hit and the
session stopped being done at all. Load does not decide hypertrophy once a set
goes to failure; the target has to match what the movement actually gives.

**The superset paired two shoulder movements.** A lateral raise straight into a
rear-delt fly gives the delt about 65 seconds between sets and it declines
within the session. Each priority movement is now paired with something that
does not compete with it: ~115 seconds between lateral raise sets, on *less*
total rest than before.

One claim in the old text was simply wrong and is recorded here because the app
repeated it to the user: ~20 sets a week is **not** the point where extra volume
stops paying. The dose-response curve flattens; it does not turn off.

### The myo-rep block

Per-set targets differ: set 1 is `all-out to failure`, sets 2 and 3 are
`4–6 reps`. The **20-second rest is the mechanism of the technique**, not a
convenience. The app must not let it be silently stretched: the timer starts
automatically, is visually prominent, and the screen says so. Skipping forward is
allowed; drifting is not. **No study card ever appears on this rest** — see
`04-rules.md`.

### Reordering a block rewrites what every slot in it MEANS

Slot IDs are `blockIndex.itemIndex.setIndex` and history is matched on that
string alone — it has no idea which exercise a slot belonged to. The floor fly
used to be appended for exactly this reason.

The 2026-09-19 restructure moved it anyway, and without a map it would have read
the myo block's numbers and told the user he was beating a set he had never
done. `History.bSlotMoves` translates old slots to new **at read time**; stored
records are never rewritten. That works only because the restructure moved
movements without removing any. Extend the map if you reorder again; if you
delete a movement, its history has nowhere to go.

---

## Supersets

A superset of two exercises for N rounds expands to:

```
round 1: partner-1 set 1 → partner-2 set 1 → rest
round 2: partner-1 set 2 → partner-2 set 2 → rest
...
```

**No rest between partners** — that is the entire point. Rest only after the
pair. The set screen indicates "superset 1 of 2" / "2 of 2" so the user knows not
to expect one, and the first partner's screen says "No rest after this — straight
into the next one."

## Trailing rest

A rest is emitted after every set including the last of a block (there is a gap
before the next exercise), then **any rest steps at the very end of the session
are dropped**. You do not rest after finishing.

## Cue emphasis

Cues containing the words **failure**, **PAUSE**, **FULL** or **mechanism**
carry the training effect and are emphasised visually. This is a regex in the
current build (`INTENSITY_WORDS`); keep the behaviour, and keep the word list
next to the program where it can be edited.

---

## Working weight

The `load` in the program is the weight the session is *written* for. The user's
actual working weight is a setting, adjustable from the home screen, which
overrides every loaded movement in the session.

- **One weight per session.** The premise is that load is fixed and reps are the
  only variable, and practically you do not change plates at 6am. This is
  enforced by a test — keep the test.
- The weight in force is **recorded on each session record** (`kg`), because reps
  are only comparable at the same weight and lifetime tonnage has to use what was
  really lifted. Sessions logged before the field existed simply have no `kg` and
  fall back to the program default.
- Adjustment step is the lightest plate the user owns.

### Plate inventory

Per handle: **2 × 2.5 kg** and **4 × 1.25 kg**. Total across both handles is
20 kg of plates, which is everything he owns.

The loadout breakdown ("2×2.5 + 2×1.25") must be **derived from this inventory,
not hard-coded**. An unbounded greedy fit returns "3×2.5" for 7.5 kg, which is
impossible with only two 2.5s per handle; the correct answer is 2×2.5 + 2×1.25.
Bounded by inventory, the derived strings match the original hand-written ones
exactly. See `src/lib/plates.ts`.

---

## Slot IDs

`blockIndex.itemIndex.setIndex`, stable across app updates, because they are how
"what did I do last time on this exact set" resolves. If the program is edited,
old slots stop matching and the rep counter falls back to a default — acceptable,
and worth a note in the code. History totals are never lost; only the per-set
prefill resets.

Note that the ledger keys slots as `"{sessionKey}:{slot}"` when mapping load per
rep, while a session record's `log` is keyed by the bare slot. Preserve both
shapes or the imported history will mis-value.

---

## Weekly target

Five sessions per week counts as a full week. **The week starts on Sunday.** Both
values live next to the program.
