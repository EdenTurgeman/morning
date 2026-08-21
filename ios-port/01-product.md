# 01 — What this is and who it's for

## One user

A 30-year-old man, 60 kg, training at home on the floor with adjustable
dumbbells — 20 kg of plates in total, nothing else. Six mornings a week, upper
body, in a hard 20-minute cap before showering and starting the day. He is also
a sommelier, which is why there is a study deck in a fitness app.

He is the only user. There will never be a second one. Every decision below
follows from that: no onboarding, no empty-state marketing, no settings screen
full of preferences nobody will touch, no explaining the app to a newcomer.

## The one fact that shapes the entire product

The dumbbells are light and the weight is **deliberately fixed for a whole
session**. That is a feature of the training program, not a limitation to work
around. Because load never changes:

> **Reps are the only progress signal that exists.**

Everything follows:

- Logging reps is not bookkeeping. It is the core loop.
- Last session's number for *this exact set* must be visible at the moment of
  doing the set — not in a history tab.
- The moment the counter passes last time's number is the emotional centre of
  the entire app. It deserves the best thing you can build.
- Three identical sessions in a row is the most valuable output the app has:
  it means it is time to change the program.
- Losing the history destroys all of it. Backup is a first-class feature.

## Context of use — this justifies every UI decision

The app is used:

- **At 6:10am, half awake.** No reading. No parsing. No decisions.
- **Standing up, phone on the floor or a shelf**, glanced at between sets, often
  from a metre or two away, sometimes upside down over a push-up.
- **With sweaty hands**, one-handed, sometimes with a knuckle.
- **In a hurry.** Friction costs minutes out of twenty.
- **Offline.** Airplane mode must be indistinguishable from normal.

| Constraint | Requirement — non-negotiable in any design |
|---|---|
| Half awake | One screen shows exactly one thing to do. Never render the workout as a scrollable list. |
| Sweaty hands | Primary tap targets ≥ 64pt. The main action is full-width. |
| Glanceable | Exercise name and rep count readable from ~1.5m. |
| In a hurry | The common case — "I did what it suggested" — is **one tap**. |
| Phone on the floor | Nothing important lives in the top 15% of the screen during a set. |
| Offline | Zero runtime network dependency. |

## The non-negotiables

If a rewrite loses any of these it is worse than a piece of paper.

1. **One screen, one action.** Never a list of the whole workout.
2. **The common case is one tap.** Reps pre-filled from history; one control advances.
3. **Last session's number is on the set screen**, next to the counter, always.
4. **Rest timers start automatically** and signal at zero. The 20-second myo-rep
   rest especially — that rest *is* the training mechanism, not a convenience.
5. **Nothing is lost** on a crash, a phone call, backgrounding, or force-quit
   mid-session.
6. **Works fully offline.**
7. **Backup is one tap**, and restoring it reproduces the history exactly.
8. **The program is one editable object in one file** that the user edits himself
   in a text editor every few months. See `03-program.md`.

## The tone — this one is easy to get wrong

This app is **not gamified** and must never become gamified. There are no points,
no badges, no levels, no XP, no "Great job!", no mascot, no streak-freeze
economy. The existing celebration code states the rule directly:

> The reward for finishing is being told exactly what you did, well.

Every headline the app shows states something **true and specific**: "Your
previous best on A was 148", "Third A at the same total", "Not one set matched
last time". That is what makes the moments land the twentieth time. A generic
congratulation is worth nothing by the third session.

This constrains visual design too. Aim for the register of a good instrument —
precise, quiet, confident — rather than a consumer fitness app. Delight comes
from craft and responsiveness, not from cartoon reward.

**But:** restraint is not the same as austerity. The previous version was
sometimes too plain, and the whole reason for this rewrite is that the phone can
do far more. Spend the budget on *motion, material, depth and response* — the
things that make an app feel alive in the hand — and keep it out of the copy.

## What good looks like

The user should want to open this app. Not because it nags him, but because it
is one of the nicest-feeling things on his phone, and because it tells him true
things about himself that nothing else does.
