import Foundation

/* ===========================================================================
 *  THE STUDY DECK
 *  ---------------------------------------------------------------------------
 *  Rotation, and how often a card is allowed to interrupt you. `04-rules.md §6`
 *  — and the numbers in it are deliberate, not round.
 *
 *  · TWO CARDS PER SESSION on rests, plus one on the summary. Not one per long
 *    rest: session A has seven rests of 45s or more, and eight cards in twenty
 *    minutes turns a workout into homework. Each one after the second lands
 *    less than the one before.
 *
 *  · Only on rests of 45 seconds or more, and NEVER on the 20-second myo rest.
 *    That rest IS the training stimulus; anything inviting you to linger there
 *    breaks the exercise.
 *
 *  · Not on the first long rest. That one is spent getting your breath back
 *    after the opening set, not reading.
 *
 *  This file owns the EVENTS and the dosing. What those events mean — when a
 *  card has earned another showing, and which of three hundred is worth this
 *  particular rest — is `StudyPlan`, kept separate so the rules can be asserted
 *  without a defaults suite.
 *
 *  ── the rotation, and why it changed ─────────────────────────────────────
 *  Cards were drawn WITHOUT REPLACEMENT: a cycle set held everything already
 *  shown, and every card appeared before any repeated. At 26 cards that was
 *  right. At three hundred it is a twenty-week cycle, and it made "a question you missed
 *  comes back sooner" impossible — a card you missed was in the seen set by
 *  definition, so it could not be drawn again until the cycle turned over.
 *  Measured: a median of fifty-seven sessions before a missed card came back.
 *
 *  Rotation is now a scheduler over two append-only logs, and both of them ride
 *  in the backup. That reverses this file's old note that rotation state was
 *  disposable and deliberately not exported — which was true of a cycle set,
 *  and is not true of a year of knowing what he has seen and missed.
 * ======================================================================== */

@MainActor
enum Deck {
    /// Rests shorter than this get no card.
    static let minimumRestForCard = 45

    /// Short-term memory, so the same card cannot turn up twice in one sitting.
    /// In memory on purpose: a relaunch ends the sitting.
    ///
    /// SEVEN, which is A's three cards plus B's four — the largest pair of
    /// consecutive sessions there is, and therefore the smallest window that
    /// keeps the guarantee this exists for: a card cannot repeat within a
    /// session, or in the next one.
    ///
    /// It was six, when every session carried three. Six was already a session
    /// and a half rather than two, and B carrying a fourth card would have made
    /// a card shown on Monday reachable again on Tuesday. Derived from the
    /// program rather than chosen, so it moves when the program does — and the
    /// smallest window that holds is the right one, because every card past it
    /// is a day added to how long a question he got wrong takes to come back.
    private static let recentLimit = 7
    private static var recent: [String] = []

    /// And the same for TOPICS, which is the other half of what Eden meant by
    /// *"so it's always diverse"*. Cards all about Burgundy make a narrow
    /// morning even when they are different cards, and with 113 topics in the
    /// deck there is no reason to allow it.
    ///
    /// FOUR, matching the most cards a session can carry. At three, B's fourth
    /// card could have repeated the topic of its first.
    private static let recentTopicLimit = 4
    private static var recentTopics: [String] = []

    // MARK: - Dosing

    /// A THIRD card only ever goes on a rest at least this long.
    ///
    /// Eden: *"maybe fitting another question or two in each workout if possible
    /// somewhere with 60+ secs"*. The "if possible" is load-bearing and is why
    /// this is a floor rather than a target — a 45-second rest has to carry the
    /// question, the four options, the think and the answer, and it is already
    /// the tightest of them.
    static let minimumRestForExtraCard = 60

    /// Working sets that must lie between two carded rests.
    ///
    /// The old rule was that the two cards could not be ADJACENT LONG RESTS,
    /// which was a proxy for "far apart in time" that held only while a session
    /// had seven of them. Session B has four, and its rests at steps 6 and 9
    /// are two working sets apart — a whole superset round, ninety-odd seconds
    /// of effort. Counting sets says what the old rule meant.
    static let minimumSetsBetweenCards = 2

