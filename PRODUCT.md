# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

**One user, and there will never be a second.** Eden — 30, 60 kg, training at
home on the floor with adjustable dumbbells, 20 kg of plates in total and
nothing else. Six mornings a week, upper body, inside a hard 20-minute cap
before showering. He is also a sommelier, which is why a fitness app contains a
wine and tea study deck.

No onboarding, no marketing, no empty-state salesmanship, no settings screen, no
explaining the app to a newcomer. Any design that spends space on a second user
has spent it wrong.

**The scene of use, which is a design constraint and not colour:** 6:10am, half
awake, standing, phone on the floor or a shelf a metre or two away, sometimes
viewed upside down over a push-up. Sweaty hands, one-handed, sometimes a
knuckle. In a hurry — friction costs minutes out of twenty. Fully offline;
airplane mode is indistinguishable from normal.

## Product Purpose

Run one 20-minute morning workout, step by step, and record what was actually
done — so that accumulated work becomes visible and real.

Success is that he wants to open it: not because it nags him, but because it is
one of the nicest-feeling things on his phone and it tells him true things about
himself that nothing else does.

## Positioning

**The load is deliberately fixed for a whole session, so reps are the only
progress signal that exists.** That single fact is the mechanism no neighbouring
fitness app is built around, and everything follows from it:

- Logging reps is not bookkeeping, it is the core loop.
- Last session's number **for this exact set** must be visible at the moment of
  doing that set — not in a history tab.
- The moment the counter passes last time's number is the emotional centre of
  the whole product.
- Three identical sessions in a row is the most valuable output the app has: it
  means the program needs to change.
- Losing the history destroys all of it, so backup is first-class.

## Operating Context

- **Eleven surfaces.** Home · Warm-up · **Set (~70% of on-screen time)** · Rest ·
  the completion moment · Summary · History · Lifetime totals · Guide · Backup ·
  the Live Activity. `spec.md` §3 is the authority on what each owes the user.
- **Three are inside a workout** — Warm-up, Set, Rest — and are bound by
  one-screen-one-action. The other surfaces are read outside a session.
- **Two sessions, A ("Heavy", ~16 min) and B ("Light", ~19 min), alternating.**
  The next one is auto-derived as the opposite of the last logged.
- **The program is one editable Swift object in one file** (`Program.swift`),
  edited by hand every few months and rebuilt. No builder UI, no indirection.
- **The study deck** is 26 cards on wine and tea, dosed twice a session during
  qualifying rests. **Confirmed 2026-08-27: it stays exactly that** — a rest
  filler, not an identity. No surface of its own, no tracked progress, no
  studying outside a workout.
- **The app ships with no history import.** Empty is the normal case on day one,
  not an edge case, on every surface.

## Capabilities and Constraints

`spec.md` is the functional specification and moves in the same commit as any
behaviour change. `ios/Docs/redesign/04-direction-reset.md` §3 lists what is
binding. The constraints that a *design* phase breaks, restated:

| Constraint | Requirement |
|---|---|
| Half awake | One screen shows exactly one thing to do. Never a scrollable list of the workout. |
| Nothing scrolls in a workout | **Ever.** Not with the longest exercise name and four cues. If it does not fit, the design is wrong, not the screen. |
| Sweaty hands | Rep controls ≥ 78pt, primary actions ≥ 64pt, the main action full-width. |
| Muscle memory | The rep controls do not move between exercises. Same place every time. |
| Phone on the floor | Nothing important in the top 15% of the screen during a set. |
| Glanceable | Exercise name and rep count readable from ~1.5 m. |
| In a hurry | The common case — "I did what it suggested" — is one tap. |
| Offline | Zero runtime network dependency. Local storage only; no account, no sync, no server. |
| Device | **iPhone 16 Pro, 402×874, portrait only.** An SE regression is not a defect. |
| Dynamic Type | The three workout surfaces **deliberately clamp** and use fixed sizes — they are already at the top of the scale and must never scroll. Every other surface supports the full range. |
| Data honesty | Reps are never compared across a weight change — say so instead. `kg` is never backfilled; `ts` is never regenerated; one history record per finished session. |
| Durability | A session in progress survives force-quit and reboot, rest deadline intact. Ending a session saves nothing, after a confirmation that says so. |

**Approved integrations are the Live Activity and nothing else.** Explicitly
declined: home-screen widget, HealthKit, Control Center control, app-icon badge,
notifications. The "warmer voice" decision below does not reopen this — a kinder
register is not a licence to speak when the app is closed.

**Two things specified and never rendered**, left deliberately for this rebuild:
`Celebration.rays` has no reader, so a plateau looks identical to a personal
best; and `SetStep.intense` has no reader, so an all-out set is not
distinguishable before you start it.

