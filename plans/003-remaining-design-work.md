# 003 — Remaining design work, in order

Opened 2026-08-30. Worked one at a time; each item verified before the next
starts. Status is updated in place as they land.

| # | Task | Who | Status |
|---|---|---|---|
| 1 | Live Activity → Paper | inline | **DONE** |
| 2 | §2.3 demotion: History list + Lifetime totals | inline | **DONE** |
| 3 | Study card → pasted ply | inline | **DONE** |
| 4 | Delete the dead Metal | agent | **DONE** |
| 5 | Warmer-voice copy pass | inline | **AUDITED — 3 lines proposed, nothing shipped** |
| 6 | `DESIGN.md` from the built world | agent | TODO |

## Why some of these are not dispatched to agents

Eden asked for agents. Four of the six need context that a cold agent would have
to re-derive and would probably get wrong:

- **the ink law** — three inks, one job each; orange is a MARK and never a
  glyph; the overprint means attention; `danger` is the one sanctioned exception
- **the measurement discipline** — every contrast figure measured on a rendered
  frame with `ios/Tools/measure-contrast.py`, never calculated, and the tool's
  zone rows are stale so its labels must be checked against the frame
- **the motion doctrine** — `01-motion-doctrine.md`, and the frequency gate that
  says most things must NOT animate
- **the port trap** — twice now, a prototype was approved for something it DREW
  and the port carried the palette while silently dropping the drawn thing
  (`Celebration.rays`, the crossing wipe, `SetStep.intense`)

Tasks 4 and 6 are genuinely self-contained — a deletion verified by the build,
and a document written from code that already exists — so those go to agents
with full packets.

**Builds contend.** `verify-ios.sh` and `shoot.sh` both drive `xcodebuild` into
`ios/build/dd`. Two of these running at once corrupt each other, which is the
other reason this is sequential rather than fanned out.


## Task 5 — the copy pass, audited

**The open item overstated the work.** Reading all eleven tiers against the two
decisions from `init` — *warmer voice only* and *on a bad morning the truth
leads and the warmth follows* — the existing copy already satisfies both.

The clearest case is the tier that matters most. `.done`, when you are down:

> **"Down on last time."**
> "Sleep, food and stress all show up here. One dip means nothing; three in a
> row means something."

Truth leading, warmth following, the number never softened. That IS the
decision, written before the decision was recorded.

Others already warm and specific: *"You moved it."*, *"You started. From now on
this screen tells you whether you beat the last one. That's the whole game."*,
*"Your previous best on A was 148. That's the number to beat now."*

### The three that read cold — PROPOSED ONLY, not applied

Content is Eden's voice and `CLAUDE.md` rule 3 keeps it out of an agent's
hands; §2.2 reopened celebration copy but that is a licence to propose, not to
rewrite unilaterally.

| Line | Reads as | Possible |
|---|---|---|
| `"Dead level."` | a verdict on a session where you matched exactly | "Matched, exactly." |
| `"Reps have stopped moving."` | clinical — **though this may be correct**: `spec.md` calls three identical sessions the most valuable output the app has, and a clinical register suits a signal that means *change the program* | leave it |
| `"Rest properly. The adaptation happens between sessions, not during them."` | an instruction with no warmth in the tier that celebrates a completed week | "You've done the week. Rest properly — the adaptation happens between sessions, not during them." |

**Recommendation: change at most the third, and leave the plateau alone.** The
one place this copy is deliberately cold is the one place coldness is the
message.
