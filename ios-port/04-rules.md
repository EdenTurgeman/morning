# 04 — Behavioural rules that must survive

Every rule here was arrived at by getting it wrong first. Where this file and
the web source disagree about *why*, this file wins. Where they disagree about
*what*, the source wins — read it.

Reference implementations: `src/lib/steps.ts`, `week.ts`, `ledger.ts`,
`celebration.ts`, `deck.ts`, `src/hooks/useWorkout.ts`.

---

## 1. The step machine

A session compiles to a **flat, linear list of steps** and the user moves through
one at a time. Three kinds: `timer` (warm-up), `set`, `rest`.

- Rest is emitted after every set, except between superset partners, and trailing
  rests at the end of the session are dropped.
- Golden fixture: `content/compiled-steps.json`. A must produce **21** steps,
  B **25**. Assert against the whole list, not just the counts.
- **Back** returns to the previous step without losing what was logged.
- **End** abandons: confirm first, save nothing at all — not even sets already
  logged. This is deliberate and the confirmation copy says so.
- A workout in progress survives a crash, a phone call, force-quit and reboot.
  The web version persists `{ session key, step index, log, endsAt }` separately
  from the history and restores on launch. Match that guarantee.

### Rep prefill priority — in this order

1. What you already logged for this slot **in this session** — so tapping Back to
   fix a mistap shows the number you actually entered, not last week's.
2. What you did on this exact set **last time**. The whole point of the app.
3. A plausible default (12 loaded, 10 bodyweight), so a first run is still one tap.

Getting this order wrong is how Back silently ate a correction in an early build.

### The rep control

- Reports a **delta**, not an absolute value. Two taps landing in the same update
  cycle both computed from the same stale value and collapsed into one increment.
  Hold-to-repeat accelerates to 60ms, so that collapse is reachable in normal use.
- The digit moves in the direction you pushed it, so a mistap is visible.
- **When the value passes last time's number it changes state** — currently it
  turns green and plays a distinct tone. This is the emotional centre of the app.
  Give it everything: haptic detent, colour, motion, sound.
- If last time's reps were done at a **different working weight**, they are not a
  like-for-like target and the control must say so rather than quietly implying
  one.

---

## 2. Session alternation

The home screen proposes the opposite of whatever was logged last. A secondary
control starts the other one instead — for a skipped day, or repeating one. A
fresh install proposes A.

---

## 3. The weekly streak

**Measured in weeks, not consecutive days.** The program is six mornings a week
with a rest day; a consecutive-day streak punishes you for following it
correctly.

- A week counts if it contains **5 sessions**, whichever days they land on.
- **The week starts on Sunday.**
- **The week in progress can never break a streak.** It hasn't finished. It only
  ever adds: if already complete it extends the count, otherwise the streak reads
  from last week backwards.
- **Longest run is remembered separately.** A missed week takes the current
  streak to zero, which is precisely when people stop — the run you built stays
  on screen as something to chase back rather than disappearing as if it never
  happened.
- Derived state the UI uses: sessions done, remaining, days left, `atRisk`,
  `missed`, `canRestToday`, and the weekday names a rest day would cost you. The
  nudge copy on the home screen is generated from these.

---

## 4. The Ledger — lifetime totals

Headline number is **tonnage: reps × load**. Two honesty constraints, both
non-negotiable:

- Every loaded movement is **two dumbbells**, and the program's load is per
  handle — so a rep moves 2 × load.
- **Bodyweight work contributes 0 kg.** Counting push-ups would need the user's
  bodyweight and a guessed multiplier, which would make the headline number
  fiction. Push-up reps still count toward total *reps* — they just don't inflate
  tonnage.
- Sessions are valued at **the weight they were actually done at**, from their
  own `kg` field, so changing your working weight never retroactively rewrites
  what you lifted last month.

### Milestones

Deliberately sparse — "a milestone you hit every fortnight is a chore; one you
hit twice a year is an event."

- Tonnes: 1, 5, 10, 25, 50, 100, 250, 500, 1000
- Reps: 1k, 5k, 10k, 25k, 50k, 100k
- Sessions: 10, 25, 50, 100, 200, 365, 500, 1000

A milestone fires **exactly once**, on the session that crossed it, computed by
diffing the ledger with and without that session. Copy is in `src/lib/ledger.ts`
— port verbatim.

---

## 5. Celebration tiers

The summary shows exactly **one** headline — the highest thing actually earned.
Full copy in `src/lib/celebration.ts`; port verbatim.

