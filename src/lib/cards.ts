/* ===========================================================================
 *  THE DECK
 *  -------------------------------------------------------------------------
 *  Things worth knowing, asked as questions, shown in the dead time during a
 *  rest and once at the end of a session.
 *
 *  ── the rule these are written to ────────────────────────────────────────
 *  Every card teaches a MECHANISM, not a fact. "Chablis is Chardonnay" is
 *  worthless to someone who already knows the map; "why is Chablis higher in
 *  acid than Meursault" is the same subject at a useful depth. WSET Level 3 is
 *  hard for exactly this reason — it tests whether you can explain cause and
 *  effect, not whether you memorised regions. The tea cards follow the same
 *  spine: terroir → processing → style.
 *
 *  ── adding more ──────────────────────────────────────────────────────────
 *  Append to the array. `id` must be unique and must never be reused for
 *  different content: it is what the rotation stores to know you have seen it.
 *  A new subject is just a new `subject` value plus a label in SUBJECTS.
 * ======================================================================== */

export type Subject = "wine" | "tea";

export const SUBJECTS: Record<Subject, string> = {
  wine: "Wine",
  tea: "Tea",
};

export interface Card {
  /** Stable and permanent — the rotation remembers it. */
  readonly id: string;
  readonly subject: Subject;
  /** Short eyebrow, e.g. "Fortified". */
  readonly topic: string;
  readonly q: string;
  readonly a: string;
}

