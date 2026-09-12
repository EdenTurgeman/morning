# 008 — Review the deck as a curriculum

- **Status**: TODO
- **Role**: an editorial reviewer, not an author. **You may rephrase, delete and
  replace.** Every agent before you was forbidden all three.
- **Scope**: `ios/Morning/Resources/Content/cards.json` — and nothing else

## Who this is for

One person, Eden, who studies during the rests of a twenty-minute morning
workout. His level, in his own words:

> "My level is Level 2 WSET sommelier, and i'm a hobbiest tea guy who visited
> china and taiwan and bought and drank and experienced a lot of tea and i'd
> like to come closer to knowing level 2 WSET and move on to Level 3, and move
> closer to being a tea sommelier."

And, correcting an earlier draft of the writing brief:

> "i'm not preparing for an actual exam i'm looking to expand my knowledge,
> think about how best i can study through this"

So: **WSET levels are markers of depth, not a syllabus to complete.** There is no
exam. The question is whether this deck actually teaches him, in the conditions
it is read in.

## The conditions, which decide everything

A card appears during a rest between sets. He is breathing hard, the phone is on
the floor, and he has around a minute. He reads the question, decides whether to
open it, chooses from four options, and gets a prose answer. **That is the whole
apparatus.** A card that would be excellent in a textbook and is unreadable at
arm's length in fifty seconds is a bad card here.

## Your job

Read all ~300 cards as **one curriculum** rather than as 15 independent batches,
which is what they are. Then improve it. Specifically:

1. **Rephrase** cards that are correct but badly put: buried lede, a stem that
   takes three lines to reach its question, options that are hard to tell apart
   at a glance, an answer whose first sentence is throat-clearing.
2. **Delete** cards that earn nothing: near-duplicates of a better card, cards
   that end in an inert fact, cards whose distractors are so weak the question is
   free, cards that are true but unusable.
3. **Add** better questions where you delete, and where the curriculum has a hole
   that matters more than what is there.
4. **Fix** anything wrong. Errors of fact, contested claims stated as settled,
   and distractors that are arguably correct are the three that actually harm
   him, because he will repeat them.

## What "as a curriculum" means here, concretely

The deck draws **at random** and tracks what he keeps missing. There is no
sequence and there can never be one. So a curriculum here is not an order — it
is a **web with no dangling edges**:

- **Every term a card leans on is taught by some card.** This is the deck's most
  important rule and the one no tool can check. See below.
- **No concept is taught twice** in two cards that do not know about each other.
- **No concept that explains many others is missing** while its consequences are
  taught. Ask repeatedly: what does this card assume, and does the deck supply it?
- **Difficulty is mixed, not sorted** — deliberately, at Eden's instruction:
  *"i don't want any difficulty level reading, just mix em up."* Do not add a
  level field and do not group by level.

## The rules that are not yours to change

- **TREAT ALL ~300 CARDS AS ONE DECK.** Twenty-six of them came from Eden's own
  web app and every writing agent was forbidden to touch them, on `CLAUDE.md`
  rule 3 — *content is fixed and not yours to improve*. **He has lifted that for
  this review**, in his words: *"idk what seperation between edens cards and the
  agent written cards, i want to treat them all as one always."*

  It is his content and his call. So no card is privileged: the oldest 26 get
  the same scrutiny as the newest, and if one of them is confusing, buried or
  wrong, fix it. **Note this in your report**, because `CLAUDE.md` still carries
  the older rule and the next agent will read it.

- **The file format and its tests.** A card is `id`, `subject` ("wine"|"tea"),
  `topic`, `q`, `a`; a question adds exactly **4** `options` and a `correct`
  index in 0...3. Anything else silently degrades to a factoid. Every `q` ends
  with `?`. Every `id` unique.
- **Answers are 190–290 characters.** Every one of the fifteen writing groups
  reported this as the binding constraint and every one was right. It is what
  makes a card readable in a rest. Do not widen it.
- **No em-dashes** anywhere. Eden asked for every one in the app removed.
  En-dashes in numeric ranges are correct and stay.
- **Every card stands completely alone.** It is never read beside the card you
  wrote next to it. Watch for *here*, *both*, *unlike that one*, *as we saw*.
- **Not gamified, ever.** No points, badges, levels, streaks or congratulation.
  An answer states what is true and stops.

## Foreign words: the failure he asked for by name

Eden's instruction, and it is a **separate problem** from the teach-the-word
rule above:

> "look out for confusing questions that over rely on specific knowledge of
> phrases or forign words and will add the english words for them or make sure
> the question clarifies what they are correctly"

