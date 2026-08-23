# The copy pass — W16

Asked for on 2026-08-23:

> "i want to go over the texts in the app, think of their ux, copy and what they
> say, i hate em-dashes and text that sounds like it's super AI generated, this
> goes for ALL text in the app."

## What the audit found first

The app has **59 em-dashes in user-facing copy**. Before changing any of them I
checked each one against `src/`, and the split is the whole story of this
workstream:

| Where | Em-dashes | Who wrote it |
|---|---:|---|
| `Screens/*.swift` — my UI copy | 6 | **Eden**, ported verbatim from the web build |
| `Screens/*.swift` — my UI copy | 7 | **Me** |
| `cards.json` | 21 | Eden |
| `Program.swift` cues and sub-labels | 14 | Eden |
| `guide.json` | 10 | Eden |
| `Celebration.swift` tiers | 4 | Eden |

**Fifty-two of the fifty-nine are his own writing**, carried across from the web
app unchanged because `CLAUDE.md` rule 3 says content is fixed and verbatim and
"not yours to improve".

So the brief splits in two and only one half is mine to act on. The suspicion
that prompted this — copy that "sounds super AI generated" — cannot apply to
text he wrote himself years before this port existed. What it can apply to is
the seven strings below, and it did.

---

## Part one — changed, because they are mine

Every one of these is UI chrome I wrote for the port. No content rule covers
them.

| Screen | Before | After | Why |
|---|---|---|---|
| History, empty | Every session you finish lands here **—** the date, which one, **and** how many reps. A year of them fits on one screen. | Every session you finish lands here**.** The date, which one, how many reps. A year of them fits on one screen. | Dash → full stop. The list reads faster without the "and". |
| History, delete confirm | A on Fri, 21 Aug **—** 209 reps. This cannot be undone. | A on Fri, 21 Aug**.** 209 reps. This cannot be undone. | Three facts, three sentences. |
| Ledger, provenance | 27,447 reps, each moving two dumbbells **at the weight that session was actually done at**. 4,907 of them were bodyweight **—** they count as reps, not as kilos. | 27,447 reps, each moving two dumbbells **at whatever that session's weight was**. 4,907 **were bodyweight, so they count as reps but not as kilos**. | "at the weight … done at" put two *at*s in one clause. The dash was hiding a *so*. |
| Ledger, empty | **This screen adds up** every rep you ever log **and tells you what it came to**. One session from now it starts being worth reading. | **Every rep you ever log adds up here.** One session from now it starts being worth reading. | "This screen…" narrates the screen you are already looking at, then says its job twice. |
| Backup | **Losing** this **loses** everything the app knows about you. The export is the only copy that survives **losing** the phone. | **This is** everything the app knows about you. The export is the only copy that survives **a lost phone**. | Three *los-* words in two sentences. |
| Backup, erase confirm | All 125 sessions, permanently. Export first if you **have not**. | All 125 sessions, permanently. Export first if you **haven't**. | Nobody says "if you have not" at 6:10am. |
| Home, first run | **First session. Session A to start.** | **Nothing logged yet.** | The panel 90pt below says SESSION A in 38pt type. Saying it twice is not orientation. |
| Home, session outline | Lateral raise **—** myo-reps | Lateral raise **·** myo-reps | The middot is already this app's separator everywhere else. |
| Review harness | Review only **—** the app returns to Home here. | Review only**.** The app returns to Home here. | Not shipped UI, but it is in the same files. |

---

## Part two — needs Eden's word, because he wrote them

These are **verbatim from the web build**, with the source line beside each.
`CLAUDE.md` rule 3 makes them not mine to change; his instruction says ALL text.
He settles it, line by line.

### The six in the workout, where an em-dash is most visible

| String | Source |
|---|---|
| No rest after this **—** straight into the next one. | `src/screens/Workout.tsx:211` |
| Done **—** start lifting | `src/screens/Workout.tsx:124` |
| Nothing will be saved **—** not even the sets you've already logged. | `src/screens/Workout.tsx:84` |
| First time **—** just go to failure | `src/components/RepDial.tsx:107` |
| at 6.25 kg **—** different weight now | `src/components/RepDial.tsx:92` |
| The 20-second rest IS the mechanism **—** don't stretch it | `src/program.ts:208` |

If he wants these changed, my suggestions, keeping the meaning exact:

- No rest after this. Straight into the next one.
- Start lifting
- Nothing will be saved. Not even the sets you've already logged.
- First time here. Go to failure.
- Different weight now. Last time: 12 at 6.25 kg.
- The 20-second rest IS the mechanism. Don't stretch it.

**"Done — start lifting" is the one worth arguing about.** It is a button, and
the "Done —" half says what tapping it does to the *warm-up*, which the button
already implies by existing. "Start lifting" says what happens next, which is
the useful half.

