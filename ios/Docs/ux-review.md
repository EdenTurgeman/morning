# UI/UX review — W14

Every figure here was measured on a rendered frame with
`ios/Tools/measure-layout.py`, not read off the source. That tool scans a
screenshot for horizontal bands carrying content and reports each band's height
and the gap above it, in **points** — the units the design system is written in,
rather than the 3× pixels a screenshot flatters everything with.

Reproduce any row below with:

```bash
python3 ios/Tools/measure-layout.py ios/build/ux/<screen>.png
```

Screens captured at the six-month seed unless noted.

---

## 1. Empty space

Eden named this first, and it is the largest single pattern in the app. Six of
the ten screens carry a void of 190pt or more.

| Screen | Largest gap | Share of the 874pt screen |
|---|---|---|
| **Backup** | 369pt | 42% |
| **Ledger** | 309pt (trailing, nothing below it) | 35% |
| **Summary** | 307pt | 35% |
| **Warm-up** | 192 + 190pt, either side of the clock | 44% combined |
| **Rest** | 166 + 170pt, either side of the ring | 38% combined |
| **Home** | 202pt | 23% |

**They are not all the same problem.** Three kinds:

**a. A focal object floating in the middle** — Rest and Warm-up. The rest ring is
237pt of content with ~168pt of air on each side, and that is close to correct:
one object, centred, nothing competing. The warm-up is the same shape with a
much smaller object — a 68pt clock with 190pt above and below it — and there it
reads as unresolved rather than composed, because the clock is not big enough to
hold the middle of a screen on its own.

**b. Content top-aligned, action bottom-pinned, void between** — Home, Summary,
Backup. Pinning the primary action low is right and deliberate: the phone is in
one hand and the thumb reaches the bottom third. The void is the cost of that,
and at 202pt (Home) it is acceptable; at 369pt (Backup) it is not, and it leaves
"Erase everything" stranded alone at the very bottom of an empty screen.
`04-rules.md §8` asks for erase to be "visually de-emphasised", which it is —
but *isolated in a void* is a different thing from de-emphasised, and it
arguably draws the eye rather than releasing it.

**c. Content simply stops** — Ledger. 309pt of nothing below the last row, with
no bottom-pinned action to justify it. This is the weakest of the three: the
screen ends and then continues for another third of its height.

---

## 2. Cramped space

Only one screen is tight, and it is the one that has to be.

`-screen set -slot 4.0.0` is the worst content in the program — four cues and a
long name. Measured, its bands run: 30pt name, 54pt metadata, 114pt cue block,
83pt rep control, 68pt button, with gaps of **8, 9, 12, 12, 15, 15, 15, 19pt**
between them.

It fits, and nothing scrolls, which is the rule. But every gap on that screen is
under 20pt where the ordinary Set screen breathes at 29–56pt. The cue block
absorbs the difference. **Nothing to fix — but this is the layout that breaks
first**, and any addition to the Set screen has to be checked here rather than
against the ordinary case.

---

## 3. Undersized text — **the first pass of this section was wrong**

I derived font sizes from measured band heights, and band height does not tell
you font size. "2×2.5 + 1×1.25" measures 10pt and "Last: A, yesterday · 209
reps" measures 12.3pt, and **both are `TypeScale.body`** — the difference is
that one line has descenders and the other has none. A `caption2` line without
descenders and a `subheadline` line without descenders measure the same.

So `measure-layout.py` answers "where is the content and how much air is around
it", which is what sections 1 and 2 rest on, and it cannot answer "is this type
too small". Corrected below by reading the scale directly instead.

**What the type scale actually is**, and where each size lands:

| Token | Font | Used for |
|---|---|---|
| `counter(_:)` | fixed 34–92pt | rep counts, clocks, the tonnage headline |
| `title` | fixed 34pt | exercise names, screen headlines |
| `body` | `.subheadline` (15pt) | every sentence in the app |
| `question` / `answer` | fixed 17 / 14.5pt | study cards |
| `label` | `.caption` (12pt) | chrome — Back, End, screen titles |
| `microLabel` | `.caption2` (11pt) | eyebrows, units, the week meter, nav links |

