import Foundation

/* ===========================================================================
 *  WHEN A CARD SHOULD COME ROUND AGAIN
 *  ---------------------------------------------------------------------------
 *  The scheduling half of the study deck, kept apart from `Deck` on purpose:
 *  everything here is a PURE FUNCTION of the two logs and a date, so the rules
 *  can be asserted without a `UserDefaults` suite and without drawing a card.
 *
 *  ── why this exists at all ───────────────────────────────────────────────
 *  The deck used to draw WITHOUT REPLACEMENT: a cycle set held every card
 *  already shown, and a card left the pool until the whole deck had been seen.
 *  That was right for 26 cards. At three hundred it is a **twenty-week cycle**, and the
 *  mastery bias built on top of it could not fire at all — a card you missed
 *  was, by definition, already in the seen set, so "a question you missed comes
 *  back sooner" was unreachable code for the length of a cycle.
 *
 *  Simulated over a year of five sessions a week, the old draw brought a missed
 *  card back after a MEDIAN OF FIFTY-SEVEN SESSIONS, and twenty misses a year
 *  never came back at all. Eden, who could feel it without seeing the numbers:
 *  *"i wanna bring back questions that i got wrong more often so i can iterate
 *  and learn better."*
 *
 *  ── what replaced it ────────────────────────────────────────────────────
 *  Every card carries an INTERVAL — how long it has earned before it is worth
 *  showing again — and its priority is simply how far past that interval it is.
 *  Nothing is ever locked out of the pool, so nothing can be stranded by one.
 *
 *  The intervals are days rather than sessions. A week off is a week of
 *  forgetting whether or not you trained, and a schedule that only advances
 *  when you show up would hand you back a fortnight-old miss as if it were
 *  fresh.
 * ======================================================================== */

enum StudyPlan {
    // MARK: - What the app knows about one card

    /// One card's whole history, folded from the two logs.
    ///
    /// Derived, never stored. `Deck` keeps the events; this is a reading of
    /// them, and a reading that can be saved is a reading that can disagree
    /// with its source.
    struct Encounter: Equatable {
        /// Times the card has been put in front of him.
        var sightings = 0
        /// Of those, how many he chose to engage with rather than let run out.
        var opened = 0
        /// When it was last shown.
        var lastSeen: Date?
        /// Times he actually answered — never the same as `sightings`, because
        /// a rest can end with the question unanswered and nothing is written
        /// for one he did not choose.
        var answered = 0
        /// Times answered wrong, ever.
        var misses = 0
        /// Consecutive right answers since the last miss.
        var run = 0
        /// EVERY WRONG ANSWER HE HAS GIVEN THIS CARD, and how often.
        ///
        /// The most interesting thing in either log, and the reason
        /// `StudyAnswer` carries the option's text: it is the difference
        /// between "he missed this" and "he keeps confusing it with THAT".
        ///
        /// Keyed by words rather than by index, so it survives a content agent
        /// reordering a card's options and can never name an answer he did not
        /// give. Answers logged before the wording was recorded count as misses
        /// and contribute nothing here.
        var wrongWordings: [String: Int] = [:]

        /// TIMES HE ACTUALLY STUDIED IT, as against times it appeared.
        ///
        /// Eden's rule: *"if i didn't interact and answer then it shouldn't be
        /// recorded."* A card that came up while he was getting his breath back
        /// and was never touched has not been studied, and the app must not
        /// count it as though it had — a question ignored three times used to
        /// read "4TH TIME" on the fourth, which is the app believing its own
        /// furniture.
        ///
        /// The two kinds of card are engaged with differently, and one rule
        /// cannot serve both:
        ///
        /// **A factoid is engaged with by being shown.** There is nothing to do
        /// with one but read it, and it reveals itself on the clock. Its
        /// appearance IS its study, and demanding a tap for one would count
        /// every factoid he has ever read as unread.
        ///
        /// **A question is engaged with by being OPENED.** It sits as a prompt
        /// for almost the whole rest precisely so that opening it is a choice —
        /// `Deck.answerDue` exists to protect that choice — and a choice not
        /// made is information rather than an accident.
        ///
        /// The SIGHTING is still recorded either way. The log keeps what
        /// happened; this is the reading that decides what it meant. Dropping
        /// the record instead would leave the card looking unseen, so it would
        /// come back two sessions later, be ignored again, and nothing would
        /// ever know that was the pattern.
        func engagements(isQuestion: Bool) -> Int {
            isQuestion ? opened : sightings
        }

