# Direction reset — 2026-08-27

**Eden rejected all three R3 directions and changed the brief.** This document is
the authoritative record of what he decided. Where it conflicts with `spec.md`,
`CLAUDE.md`, `ios-port/01-product.md` or `ios-port/02-design-brief.md`, **this
document is newer and wins** until those are rewritten.

---

## 1. Why R3 was rejected

His words: *"None of the designs in the prototypes fit me, I like the font
choices, but some of them are pretty empty and leave a lot of empty space. All
just being similar to the previous app and its background."*

**The diagnosis, stated plainly so it is not repeated.** All three R3 variants
sat on the same `DawnBackdrop`, used the same `RepControl`, the same
`DawnPrimaryButton` and the same near-black indigo sky. They diverged on
*arrangement* and held *material, density and identity* constant. That is the
failure the `prototype` skill names outright — three tints read as one direction.
The empty space was the same fault from the other side: content pushed around a
fixed world instead of the world being questioned.

**Do not diverge on layout again. Diverge on world.**

---

## 2. The three decisions

Asked and answered explicitly on 2026-08-27.

### 2.1 Brightness — **mid-tone world**

Not dark. Not light. A muted mid-luminance world — overcast morning, paper, soft
sage, sand. It should read as **calm**, not as night.

| | |
|---|---|
| **Overridden** | `spec.md` §2 and `02-design-brief.md` §6: *"Dark by default. It is used before sunrise. A light mode is optional and low priority."* |
| **Cost he accepted** | Every contrast figure re-measures from scratch. Dark-on-light and light-on-dark will both appear, so the single 6.6:1 floor as currently expressed does not survive unchanged. It is also brighter than ideal at 6:10am with dilated pupils. |
| **What survives** | The **measurement discipline**, not the numbers. `ios/Tools/measure-contrast.py`, measured on rendered frames, never calculated and never judged by eye. Both of those have already lied on this project. R2 found a live 6.18:1 failure this way three days ago. |

### 2.2 Tone — **the no-gamification rule is dropped**

Encouragement in the ordinary sense is now permitted: praise, positive
reinforcement, possibly streaks-as-reward.

| | |
|---|---|
| **Overridden** | The most emphatic value in the project, stated in **four** documents. `spec.md` §2: *"Not gamified, and it must never become gamified. No points, no badges, no levels, no XP, no mascot, no streak-freeze economy, no 'Great job!'."* Also `CLAUDE.md`, `01-product.md` §Tone, `02-design-brief.md`. |
| **Also affected** | `spec.md` §9's eleven celebration tiers exist *because* of that rule — *"Every headline must add something the rep total does not already say"*, *"a generic congratulation is worth nothing by the third session"*. The tier system's whole justification is now optional. |
| **Also affected** | The copy pass is marked DONE (`ios/Docs/copy-pass.md`) with content "fixed and verbatim". Warmer copy reopens it. |
| **Concern raised, and his answer** | The option he selected carried the text *"This deletes the product's most emphatic stated value… I would push back on this one, but it is your product and your call."* He selected it with that visible. **Treat it as decided. Do not re-litigate it.** |

**Left open deliberately, and the next agent must settle it in `init`:** "drop the
rule" spans a very wide range, from *a warmer, kinder voice* to *points, badges,
levels and a mascot*. Nothing here says which. `/impeccable init` interviews for
product truth — **nail down the specific mechanics there** rather than assuming
either end.

### 2.3 Numeric density — **demote the analytical screens**

The Set screen keeps its numbers and their weight. **History, Lifetime totals and
the year grid stop leading with figures** and lead with something qualitative
instead — shape, colour, streak-as-texture.

| | |
|---|---|
| **Not overridden** | The product thesis stands: the load is fixed for a whole session, so **reps are the only progress signal that exists**. The rep counter, last time's number and the crossing keep their full weight. |
| **Scope** | Three surfaces' hierarchy. No behaviour changes. `spec.md` §7, §8 and §11 are untouched. |

### 2.4 Everything else visual is up for replacement

His words: *"I want to do both the background and the rest. Everything is up for
replacement."*

