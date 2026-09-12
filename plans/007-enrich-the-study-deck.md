# 007 — Research and enrich the study deck

- **Status**: TODO
- **Commit**: 259f47e
- **Owner**: a dedicated content agent. **This is its only job.**
- **Scope**: `ios/Morning/Resources/Content/cards.json` — **and nothing else**

## Who this is for

One person. Eden, who uses this app alone at 6:10am. His level, in his words:

> "My level is Level 2 WSET sommelier, and i'm a hobbiest tea guy who visited
> china and taiwan and bought and drank and experienced a lot of tea and i'd
> like to come closer to knowing level 2 WSET and move on to Level 3, and move
> closer to being a tea sommelier. so i need a hybrid amount of facts, i need to
> understand key words processes, regions and then more advanced stuff."

Read that as two different jobs:

- **Wine** — he holds WSET Level 2. The deck should *consolidate* that until it
  is genuinely solid, then reach deeper. Deeper means the questions stop being
  "what" and start being "why, and what follows from it": why a grape behaves as
  it does in a given climate, what a winemaking choice costs as well as buys,
  how a classification actually constrains a producer. **The levels are a
  measure of depth, not a syllabus to complete** — see "What he is actually
  doing" below.
- **Tea** — no formal qualification, but real palate experience from China and
  Taiwan. He needs the **vocabulary and the framework** he never got formally:
  the words for processes he has tasted, the regions he has drunk from, the
  chemistry underneath. Then the advanced material a tea sommelier would hold.

**A hybrid across levels, not a curriculum in order.** He is not working through
a syllabus front to back; the deck draws at random during rests. Any given card
must stand alone.

## What the deck is, and the constraint that shapes every card

A card appears on a rest of 45 seconds or more, twice a session, plus one on the
Summary. **It is a rest filler.** He is between sets, breathing hard, phone on
the floor, and the answer auto-reveals after 6.5–11 seconds whether he has
engaged or not.

So:

- **Every card teaches a MECHANISM, not a lookup.** This is already the deck's
  stated rule: *"Why is Fino fortified to about 15% and Oloroso to about 17%"*
  rather than *"what abv is Fino"*. A fact he can look up; a mechanism he can
  reason from at a tasting.
- **Answers are 190–290 characters.** The 27 existing cards sit in that band and
  it is not an accident — it is what can be read in a rest. Stay in it.
- **Every `q` must be phrased as a question and end with `?`.** There is an
  acceptance test.

## The file format

`ios/Morning/Resources/Content/cards.json`. A factoid:

```json
{
  "id": "t-oxidation-vs-roast",
  "subject": "tea",
  "topic": "Processing",
  "q": "What is the difference between oxidation and roasting?",
  "a": "Oxidation is enzymatic and happens to the fresh leaf: it is the process that turns green tea into black. Roasting is applied heat after processing is finished: it caramelises sugars and drives off moisture, and it can be repeated years later to revive a stored tea."
}
```

A question is the same object plus two keys:

```json
{
  "id": "w-madeira-estufagem",
  "subject": "wine",
  "topic": "Fortified",
  "q": "Madeira is deliberately heated during production. What does that heating buy?",
  "options": [
    "It kills the yeast to stop fermentation",
    "It makes the wine effectively indestructible once opened",
    "It concentrates the sugars by evaporation",
    "It removes the fortifying spirit's harshness"
  ],
  "correct": 1,
  "a": "Estufagem cooks the wine, oxidising and caramelising it on purpose. Because that damage has already been done deliberately, air and time can do very little more to it: an open bottle keeps for months where a table wine keeps for days."
}
```

Rules the code enforces, with tests behind them:

| Rule | Why | Test |
|---|---|---|
| `id` unique across the whole deck | It is the mastery key | `testEveryCardIdIsUniqueAndEveryCardIsAQuestion` |
| `q` ends with `?` | Every card is phrased as a question | same |
| `a` and `topic` non-empty | — | same |
| **Exactly 4 options**, `correct` in 0...3 | Anything else silently degrades to a factoid | `testAMalformedQuestionFallsBackToAFactoid`, `testEveryShippedQuestionIsWellFormed` |
| Adding a card is a **ONE-LINE APPEND** — no registry, no count constant, no enum | A deck that needs two edits will eventually get one | `testAddingACardRequiresExactlyOneEdit` |

`subject` is `"wine"` or `"tea"`. `topic` is free-form and shows as the card's
masthead label — keep them short, one or two words, and **reuse the existing
topics** where one fits rather than inventing a synonym.