        /// Missed, and not yet settled.
        var isShaky: Bool {
            misses > 0 && run < settledRun
        }

        /// A wrong answer he has reached for more than once.
        ///
        /// Twice is the threshold and it is the whole point: one wrong answer
        /// is a slip, the same wrong answer twice is something he believes.
        /// Only the second is worth saying out loud.
        ///
        /// Ties broken on the wording, so the reading is stable rather than
        /// dependent on dictionary order — which is not.
        var confusion: (wording: String, times: Int)? {
            let worst = wrongWordings
                .filter { $0.value > 1 }
                .max { left, right in
                    left.value == right.value ? left.key > right.key : left.value < right.value
                }
            guard let worst else { return nil }
            return (worst.key, worst.value)
        }
    }

    /// Two right in a row and a question goes quiet.
    ///
    /// Two rather than one because a single correct guess out of four options
    /// is a 25% accident, and twice running is 6%. Three would be more certain
    /// and would also mean the deck rarely settles anything.
    static let settledRun = 2

    // MARK: - The ladders

    /// A QUESTION'S interval in days, by the run of right answers since its
    /// last miss.
    ///
    /// The steps are close at the bottom and far apart at the top, which is the
    /// whole shape of spaced repetition: the thing you just got wrong is worth
    /// asking again this week, and the thing you have had right four times
    /// running is worth asking again next season.
    ///
    /// Two days at the bottom rather than one. One would put a missed question
    /// in the very next session, every session, until it settled — and at three
    /// cards a morning that is a deck that only ever shows you your mistakes.
    static let questionLadder: [Double] = [2, 6, 16, 40, 90]

    /// A question he has SEEN but never answered.
    ///
    /// Between a miss and a settled card, and deliberately closer to the miss.
    /// Letting a question time out is not a wrong answer — Eden's ruling, and
    /// the reason nothing is written for one — but it is not knowledge either,
    /// and the card has not done its job yet.
    static let unansweredInterval: Double = 5

    /// A FACTOID'S interval in days, by how many times it has been shown.
    ///
    /// Longer than a question's at every step, because a factoid cannot be got
    /// wrong: there is no signal to react to, so the only honest policy is to
    /// show it a few times, further apart each time, and then leave it alone.
    static let factoidLadder: [Double] = [12, 30, 70, 140]

    /// How much each miss shortens the interval, compounding.
    ///
    /// This is the bit Eden actually asked for — *"bring back questions that i
    /// got wrong more often"* — and it is proportional rather than binary. A
    /// card missed once comes back at 72% of its interval; missed four times,
    /// at 27%. So a question you keep getting wrong is asked roughly four times
    /// as often as one you fumbled once, at the same point on the ladder.
    static let troubleFactor: Double = 0.72
    /// Past four misses the shortening stops. A card that keeps being missed
    /// after that is not being served by asking it more often — it is either
    /// badly written or genuinely hard, and grinding it every session would
    /// crowd out the whole rest of the deck.
    static let troubleCeiling = 4

    /// Days a card has earned before it is worth showing again.
    static func interval(for encounter: Encounter, isQuestion: Bool) -> Double {
        let base: Double = if isQuestion {
            encounter.answered == 0
                ? unansweredInterval
                : questionLadder[min(encounter.run, questionLadder.count - 1)]
        } else {
            factoidLadder[min(max(encounter.sightings - 1, 0), factoidLadder.count - 1)]
        }
        return base * pow(troubleFactor, Double(min(encounter.misses, troubleCeiling)))
    }

    // MARK: - Priority

    /// What a card he has never met is worth.
    ///
    /// Expressed on the same scale as everything else — "as wanted as a card
    /// two and a half times past its interval" — so novelty and review compete
    /// on one axis instead of being traded off by a rule.
    static let noveltyPriority: Double = 2.5

    /// The most any card can be worth, however long it has been.
    ///
    /// Without it, a card forgotten for a year would outrank the whole deck
    /// forever and the top of the queue would ossify into the same few cards.
    /// With it, everything sufficiently overdue is equally overdue and the
    /// weighted draw picks among them.
    static let priorityCeiling: Double = 4

    /// How much this card wants to be shown, now. Higher is sooner.
    static func priority(for encounter: Encounter, isQuestion: Bool, now: Date) -> Double {
        guard let lastSeen = encounter.lastSeen else { return noveltyPriority }
        let days = now.timeIntervalSince(lastSeen) / 86400
        return min(priorityCeiling, days / max(interval(for: encounter, isQuestion: isQuestion), 0.5))
    }