    /// Which rest steps carry a card.
    ///
    /// Two of them, taken from roughly the first and third quarter of the long
    /// rests so they land spread across the session, and never from the very
    /// first one — that one is for getting your breath back.
    ///
    /// Then a third, if the session can afford it: a free rest of at least
    /// `minimumRestForExtraCard`, with at least `minimumSetsBetweenCards`
    /// between it and its neighbours. **Session A cannot afford one** — its only
    /// spare 60-second rest is a single push-up set away from a card it already
    /// carries — and session B can. That asymmetry is the rule working, not a
    /// bug: the answer to "can we fit another question in" is allowed to be no.
    static func cardRestIndices(in steps: [Step]) -> [Int] {
        let long = steps.enumerated().compactMap { index, step -> Int? in
            guard case let .rest(rest) = step, rest.seconds >= minimumRestForCard else { return nil }
            return index
        }
        guard long.count > 1 else { return long }

        func at(_ fraction: Double) -> Int {
            let position = min(long.count - 1, max(1, Int((Double(long.count) * fraction).rounded())))
            return long[position]
        }
        var chosen = Array(Set([at(0.25), at(0.72)])).sorted()

        // The first long rest is never a candidate, for the third card either.
        for candidate in long.dropFirst() where !chosen.contains(candidate) {
            guard case let .rest(rest) = steps[candidate],
                  rest.seconds >= minimumRestForExtraCard,
                  chosen.allSatisfy({ setsBetween(candidate, $0, in: steps) >= minimumSetsBetweenCards })
            else {
                continue
            }
            chosen.append(candidate)
            chosen.sort()
            break
        }
        return chosen
    }

    /// Working sets strictly between two step indices, in either order.
    private static func setsBetween(_ one: Int, _ other: Int, in steps: [Step]) -> Int {
        let range = min(one, other) + 1 ..< max(one, other)
        return steps[range].compactMap(\.asSet).count
    }

    /// What each of a session's three cards is FOR, in the order they land.
    ///
    /// The first rest card opens the deck up and the second closes a loop.
    /// See `StudyPlan.Intent`: asking each slot for something different is what
    /// stops coverage and review from being a trade against each other.
    ///
    /// **The third, where a session can afford one, reviews.** This was written
    /// as `.fresh` first, on what looked like solid reasoning: the deck holds
    /// ~450 cards, he has met about a quarter, so coverage is what another card
    /// buys most, and review is already served by slot 1 and by `.open`.
    ///
    /// The year-long simulation disagreed, and it was right. A fresh slot meets
    /// new cards, every new card joins the review pool, and the pool grows
    /// faster than the draws that serve it: a question he got wrong went from
    /// coming back in a median of **5 days to 8**, with a 90th percentile of
    /// **28 days rather than 9**. Coverage up, and the thing Eden actually
    /// asked the scheduler for — *"i wanna bring back questions that i got
    /// wrong more often so i can iterate and learn better"* — measurably worse.
    ///
    /// So the extra card goes to review. Coverage still improves, because a
    /// fourth card is a fourth card and `.fresh` still leads every session; it
    /// just improves by less than it would have, in exchange for not spending
    /// a stated priority to buy it.
    static func intent(forCardNumber number: Int) -> StudyPlan.Intent {
        switch number {
        case 0: .fresh
        case 1: .review
        case 2: .review
        default: .open
        }
    }

    /// What the SUMMARY's card asks for — the one with no timer to beat.
    ///
    /// Named rather than positional. It used to be `intent(forCardNumber: 2)`,
    /// which was only ever a way of spelling "the third one", and the moment a
    /// session could carry a real third card that spelling started meaning
    /// something else. `.open` takes whatever the deck wants most, which is
    /// usually the hardest thing in the queue: the right thing to read standing
    /// still.
    static let summaryIntent: StudyPlan.Intent = .open

    /// How long to think before the answer appears by itself.
    ///
    /// Scaled to the rest, then clamped: never so fast that a 45s rest gives no
    /// chance to work it out, never so slow that a 90s rest runs out before the
    /// answer has been read.
    static func revealDelay(forRestOf seconds: Int) -> TimeInterval {
        min(11.0, max(6.5, Double(seconds) * 0.160))
    }