## TEACH THE WORD BEFORE YOU LEAN ON IT

Eden, on group one's kill-green question:

> "the question assumes i know what 'kill-green' this is exactly the type of
> stuff i want the app to teach me, not assume that i know, we can have the kill
> green question but only if we have a question that tells me what kill green
> is"

**This is the most important rule in this brief.** He is using the deck to
acquire vocabulary he does not have. A card that spends a term he has never met
teaches him nothing except that there is something he does not know.

The line, precisely:

- **A gloss in place is fine.** `t-plucking-standard` writes *"kai mian cai,
  open-face picking of three or four mature leaves"* — the term arrives with its
  meaning attached, in the same breath. `t-steaming-depth` does the same for
  *fukamushi*, and `t-theanine-shade` for theanine and catechins. All correct.
- **A setup clause is NOT fine.** `t-shaqing` opens *"Kill-green stops oxidation
  with heat. Why is it a dial rather than a switch?"* — it asserts the term and
  then asks something harder about it. The reader who does not have the word
  cannot get past the first sentence.

So: **if a card leans on a term, either gloss it in the same answer, or write
the definition card in the same group.** Never assume a term the deck has not
taught. When in doubt, write the definition card — a deck of 200 has room, and
the foundational cards are the ones he actually asked for.

### Debt from group one, to be paid FIRST in group two

These are already in the deck and are currently unsupported. Write them before
anything else:

1. **Kill-green (shaqing)** — its own card. What it is, where it sits in the
   process, and that pan-firing and steaming are two ways of doing it. This is
   the one Eden named.
2. **Maocha** — used in `t-shaqing`'s answer with no gloss at all, which is
   worse than kill-green: there is not even a setup clause. Either give it a
   card or, if it does not earn one, rewrite that clause to say what it means.
   **This is the single exception to "do not edit existing cards"** — you may
   change that clause in `t-shaqing`'s answer, and nothing else.
3. **TCA** — `w-corked` uses the acronym without ever expanding it. A gloss in
   a new faults card is enough; it does not need one of its own.

## What he is actually doing, and how to write for it

**He is not preparing for an exam.** His words, and they change what a good card
is:

> "i'm not preparing for an actual exam i'm looking to expand my knowledge,
> think about how best i can study through this"

WSET Level 2 and Level 3 are useful in this brief as **markers of depth** — how
far into a subject a card reaches — and for nothing else. There is no syllabus
to complete and no coverage target to hit. Do not write a card because an exam
would ask it.

What follows from that:

### 1. A card should land on something he can perceive

This is the single most useful test of a card, and it is what separates
knowledge from trivia. **Does it change what he notices in a glass or a cup?**

- *"Estufagem cooks the wine, oxidising and caramelising it on purpose. Because
  that damage has already been done deliberately, air and time can do very
  little more to it"* — he can act on that the next time he finds a half-drunk
  bottle of Madeira.
- A card ending in an inert fact — a date, a percentage, a hierarchy of names —
  gives him nothing to do. Those are the cards to cut when the character band
  bites.

Where a mechanism has a perceptible consequence, **say the consequence**. That
is what makes it stick and what makes it worth knowing.

### 2. Prefer mechanisms that explain the most

One mechanism that generates twenty observations beats twenty facts. Oxidation
versus roasting, kill-green as a dial, sugar ripeness outrunning phenolic
ripeness, temperature as a selective solvent — each of those pays out across
dozens of teas or wines he will meet. Reach for those before reaching for
another region's rules.

### 3. Lean toward questions

Being asked and having to retrieve an answer is itself the learning; reading a
statement is not. **The half-and-half split in this brief is a floor for
questions, not a ceiling.** Where the material supports a genuine question, ask
one.

### 4. Do not try to sequence anything

The app draws at random and tracks what he keeps missing, so spacing and
interleaving are already handled.

**Write each card to stand completely alone, and watch for the words that break
that.** A card is never read next to the card you wrote beside it. Group four
caught one of its own ending *"Here the date really is a price ladder"* — the
"here" contrasted with a different card about Japanese naming, so under a random
draw it read as half a thought with the other half missing. Any of these is the
same bug: *here*, *unlike that one*, *as we saw*, *the other method*,
*mentioned above*, *by contrast*. If a card needs a comparison, put both sides
inside it.

## Question craft, borrowed from the people who do it professionally