### The other 49

| File | Count | What they are |
|---|---:|---|
| `cards.json` | 21 | The study questions and answers |
| `Program.swift` | 14 | Exercise cues and sub-labels |
| `guide.json` | 10 | The nine Guide entries |
| `Celebration.swift` | 4 | Celebration tier bodies |

These are not chrome. They are the training program and the things he wrote to
read at 6am, and an em-dash inside a sentence about flor yeast is doing ordinary
punctuation work. **Recommendation: leave them.** The dash is a problem where it
stands in for a full stop in a two-word UI string, not where it introduces a
clause in prose he wrote deliberately.

---

## On "sounds AI generated"

The tell is register, not vocabulary: hedged, balanced, faintly promotional,
every sentence the same length. I read every string in `Screens/` aloud looking
for it. The seven above are what I found — and the pattern in them is not
hedging, it is **narrating the screen you are already looking at** ("This screen
adds up…"), and **saying the same thing twice in different words** ("First
session. Session A to start.", "loses / losing / losing").

The rest of the app's copy states one fact per sentence and stops, which is the
register the product asked for and mostly already had.

## Not covered here

Accessibility labels. There are 23 of them, they are never seen, and VoiceOver
phrasing follows different rules from visible copy. Worth its own pass if the
app is ever used with VoiceOver; not worth folding into this one.

---

## Part two, done — Eden chose "all 59, everywhere" (2026-08-23)

Every em-dash in user-facing copy is gone. Forty rewrites, applied to **every
file that carries each string at once** so the iOS app, the port's content
sources, the golden test fixtures, the web build and the prototype cannot drift
apart:

`Program.swift` · `Celebration.swift` · `Week.swift` · four screens ·
`cards.json` · `guide.json` · `MorningTests/Fixtures/{compiled-steps,program}.json` ·
`ios-port/content/*.json` · `src/program.ts` · `src/lib/{cards,celebration,week}.ts` ·
`src/screens/Workout.tsx` · `src/components/RepDial.tsx` · `prototype/index.html`

**The rule I applied:** replace the dash with the punctuation the sentence
actually wanted, and keep every other word. A dash was standing in for a full
stop, a colon or a pair of commas; picking the right one is a smaller change
than rewriting, and it keeps his voice.

**En-dashes stay.** "8–15 reps", "4–5s", "20–80%", "+1–1.5 kg" are number
ranges and a hyphen there would be wrong. He objected to em-dashes; these are a
different mark doing a different job.

### The changes

| Where | Before → After |
|---|---|
| Warm-up cue | 10 towel dislocates **—** grip a towel wide → **:** grip a towel wide |
| Overhead press cue | Shoulder insurance **—** don't skip it → **.** Don't skip it |
| Push-up sub | deficit **—** hands on books → deficit**,** hands on books |
| Myo cue | The 20-second rest IS the mechanism **—** don't stretch it → **.** Don't stretch it |
| Floor fly cue | Elbows slightly bent and locked there **—** a fly, not a press → **:** a fly |
| Superset line | No rest after this **—** straight into the next one. → **.** Straight into |
| Warm-up button | Done **—** start lifting → **Start lifting** |
| Discard warning | Nothing will be saved **—** not even → **.** Not even |
| Rep control | First time **—** just go to failure → **First time here. Go to failure** |
| Rep control | Last time: 12 at 6.25 kg **—** different weight now → **Different weight now.** Last time: 12 at 6.25 kg |
| Week nudge | Train today or the week's gone **—** 3 left → **.** 3 left |
| Week nudge | you still make 5 **—** but you'd need → 5**,** but you'd need |
| Celebration, 2 weeks | becoming a habit **—** and where most → habit**,** and where most |
| Celebration, 52 weeks | Nothing to add **—** just don't stop. → Nothing to add**.** Just don't stop. |
| Celebration, clean sweep | matched last time **—** every single one → **.** Every single one |
| Celebration, weight up | a fresh baseline **—** beat it next time. → **.** Beat it next time. |
| Guide ×4 headings | Protein **—** 120 g/day → Protein**:** 120 g/day (and Calories, Creatine) |
| Guide ×5 bodies | dash → full stop, colon or comma as the clause wanted |
| Cards ×16 answers | dash → full stop, colon or comma as the clause wanted |

**The weight-changed line is the one that changed most, and for a reason
beyond punctuation.** It read "Last time: 12 at 6.25 kg — different weight now",
which buries the important part at the end. The important part is that the
comparison does not hold. It leads now.

**"Done — start lifting" lost half of itself.** The "Done —" said what the
button does to the warm-up, which a button does by existing. "Start lifting"
says what happens next.

### One left, deliberately

`cards.json` still contains one em-dash: *"The study deck. Port verbatim — the
copy is the product."* It is the file's own header note, not a card. Nobody
sees it.
