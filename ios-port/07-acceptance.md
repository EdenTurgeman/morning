# 07 — Acceptance

The web build has three verification scripts that run as `npm test`. They are the
executable specification for everything in `04-rules.md`, and they exist because
each assertion in them was once a bug. **Port them to XCTest early** — before the
UI work, not after. They will catch a mis-ported rule in seconds that would
otherwise show up as a wrong number six weeks from now.

Source: `scripts/verify-program.ts`, `verify-week.ts`, `verify-deck.ts`.
Golden fixture: `content/compiled-steps.json`.

---

## Program and step compiler

- [ ] Session A compiles to **21** steps; B to **25**. Assert the full list
      against `content/compiled-steps.json`, not just the counts.
- [ ] No rest step appears between superset partners.
- [ ] A rest appears after each superset round, including the last of a block.
- [ ] No rest is left dangling at the very end of a session.
- [ ] The myo block produces 3 sets with per-set targets and 20s rests.
- [ ] **One weight per session** — no session contains two different loads.
- [ ] Lateral raises are under 50% of session B's working sets.
- [ ] The floor fly is present in B.
- [ ] Slot IDs are stable and unique, and match the golden fixture exactly.
- [ ] Plate breakdowns are derived from the inventory and are achievable: 7.5 kg
      resolves to `2×2.5 + 2×1.25`, never `3×2.5`.

## Week and streak

- [ ] The week starts on **Sunday**.
- [ ] Five sessions on any days completes a week; five consecutive days is not
      required and six days with four sessions does not count.
- [ ] An incomplete week in progress never breaks a streak.
- [ ] A complete week in progress extends it.
- [ ] Longest run survives the current streak dropping to zero.
- [ ] `canRestToday` is false when the remaining days exactly equal the remaining
      sessions.
- [ ] The nudge names the correct weekdays.
- [ ] `completedThisWeek` fires only on the session that reaches target, not on
      the ones after it.

## Ledger

- [ ] Tonnage counts 2 × load per rep (two dumbbells, load is per handle).
- [ ] Bodyweight reps contribute **0 kg** but do count toward total reps.
- [ ] Each session is valued at its own recorded `kg`; changing the working
      weight does not re-value past sessions.
- [ ] Each milestone fires exactly once, on the session that crossed it.

## Celebration

- [ ] Exactly one tier fires, in the documented priority order.
- [ ] Rep deltas are suppressed entirely when the working weight changed.
- [ ] `plateau` requires three same-letter sessions on an identical total.
- [ ] `clean-sweep` requires every comparable set to improve, at least three of
      them, at the same weight.
- [ ] No headline restates the rep total that is rendered directly above it, and
      no eyebrow restates its headline.
- [ ] Ordinary confetti fires on **every** finished session; the milestone burst
      only on week completions and lifetime thresholds.

## Study deck

- [ ] Every card id is unique and every card is phrased as a question.
- [ ] Two cards per session on rests, plus one on the summary.
- [ ] No card on any rest under 45 seconds — the 20s myo rest in particular.
- [ ] Not on the first long rest; the two are spread apart.
- [ ] Draws without replacement; a run of eight draws never repeats.
- [ ] Reveal delay scales with rest length and stays within 6.5–11 s.
- [ ] Adding a card to the deck requires exactly one edit and no other change.

## Session lifecycle

- [ ] A fresh install proposes A; completing A proposes B, and vice versa.
- [ ] Rep counter pre-fills from the most recent same-session, same-slot value.
- [ ] Back returns to the previous step **without losing logged reps**, and shows
      the number actually entered this session rather than last week's.
- [ ] Rapid taps on the rep control never collapse into a single increment.
- [ ] End mid-session discards everything after a confirm, including sets already
      logged.
- [ ] Force-quitting mid-session and relaunching restores the same step, the same
      logged reps, and a correct remaining time.
- [ ] A phone call mid-rest leaves the timer correct on return.
- [ ] Finishing a session writes exactly **one** history record. (The web build
      briefly wrote two — this is a real failure mode.)

## Data

The app ships starting at zero — see `06-data.md`. Importing the web history is
a follow-up, so the checks below are about the empty case and the schema, not
about migration.

- [ ] A fresh install works end to end: start, log a session, see the `first`
      celebration tier, land on a Home screen with one session behind it.
- [ ] Every screen is reviewed at **empty**, **one week** and **six months** of
      seeded data. Empty states are designed screens with their own copy, not a
      fallback label.
- [ ] The set screen with no history shows the first-run message and a sensible
      default, and does not look broken.
- [ ] Local dates do not shift by a day under any device timezone.
- [ ] Records without `kg` fall back to the program default and are not backfilled.
- [ ] Export → wipe → restore reproduces the history exactly.
- [ ] A failed write surfaces an error and never silently drops a session.
- [ ] Exported JSON is byte-compatible with the web app's format — open it in the
      web app's Restore box and confirm it parses.

### Phase 2 — when the web history is imported

- [ ] Importing the real backup reproduces, exactly: total tonnage, total reps,
      session count, current streak, longest run, and the year grid. **Verify
      against the running web app on the actual device.**
- [ ] Malformed records are skipped; the rest of the import succeeds.

## Device checks — do these on the phone, not the simulator

- [ ] Airplane mode is indistinguishable from normal.
- [ ] Nothing scrolls on any workout screen, at any content length.
- [ ] Exercise name and rep count are readable at 1.5 m in a dark room.
- [ ] Every meaningful tap produces a haptic, and the "beat your last number"
      haptic is distinguishable from the ordinary one **with the phone face down**.
- [ ] Music from another app ducks once at five seconds and returns after zero —
      it does not stop, and it does not pump six times.
- [ ] The screen never sleeps mid-session.
- [ ] 120Hz with no dropped frames while a timer runs.
- [ ] Reduce Motion produces a calmer app, not a broken one.
- [ ] A full session of A and a full session of B, start to finish, with zero
      glitches. Then do it again for real at 6am — that is the only test that
      actually counts.