The *purpose* above is his; the *craft* below is worth taking from wine
education, which has spent decades on how to ask a good question. **Take the
craft, write your own cards.** Do not lift question text from a study site or
question bank — theirs are built for a fifty-question written paper with five
options and a syllabus behind it, and yours is read off the floor in a rest with
four options and 290 characters. A copied question is the wrong shape even when
it is the right fact.

| Style | What it tests | Use it here? |
|---|---|---|
| **Single best answer** — one option fully right, others partly right | Precision; telling vague correctness from complete accuracy | **The workhorse.** Default to this |
| **Definition and terminology** | Vocabulary, with similar-sounding terms as distractors | **Yes** — this IS the teach-the-word rule as a question |
| **Comparative** — two styles, methods or regions | The distinction between them; distractors blur it with secondary characteristics | **Yes.** The deck already does this well: Yiwu vs Bulang, sheng vs shou |
| **Scenario / applied** — a situation, then a cause and effect | Reasoning rather than recall; distractors address the topic but not the problem posed | **Yes, and this is the deep shape.** Use it for the harder half |
| **Straight factual recall** | Core facts | **Sparingly.** Mechanism over lookup, always |
| **"All of the following EXCEPT"** | Comparative thinking by elimination | **NO.** The exams use it; this app does not. At 6:10am under load a negation is a trick rather than a test |
| **Combination (i, ii, iii, iv)** | Several facts at once | **NO.** Four short options read at arm's length cannot carry it |

### What makes a card deep rather than obscure

The most useful thing wine education has settled: at the introductory level the
wording is direct and tests core knowledge, while deeper in, **the difference
between the right answer and a wrong one comes down to a single phrase.**

So a hard card is not one about a more obscure subject. It is one where the
distractor is wrong **by one clause** — right mechanism, wrong consequence;
right region, wrong reason. That is also what makes getting it wrong teach
something, which is the whole argument for tempting distractors. A distractor he
can dismiss without thinking taught him nothing; one he has to reason past
sharpens the model.

## Sources

- **Wine**: WSET Level 2 and 3 material and the free practice banks built around
  it; GuildSomm; Court of Master Sommeliers study guides; regional consorzio and
  appellation bodies for what a classification actually binds a producer to.
- **Tea**: there is **no open question bank**. ITMA's Certified Tea Sommelier
  examination is 100 questions drawn from manuals issued on registration and is
  not public. So take the *curriculum shape* from ITMA and the International Tea
  Academy, and the facts from reference sources — the six processing categories
  and the regions and producers behind them (`chinesetea.life` is a reference
  wiki, not a quiz), producer and association material, and the tea-chemistry
  literature for anything about compounds.
- **Where a fact is contested, say so or leave the number out.** Group three's
  sherry card teaches the solera mechanism and carries no figure, because
  sources disagree on the maximum annual draw. That is the standard.

## Writing the four options

This is the part that is easy to do badly. The right answer is inked as a solid
black block; a wrong pick is **struck through in red** and stays on screen. So:

- **All three distractors must be genuinely tempting.** They should be things a
  reasonable L2 candidate might believe — common misconceptions, adjacent
  mechanisms, half-truths. Filler options make the card free and teach nothing.
- **The distractor is where the teaching happens.** The best questions here are
  ones where getting it wrong tells you something specific about what you had
  confused.
- **Keep options to one line where possible**, two at most. They are rendered at
  64pt minimum height in a card he reads at arm's length.