## Brand Commitments

Volunteered and made binding on 2026-08-27; recorded, not expanded.

- **The font choices stay.** SF, weight-led hierarchy, and the measured tracking
  work in `DesignTokens.swift` (`counterTracking -1.5`, `titleTracking -0.4`,
  `microTracking 0.6`).
- **Voice: warm, and true.** See Product Principles.

## Evidence on Hand

- **`spec.md`** — the functional specification. Behaviour authority.
- **`ios/Docs/redesign/04-direction-reset.md`** — the 2026-08-27 decisions;
  newest, and it wins over `spec.md`, `CLAUDE.md` and `ios-port/` on conflict.
- **The web app** (`src/`, deployed) — the behaviour specification for the port,
  and explicitly **not the design ceiling**.
- **`ios/Morning/PrototypeSetVariants.swift`** — three rejected R3 Set-screen
  directions, still runnable. **Anti-reference, not reference.**
- **`ios/Docs/redesign/01-motion-doctrine.md`** — the per-surface motion ruling.
  Its core conclusion survives a world change.
- **`ios/Docs/design-system.md`** — 655 lines, every contrast figure measured on
  rendered frames. The *numbers* do not survive a mid-tone world; the *method*
  does.

**There is no real training history in the iOS build** and none is imported.
Do not fabricate history, streaks, milestones or tonnage to make a surface look
populated — empty is the shipping state.

## Product Principles

1. **Reps are the only progress signal, so the crossing is the product.** Last
   time's number for this exact set, visible while you do that set, and the
   moment the counter passes it treated as the emotional centre it is.
2. **Warm, but never at the expense of true.** Confirmed 2026-08-27: the
   no-gamification rule is dropped **to the extent of register only** — no
   points, no badges, no levels, no XP, no mascot, no streak economy, and no new
   things to earn. The eleven celebration tiers survive intact. What changes is
   that the app is kind when it speaks, not that it praises without cause.

   **Widened 2026-09-09, for the study deck only.** Eden: *"I want to start
   gamifying this."* The deck now remembers every card it has shown him and
   every answer he has given, brings back what he gets wrong, and marks a card
   with what it already is to him. **The line that held is "no new things to
   earn"** — knowledge state is fair game, a reward economy is not, and the
   workout's own celebration tiers stay the only thing on that surface. See
   `plans/009-remembering-the-deck.md`.
3. **On a bad morning, the truth leads and the warmth follows.** Confirmed
   2026-08-27. "Not one set matched last time" still leads and is still the
   biggest thing on the surface; a kind line comes after it. The app never
   softens the number, never buries it, and never quietly skips a bad session.
4. **One screen, one action, at 6:10am with a knuckle.** Every layout decision
   is answerable to the scene of use, not to a design system.
5. **Empty is the normal case.** Every surface holds at zero data, at one week,
   and at six months — and empty reads as the beginning of a record, not as an
   error.

## Accessibility & Inclusion

- **Contrast is measured, never calculated and never judged by eye.** Both have
  already lied on this project — R2 found a live 6.18:1 failure this way.
  Measure on rendered frames with `ios/Tools/measure-contrast.py`. The mid-tone
  world means every figure re-measures from scratch and both dark-on-light and
  light-on-dark will appear; the single 6.6:1 floor as previously expressed does
  not survive unchanged, but the discipline does.
- **A mid-tone ground cannot carry three luminance levels of text over the
  floor.** Measured on rendered R4 frames, 2026-08-27, and it is a property of
  the ground rather than of any one direction. Two consequences bind whatever
  world is chosen: a saturated accent cannot be a glyph (a 152pt orange numeral
  on sand measured **2.14:1** — under the house floor *and* under WCAG's 3:1
  large-text bar), and a "quieter" text level cannot be bought with lightness
  (a mid slate measured **3.27:1**). Recession comes from size and weight, and
  a level that must be distinguishable from another does it by **hue**. This
  restates what `Ink.tertiary`'s own header already said and what the dawn ramp
  learned as *accent lights, accentText writes* — arrived at independently from
  the other side of the luminance range.
- **`measure-contrast.py`'s zone rows are tuned to the shipped layout.** On a new
  layout its labels land on the wrong elements and its numbers are right while
  its names are wrong. Check the printed row ranges against the frame, as the
  tool's own footer instructs, before quoting any figure from it.
- **Reduce Motion produces a calmer form, never a static or broken one.**
- **Dynamic Type** per the table above: clamped on the three workout surfaces by
  design, fully supported everywhere else.
- **Motion is verified in captured frames, never by reasoning.** An implicit
  animation that silently does nothing has cost this project twice.