**The finding that survives**, now stated properly: `microLabel` at 11pt is
carrying more than an eyebrow font should.

- **The four Home nav links** — History, All time, Guide, Backup — are
  `microLabel`, 11pt. Their tap targets are a correct 44pt (`Hit.minimum`), so
  this is legibility rather than reachability, but 11pt is the smallest text in
  the system and these are the only way into four of the app's ten screens.
- **The week meter's labels and the streak line** are `microLabel` too. "9 weeks
  running · best 16" is the one number on Home that rewards a glance.

**Withdrawn from the first pass**, having checked the source rather than the
pixels: the plate breakdown and the Ledger stat rows are both `body` (15pt), not
11pt. They are the same size as every other sentence in the app and there is
nothing wrong with them.

**Not a finding:** the counters, titles and headlines are 34–92pt and sized
against the 1.5 m reading distance. Those are right.

---

## 4. What is already good, so nobody re-opens it

- **The Set screen's ordinary state.** Bands throughout, gaps 8–56pt, no void,
  everything on one screen, nothing scrolling. It is the most constrained layout
  in the app and the best-composed one.
- **History.** 15pt gaps between rows, 25pt rows, a rule between each. Dense
  without being tight, and it scrolls, so length is not a constraint.
- **Guide.** Paragraph blocks of 120–182pt separated by 35pt, headings at 14–18pt.
  Correct reading rhythm.
- **Hit targets.** Every control checked carries `Hit.minimum` (44pt) or larger;
  the rep steppers are 82pt and the primary buttons 68pt.

---

## 5. Fixed in this round

- **Backup now leads with its status.** `AppData.lastBackup` was in the schema,
  in every seed and in the web build's own writer, and this port never wrote it
  and never showed it — so the one screen whose entire job is "do you have a
  copy" could not answer the question. It says "Never backed up." / "Backed up
  today." / "Last backup N days ago." against a coloured rule, and exporting
  stamps the date. That is a completeness gap that happened to be found by a
  layout measurement.
- **Erase everything sits under a hairline.** The distance from Export is the
  safety mechanism and it stays; what changed is that the control now reads as
  the last *section* rather than as something orphaned at the foot of a void.
- **The Ledger closes with the run** — "9 weeks running. Longest run 16 weeks."
  Ported from `src/screens/Ledger.tsx`, which the port had dropped. It is the
  right thing to end a lifetime page on, and it was the only void in the app
  with no action to justify it.
- **The warm-up's clock follows its cues.** 192pt above and 190pt below became
  52pt above and one void below, where it pays for the bottom-pinned button like
  every other screen. The two things you read there — what to do, how long — now
  read as one instruction.
- **`Semantic.danger` exists.** `02-design-brief.md §6` asks for semantic colours
  for success *and destruction*; success had a token and destruction did not, so
  `HistoryScreen` carried the value inline and Backup had nothing to say "never
  backed up" with.

## 6. Ranked, still open

1. ~~**`microLabel` at 11pt on Home's four nav links.**~~ **Fixed** — lifted to
   `label` (12pt). Still the quietest thing on the screen, still one line with
   room to spare, but no longer the floor of the whole type system on the only
   route into four screens.
2. **Home's 202pt gap** — real, but the least wrong of the six, because the low
   primary action is buying something with it.
3. ~~**Summary's 307pt gap.**~~ **Closed by measuring it properly.** That figure
   was taken three seconds in, before the card answer arrives. After the reveal
   the answer occupies 112pt and the gap is **179pt** — the same range as Home,
   already judged acceptable. The first measurement was the same mistake as
   section 3: a number taken before checking what it was a number *of*.

Rest's spacing is deliberately excluded: measured it looks like the same
problem, but a single 237pt focal object centred in the screen is the one case
where the air is the composition.