Teach-the-word asks *does the deck define this anywhere*. This asks *can he
answer THIS card, right now, on the floor, without having met the word before* —
and the answer must be yes, because there is no glossary to reach for and no
next card coming.

**Measured across the deck: 42 distinct foreign or transliterated terms, 65
mentions, and 20 cards carry one in the stem or in an option** — that is, in the
part he reads first and must understand before he can even choose. Both
languages are affected. Chinese and Japanese: *shaqing*, *huigan*, *yao qing*,
*maocha*, *zhengyan*, *kai mian cai*, *tui huo*, *qu hong bian*, *jin hua*,
*gong dao bei*, *men huang*, *fukamushi*, *tencha*, *hi-ire*, *zisha*, *nei fei*.
French, German and Italian: *élevage*, *saignée*, *sur lie*, *assemblage*,
*tirage*, *garrigue*, *vieilles vignes*, *Einzellage*, *Grosslage*,
*Bocksbeutel*, *Prädikat*, *Smaragd*, *Federspiel*, *appassimento*, *ripasso*,
*beneficio*, *estufagem*, *criadera*, *mutage*.

**He is not a beginner, and the opposite failure is just as bad.** In his own
words:

> "i'm not a newbie i know some of the phrases, i can recognize the 5 types of
> tea red/yellow/green/oolong/puar and such, i'm talking about more specific
> stuff."

Note that he says **red**, not black — the Chinese framing, 红茶. That is not
someone who needs the six classes explained to him.

**Assume he already holds**, and do not spend a card teaching it:

- The tea classes and their names, in both the Chinese and Western framings, and
  that the classes are defined by process.
- Oxidation as distinct from fermentation; roasting as distinct from both.
- The everyday brewing vocabulary: gongfu against western brewing, leaf ratio,
  water temperature, multiple infusions.
- WSET Level 2 wine vocabulary: tannin, acidity, body, oak, vintage, terroir,
  appellation, the major grapes, the classic regions by name.
- What Bordeaux, Burgundy, Champagne, Rioja, Chianti, Mosel and Napa **are**.

**Assume he does not hold** the specialist and trade vocabulary — the words a
grader, a producer or an examiner uses and a drinker does not meet: *qu hong
bian*, *tui huo*, *nei fei*, *banjhi*, *yao qing*, *kai mian cai*, *criadera*,
*beneficio*, *Bocksbeutel*, *Smaragd*, *Federspiel*, *saignée*, *tirage*,
*Einzellage* against *Grosslage*.

**The deck draws without replacement, so a wasted card is a real loss** — it
costs him one of the two he will see that day. A card that stops to explain what
oolong is has cost him a card and taught him nothing. Patronising him is not the
safe error; it is simply the other error.

What to do with each:

1. **A term in the STEM or an OPTION must arrive with its English attached**, in
   the same breath: *"kai mian cai, open-face picking of three or four mature
   leaves"* is right. *"Kill-green stops oxidation with heat. Why is it a dial?"*
   is wrong, and Eden caught that one himself.
2. **A card whose whole answer is the term's meaning is a good card** — that is
   the definitional shape the deck was short of, and the best form found so far
   is encounter-then-define: *"A back label says the wine had eighteen months of
   élevage. What was happening in that time?"*
3. **A term used only in the ANSWER is usually fine**, because by then he has
   already chosen; but it still needs its English if the answer leans on it to
   explain anything.
4. **Where the English is genuinely the better word, use the English** and put
   the foreign term second, or drop it. A card is not improved by the reader
   having to hold a transliteration he will never see on a label.
5. **Do not test spelling or transliteration.** Never make the correct answer
   turn on which of two romanisations is right; that is trivia, not knowledge.

Some of these he will genuinely meet — *terroir*, *sur lie*, *Prädikat*,
*zhengyan* on a Wuyi tin — and some he already knows. Others are trade
vocabulary he will never see on a label. **Judge each one by whether he will
actually encounter it**, and where he will not, say the thing in English.

The test is not "is this word foreign". It is **"could he answer this card
without having met this word, and if not, is the word worth the card"**. Leave
the vocabulary that is worth having; gloss the vocabulary that is load-bearing;
cut the vocabulary that is neither.

## The one thing that will bite you: card ids are history

Every answer Eden gives is logged as an event — card id, timestamp, which option
he picked, right or wrong — and his mastery ("what you keep missing") is rebuilt
from that log. **The id is the join.**

