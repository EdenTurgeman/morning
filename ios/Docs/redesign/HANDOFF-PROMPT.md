You are redesigning the UI of **Morning**, a native SwiftUI iPhone app, from the
world up. Work in `/Users/eden.turgeman/Dev/morning`. Start a fresh session.

**Read `CLAUDE.md` first — it sets the read order — then `spec.md`, then
`ios/Docs/redesign/04-direction-reset.md`. That last one is newest and it
overrides the other two wherever they disagree.**

---

## First, run this

```
/impeccable init
```

Impeccable v3.6.0 is installed at `.claude/skills/impeccable` (project-level).
It will interview you for product truth and write `PRODUCT.md`. Then continue
into `reference/new-work.md` — this is a **replacement visual world**, not a
refinement, so new-work is the playbook that owns it.

Two things about the tooling before you start:

- **This is a native iOS project.** Load the native variants:
  `reference/ios.md`, `adapt.native.md`, `audit.native.md`.
- **Four of Impeccable's iOS defaults collide with this app's binding brief**
  (Dynamic Type, semantic system colours, system materials, tab bar). They are
  tabulated in `04-direction-reset.md` §4. `spec.md` wins on all four. Do not let
  the skill correct them into generic iOS.

---

## The product, in one paragraph

One user. A 30-year-old man, 60 kg, training at home on the floor with adjustable
dumbbells — 20 kg of plates total, nothing else. Six mornings a week, upper body,
in a hard 20-minute cap before showering. He is also a sommelier, which is why
there is a wine and tea study deck in a fitness app. **There will never be a
second user**: no onboarding, no marketing, no settings screen.

Used at 6:10am, half awake, standing, phone on the floor or a shelf a metre or
two away, sometimes upside down over a push-up, with sweaty hands, one-handed,
sometimes with a knuckle. Fully offline.

**The one fact that shapes everything:** the dumbbells are light and the weight
is deliberately fixed for a whole session. So **reps are the only progress signal
that exists**. Last session's number for *this exact set* must be visible while
you do that set, and the moment the counter passes it is the emotional centre of
the product.

---

## Why you are being called, and what went wrong last time

The previous agent ran a nine-phase redesign plan (`ios/Docs/redesign-plan.md`)
through R0–R3 and produced three Set-screen directions. **Eden rejected all
three.** His words:

> *"None of the designs in the prototypes fit me, I like the font choices, but
> some of them are pretty empty and leave a lot of empty space. All just being
> similar to the previous app and its background."*

The diagnosis, so you do not repeat it: all three variants sat on the **same
background**, the same rep control, the same button, the same near-black indigo
sky. They diverged on *arrangement* and held *material, density and identity*
constant. Three tints read as one direction. The empty space was the same fault
seen from the other side — content pushed around a fixed world instead of the
world being questioned.

**Diverge on world, not on layout.** If your directions share a background, you
have made the same mistake.

---

## What Eden decided on 2026-08-27

Full detail and blast radius in `04-direction-reset.md` §2. Summary:

### Everything visual is up for replacement — including the sky

That explicitly includes the dawn/sunrise idea and the Metal shader behind it.
The current app's entire colour is a function of session progress: it starts at
astronomical twilight and walks the real phases of a dawn as you work, arriving
at gold as you finish, so you can read your progress from across the room without
reading anything. The session ends at sunrise, and the completion moment is that
sun clearing the horizon.

**You may replace it. You may not replace it with nothing.** A replacement must
be an equally load-bearing idea: it makes progress legible without text, it
belongs to this specific app, and it gives the finish somewhere to arrive.
A palette is not an idea.

### Mid-tone, not dark

Not dark, not light. Overcast morning, paper, soft sage, sand. It should read as
**calm**, not as night. This overrides "Dark by default" in `spec.md` §2.

Cost he accepted: every contrast figure re-measures from scratch. What survives
is the **discipline**, not the numbers — measure on rendered frames with
`ios/Tools/measure-contrast.py`, never calculated, never judged by eye. Both of
those have already lied on this project, and R2 found a live 6.18:1 failure this
way three days ago.

### The no-gamification rule is dropped

This was the most emphatic value in the project, stated in four documents:
*"No points, no badges, no levels, no XP, no mascot, no 'Great job!'."* **Eden
dropped it deliberately, having read a written objection, and it is not to be
re-litigated.**

**But "drop the rule" spans a huge range** — from a warmer, kinder voice to
points, badges, levels and a mascot. Nothing says which. **Settle it in `init`.**
Do not assume either end.

Related: the copy pass is marked DONE and content is "fixed and verbatim". §2.2
reopens *celebration and encouragement copy only*. It does **not** reopen
exercise names, cues, targets, rest seconds or Guide text.

### The analytical screens get demoted

The Set screen keeps its numbers and their full weight — the counter, last time's
number, the crossing. **History, Lifetime totals and the year grid stop leading
with figures** and lead with something qualitative: shape, colour,
streak-as-texture. Three surfaces' hierarchy; no behaviour changes.

### What he liked, and said unprompted

- **The font choices.** Keep SF, keep weight-led hierarchy, keep the tracking
  work in `DesignTokens.swift` (`counterTracking -1.5`, `titleTracking -0.4`,
  `microTracking 0.6`).