    /// WHEN THE ANSWER IS DUE, in seconds from now, at the moment a rest opens.
    ///
    /// The two kinds of card want opposite things and one rule cannot serve
    /// both.
    ///
    /// **A factoid is passive.** Nothing is asked of him, so its answer arrives
    /// after the thinking time and `04-rules.md §6` requires exactly that: you
    /// must never miss the timer because you were thinking.
    ///
    /// **A question is a prompt, and the prompt is the point.** Eden, when the
    /// first version of this treated both the same: *"what happened to reading
    /// the question and choosing if i wanna answer or not by clicking"* — the
    /// card was opening itself about eight seconds in and taking the decision
    /// away from him. So a question's own deadline sits at the FAR END of the
    /// rest. He gets almost the whole rest to read it and decide, and only a
    /// question he never engages with opens itself, late, with just enough left
    /// to read the answer.
    static func answerDue(isQuestion: Bool, thinking: TimeInterval, restRemaining: TimeInterval) -> TimeInterval {
        guard isQuestion else { return thinking }
        // Never sooner than a factoid would have been: on a rest too short to
        // hold both windows the question simply stays a prompt and the rest
        // ends, which is better than snatching it open at the last second.
        return max(thinking, restRemaining - thinking)
    }

    /// The summary card gets longer, because there is no timer to beat.
    static let summaryRevealDelay: TimeInterval = 14

    // MARK: - The draw

    /// Draw one card, log that it was shown, and hold it back from the rest of
    /// the sitting.
    ///
    /// `preferring` is what this slot is for — see `intent(forCardNumber:)`.
    /// The default is `.open` so a caller that has no opinion still gets the
    /// most-wanted card rather than a random one.
    static func draw(
        preferring intent: StudyPlan.Intent = .open,
        using defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> Card? {
        guard !Cards.all.isEmpty else { return nil }
        let history = encounters(using: defaults)

        // The sitting's guards, in falling order of how much they matter. A
        // guard that would empty the pool is dropped rather than enforced: no
        // rest goes cardless to protect a preference.
        var pool = Cards.all.filter { !recent.contains($0.id) && !recentTopics.contains($0.topic) }
        if pool.isEmpty {
            pool = Cards.all.filter { !recent.contains($0.id) }
        }
        if pool.isEmpty {
            pool = Cards.all
        }

        let candidates = StudyPlan.candidates(pool, intent: intent, encounters: history, now: now)
        guard let card = StudyPlan.choose(from: candidates, encounters: history, now: now) else { return nil }

        sight(card.id, using: defaults, now: now)
        remember(card)
        return card
    }

    static func reset(using defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: seenKey)
        defaults.removeObject(forKey: masteryKey)
        defaults.removeObject(forKey: answersKey)
        defaults.removeObject(forKey: sightingsKey)
        recent.removeAll()
        recentTopics.removeAll()
    }

    /// Keys that no longer hold anything the app reads.
    ///
    /// `seenKey` was the cycle set and `masteryKey` was a cache of a reading
    /// that is now taken from the log every time it is asked for. Both are
    /// still cleared by `reset` so an install carrying them does not keep them
    /// forever, and neither is written again.
    private static let seenKey = "morning.cards.seen.v1"
    private static let masteryKey = "morning.cards.mastery.v1"

    // MARK: - Mastery

    /// What the app remembers about one question.
    ///
    /// Deliberately NOT a score. `04-direction-reset.md` §2.2 and `PRODUCT.md`
    /// settle the register as warmer voice only — no points, no levels, no
    /// badges, no streak to protect. This is knowledge state: what you have
    /// missed, and whether you have since got it right enough times to stop
    /// asking. It is read back as a true statement, never as a number that goes
    /// up.
    struct Mastery: Codable, Equatable {
        /// Times answered wrong, ever.
        var misses = 0
        /// Consecutive right answers since the last miss.
        var run = 0
    }

    /// Two right in a row and a question goes quiet.
    static var settledRun: Int {
        StudyPlan.settledRun
    }

    /// Derived from the log every time, rather than cached beside it.
    ///
    /// The cache is gone. Its comment already said the events were the source
    /// of truth and the summary was a reading of them — *"a reading that can
    /// disagree with its source is a bug waiting to be found"* — and keeping
    /// both meant the bug was always one missed write away. A few hundred
    /// events folded three times a session costs nothing.
    static func mastery(using defaults: UserDefaults = .standard) -> [String: Mastery] {
        masteryFrom(answers(using: defaults))
    }