export const CARDS: readonly Card[] = [
  /* --- wine --------------------------------------------------------------- */
  {
    id: "w-flor-abv",
    subject: "wine",
    topic: "Fortified",
    q: "Why is Fino fortified to about 15% and Oloroso to about 17%?",
    a: "Flor yeast survives only to roughly 15.5% abv. Below that the flor layer lives and shields the wine from oxygen — biological ageing, which gives Fino its saline, bready character. Above it the flor dies and the wine ages oxidatively, giving Oloroso its nutty, dried-fruit profile.",
  },
  {
    id: "w-diurnal",
    subject: "wine",
    topic: "Viticulture",
    q: "Why does a large diurnal temperature range help red wine quality?",
    a: "Warm days drive photosynthesis and phenolic ripening; cold nights slow respiration, which is the process that consumes malic acid. The fruit accumulates sugar and colour while retaining acidity — a combination that is hard to achieve in a uniformly warm climate.",
  },
  {
    id: "w-mlf-diacetyl",
    subject: "wine",
    topic: "Winemaking",
    q: "Malolactic conversion always softens acidity. So why does it not always taste buttery?",
    a: "It converts sharp malic acid into softer lactic acid, raising pH. Diacetyl — the buttery compound — is only a by-product: the bacteria can metabolise it further, lees stirring disperses it, and blending dilutes it. Chablis routinely goes through MLF without tasting of butter.",
  },
  {
    id: "w-pradikat",
    subject: "wine",
    topic: "Germany",
    q: "A bottle says Spätlese. Is the wine sweet?",
    a: "Not necessarily. Prädikat levels measure must weight — sugar in the grapes at harvest — not residual sugar in the finished wine. A Spätlese can be fermented bone dry and labelled Spätlese Trocken.",
  },
  {
    id: "w-autolysis",
    subject: "wine",
    topic: "Sparkling",
    q: "Where does the biscuit and brioche character in Champagne come from?",
    a: "Autolysis. The second fermentation happens inside the bottle, and the dead yeast cells then break down in contact with the wine under pressure. Tank-method wines finish their second fermentation in a pressurised tank with little lees contact, so they keep primary fruit and florals instead.",
  },
  {
    id: "w-gran-reserva",
    subject: "wine",
    topic: "Rioja",
    q: "What does Gran Reserva actually guarantee?",
    a: "Only maturation. For reds: at least 60 months in total, of which a minimum of 24 in oak and 24 in bottle. It says nothing about vineyard site or fruit quality — a producer can bottle an outstanding wine as Genérico if they choose to age it differently.",
  },
  {
    id: "w-acid-vs-tannin",
    subject: "wine",
    topic: "Structure",
    q: "Someone calls a wine firm. How do you work out whether they mean acid or tannin?",
    a: "Acid is a taste — registered at the sides of the tongue, and it makes you salivate. Tannin is tactile — it binds salivary proteins and leaves the mouth dry. A high-acid, low-tannin Riesling and a low-acid, high-tannin red both feel firm, for opposite reasons.",
  },
  {
    id: "w-neutral-oak",
    subject: "wine",
    topic: "Oak",
    q: "Why would a winemaker choose fourth-fill barrels that impart almost no flavour?",
    a: "For texture rather than flavour. The extractable oak compounds are largely spent, but the barrel still allows slow oxygen ingress, which polymerises tannin and stabilises colour. Neutral oak is a deliberate tool, not a compromise.",
  },
  {
    id: "w-grand-cru-land",
    subject: "wine",
    topic: "Burgundy",
    q: "Two growers bottle Chambertin Grand Cru. Why can the wines differ so much?",
    a: "Because Burgundy classifies land, not producers. Le Chambertin is one vineyard divided among many owners, each with their own parcels, viticulture and winemaking. The classification guarantees the site; it says nothing about the execution.",
  },
  {
    id: "w-vintage-variation",
    subject: "wine",
    topic: "Climate",
    q: "Why does vintage matter far more in Chablis than in the Languedoc?",
    a: "Chablis sits at the northern margin of viable Chardonnay, where spring frost and poor flowering weather regularly threaten both crop size and ripeness. Warm, dry regions ripen reliably every year, so the differences between vintages are much smaller.",
  },
  {
    id: "w-alcohol-sweetness",
    subject: "wine",
    topic: "Tasting",
    q: "A technically dry wine reads as slightly sweet. What is happening?",
    a: "Ethanol itself tastes faintly sweet at moderate concentration, and glycerol adds body, so high-alcohol dry wines can read off-dry. Where acidity is too low to balance that alcohol, the same wine reads hot instead.",
  },
  {
    id: "w-old-vine",
    subject: "wine",
    topic: "Labelling",
    q: "A label says old vine. What does that guarantee?",
    a: "Almost nothing — the term is unregulated in most of the world. The underlying mechanism is real: lower vigour, smaller yields, and deep roots that buffer drought. But with no legal minimum age it stays a claim rather than a specification.",
  },
  {
    id: "w-port-sweetness",
    subject: "wine",
    topic: "Port",
    q: "Port is not back-sweetened. So why is it sweet?",
    a: "Fermentation is deliberately arrested at around 6–8% abv by adding neutral grape spirit, which kills the yeast while a large amount of grape sugar is still unfermented. The sweetness is leftover must, not an addition.",
  },
  {
    id: "w-tartaric",
    subject: "wine",
    topic: "Acidity",
    q: "Grapes contain both tartaric and malic acid. Why does tartaric matter more to the winemaker?",
    a: "It is the stronger and far more stable of the two, and it largely survives fermentation and ageing. Malic is respired away by the vine in warm conditions and can be converted by MLF. Tartaric is what ultimately underpins the finished wine's pH.",
  },

  /* --- tea ---------------------------------------------------------------- */
  {
    id: "t-oolong-range",
    subject: "tea",
    topic: "Oolong",
    q: "What does the word oolong actually specify?",
    a: "A processing range — not a plant, not a place. Oxidation spans roughly 20–80%, the widest of any category. A modern Anxi tieguanyin at around 20% sits close to green tea; a Wuyi yancha at 50–70% plus charcoal roast sits close to black.",
  },
  {
    id: "t-oxidation-vs-roast",
    subject: "tea",
    topic: "Processing",
    q: "What is the difference between oxidation and roasting?",
    a: "Oxidation is enzymatic and happens to the fresh leaf — it is the process that turns green tea into black. Roasting is applied heat after processing is finished: it caramelises sugars and drives off moisture, and it can be repeated years later to revive a stored tea.",
  },
  {
    id: "t-sheng-shou",
    subject: "tea",
    topic: "Puerh",
    q: "How do sheng and shou puerh differ?",
    a: "Not by age — by process. Sheng is pressed raw and transforms slowly over decades. Shou was developed in the 1970s to imitate that result using 45–60 days of wet piling, wo dui, an accelerated microbial fermentation. Five-year examples of each have very little in common.",
  },
  {
    id: "t-gaoshan",
    subject: "tea",
    topic: "Altitude",
    q: "Why is Taiwanese high-mountain oolong so much less astringent?",
    a: "Above roughly 1000m, cooler temperatures and persistent cloud slow the plant's growth and reduce catechin production — catechins being the main source of astringency — while amino acids stay relatively higher. The result reads thick and sweet rather than brisk.",
  },
  {
    id: "t-yan-yun",
    subject: "tea",
    topic: "Terroir",
    q: "What is yan yun, and what is it attributed to?",
    a: "Rock rhyme — the mineral signature of Wuyi yancha. It is credited to the weathered volcanic and sandstone soils of the narrow ravines, with sharp drainage and limited direct sun. Zhengyan, true cliff tea, commands several times the price of tea grown on nearby flat land.",
  },
  {
    id: "t-fixing-method",
    subject: "tea",
    topic: "Green tea",
    q: "Why does Chinese green tea taste nutty while Japanese green tea tastes marine?",
    a: "The fixing method. China pan-fires, which introduces Maillard character — chestnut, toast, a rounder body. Japan steams, which halts oxidation faster and preserves more chlorophyll, producing the vivid green, grassy, oceanic profile of sencha and gyokuro.",
  },
  {
    id: "t-white-ageing",
    subject: "tea",
    topic: "White tea",
    q: "Why does white tea keep developing in storage when green tea merely goes stale?",
    a: "White tea is only withered and dried — there is no fixing step, so its enzymes are never fully deactivated and slow transformation continues. Aged Shou Mei is a recognised category. Green tea's enzymes are killed during fixing, so it can only degrade.",
  },
  {
    id: "t-gongfu-curve",
    subject: "tea",
    topic: "Brewing",
    q: "Why does gongfu brewing taste different from Western brewing of the same leaf?",
    a: "It is a different extraction curve. A high leaf-to-water ratio with very short steeps pulls compounds out in stages, so you taste the tea evolve across infusions. A single long Western steep extracts most of it at once, averaging that whole progression into one cup.",
  },
  {
    id: "t-tieguanyin-modern",
    subject: "tea",
    topic: "Tieguanyin",
    q: "Is the jade-green, intensely floral tieguanyin the traditional style?",
    a: "No — it is a market development from around the 1990s. Traditional Anxi tieguanyin was more oxidised, near 40%, and roasted. Demand for green, aromatic oolong pushed producers toward 15–30% oxidation with little or no roast. Both are authentic to their own era.",
  },
  {
    id: "t-storage-exception",
    subject: "tea",
    topic: "Storage",
    q: "Which tea should not be stored airtight, and why?",
    a: "Sheng puerh. Green, white and oolong all degrade with oxygen, light and humidity, so they want a seal. Sheng needs modest airflow and humidity for its microbial and oxidative ageing to proceed at all — sealed away, it simply stalls.",
  },
  {
    id: "t-water",
    subject: "tea",
    topic: "Water",
    q: "Why does the same leaf taste different at home than it did in the shop?",
    a: "Usually the water rather than the tea. Mineral content changes both extraction and aroma perception: hard water mutes delicate aromatics and flattens greens, while very soft water can leave a tea tasting thin. Most specialists target low to moderate mineralisation.",
  },
  {
    id: "t-withering",
    subject: "tea",
    topic: "Processing",
    q: "What is withering actually for?",
    a: "Controlled moisture loss. It makes the leaf pliable enough to roll without shattering, and it starts the chemical changes that precede oxidation. Under-withered leaf breaks up during processing; over-withered leaf loses aromatic potential before it is even rolled.",
  },
];