    // MARK: - What a session asks for

    /// What this particular draw is FOR.
    ///
    /// A session shows three cards, and letting one rule pick all three is what
    /// made the choice between coverage and review look forced. Asking each
    /// slot for something different is what makes it not a trade: simulated
    /// over a year, `fresh · review · open` sees **296 of the 302 cards** the deck then held — more
    /// than the old draw's 256 — while bringing a missed card back in a median
    /// of six days rather than eleven weeks. Better on both axes at once, which
    /// is the only reason to believe it is the right shape.
    enum Intent {
        /// A card he has never met, if the deck still holds one. This is the
        /// slot that guarantees the deck keeps opening up rather than closing
        /// in around what he already half-knows.
        case fresh
        /// Something he got wrong. This is the slot Eden asked for.
        case review
        /// Whatever wants it most — **unless he is behind**, and then this
        /// reviews too; see `reviewBacklog`. The summary's card, which has no
        /// timer to beat and can afford the hardest thing in the queue.
        case open
    }

    /// The candidates an intent is willing to draw from, in preference order:
    /// its own kind first, and the whole pool when its own kind is empty.
    ///
    /// **Never returns nothing when given something.** A slot that cannot be
    /// filled must fall through to an ordinary draw, not skip the card — an
    /// empty rest is a worse outcome than a slightly-off one.
    static func candidates(
        _ cards: [Card],
        intent: Intent,
        encounters: [String: Encounter],
        now: Date
    ) -> [Card] {
        guard !cards.isEmpty else { return [] }
        let preferred: [Card]
        switch intent {
        case .fresh:
            preferred = cards.filter { encounters[$0.id] == nil }
        case .review:
            // Shaky first — a question he has actually got wrong. Failing that,
            // anything genuinely past its interval, which on a young deck is
            // how this slot still earns its place before there are any misses.
            let shaky = cards.filter { encounters[$0.id]?.isShaky == true }
            preferred = shaky.isEmpty ? cards.filter { isDue($0, encounters: encounters, now: now) } : shaky
        case .open:
            // THE THIRD SLOT REVIEWS WHEN HE IS BEHIND, AND EXPLORES WHEN HE
            // IS NOT.
            //
            // One dedicated review slot is not enough throughput. Measured over
            // a simulated year: misses arrive at about one every other session
            // and each costs roughly two more right answers to settle, so a
            // single slot runs a standing backlog of a dozen questions and a
            // card waits its turn behind all of them. **Ordering that queue
            // does not help** — every shaky card is pinned at the priority
            // ceiling, so the wait is set by throughput, not by which one comes
            // first. Sorting it, shortening the shortlist and halving the
            // bottom of the ladder all moved the median by nothing.
            //
            // Making this slot review ALWAYS fixes the wait and costs eighteen
            // cards a year of coverage. Making it review only while the backlog
            // is over `reviewBacklog` costs **nothing measurable** and gets
            // almost all of it: the median wait for a missed question falls
            // from six days to four, the 90th percentile from fourteen to six,
            // and the worst case from thirty days to nine.
            //
            // It is also the more honest behaviour. When he is on top of the
            // deck the last card of the morning is free to be anything; when he
            // is carrying five questions he keeps getting wrong, it is not.
            let backlog = encounters.values.count { $0.isShaky }
            preferred = backlog >= reviewBacklog
                ? cards.filter { encounters[$0.id]?.isShaky == true }
                : []
        }
        return preferred.isEmpty ? cards : preferred
    }

    /// Past its interval.
    static func isDue(_ card: Card, encounters: [String: Encounter], now: Date) -> Bool {
        let encounter = encounters[card.id] ?? Encounter()
        guard let lastSeen = encounter.lastSeen else { return true }
        let days = now.timeIntervalSince(lastSeen) / 86400
        return days >= interval(for: encounter, isQuestion: card.choices != nil)
    }

    // MARK: - The draw

    /// How many questions he can be carrying before the session's last card
    /// stops being free.
    ///
    /// Five. Below it the third slot explores and coverage is untouched; at it
    /// the backlog stops growing, which is the only thing that actually
    /// shortens the wait. Four reviews more eagerly and costs a little
    /// coverage; eight lets the median drift back towards five days.
    static let reviewBacklog = 5