- **"Chill vibes."** The register moves from *precise instrument* toward *calm*.
- **"Encouragement"** and **"learning."** He named the study deck — 26 cards on
  wine and tea, currently a rest-filler dosed twice a session — as something he
  values. Whether it deserves more of the app's identity is worth proposing.
  Do not assume it; it adds scope.

---

## The eleven surfaces

`spec.md` §3 is the authority on what each owes the user. Three are inside a
workout (**Warm-up, Set, Rest**) and may never scroll. The rest are read outside
a session and may.

Home · Warm-up · **Set (the most important, ~70% of on-screen time)** · Rest ·
The completion moment · Summary · History · Lifetime totals · Guide · Backup ·
The Live Activity.

---

## What is binding and was never up for discussion

Behaviour and physics, not taste. Full list in `04-direction-reset.md` §3. The
ones a *design* phase breaks:

1. **Nothing inside a workout scrolls. Ever.** Not with the longest exercise name
   and its cues. If it does not fit, the design is wrong, not the screen.
2. **Rep controls ≥ 78pt, primary actions ≥ 64pt, main action full-width.**
   Sweaty hands at 6:10am. Not a guideline.
3. **The rep controls do not move between exercises.** Same place every time.
4. **Nothing important in the top 15% during a set.** The phone is on the floor.
5. **Exercise name and rep count readable at ~1.5m.**
6. **Every surface holds at empty, one week, and six months.** The app ships with
   no history, so **empty is the normal case on day one**, not an edge case.
7. **Reduce Motion produces a calmer form**, never a static or broken one.
8. **Reps are never compared across a weight change** — say so instead.
9. **A session in progress survives force-quit**, rest deadline intact.
10. **`spec.md` moves in the same commit as any behaviour change.**

---

## The tooling you have

```bash
./scripts/shoot.sh all                    # every surface → ios/build/shots/*.png
./scripts/shoot.sh set -session B -step 16    # the worst content in the program
./scripts/verify-ios.sh                   # build + 68 tests + lint + format
python3 ios/Tools/measure-contrast.py <frame.png> <set|rest|home|card>
```

`shoot.sh` builds, boots, installs, launches with arguments and screenshots. Its
header documents three decisions worth knowing — script flags are `--long` and
the app's are `-short`; every launch names a seed because `-seed` *writes* to the
store; the 4s delay is measured slack, not superstition.

**Two hard environment facts:**

- **No tap reaches the simulator from an agent.** Verified through both `simctl`
  and the iOS Simulator MCP — `control{action:"tap"}` returns success and
  delivers nothing. Every interactive state is reached by launch flag. **Eden's
  own taps in his panel do work**, so the final feel check is his.
- **No frame-rate claim can be made from this machine.** The simulator does not
  run at 120Hz and its timing is not representative.

**And the trap that has cost this project twice:** an implicit animation that
silently does nothing. A `withAnimation` inside `onAppear` and a
`.transaction { $0.animation = nil }` placed outside an `.animation(_:value:)`
both compiled, both read correctly, and both did nothing on screen. Neither was
caught by inspection; both were caught by filming the simulator and stepping
frames. **Verify motion in a captured frame, never by reasoning.**
`ios/Tools/frames.swift` exists for this.

---

## What is already done and worth keeping

- `ios/Docs/redesign/00-brief.md` — screen inventory, six composition findings.
- `ios/Docs/redesign/01-motion-doctrine.md` — a per-surface ruling on what
  animates. **Its core conclusion survives a world change:** the twenty minutes
  the app is in use is the tier where motion should be *removed*, and nearly the
  whole budget belongs to the four seconds at the end that happen once. Two
  sharpenings worth carrying: **tier the event, not the surface** (the Set screen
  is high-frequency but the crossing on it is rare), and **press feedback is
  exempt from the frequency gate** — at 6:10am it is often the only proof a
  knuckle tap landed.
- `ios/Docs/redesign/02-foundation.md` — R2's token work. The contrast *numbers*
  do not survive a mid-tone world; the *method* does.
- `ios/Morning/PrototypeSetVariants.swift` — the three rejected directions, still
  runnable via `-screen set -variant dawn|far-field|track`. Kept as the record of
  what was considered and rejected. **Anti-reference, not reference.**

## Two things `spec.md` requires that no shipped screen has ever drawn

Both were left for this rebuild deliberately. Neither is a design choice.

- **`Celebration.rays` has no reader**, so a plateau looks identical to a
  personal best. `spec.md` §9 says the bottom five tiers must be visibly quieter
  than the top four, and that distinction is the entire reason the tiers exist.
- **`SetStep.intense` has no reader.** An all-out set must be distinguishable
  *before* you start it. The web build shows a MYO badge; the rejected R3
  variants all rendered it, so there is working reference in
  `PrototypeSetVariants.swift`.

---

## How to finish

Write your handoff entry in `ios/Agents/00-handoff-log.md`. One agent works this
clone at a time, and that file is the only thing standing between the next agent
and re-deciding what you already decided.

**The gate that matters: Eden picks the direction.** Build two or three *running*
directions of the Set screen — real code, real content, on the simulator, not
static mockups — present them honestly with what each costs, and stop. Getting
agreement on the look is the first deliverable, not the last.
