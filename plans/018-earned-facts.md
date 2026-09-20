# 018 — What this app should give back

Opened 2026-09-20. Eden: *"let's think hard on actual good gamification
practices, what does the app need, what could delight me as i work out… i want
to make a pass on the flavor text."*

A design document, not a change. Everything below is measured against his own
22 logged sessions.

---

## 1. What the record says he actually saw

Replaying the tier ranker over his history:

```
12×  record        "A personal best."
 3×  PLATEAU       "Reps have stopped moving."
 3×  matched       "Dead level."
 2×  done
 1×  improved
 1×  first
```

**"A personal best." fired on 12 of 22 sessions.** Fifty-five percent. In the
first months of a fixed-load program almost every session beats the last one,
so the rarest-sounding thing the app can say is the thing it says most often.
The words are spent, and the session that is genuinely a landmark will land
exactly like the eleven before it.

**Every tier says the same body every time.** Twelve identical *"Your previous
best on A was N. That's the number to beat now."* Six months in, that is the
sentence he has read more than any other in the app.

**And the app asked for something repeatedly that never happened.** "Dead
level." says *"One more identical session and it's time to move up the ladder."*
Between them, `matched` and `plateau` fired six times.

So the flavor text is not bad — it is genuinely good, and the streak milestones
are the best writing in the product. The problem is **distribution**: the good
copy is rare, the common copy repeats, and the top tier is inflated.

---

## 2. What good practice actually supports

Stripped of the industry's habits, the mechanics that reliably work and are not
manipulative:

| Works | Why it fits here |
|---|---|
| **Competence feedback** — evidence you are better at a specific thing | This is the app's entire premise already |
| **Closure** — a thing that finishes | The completion moment |
| **Goal gradient** — effort rises near a visible finish | The week meter, if it did anything |
| **Meaningful choice** | The ladder: reps, tempo, partials, weight |

And the ones to keep refusing, which is most of the industry:

- **Variable-ratio reward.** Slot-machine scheduling. Effective and dishonest.
- **Loss aversion.** Streak anxiety works by making a missed morning cost
  something. `PRODUCT.md` forbids it and is right to: the weekly streak exists
  precisely so following the program properly cannot punish him.
- **Points, levels, badges.** A second scoring system beside a true one always
  wins, because it is easier to move.
- **Social comparison.** One user.

---

## 3. The mechanism this app should use: earned facts

**The best writing already in the app is not praise — it is teaching.**

> *"Eight weeks is past the point where gains are just your nervous system
> learning the movement. This is tissue now."*

That is the model. The reward for training is being told something true about
what just happened that you did not already know. It is non-inflationary,
impossible to fake, and — unlike points — **it gets better the longer he trains,
because the history it draws on grows.**

The machinery exists. `History.stalls` already derives "these movements have not
moved" from the rep log. The same fold gives the opposite, and much more.

Computed from his real history, today:

> *"Overhead press has gone from 27 to 41 since you started. Your most improved."*
>
> *"Your first A was 133 reps. This one was 174."*
>
> *"You have done 586 curls in A alone."*
>
> *"That is 3,186 reps since 17 August."*

None of these is a reward. Each is a fact he earned and cannot see any other
way, and there is an unbounded supply because the data keeps arriving.

**This is the answer to "more gamification" for this app.** Not a layer on top
of the numbers — more of the numbers, better chosen, at the right moment.

---

## 4. What to change, ranked

### 4a. Stop spending "personal best" — **the highest-value fix**

Twelve in twenty-two. Grade it instead of flattening it:

- beat the previous best **by a rep or two** → this is `improved` with a
  different eyebrow, not a landmark
- beat it **by a real margin**, or beat a best that has stood for weeks →
  *that* is "A personal best."

The delta is already computed. This costs a threshold and a sentence, and it
gives the phrase back its meaning.

### 4b. A pool of bodies per tier, chosen deterministically

Not random — keyed off the record's `ts`, so a given session always shows the
same line and the History screen never disagrees with itself. Three or four per
common tier and the repetition disappears for a year.

This is a pure content job once the plumbing exists, and it is the "pass on the
flavor text" he asked for.

### 4c. Earned facts, as a second line

One derived fact under the headline, chosen by what is most interesting today —
most-improved movement, a round total crossed, a first-versus-now comparison.
Same shape as the stall line and the deck's standing line: **absent entirely
when there is nothing true to say.**

Start with three generators. They compose with everything and never need new
storage.

### 4d. In the workout: mark the all-time high WHERE IT HAPPENS

The crossing fires when the counter passes last time's number — the emotional
centre, and correctly placed. **Beating the best you have ever done on that
movement is a rarer and larger thing, and the app currently says nothing until
the summary.**

It should be marked at the rep control, in the moment, while he is holding the
dumbbells. A different mark from the crossing, not a louder one.

### 4e. In the workout: say when it is the last set

Nothing marks it. It is the one set where everybody finds something extra, the
information is free (`isLastStep` already exists), and it costs no tap and no
motion.

### 4f. Make completing a week land

Still true from `plans/016`: the most meaningful recurring event in the app is
drawn on Home as five static pips.

---

## 5. Corrections to plans/016

- **3c was wrong.** I proposed showing the current run as well as the best. Home
  already does exactly that, in `runLine`, including keeping the best on screen
  after a streak breaks — with a comment explaining why that moment matters.
  Read the screen before proposing a feature for it.

---

## 6. Order

1. **4a** — one threshold, immediately stops the inflation getting worse.
2. **4e** — free, and the biggest in-workout feeling per line of code.
3. **4c** — the generators; this is the one that keeps paying.
4. **4b** — content, once 4c proves the shape.
5. **4d** — needs care at the rep control, which is the most-touched surface.
6. **4f** — needs `plans/016` §2 first, or it cannot be reviewed.
