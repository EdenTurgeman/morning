# 016 — More fun, without being tacky

Opened 2026-09-20. Eden: *"let's gamify more, maybe cooler animations/streaks
better final screens, let's make the app more fun without being tacky"*.

---

## 0. The line, restated — this is the part that gets broken

`CLAUDE.md` already settles what "gamify" may mean here, and it is narrow. It is
restated at the top of this plan because every idea below had to be checked
against it, and three good-sounding ones died on it.

- **The deck may keep score of what he KNOWS.** Seen, missed, due, confused.
- **Nothing may keep score of what he EARNS.** Nothing accumulates, nothing
  unlocks, nothing is lost by missing a morning.
- **Nothing gamified may cost a tap inside a workout.**
- **No second scoring system** beside the eleven celebration tiers and the
  weekly streak. `PRODUCT.md` principle 2.
- **Every headline states something true and specific.** No points, no badges,
  no levels, no XP, no "Great job!".

So "more fun" here cannot mean more reward. It has to mean **the true things
already in the app being better felt** — which, it turns out, is where the
easiest wins are, because the port dropped several of them on the way across.

---

## 1. Shipped tonight: two numbers that were supposed to move

### The completion total counts up again

The web build wrapped the summary's rep total in `CountUp`, with a comment
explaining that it was interval-driven precisely so it could not sit at zero if
frames were dropped: *"for the total-reps number on the summary screen, the
whole point of the app, 'shows 0 forever' is not an acceptable failure mode."*

The port drew it statically. **That is the third thing this port has silently
dropped** — the crossing wipe and the ALL OUT stamp were the first two, both
recorded in the handoff log, and all three were found the same way: by reading
the old source for something else entirely.

It now counts up over 0.75s from the `number` beat, landing at 2.30s against
pips at 2.35 — the number finishes arriving and then the week arrives under it.
Driven off `elapsed`, because this moment runs on one clock and a second clock
is how two things that should land together stop doing so. Off under Reduce
Motion, which keeps every beat here and drops the travel. Not applied below 20
reps, where a count-up reads as a glitch rather than a flourish.

### The lifetime tonnage counts up

Same omission, same origin (`src/screens/Ledger.tsx` wrapped it too), and this
one matters on its own terms: the number is everything he has ever lifted and it
is the reason that screen exists. Driven by SwiftUI's own animation rather than
a clock, because unlike the completion moment there is nothing else on that
screen to stay in step with.

**Both are guaranteed to land on the true number.** That is the property worth
having and the only one asserted: past the duration the count returns the total
itself, so the worst a stalled render can do is show the right answer sooner.

---

## 2. Found on the way: the completion moment cannot be reviewed

`./scripts/shoot.sh daybreak` returns the **launch screen**, at every delay from
4 to 20 seconds. Not a crash — the app runs, logs 269 lines and exits cleanly —
it simply never produces a frame of Daybreak for the capture.

It is not new and it is not the count-up: stashing tonight's change and shooting
the previous commit gives the same white frame. And it is simulator-only, which
is why it has gone unnoticed — Eden described this animation in detail on the
phone four days ago (*"the element appear and do their thing but with some
dropped frames"*), so it plainly works on device.

The likely cause is the one `shoot.sh`'s own header warns about: the 41-ray
Canvas needs a Metal pipeline compile before its first frame, and the capture
lands before it.

**This blocks every future change to the most crafted screen in the app.** Any
motion work on the completion moment is currently unreviewable except by
installing on the phone. Worth fixing before, not after, the next idea below.

Where to start: a `-freeze <seconds>` flag pinning `elapsed` to a fixed value so
the moment renders as a still with no timeline running at all. That is how
`-prototype …-snapshot` already freezes a rest, so the pattern exists.

---

## 3. Ranked, not built

### 3a. A movement that hit an all-time high should be named

The exact mirror of the stall line built on 19 September, using the same
machinery. The Summary already says *"Floor fly and rear-delt fly have not moved
in three sessions"*; it should equally be able to say **"Most lateral raises you
have ever done."**

Not a score — the same "beat your last number" premise the whole app rests on,
applied per movement instead of per session, and per movement is where he can
actually act on it. It is true, specific, and needs no new storage: `History`
already holds every slot of every session.

Cheapest real win on this list. **Recommend first.**

### 3b. Completing a week should land

Finishing a week is the most meaningful recurring event in the app and Home
draws it as five static pips. There is a celebration tier for it inside the
session, and then nothing when he returns to the screen that shows it.

Not a new reward — the same fact, felt. The paper world has its own vocabulary
for this already (the crossing's orange rule, the torn ply) and none of it is
being used here.

### 3c. The current run, not just the best one

Home says *"Best run: 16 weeks"*. It does not say what the current run is, which
is the number he can still do something about. Say both when they differ.

Careful: this is the idea closest to the line. It is fine as a **statement**
(*"3 weeks running"*) and becomes a streak mechanic the moment anything is at
stake in keeping it. No warnings, no "don't break it", no freezes.

### 3d. The facts row could stagger in

Four numbers that appear at once, behind Daybreak, so nobody ever sees them
arrive. Low value until 3b, and only worth doing once §2 makes the screen
reviewable.

---

## 4. Explicitly rejected

Written down so they are not proposed again in three months.

- **Badges, levels, XP, unlockables, a points total.** Forbidden by the rule at
  the top, and they would compete with the eleven tiers.
- **Confetti.** The web build had `canvas-confetti` as a dependency and the
  paper world deliberately does not; a burst of coloured plastic is the exact
  tacky he asked to avoid.
- **Streak freezes, streak repair, "don't lose your streak" notifications.**
  These work by making a missed morning cost something. `PRODUCT.md` is explicit
  that nothing is lost by missing a morning, and the weekly streak exists
  precisely so that following the program properly cannot punish him.
- **A second card-based scoring surface.** `plans/009` settled this.
