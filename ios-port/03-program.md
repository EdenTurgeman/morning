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

Two sessions, **A** ("Heavy") and **B** ("Light"), alternating. The app always
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

## Session B — "Light", ~19 min, 5 kg per handle

| Block | Exercise | Sets | Load | Target | Rest |
|---|---|---|---|---|---|
| 1 | Warm-up | — | — | 90 s | — |
| 2 | Push-up (deficit — hands on books) | 3 | bodyweight | 8–15 | 60 s |
| 3 | Lateral raise + Rear-delt fly | 3 rounds | 5 kg | 15–25 each | 45 s after each round |
| 4 | Lateral raise (myo-reps) | 3 | 5 kg | per-set targets | **20 s** |
| 5 | Floor fly (lying on your back) | 2 | 5 kg | 15–25 | 60 s |

Compiles to **25 steps.**

### Why B looks lopsided — do not "fix" it

With 5 kg in each hand there is almost nothing you can train hard except small
muscles, so B is a delt-and-chest isolation day while A carries the compounds.
An earlier version was 57% lateral raises, which pushed side delts past ~20 sets
a week — the point where extra volume stops paying — while the pecs had one
movement and no isolation at all. The myo block came down from 5 sets to 3 and
the floor fly took the difference. This is explained to the user in the Guide.

### The myo-rep block

Per-set targets differ: set 1 is `all-out to failure`, sets 2 and 3 are
`4–5 reps`. The **20-second rest is the mechanism of the technique**, not a
convenience. The app must not let it be silently stretched: the timer starts
automatically, is visually prominent, and the screen says so. Skipping forward is
allowed; drifting is not. **No study card ever appears on this rest** — see
`04-rules.md`.

### The floor fly was appended, not inserted

Deliberately. Slot IDs are `blockIndex.itemIndex.setIndex`; inserting it earlier
would have shifted every later block's IDs and handed this exercise the myo
block's rep history as its starting target. Preserve this ordering property in
any future edit, and say so in the file's header comment.

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