- **Rephrasing a card: KEEP its id.** The history follows it, which is what you
  want when the question is the same question, better put.
- **Changing what a card asks: give it a NEW id** and delete the old. Otherwise
  answers he gave to a different question attach to this one and his mastery
  becomes a lie.
- **Deleting is safe.** Orphaned events stay in the log as history and are
  ignored by the live reading.

## What fifteen groups already learned, so you do not rediscover it

- **The tooling has never once caught a teach-the-word violation.** Every group
  found its own by re-reading its cards by hand, and several found factual errors
  and arguably-correct distractors the same way. `python3 ios/Tools/check-deck.py`
  prints an ADVISORY to aim that read; it is a hint, not a verdict.
- **The teach-the-word rule did not exist until group two.** The first ~20
  agent-written cards were composed without it. **Audit them first** — that is
  the highest-yield place in the deck for the failure Eden himself caught: a card
  that opens *"Kill-green stops oxidation with heat. Why is it a dial rather than
  a switch?"* asserts a term he does not have and asks something harder about it.
  A gloss in place is fine; a setup clause is not.
- **Contested claims taught as settled are a live failure.** A Côte-Rôtie card
  asserted that co-fermented Viognier fixes Syrah's colour and struck through
  "it dilutes it" as false. Trials found co-fermentation *"neither improve[s] the
  phenolic composition nor enhance[s] the color stability"*, and high
  proportions lower it. It survived its author's own re-read. **Tea is worse for
  this** — health claims, tree ages, "ceremonial grade", origin stories, and the
  antiquity of practices that turn out to be recent.
- **A near-duplicate is worse than a gap.** The deck draws without replacement,
  so a repeat costs him a card he has never met.
- **Read the ANSWERS when hunting duplicates, never just the stems.** Groups five
  through fifteen each lost between three and nine planned cards to a mechanism
  already spent inside an existing answer as a passing clause. It is invisible
  from the question.

## Known imbalances, measured

- **29 of 59 wine topics hold exactly one card.** Breadth without depth.
- **Fortified wine holds 15 cards** — more than Bordeaux and Burgundy together.
  Nobody chose that: fortified wine has unusually tidy mechanisms, and a brief
  that rewards tidy mechanisms over-selects them. **This is your clearest
  deletion candidate.**
- **Yellow tea sits at 2** and two separate groups went looking and found no
  unspent mechanism. Probably correct; confirm rather than pad.
- Tea skews to China and Taiwan against India and Sri Lanka. That may be right —
  it is where he has actually drunk — but decide it rather than inherit it.

## How to work

- **Research extensively.** Where sources disagree, take the mainstream
  professional position and say so in the card, or leave the claim out.
  For wine, WSET Level 2 and 3 material, GuildSomm, Court of Master Sommeliers
  guides, and appellation bodies for what a classification actually binds. For
  tea there is **no open question bank** — ITMA's exam is drawn from manuals
  issued on registration — so take curriculum shape from ITMA and the
  International Tea Academy, and facts from producer, association and
  tea-chemistry sources.
- **Use subagents for breadth.** Fan out read-only research on topics you intend
  to rewrite, and keep the editorial judgement yourself. Each subagent starts
  cold, so give it the card text it needs rather than a pointer.
- **Work in batches of about ten and save as you go.** Several previous
  dispatches were killed by API rate limits mid-research having written nothing
  and lost everything. Write early.
- **A security hook intermittently blocks Bash output** with "Failed to contact
  the Runlayer API… fail-closed". Transient and unrelated to your command: run
  the identical command again. One agent died by stalling when it saw this.
- **Do not run while a writing agent is running.** Both append to `cards.json`
  and would clobber each other. Check with whoever dispatched you.

## Verification

```bash
python3 ios/Tools/check-deck.py --ledger   # must print OK and exit 0
./scripts/verify-ios.sh                     # seven phases PASS
./scripts/shoot.sh rest-card --keep -card <id> -expand-after 1.2
```

`-expand-after` is required or the card renders collapsed with no options
visible, which proves nothing about whether your options fit.

**Look at your worst case on screen.** Longest stem, longest options, and a
wrong pick struck through with the full prose answer below it. It must fit above
the +15S and SKIP buttons.

## Report

- What you rephrased, what you deleted and why, what you added in their place.
- Every factual error, contested claim and arguably-correct distractor you found,
  with the source that settled it. **This list is the most valuable thing you
  will produce** — it is what he would otherwise have repeated out loud.
- Your honest verdict on the deck as a way to learn these two subjects during a
  workout, and what you would do next.