That explicitly includes **the dawn/sunrise idea and the Metal sky**. `spec.md`
§2 already permitted this — *"You may keep this, evolve it, or replace it. The
one thing you may not do is replace it with nothing"* — and the replacement must
be an equally load-bearing idea: something that makes progress legible without
text, belongs to this specific app, and gives the finish somewhere to arrive.

**A palette is not an idea.**

### 2.5 What he liked

- **The font choices.** Named explicitly and unprompted. Keep SF, keep the
  weight-led hierarchy, keep the R2 tracking work (`counterTracking -1.5`,
  `titleTracking -0.4`, `microTracking 0.6`).
- **"Chill vibes."** The register moves from *precise instrument* toward *calm*.
- **"Encouragement."** See 2.2.
- **"Learning."** He named the study deck as something he values. It is 26 cards
  on wine and tea, currently a rest-filler dosed twice a session. Worth
  considering whether it deserves more of the app's identity — but that ADDS
  scope, and he did not ask for it directly. Propose, do not assume.

---

## 3. What is still binding, and was never up for discussion

Nothing in §2 touches any of this. It is behaviour and physics, not taste.

1. **A session in progress survives force-quit and reboot**, rest deadline intact.
2. **Ending a session saves nothing**, after a confirmation that says so.
3. **Back does not lose a logged rep**, and the prefill priority holds.
4. **The rep control reports deltas**, never absolutes.
5. **Reps are never compared across a weight change.**
6. **One history record per finished session; `ts` is never regenerated.**
7. **`kg` is never backfilled.**
8. **Bodyweight reps are 0 kg of tonnage** and still count as reps.
9. **A milestone fires once, ever.**
10. **The week in progress cannot break a streak.**
11. **No card on the 20-second myo rest, and the card is silent.**
12. **Nothing inside a workout scrolls, ever**, and the rep controls do not move
    between exercises.
13. **Every surface behaves correctly at empty, one week, and six months.**
14. **Rep controls ≥ 78pt; primary actions ≥ 64pt; nothing important in the top
    15% during a set.** Sweaty hands, 6:10am, knuckle taps.
15. **Zero runtime network dependency.** Airplane mode is indistinguishable.
16. **iPhone 16 Pro only, 402×874, portrait.** An SE regression is not a defect.
17. **Exercise names, cues, targets, rest seconds and Guide text stay verbatim.**
    §2.2 reopens *celebration and encouragement copy*. It does not reopen the
    training content.

---

## 4. Where Impeccable's iOS defaults collide with this project

`reference/ios.md` is HIG-conformance-oriented. This app departs from HIG in
specific, documented, measured ways. **`spec.md` wins on all four**; do not let
the skill "correct" them.

| Impeccable's iOS rule | This project |
|---|---|
| "Use system text styles. **No hard-coded point sizes**" | `spec.md` §3.14 — the three workout surfaces *deliberately* clamp Dynamic Type and use fixed sizes, because they are already at the top of the scale and must never scroll. Reading surfaces do support the full range. |
| "**Semantic system colors**; raw hex breaks in Dark Mode" | Colour is the progress signal. Whatever replaces the dawn ramp, it is a designed ramp, not `Color.label`. |
| "**System materials** for blur; no hand-rolled glassmorphism" | R2 measured this and ruled against it over a live shader — Material adapts its tint to what is behind it, so contrast drifts on Apple's curve rather than ours. **Re-open only if the shader goes.** |
| "**Tab bar** for 2–5 top-level sections" | `spec.md` §3.13 — "There is no tab bar and no deep hierarchy; the app has one home and one flow." |

---

## 5. Documents that now contain overridden text

Flagged, not rewritten — rewriting the binding brief is Eden's call, and a
half-rewritten `spec.md` is worse than a clearly-flagged one.

| File | What is stale |
|---|---|
| `spec.md` §2 | "Dark by default"; the entire "Not gamified" paragraph |
| `spec.md` §9 | The tiers' justification, though the tier *logic* is still correct |
| `CLAUDE.md` | The no-gamification rule, stated twice |
| `ios-port/01-product.md` | §Tone, in full |
| `ios-port/02-design-brief.md` | §6 "Dark by default"; §2's register |
| `ios/Docs/copy-pass.md` | Marked DONE; §2.2 reopens it |

**`spec.md` moves in the same commit as the behaviour change it describes.** That
rule is still in force — it is how the next rebuild avoids starting from a lie.