    /// How many of the best candidates are actually in the running.
    ///
    /// Strictly picking the top card would make the deck deterministic —
    /// the same morning order every week — and picking uniformly at random
    /// would throw away the ordering that this whole file computes. A weighted
    /// draw from a shortlist is both: the most-wanted card usually comes up,
    /// and it is never the only one that can.
    static let shortlist = 24

    /// One card, weighted by priority, from the front of the queue.
    ///
    /// `randomness` is injected so the tests can assert the ORDERING without
    /// asserting the dice.
    static func choose(
        from cards: [Card],
        encounters: [String: Encounter],
        now: Date,
        randomness: () -> Double = { Double.random(in: 0 ..< 1) }
    ) -> Card? {
        guard !cards.isEmpty else { return nil }

        // Written out rather than chained. As one `map`/`sorted`/`prefix`
        // expression the type checker gives up on it — "unable to type-check
        // this expression in reasonable time" — because every step is generic
        // over a tuple it has to infer.
        var ranked: [Weighted] = []
        ranked.reserveCapacity(cards.count)
        for card in cards {
            let encounter = encounters[card.id] ?? Encounter()
            let weight = priority(for: encounter, isQuestion: card.choices != nil, now: now)
            ranked.append(Weighted(card: card, weight: weight))
        }
        // Ties broken by id, so the shortlist is stable rather than dependent
        // on the deck file's order — which content agents rewrite.
        ranked.sort { $0.weight == $1.weight ? $0.card.id < $1.card.id : $0.weight > $1.weight }
        let front: [Weighted] = Array(ranked.prefix(shortlist))

        var total: Double = 0
        for entry in front {
            total += max(entry.weight, floorWeight)
        }
        var target = randomness() * total
        for entry in front {
            target -= max(entry.weight, floorWeight)
            if target <= 0 {
                return entry.card
            }
        }
        return front.last?.card
    }

    /// A card and what it is currently worth. A named struct rather than a
    /// tuple: see `choose`.
    private struct Weighted {
        let card: Card
        let weight: Double
    }

    /// The least a card can weigh in the draw.
    ///
    /// A card can score zero — shown today, nothing overdue about it — and a
    /// shortlist of zeroes would make the weighted draw divide by nothing. This
    /// keeps every candidate reachable and keeps the sum positive.
    private static let floorWeight: Double = 0.01

    // MARK: - Folding the logs

    /// Everything the two logs say, per card, in one pass.
    ///
    /// Order matters — a run is consecutive right answers SINCE the last miss —
    /// so both logs are applied oldest first.
    static func encounters(sightings: [StudySighting], answers: [StudyAnswer]) -> [String: Encounter] {
        var all: [String: Encounter] = [:]

        for sighting in sightings.sorted(by: { $0.ts < $1.ts }) {
            var entry = all[sighting.card] ?? Encounter()
            entry.sightings += 1
            if sighting.opened {
                entry.opened += 1
            }
            entry.lastSeen = Date(timeIntervalSince1970: Double(sighting.ts) / 1000)
            all[sighting.card] = entry
        }

        for answer in answers.sorted(by: { $0.ts < $1.ts }) {
            var entry = all[answer.card] ?? Encounter()
            entry.answered += 1
            if answer.right {
                entry.run += 1
            } else {
                entry.misses += 1
                entry.run = 0
                // Only when the words were recorded. An answer from before the
                // field existed is a miss the app cannot describe, and guessing
                // at it from the card's options as they stand today is exactly
                // the lie `StudyAnswer.pickedText` exists to prevent.
                if let wording = answer.pickedText {
                    entry.wrongWordings[wording, default: 0] += 1
                }
            }
            // AN ANSWER PROVES A SIGHTING.
            //
            // The sighting log is newer than the answer log, so every answer
            // Eden gave before this file existed — and every answer that comes
            // back from a backup written before it — has no sighting beside it.
            // Without this the scheduler would treat a question he answered
            // last month as one he has never met, and the `fresh` slot would
            // spend the next year re-introducing cards he knows.
            if entry.sightings == 0 {
                entry.sightings = 1
                entry.opened = 1
            }
            let when = Date(timeIntervalSince1970: Double(answer.ts) / 1000)
            if entry.lastSeen == nil || entry.lastSeen! < when {
                entry.lastSeen = when
            }
            all[answer.card] = entry
        }

        return all
    }
}