    /// Records an answer the user ACTUALLY GAVE.
    ///
    /// Never called when a rest runs out unanswered. Eden's ruling, and the
    /// right one: a slow morning is not ignorance, and writing a result nobody
    /// chose would make the deck's own record untrue.
    /// `wording` is what the option he tapped actually said. Required rather
    /// than defaulted: an index alone cannot describe a mistake later, and a
    /// parameter with a default is a parameter someone forgets. Every real
    /// caller has the text in hand — `pick` is only reachable on a card whose
    /// `choices` exist.
    static func record(
        _ id: String,
        picked: Int,
        right: Bool,
        wording: String,
        using defaults: UserDefaults = .standard
    ) {
        appendAnswer(
            StudyAnswer(
                card: id,
                ts: Int(Date().timeIntervalSince1970 * 1000),
                picked: picked,
                right: right,
                pickedText: wording
            ),
            using: defaults
        )
    }

    /// A question you have missed and not yet settled.
    static func isDue(_ id: String, using defaults: UserDefaults = .standard) -> Bool {
        mastery(using: defaults)[id].map { $0.misses > 0 && $0.run < settledRun } ?? false
    }

    /// Everything the app knows about one card — for the card itself to read.
    static func encounter(for id: String, using defaults: UserDefaults = .standard) -> StudyPlan.Encounter? {
        encounters(using: defaults)[id]
    }

    static func encounters(using defaults: UserDefaults = .standard) -> [String: StudyPlan.Encounter] {
        StudyPlan.encounters(sightings: sightings(using: defaults), answers: answers(using: defaults))
    }

    /// The deck's state as facts, for the Summary's one line.
    ///
    /// A struct rather than a tuple because the SENTENCE belongs with the
    /// numbers. Copy assembled at the call site is copy no test can see, and
    /// this app has already shipped one screen whose branches nothing could
    /// reach — see `StudyCardBody`.
    struct Standing: Equatable {
        /// Distinct cards he has actually STUDIED — see
        /// `StudyPlan.Encounter.engagements`. Not the same as cards shown: a
        /// question that came up while he was getting his breath back and was
        /// never opened is not one he has met, and a line that counted it would
        /// overstate him to himself every morning.
        var met = 0
        var cards = 0
        /// Distinct questions he has answered at least once.
        var answered = 0
        /// Of those: settled, and still being missed.
        var settled = 0
        var shaky = 0

        /// The Summary's line, **or nothing at all**.
        ///
        /// `plans/004` is specific about what this may and may not be:
        /// *"Progress reads as a true statement about knowledge — '19 of 26
        /// solid, 4 you keep missing' — never as a score."*
        ///
        /// **The denominator changed, because the deck did.** That sentence was
        /// written for 26 cards. Against 302 it reads "19 of 302 questions
        /// solid" — six percent — which is a score of six percent wearing a
        /// fact's clothes, and it would get WORSE every time a card was added.
        /// So the questions are counted against the ones he has actually
        /// answered, which is the number that can only go up by studying.
        ///
        /// **What he has met leads**, because at three hundred cards that is
        /// the interesting fact and the one that moves every morning. Eden went
        /// to fifteen writing groups and a curriculum review for those cards;
        /// how much of it he has seen is worth saying out loud.
        ///
        /// **Nothing, until there is something true to say.** A deck nobody has
        /// answered has nothing, and "0 of 302" on the first morning is a zero
        /// dressed as a fact.
        var line: String? {
            guard met > 0, cards > 0 else { return nil }
            let coverage = "\(met) of \(cards) cards met."
            guard answered > 0 else { return coverage }

            let missed = shaky == 1 ? "question" : "questions"
            switch (settled, shaky) {
            case (0, 0):
                return coverage
            case (0, _):
                return "\(coverage) \(shaky) \(missed) you keep missing."
            case (_, 0):
                let noun = settled == 1 ? "question" : "questions"
                return "\(coverage) \(settled) \(noun) solid."
            default:
                let noun = settled == 1 ? "question" : "questions"
                return "\(coverage) \(settled) \(noun) solid, \(shaky) you keep missing."
            }
        }
    }

