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

## 3. Undersized text

The measured band height is roughly cap-to-descender, so a band of 8–10pt is a
`caption2`/`caption` font (11–12pt) and a band of 12–14pt is `subheadline`
(15pt).

**Where 10pt type is doing more work than 10pt type should:**

- **The plate breakdown on Home** — "2×2.5 + 1×1.25", measured 10pt. This is the
  instruction you follow while loading dumbbells at 6:10am, and it is set two
  steps smaller than the weight above it. It is arguably the single most
  actionable line on the home screen.
- **Every Ledger stat row** — Sessions, Reps, Time, Since, Session A, Session B
  all measure ~10pt. They are the substance of that screen and they are smaller
  than the navigation links on Home.
- **"Start A instead"** at 10pt. The secondary action, but still an action.
- **The four Home nav links** at 10.3pt. Their tap targets are a correct 44pt
  (`Hit.minimum`), so this is a legibility question, not a reachability one.

**Not a finding:** the counters, titles and headlines all measure 30–68pt and
are sized against the 1.5 m reading distance. Those are right.

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

## 5. Ranked

1. **Backup's 369pt void and its stranded Erase.** Worst offender, and the fix
   is compositional rather than a rewrite.
2. **Ledger stopping a third of the way up the screen.**
3. **The warm-up clock floating between two 190pt gaps.**
4. **The plate breakdown at 10pt**, given what it is for.
5. **Ledger stat rows at 10pt.**
6. Home's 202pt gap — real, but the least wrong of the six, because the low
   primary action is buying something.

Rest's spacing is deliberately excluded: measured it looks like the same
problem, but a single 237pt focal object centred in the screen is the one case
where the air is the composition.