- **No "all of the above", no "none of the above", no negations** ("which is
  NOT…"). At 6am, under load, a negation is a trick rather than a test.
- Vary which index is correct. Do not let the answer cluster at 1.

## Voice

The app's rules apply to card text:

- **No em-dashes.** Eden asked for every one of them gone across the app, and
  they were removed in W16. There are 2 left in this file; remove those too
  while you are in here. Use a colon, a full stop, or a comma.
- **No copy that sounds generated.** No "delve", no "it's important to note",
  no "unlock", no rhetorical questions inside answers.
- **Nothing congratulatory.** This app is not gamified and never will be. An
  answer states what is true and stops.
- Existing card text is **Eden's own writing, ported verbatim, and not yours to
  reword.** You are the author of NEW cards only. The one exception is the two
  em-dashes.

## Coverage to aim for

The deck is 27 cards today: 15 wine, 12 tea, and exactly **one** question. That
last number is the real gap — the mastery tracking and the whole Summary line
exist and have almost nothing to work on.

**Target: 200 cards, roughly half of them questions.** Balance wine and tea near
evenly. The deck holds 47 after group one, so that is ~153 still to write.

**Work in groups of 20.** Eden's instruction, and the reason it matters is that
voice drifts: twenty cards can be read and corrected, two hundred cannot.
**Write the first 20 and STOP for review.** Do not continue to the second group
on your own — the next group is dispatched once the first has been read.

**Mix the levels freely.** Eden: *"i don't want any difficulty level reading,
just mix em up."* Do not sort by difficulty, do not group foundational cards
together, and do not add a field for it. A group of 20 should span the whole
range, from a word he needs to know to something that would stretch an L3
candidate — because the deck draws at random and every card has to stand alone
anyway.

Existing topics, to reuse rather than duplicate:

- **wine** — Acidity, Burgundy, Climate, Fortified, Germany, Labelling, Oak,
  Port, Rioja, Sparkling, Structure, Tasting, Viticulture, Winemaking
- **tea** — Altitude, Brewing, Green tea, Oolong, Processing, Puerh, Storage,
  Terroir, Tieguanyin, Water, White tea

Gaps worth filling, given the two jobs above:

- **Wine, consolidating L2**: the major regions he must know cold (Bordeaux,
  Loire, Rhône, Piedmont, Tuscany, Douro, Mosel, Rioja, Champagne), the
  principal grape varieties and what climate does to each, food-and-wine
  principles, service and storage.
- **Wine, reaching toward L3**: soil and site rather than region alone;
  vinification choices and their trade-offs (malolactic, lees, whole-bunch,
  extraction, oak format and age); classification systems and what they actually
  bind a producer to; faults and their causes; the mechanics of ageing.
- **Tea, the framework he lacks**: the six classes and what actually separates
  them, kill-green and its methods, withering, rolling, oxidation vs
  fermentation vs ageing, roasting, the cultivar question, plucking standards
  and their vocabulary.
- **Tea, regional depth he has tasted but not named**: Wuyi and the yancha
  ranks, Anxi, Phoenix Dancong and its aroma types, Yunnan and puerh's mountains,
  Taiwan's altitudes and Dong Ding vs Alishan vs Lishan, Japanese steaming
  grades.
- **Tea, advanced**: water chemistry and its measurable effect, brewing ratio
  and temperature as levers rather than recipes, storage and post-fermentation,
  grading vocabulary, the chemistry behind astringency and umami.

## Before you write a single card: read the ledger

`plans/007-covered.md` lists **every question already in the deck**, grouped by
subject and topic. It is regenerated before each group is dispatched.

**Read the answers in it, not only the questions.** A stem tells you what a card
asks; only the answer tells you what it *teaches*, and teaching the same thing
twice is the duplication that matters. Group five lost three good cards to this:
an existing card had already spent their mechanism inside its answer as a
contrast clause, invisible from the stem.

Read it first, and do not re-teach anything in it. The deck is filled by a
series of agents who cannot see each other's work, so this file is the only
thing standing between you and writing a card somebody already wrote. A near
duplicate is worse than a gap: it wastes one of the two cards he sees in a
session, and the rotation draws without replacement so it crowds out something
he has not met.

Regenerate it yourself if you want to check your own work as you go:

```bash
python3 ios/Tools/check-deck.py --ledger
```

That script also runs the mechanical checks the acceptance suite cannot — the
answer length band, em-dashes, and correct-index clustering. **Run it before you
report.** It exits non-zero if anything is wrong.

It also prints an **ADVISORY** list: terms spent in a question stem or an option
with no gloss beside them, and rare enough in the deck that they are not
established vocabulary. That is the teach-the-word rule, aimed rather than
enforced — the rule needs judgement and a script cannot supply it. Three groups
running, **every agent has found violations in its own draft by re-reading all
twenty cards by hand, and every one was invisible to tooling.** Do the re-read.
The advisory tells you where to look first; most of what it lists will be fine.

## Save as you go

**Research and append in batches of about five cards, not twenty. Your first
append should happen early — do not research more than about five cards before
writing anything to the file.**

Group four's first attempt was killed by an API rate limit after it had
researched all twenty cards and before it had written a single one. Every bit of
that work was lost, and the deck was byte-identical to where group three left
it. A long research phase followed by one big write is the worst shape for a job
that can be interrupted, and this one can.

Five at a time also means the mechanical checks run against real content early,
so a systematic mistake — a length band you have been overshooting, an id
convention you got wrong — surfaces on card five rather than card twenty.

**This has now happened twice**, and the second time the instruction to batch
was already in this brief. The agent read it and still researched the whole
group before writing, because planning everything first feels like the tidy way
to work. It is not, on a job that gets killed. Write five, then think about the
next five.

## Boundaries

- **Touch `cards.json` and nothing else.** Not `Deck.swift`, not `Cards.swift`,
  not any screen, not the tests. If you believe the schema needs a new field,
  STOP and say so rather than adding one.
- Do not reword, retopic or delete any existing card. **One exception**, named
  above: the `maocha` clause in `t-shaqing`'s answer may be rewritten to gloss
  the term. Nothing else in any existing card.
- **Do not add a difficulty or level field.** Ruled on directly by Eden. The
  deck draws at random and nothing reads such a field; adding one would be a
  change to the app, not to the deck.
- Do not exceed the answer length band. A card that cannot be read in a rest is
  a card that teaches nothing.

## Verification

```bash
./scripts/verify-ios.sh
```

Seven phases, all PASS, and the assertion count must not drop. The study deck
tests are the ones that matter here — they check id uniqueness, the `?` rule,
question well-formedness, and the one-line-append promise.

Then look at one on screen, because a card that reads fine in JSON can still
overflow its sheet:

```bash
./scripts/shoot.sh rest-card --keep -card <id> -expand-after 1.2
./scripts/shoot.sh rest-card --keep -card <id> -answer 0     # a wrong pick, struck through
```

**`-expand-after` is not optional.** Plain `-card <id>` renders the card
COLLAPSED — you get "Tap to answer" and no options at all, so a screenshot
without it proves nothing about whether your options fit. Group eight found this
the hard way.

Check: the four options fit without the sheet running into the buttons, and the
prose answer fits under them once revealed.

**Done when**, for the group you were asked to write: 20 new well-formed cards,
about half of them questions, wine and tea near evenly balanced, levels mixed
rather than sorted, `verify-ios.sh` green with the assertion count not dropping,
and the longest question you wrote rendering inside its sheet.

Then **stop and report** — what you added, what you deliberately left out, and
anything in this brief that fought you. The next group is a separate dispatch.


---

## Progress — CLOSED at 200 on 2026-09-05

| Group | Cards | Deck after | Questions | Notes |
|---|---|---|---|---|
| 1 | 20 | 47 | 11 | Surfaced the strike-through defect on two-line options |
| 2 | 20 | 67 | 22 | Paid the vocabulary debt: `t-killgreen`, `maocha` glossed, `TCA` expanded |
| 3 | 20 | 87 | 32 | Reported that the teach-the-word rule is invisible to tooling |
| 4 | 20 | 107 | 42 | Grapes and the New World; two rate-limit kills before it landed |
| 5 | 20 | 127 | 56 | Found the ledger's stem-only listing was hiding collisions |
| 6 | 20 | 147 | 70 | Its re-read caught two factual errors the tooling passed |
| 7 | 20 | 167 | 84 | Wrote the unspent half of six colliding leads |
| 8 | 20 | 187 | 98 | Sixteen defects caught by hand, none by tooling |
| 9 | 10 | 197 | 107 | Killed by a rate limit, but saved as it went |
| 10 | 3 | **200** | **110** | Closed at 100 wine / 100 tea |

**Final state**: 200 cards, 100 wine / 100 tea, 110 questions, 85 topics,
correct-index spread 27/28/27/28, every answer inside 198–290 characters, no
em-dashes, no duplicate ids. `verify-ios.sh` green at 80 assertions.

**Every group was verified independently** rather than on its report: card
counts, malformed questions, duplicate ids, the `?` rule, the length band, and
which pre-existing cards changed. Across ten groups **exactly one pre-existing
card was ever edited** — `t-shaqing`, to gloss `maocha`, which was sanctioned.

### What ten cold agents taught about running this

- **The tooling never once caught a teach-the-word violation.** Every group
  found its own by re-reading its cards by hand; group eight found sixteen that
  way, including a distractor that half-agreed with its own key. The advisory in
  `check-deck.py` aims that re-read and cannot replace it.
- **The ledger had to carry ANSWERS, not stems.** Until group five it listed
  questions only, and groups were writing cards whose mechanism an existing
  answer had already spent as a passing clause. Invisible from the stem, and the
  most common reason a planned card died from group five onward.
- **Save as you go, and start by writing.** Three dispatches were killed
  mid-flight; the two that had front-loaded their research lost everything, and
  the one that had been batching lost three cards.
- **A group's leads for the next group go stale.** Group eight handed on four
  leads that were already in the deck. Trust the ledger, not the handover.



---

## Calibration review at 200 cards — 2026-09-05

Measured on the finished deck, not sampled by impression.

### The brief's founding rule fought Eden's stated need

**Six of 200 cards are definitional** — five tea, **one wine**. The rest teach
mechanisms.

That is a direct miss against what he asked for: *"i need to understand key
words processes, regions and then more advanced stuff."* Key words came first in
his sentence and last in the deck.

The cause is in this brief. Its founding rule, inherited from `Cards.swift`'s
own header, is *"every card teaches a MECHANISM, not a lookup"* — and every
dispatch restated it. That rule is right for depth and it is why the deck is
good. But repeated eleven times with nothing pulling the other way, it starved
the vocabulary layer he explicitly wanted. The teach-the-word rule compensates
in part, because terms now arrive glossed — but **a term glossed inside a
mechanism card is not a card that tests whether he knows the term.**

**Fix**: a vocabulary group, weighted to wine, of cards that are frankly
definitional. Not lookups of numbers — definitions of the words he will meet on
a shelf and in a tasting note.

### Fortified wine is 15% of the wine half

Fortified 7, Port 5, Sweet wine 2, Jerez 1 = **15 of 100 wine cards**, against
Burgundy's 3 and Bordeaux's 5.

Nobody chose that. Fortified wine has unusually tidy mechanisms — solera,
estufagem, mutage, flor, PX, the fortification point — and tidy mechanisms are
what this brief asks for, so eleven independent agents each reached for them.
**A rule that rewards a shape will over-select whatever has that shape.**

### Breadth without depth on the wine side

**35 of 53 wine topics hold exactly one card**: Zinfandel, Gewurztraminer,
Cahors, Jura, Albariño, Viognier, Merlot, each a single card. For a reader
consolidating Level 2 and reaching past it, the classics should outweigh a
one-card tour of everything.

### Everyday use is thin where it matters most

Wine: Food 1, Tasting 2, Service 2, Storage 1 — **6 of 100**, on the material he
uses every single time he opens a bottle and the highest-perceptibility content
in the subject. Tea is better served here only because Brewing (7) and Storage
(5) are core to how tea is made at all.

### Tea skews to China and Taiwan

Puerh 8, Wuyi 5, Tieguanyin 4, Taiwan 4 against Darjeeling 1, Assam 1, Ceylon 1,
Kenya 1, Nepal 1. **This one may be correct** — it matches where he has actually
drunk and bought, and meeting him there is a reason, not an accident. Recorded
so a later group decides deliberately rather than drifting.


---

## State at 300 — 2026-09-06

**300 cards, 157 wine / 143 tea, 210 questions**, correct-index spread
53/53/52/52, every answer inside 198–290, no em-dashes, no duplicate ids.
`verify-ios.sh` green at 84 assertions.

Groups 11 to 15 were corrections rather than top-ups, driven by measurement
rather than by what felt missing:

| | before | after |
|---|---|---|
| everyday **wine** (Food/Tasting/Service/Storage) | 6 of 100 | 18 of 157 |
| everyday **tea** food and tasting | Food 1, Tasting 4 | Food 6, Tasting 7 |
| Italy | 5 | 10+ |
| Burgundy | 3 | 6 |
| Spain | 1 | 6+ |
| fortified family | 15 of 100 (15%) | 15 of 157 (10%) |
| Japan / Taiwan | 4 / 4 | 8 / 7 |

**Fortified was never cut, only diluted.** It stayed at 15 while the deck grew,
which is the right way to fix an over-weighting that nobody chose.

**Yellow tea stays at 2, deliberately.** Three separate groups looked for an
unspent mechanism and none found one. Recorded so a fourth does not pad it.

### The two things that would have gone wrong unattended

- **Group 12 was killed by a rate limit after writing all 20 and before
  reporting.** Its cards were never hand-re-read, and one of them taught a
  contested claim as settled — that co-fermented Viognier fixes Syrah's colour,
  with "it dilutes it" struck through as false. Research says the reverse. It
  was found only because the supervising session re-checked a card an earlier
  group had explicitly refused to write.
- **Group 15 was killed during its final verification**, after writing and after
  applying its own edits. Verified from the supervising session instead: 300
  cards, nothing from before it modified, suite green.

**A group's own report is not the check.** Every group was verified
independently — counts, malformed questions, duplicate ids, the length band, and
which pre-existing cards changed — and across fifteen groups exactly one
pre-existing card was ever edited, which was sanctioned.
