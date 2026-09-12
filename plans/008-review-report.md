# 008 — Curriculum review: report

- **Status**: DONE
- **Scope**: `ios/Morning/Resources/Content/cards.json` only
- **Deck**: 300 cards in, **302 out**. 10 deleted, 12 added, 68 edited in place.
- **Verification**: `check-deck.py --ledger` OK, `verify-ios.sh` seven phases PASS
  (84 assertions, none skipped), three worst-case cards shot and read on screen.

---

## 0. A rule that is now stale, for whoever reads `CLAUDE.md` next

`CLAUDE.md` rule 3 still says **"Content is fixed; form is yours… card text is
not yours to improve."** Eden lifted that for this review, in his words:

> "idk what seperation between edens cards and the agent written cards, i want
> to treat them all as one always."

**Exactly one of his original 26 was edited here: `w-diurnal`**, and only because
a 2014 trial contradicted its mechanism (§2b #10). His own cards came through
this almost entirely untouched.

> **Correction, 2026-09-11.** This paragraph first claimed four of his 26 were
> edited, naming `w-tannin-ageing`, `t-yixing` and `t-huigan-shengjin` alongside
> `w-diurnal`. Checked against the commit, those three are **agent-written cards
> from the earlier batches, not Eden's**. The count was wrong; the edits
> themselves are recorded correctly everywhere else in this report.

**`CLAUDE.md` rule 3 has now been updated** (2026-09-11) to carve the study deck
out of "content is fixed", record the id-is-history rule, and point here.

---

## 1. The vocabulary decisions, which is what was asked for

Eden was asked directly which specialist terms he reads without a gloss. His
answer for **both** lists — Chinese/Japanese and French/German — was **"none."**
That is a lower floor than the writing brief assumed, and it settles the audit:
a card whose options require holding a transliteration is unanswerable, and a
card that *teaches* the word is worth more than the brief credited.

He then chose **"English first, term second"**: keep the words, but let the
mechanism lead and the foreign word land as a closing aside.

### 1a. Glossed in place, because he had to hold the word before he could choose

| Card | Word | What changed |
|---|---|---|
| `t-shaqing` | kill-green | **The one Eden caught himself.** Stem now: *"Kill-green is the burst of heat that shuts down the enzymes that would otherwise brown fresh leaf. Why is it a dial rather than a switch?"* |
| `t-hiire` | aracha | Stem now *"leaves the farm as aracha, crude leaf still full of stem and dust"* |
| `t-usucha-koicha` | usucha, koicha | **koicha sat unglossed in three of the four options.** Stem now glosses both; options say "the thick one" |
| `t-yixing-clays` | zhu ni, duan ni | **The worst card in the deck.** Both terms were in the stem *and all four options* — the answer turned on recalling which romanisation was which. Now described physically ("a fine red clay fired almost dense", "a coarse sandy clay left porous"); the names stay in the answer, where he has already chosen |
| `t-rougui-shuixian` | Rou Gui, Shui Xian | Stem now glosses *"named for cassia bark"* and *"an old large-leaf bush"*, so the card can be reasoned rather than recalled |
| `w-en-rama` | en rama | Stem now *"en rama, meaning raw"* |
| `t-dancong-xiang` | Mi Lan Xiang, Ya Shi Xiang | Untranslated, in a card whose entire point is that the names *are* aromas. Now *"Mi Lan Xiang is honey orchid, Ya Shi Xiang is duck shit"* |
| `t-oxidation-percent` | kill-green | My own new card broke my own rule in a distractor. Fixed. |

### 1b. Moved to the end of the answer — 22 cards

Mechanism first, word last: **estufagem, élevage, saignée, sur lie, bâtonnage,
mutage + vin doux naturel, ripasso, men huang** (twice), **yao qing, qu hong
bian, huang pian, tuan rou, jin hua, gong dao bei, wen xiang bei, la lao huo,
kuchikiri, agari + konacha, zhengyan / banyan / zhoucha, zisha, sheng jin +
hui gan.**

So `w-elevage` now reads *"Everything between the last of the fermentation and
the bottling… Élevage means raising"* rather than opening on the word.

### 1c. Deliberately left in the stem

Label words stay where you meet them: **gushu/taidi, qing xiang/nong xiang, dong
pian, ming qian, zhengyan, Federspiel/Smaragd, Trocken/Feinherb,
Einzellage/Grosslage, Prädikat, sur lie, saignée, élevage, ripasso.** A card
shaped *"a back label says X, what does it mean?"* is the best form the deck has
found, and he chose to keep those rather than cut them.

The one exception is `t-huigan-shengjin`: *sheng jin* and *hui gan* are heard,
not read off a tin, so the stem no longer gates on them.

**Headline: the brief measured "20 cards carry a term in the stem or an option."
Read card by card, only three were genuine failures** — `t-yixing-clays`,
`t-usucha-koicha`, `t-hiire`. The rest were already glossed in place or were the
encounter-then-define shape, which is the form the deck should have more of.

---

## 2. The error list

**This is the valuable part.** Each of these is something he would otherwise
have repeated out loud.

### 2a. Wrong, including one where the *keyed answer* was the error

| # | Card | The error | What settled it |
|---|---|---|---|
| 1 | `w-tannin-ageing` | **The correct answer was the debunked belief.** It taught that tannin drops out as sediment and "there is measurably less tannin left in the glass" | AWRI's 30- and 50-year verticals state aged reds hold tannin concentrations close to young ones, *"dispelling the commonly held belief that changes in red wine astringency with ageing are due to the loss of wine tannins through precipitation"* (AWRI pub #1255; Smith et al., AJGWR 2015). **Replaced by `w-tannin-softening`: the tannin rearranges and binds saliva weakly.** New id, because his history on the old key would otherwise be a lie |
| 2 | `t-puerh-recipe-numbers` | "a code set up in 1974" — and the card contradicted itself, dating the system to 1974 while reading 75 as 1975 | The four-digit system was standardised in **1976**; 1974 is the separate wet-piling milestone, evidently conflated. Yunnan trade histories; Tea DB |
| 3 | `t-anji-baicha` | "albino below roughly 22C… as the weather warms the leaf greens over" — **the direction was wrong** | The albino window is a *narrow band* around 20C and **both warmer and colder** cause re-greening. CAAS Tea Research Institute; *Differential Metabolic Profiles during the Albescent Stages of 'Anji Baicha'* (PMC4622044) |
| 4 | `t-dahongpao` | "Clones taken from the originals… sold as Qi Dan or Bei Dou" | 2009 RAPD-PCR work (Fujian Agriculture and Forestry Univ.) found **Qi Dan genetically identical to mother bushes 2 and 6, but Bei Dou genetically distant.** Only half the claim held |
| 5 | `w-cava-method-and-place` | Named Catalonia, Rioja, Aragón and Extremadura, then said "four zones" | **Valencia (Altos de Levante) was missing** — a whole zone, not a footnote. D.O. Cava. Also updated to the reformed tier name, Cava de Guarda |
| 6 | `w-saint-emilion-revised` | "three of the biggest names walked out **in 2022**" | Cheval Blanc and Ausone announced withdrawal in **July 2021**; only Angélus in January 2022. Now "across 2021 and 2022". The Drinks Business; Conseil des Vins de Saint-Émilion |
| 7 | `w-alsace-grand-cru` | "reserved for Riesling, Gewurztraminer, Pinot Gris and Muscat, with a handful of named exceptions" | Materially incomplete now: **red Pinot Noir was authorised on Hengst and Kirchberg de Barr in 2022 and Vorbourg in 2024**, and blends are permitted at Altenberg de Bergheim as well as Kaefferkopf. Légifrance; CIVA |
| 8 | `w-tokaji-aszu` | "macerated in **a dry base wine**", and "sugar is extracted rather than fermented" | The specification permits **must, fermenting must or wine** of the same vintage, and a slow incomplete ferment does follow. Wines of Tokaj |

### 2b. Contested claims taught as settled

| # | Card | The claim | The state of the evidence |
|---|---|---|---|
| 9 | `w-cote-rotie-viognier` | "The aromatic lift is the part **nobody disputes**" | Not so. A Texas Tech sensory study of 5–20% Viognier coferments found **only 1 of 12 attributes differed** (honey, not apricot or blossom), and Casassa 2020 (AJGWR) found Viognier adds aromatics *whether co-fermented or blended* — which undercuts the premise that co-fermentation is what buys it. **Rewritten as `w-cote-rotie-colour`, which now teaches the debunk itself** and notes Viognier ripens *before* Syrah |
| 10 | `w-diurnal` (Eden's own) | "cold nights slow respiration, which is the process that consumes malic acid" | The night half is the contested half. Sweetman et al. (J. Exp. Bot. 2014): when **minimum temperatures were also raised, malate was not reduced.** Softened to "trials suggest the night alone matters less than the season's warmth" |
| 11 | `t-caffeine-rinse` | "a thirty second rinse takes **under a tenth**" | The optimistic end of a **9–20% range**, and no study measures a 30s infusion directly — the 9% figure is extrapolated from Hicks, Hsieh & Bell (1996), which sampled only at 5/10/15 min. **Re-keyed to "a fifth at most" and now says the range is unmeasured** |
| 12 | `t-enshi-steamed` | "**the one** Chinese green still made that way" | Xianrenzhang Cha (Yuquan Temple, Dangyang) still uses a steam kill-green. Softened to "the one steamed Chinese green made at any scale" |
| 13 | `t-jin-jun-mei` | "Buds only" | True of the genuine article, but **the name was never trademarked and is now generic**, so most tins hold leaf as well as bud. The card now says so, which makes it a better card |
| 14 | `t-keemun-invented` | "A local man… in **1875**" | The year wobbles to 1876 across Chinese sources and **the founder is genuinely disputed** (Yu Ganchen vs Hu Yuanlong). Now "in the 1870s… which man is disputed". Geraniol held up (Food Chemistry; PMC8911931) |
| 15 | `t-oriental-beauty` | Leafhopper damage raises monoterpenes, "the honeyed aroma is a wound response" | Monoterpenes track the **muscatel/floral** side; the honey note comes from phenylacetaldehyde, damascenone and phenethyl alcohol. Also the insect is now *Empoasca onukii*, not *Jacobiasca formosana* |
| 16 | `t-liubao` | Basket ageing builds *binglang xiang* | Oversimplified: cultivar, the pile **and** the ageing together. Also legally-defined "traditional process" Liu Bao skips wet-piling |
| 17 | `t-theanine-caffeine` | "with caffeine it **measurably** sharpens attention" | The trials dose **100–200mg theanine against the ~25–60mg in a cup.** Now hedged, and it credits the plain dose difference too |
| 18 | `w-german-origin` | 2021 reform "phased in to the 2026 vintage" | The *law* binds from 2026; **the regions have not finished ranking their sites.** Both now said |

### 2c. Distractors that were true, struck through as false

This is the failure that teaches him something wrong, because the app renders a
wrong pick with a red strike through it.

| # | Card | The struck option | Why it was true |
|---|---|---|---|
| 19 | `t-theanine-caffeine` | "Tea holds far less caffeine per cup than coffee does" | **Simply true** — USDA: brewed black tea ≈47mg/8oz, coffee ≈95mg. Worse, it is also a partial explanation of the very thing being asked. Replaced with the *theine* myth, which is false |
| 20 | `t-theanine-shade` | "It raises the caffeine, which reads on the palate as body" | **Shading raises caffeine** as well as theanine, and lowers catechins (IJMS matcha shading study). Replaced with a chlorophyll claim, which is false in the right direction |
| 21 | `w-food-fat-tannin` | "Fat is faintly sweet, and sweetness suppresses the sensation of tannin" | **Contradicted another card.** `t-sugar-astringency` teaches sweetness suppressing astringency as true. Same mechanism affirmed in one card and struck in another |
| 22 | `t-second-infusion` | "The leaf has warmed through, and heat drives extraction" | A real minor contributor, not a falsehood — pouring onto cold leaf in a cold vessel drops brew temperature 8–12C. Replaced with something cleanly wrong |

### 2d. Structural defects, invisible one card at a time

| # | Defect | Fix |
|---|---|---|
| 23 | **In 19 questions the correct option was visibly the longest** — worst case 100 characters against 69/76/77. Guessable without knowing anything about wine or tea | All 19 rebalanced. Zero length tells remain |
| 24 | `w-sulphur-dioxide`'s closing sentence **was the entire content of `w-ph-sulphur-dose`**, spent as a passing clause. Exactly the failure groups five through fifteen reported | Trimmed; the pH half now belongs only to the card built for it |
| 25 | `t-yixing` says porous clay *gives back* aroma; `t-yixing-clays` said porous clay *softens*. Same physics, opposite-sounding virtues | Made the absorption explicit so the two agree |
| 26 | `t-alkalinity` opened on a subordinate clause with no main verb; `t-white-fuding-zhenghe` had a 165-character opening with a definition nested inside it | Both rewritten |

---

## 3. Deletions, and what replaced them

**Ten deleted.** Every one was read against the *answers*, not the stems.

| Deleted | Why |
|---|---|
| `t-killgreen` | Near-duplicate of `t-shaqing`; spent a whole card naming a process word |
| `t-chilli-heat` | Same TRPV1 mechanism as `w-food-chilli`, down to a near-identical opening sentence |
| `t-bag-barrier` | Second teabag card. Two is over-spend for someone brewing gongfu |
| `t-korea-grades` | A four-term transliteration ladder with no mechanism, and its one insight was already inside `t-mingqian`'s answer |
| `w-amontillado` | Its whole mechanism is spent inside `w-flor-abv` — flor lives below 15.5%, dies above |
| `w-colheita` | Cask-time-is-the-ageing is spent across `w-tawny-ruby` and `w-lbv-vs-vintage-port` |
| `w-cru-bourgeois` | The fourth Bordeaux classification card, and its lesson is the whole of `w-saint-emilion-revised` |
| `w-tannin-ageing` | Keyed answer factually wrong (§2a #1) |
| `w-cote-rotie-viognier` | Answer overclaimed (§2b #9) |
| `t-caffeine-rinse` | Keyed figure was the optimistic end of a range (§2b #11) |

**Twelve added.** Wine went where Eden chose, *deeper into the classics*; tea
stayed in China and Taiwan, as he asked.

- `w-cote-dor-midslope` — **Burgundy had six cards and every one was about
  classification.** Why the grand crus sit mid-slope: thin and cold above,
  deep, damp and frost-pooling below.
- `w-medoc-river` — five of Bordeaux's six ranked châteaux rather than
  explaining the place. What the Gironde actually does, and why the gravel is
  deepest nearest it.
- `w-chateauneuf-galets` — heat storage and evaporation cover, and the catch
  that some of the finest parcels are sand.
- `w-barolo-mga` — Barolo named 170 vineyards in 2010 and **deliberately did not
  rank them.** Pairs against the Burgundy cru cards the deck already has.
- `w-german-selection` — **a hole under a card the deck leans on.** `w-pradikat`
  teaches that Prädikat is must weight, not sweetness, but nothing said what the
  picker *does* to climb it: selected bunches, berries, shrivelled berries.
- `w-tannin-softening`, `w-cote-rotie-colour` — the two corrections above.
- `t-oxidation-percent` — the 20/40/70% figure he reads on every oolong is a
  maker's estimate by eye and nose, not a measurement.
- `t-white-caffeine-myth` — white tea is not the low-caffeine one; caffeine
  concentrates in the bud.
- `t-cake-facing` — cakes can be faced, which is why buyers pry from the edge.
- `t-leaf-ratio-vs-time` — more leaf briefly beats less leaf for longer, because
  bitterness keeps climbing while sweetness levels off. The most actionable
  brewing fact in the deck.
- `t-rinse-caffeine` — the corrected rinse card.

**Fortified is fixed.** It held 15 against Bordeaux-plus-Burgundy's 12. It now
holds **11 against 13**.

**Yellow tea stays at 2.** Confirmed rather than padded, as the brief asked: two
separate groups went looking and found no unspent mechanism, and neither did I.

---

## 4. Verdict

**The deck is good, and better than its own tooling could show.** The prose is
genuinely strong — answers land the payload in the first clause, closers state a
consequence rather than trailing into trivia, and the "every term is taught
somewhere" web is tighter than the brief feared. I checked twenty-odd load-bearing
concepts (anthocyanin, catechins, theanine, lees, flor, phylloxera, assamica,
pH vs titratable acidity, wo dui, dosage) and found no dangling edges.

**Its failures were structural, not stylistic**, and that is why fifteen careful
groups missed them. Nothing is visible from inside one card: the longest-option
tell needed all 214 questions in one table, the sulphur-dioxide overlap needed
reading two answers against each other, and the tannin error needed an outside
source. A sixteenth writing group would not have found any of them.

**On the format itself: it works.** Three worst-case cards were shot on device
— longest stem, longest options, a wrong pick struck through, full prose answer
— and all three fit above the buttons with room. Fifty seconds is enough for
this shape of card. The 190–290 character band is doing exactly what every group
said it was.

**One honest calibration.** Asked which of four mechanisms he would get right
cold, Eden answered **none** — including "why the Left Bank is Cabernet", which
the deck already teaches in `w-bordeaux-banks`. Read plainly, that means the WSET
Level 2 layer is not passive recall for him yet, and it is doing real work. So
**do not strip the L2 cards to make room for L3 ones.** The deck is pitched
correctly; the reach upward should come from adding, not from replacing.

### What I would do next

1. **Update `CLAUDE.md` rule 3.** It still forbids what Eden has now asked for.
2. **Add a mechanical check for the longest-correct-option tell.** It is a
   four-line addition to `check-deck.py` and it caught 19 cards; it will catch
   the next writing group's too.
3. **Add a cross-card duplication check on answers.** A rare-word overlap scan
   between every pair of answers surfaced the sulphur-dioxide and Yixing
   collisions in seconds. The ledger already warns agents to read answers; this
   would enforce it.
4. **Resist widening.** 29 wine topics still hold exactly one card and Eden
   chose depth over filling them. That was the right call and the next agent
   should not quietly reverse it.
5. **The tea half is now the stronger of the two.** If a next pass has a budget,
   spend it on wine mechanism — viticulture and winemaking are where the L2-to-L3
   reach actually lives, and where the deck is thinnest relative to its
   geography.