    static func standing(using defaults: UserDefaults = .standard) -> Standing {
        let history = encounters(using: defaults)
        let questions = Cards.all.filter { $0.choices != nil }
        return Standing(
            met: Cards.all.count { (history[$0.id]?.engagements(isQuestion: $0.choices != nil) ?? 0) > 0 },
            cards: Cards.all.count,
            answered: questions.count { (history[$0.id]?.answered ?? 0) > 0 },
            settled: questions.count { (history[$0.id]?.run ?? 0) >= settledRun },
            shaky: questions.count { history[$0.id]?.isShaky == true }
        )
    }

    // MARK: - The answer log

    private static let answersKey = "morning.cards.answers.v1"

    /// Every answer he has given, oldest first.
    ///
    /// Append-only, and deliberately never trimmed. Two questions a session is
    /// under a thousand events a year; the cost of keeping all of them is
    /// nothing next to the cost of having thrown away the one a future feature
    /// wanted.
    static func answers(using defaults: UserDefaults = .standard) -> [StudyAnswer] {
        decode(answersKey, using: defaults) ?? []
    }

    private static func appendAnswer(_ answer: StudyAnswer, using defaults: UserDefaults) {
        encode(answers(using: defaults) + [answer], to: answersKey, using: defaults)
    }

    /// Puts a restored log back.
    ///
    /// This is half of what makes an import restore study progress rather than
    /// just study history — see `restoreSightings` for the other half. Nothing
    /// is recomputed and stored: mastery and the schedule are both readings of
    /// these events, taken fresh every time they are asked for.
    static func restoreAnswers(_ log: [StudyAnswer], using defaults: UserDefaults = .standard) {
        encode(log, to: answersKey, using: defaults)
    }

    /// Mastery as the log implies it. Order matters — a run is consecutive
    /// right answers SINCE the last miss — so the log must be applied oldest
    /// first, which is how it is stored.
    static func masteryFrom(_ log: [StudyAnswer]) -> [String: Mastery] {
        StudyPlan.encounters(sightings: [], answers: log)
            .mapValues { Mastery(misses: $0.misses, run: $0.run) }
    }

    // MARK: - The sighting log

    private static let sightingsKey = "morning.cards.sightings.v1"

    /// Every time a card was put in front of him, oldest first.
    static func sightings(using defaults: UserDefaults = .standard) -> [StudySighting] {
        decode(sightingsKey, using: defaults) ?? []
    }

    /// Records that a card was SHOWN.
    ///
    /// Called from `draw` rather than from the screens, so it cannot be
    /// forgotten by a new surface that shows a card — and so the review launch
    /// flags, which set a card directly and never draw one, write nothing.
    /// Reviewing a screen must never write study history.
    static func sight(_ id: String, using defaults: UserDefaults = .standard, now: Date = Date()) {
        let sighting = StudySighting(card: id, ts: Int(now.timeIntervalSince1970 * 1000))
        encode(sightings(using: defaults) + [sighting], to: sightingsKey, using: defaults)
    }

    /// Records that he opened the card now on screen, rather than letting the
    /// clock open it.
    ///
    /// **The one write in either log that is not an append**, and it is a
    /// deliberate exception: a sighting is an event that is still happening
    /// when it is first written, and the alternative — waiting until the rest
    /// ends to write anything — loses the whole sighting to a force-quit.
    ///
    /// Idempotent, so every by-hand path can call it without coordinating:
    /// opening a question, revealing a factoid, and picking an answer all mean
    /// the same thing here.
    static func markOpened(_ id: String, using defaults: UserDefaults = .standard) {
        var log = sightings(using: defaults)
        guard let index = log.lastIndex(where: { $0.card == id }), !log[index].opened else { return }
        log[index].opened = true
        encode(log, to: sightingsKey, using: defaults)
    }

    static func restoreSightings(_ log: [StudySighting], using defaults: UserDefaults = .standard) {
        encode(log, to: sightingsKey, using: defaults)
    }

    // MARK: - Storage

    private static func decode<T: Decodable>(_ key: String, using defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func encode(_ value: some Encodable, to key: String, using defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func remember(_ card: Card) {
        recent.append(card.id)
        if recent.count > recentLimit {
            recent.removeFirst()
        }
        recentTopics.append(card.topic)
        if recentTopics.count > recentTopicLimit {
            recentTopics.removeFirst()
        }
    }
}