Priority order:

| # | Tier | Fires when | Confetti | Rays |
|---|---|---|---|---|
| 1 | `lifetime-milestone` | A ledger threshold was crossed | yes | yes |
| 2 | `clean-sweep` | Every comparable set beat last time (≥3 sets, same weight) | yes | yes |
| 3 | `weight-changed` | Working weight differs from the last same-letter session | no | no |
| 4 | `streak-milestone` | Week completed *and* streak hits 2/4/8/12/26/52 | yes | yes |
| 5 | `week-complete` | The week just reached 5 | yes | yes |
| 6 | `record` | Beat your best ever on this letter | no | yes |
| 7 | `first` | First session ever logged | no | yes |
| 8 | `plateau` | Third same-letter session on the identical total | no | no |
| 9 | `improved` | More reps than last time | no | no |
| 10 | `matched` | Exactly equal | no | no |
| 11 | `done` | Anything else, including down on last time | no | no |

### Rules the tiers encode

- **Reps are only comparable at the same weight.** If the working weight moved,
  every delta is meaningless — "+18 reps" for dropping 2.5 kg a side is not
  progress, and "dead level" at a heavier weight is not a plateau. When it moves,
  say so honestly instead of showing a comparison that isn't one, and start a
  fresh baseline.
- **Every headline must add something the number doesn't already say.** The
  summary renders the rep total as a large number directly above, so a headline of
  "252 reps." prints the same figure twice. This was a real bug the user caught.
  The same applies to eyebrows restating headlines.
- **Confetti fires on every finished session**; the larger *milestone* burst is
  reserved for week completions and lifetime thresholds. The user asked for this
  explicitly. Do not gate the ordinary celebration.
- `plateau` is the app's most valuable output. It should not feel like a failure
  state — it is an instruction to change the program, and the copy says which
  rung to move to.

---

## 6. The study deck

26 cards, wine and tea, in `content/cards.json`. Exam-style: every card teaches a
**mechanism**, not a fact. Port verbatim; the user will add more over time, so
adding a card must be a one-line append with no other edits.

### Dosing — these numbers are deliberate

- **Two cards per session on rests**, plus **one on the summary**. Not one per
  long rest: session A has seven rests of 45s or more, and eight cards in twenty
  minutes turns a workout into homework.
- Only on rests of **45 seconds or more**.
- **Never on the 20-second myo rest.** That rest *is* the training stimulus, and
  anything inviting you to linger there breaks the exercise.
- Not on the **first** long rest — that one is spent getting your breath back
  after the opening set. Taken from roughly the first and third quarter of the
  long rests so they land spread out.
- Drawn **without replacement**: nothing repeats until the deck has been through.
  A short-term buffer additionally prevents a repeat within one sitting.

### The reveal — the rule that shaped the component

> You must never miss the timer because you were thinking.

So the answer **auto-reveals**; tapping only brings it forward if you already
have it. Nothing is gated behind an interaction, because at 6am mid-rest you will
not reliably perform one, and a card you never got the answer to is worse than no
card. Reveal delay scales with the rest length, clamped to 6.5–11 seconds; the
summary card gets 14 seconds because there is no timer to beat.

A progress bar fills over the thinking time and then becomes the rule the answer
sits under — one element doing both jobs.

**The card is silent.** The app's audio vocabulary is entirely about time; a card
making a noise during the last five seconds of a countdown would be actively
misleading. Haptics on reveal are fine and probably good — sound is not.

---

## 7. History

- Reverse-chronological: date, session letter, total reps, duration.
- A week strip and a year grid (one cell per day, painted from the accent ramp,
  intensity scaled to the user's own range — his quietest session is the coldest
  colour, his best is the warmest, so a good month literally looks warmer).
  **The grid must fit the screen.** A fixed-cell version was wider than a phone
  and pushed the recent weeks off the right edge; the whole point of showing a
  year is seeing it at once.
- Deleting a session sits behind an **explicit edit mode**. Never a swipe: sweaty
  hands, and an accidental delete is unrecoverable.

---

## 8. Backup

- Export produces JSON; restoring it reproduces the history exactly.
- Restore validates, confirms the session-count swap, then replaces.
- Erase everything is destructive, confirmed, and visually de-emphasised.
- **Never lose data on a failed write** — surface the failure rather than
  silently dropping a session. This is the one unacceptable failure mode.

See `06-data.md`; with iCloud in the picture this screen can become much quieter,
but the export path must remain because it is the only thing that survives losing
the phone *and* the account.
