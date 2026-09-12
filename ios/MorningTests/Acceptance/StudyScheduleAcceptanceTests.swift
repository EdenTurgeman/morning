//
//  StudyScheduleAcceptanceTests.swift
//
//  The scheduler that replaced draw-without-replacement.
//
//  Everything here is pure — `StudyPlan` takes the logs and a date and returns
//  a number — so these run without a defaults suite and without drawing a card.
//  That is the whole reason the scheduling rules were split out of `Deck`.
//

import XCTest
@testable import Morning

@MainActor
final class StudyScheduleAcceptanceTests: XCTestCase {
    // MARK: - The thing Eden actually asked for

    /// A QUESTION HE MISSED COMES BACK IN DAYS; ONE HE HAS SETTLED, IN MONTHS.
    ///
    /// Eden: *"i wanna bring back questions that i got wrong more often so i
    /// can iterate and learn better."* The old deck could not do this at all —
    /// a card was held out of the pool until every other card had been shown,
    /// which at 302 cards is twenty weeks — so this is the assertion that the
    /// mechanism exists rather than just being described in a comment.
    func testAMissedQuestionComesBackInDaysAndASettledOneInMonths() {
        let missed = StudyPlan.Encounter(sightings: 3, answered: 3, misses: 1, run: 0)
        let onceRight = StudyPlan.Encounter(sightings: 3, answered: 3, misses: 1, run: 1)
        let settled = StudyPlan.Encounter(sightings: 4, answered: 4, misses: 1, run: 2)
        let old = StudyPlan.Encounter(sightings: 8, answered: 8, misses: 0, run: 5)

        let missedDays = StudyPlan.interval(for: missed, isQuestion: true)
        let settledDays = StudyPlan.interval(for: settled, isQuestion: true)

        XCTAssertLessThan(missedDays, 3, "a question he just got wrong must come back inside a week")
        XCTAssertGreaterThan(settledDays, 10, "a settled question must go quiet for weeks, not days")
        XCTAssertGreaterThan(
            StudyPlan.interval(for: old, isQuestion: true),
            60,
            "a question right five times running is worth asking again next season, not next month"
        )

        // And the ladder only ever climbs.
        XCTAssertLessThan(missedDays, StudyPlan.interval(for: onceRight, isQuestion: true))
        XCTAssertLessThan(StudyPlan.interval(for: onceRight, isQuestion: true), settledDays)
    }

    /// MISSING IT MORE OFTEN BRINGS IT BACK MORE OFTEN, PROPORTIONALLY.
    ///
    /// *"bring back questions that i got wrong more often"* — the literal
    /// reading. A card fumbled once and a card missed four times are not the
    /// same card, and the old binary `isDue` treated them identically.
    func testEachMissShortensTheIntervalAndTheShorteningStops() {
        func days(misses: Int) -> Double {
            StudyPlan.interval(for: .init(sightings: 5, answered: 5, misses: misses, run: 2), isQuestion: true)
        }

        XCTAssertGreaterThan(days(misses: 0), days(misses: 1))
        XCTAssertGreaterThan(days(misses: 1), days(misses: 2))
        XCTAssertGreaterThan(days(misses: 3), days(misses: 4))
        XCTAssertLessThan(
            days(misses: 4),
            days(misses: 1) / 2,
            "four misses must bring a card back more than twice as often as one"
        )

        // Past the ceiling it stops. A card missed ten times is not served by
        // being asked every single morning — it would crowd out the deck.
        XCTAssertEqual(days(misses: 4), days(misses: 10), accuracy: 0.0001)
    }

    /// A FACTOID IS SPACED FURTHER OUT THAN A QUESTION, ALWAYS.
    ///
    /// There is no signal to react to: it cannot be got wrong. The only honest
    /// policy is a few showings, further apart each time.
    func testAFactoidIsSpacedFurtherOutThanAQuestion() {
        for shown in 1 ... 5 {
            let encounter = StudyPlan.Encounter(sightings: shown, answered: 0)
            XCTAssertGreaterThan(
                StudyPlan.interval(for: encounter, isQuestion: false),
                StudyPlan.interval(for: encounter, isQuestion: true),
                "a factoid seen \(shown) time(s) must wait longer than a question in the same place"
            )
        }
        XCTAssertLessThan(
            StudyPlan.interval(for: .init(sightings: 1), isQuestion: false),
            StudyPlan.interval(for: .init(sightings: 4), isQuestion: false),
            "a factoid's interval grows with each showing"
        )
    }

    /// A QUESTION HE LET TIME OUT IS NOT TREATED AS KNOWLEDGE.
    ///
    /// Nothing is written when a rest ends unanswered — Eden's ruling, so a
    /// slow morning is never recorded as ignorance. But it is not a right
    /// answer either, and the card has not done its job.
    func testAQuestionHeNeverAnsweredSitsBetweenAMissAndASettledCard() {
        let unanswered = StudyPlan.interval(for: .init(sightings: 2, answered: 0), isQuestion: true)
        let missed = StudyPlan.interval(for: .init(sightings: 2, answered: 2, misses: 1), isQuestion: true)
        let settled = StudyPlan.interval(for: .init(sightings: 3, answered: 3, run: 2), isQuestion: true)

        XCTAssertGreaterThan(unanswered, missed)
        XCTAssertLessThan(unanswered, settled)
    }

    // MARK: - Novelty against review

    /// A CARD HE HAS NEVER MET COMPETES ON THE SAME SCALE AS ONE HE MISSED.
    ///
    /// Novelty is a priority, not a rule that runs first — which is what lets
    /// the two balance themselves instead of being traded off by a constant.
    func testNoveltyAndOverdueCompeteOnOneScale() {
        let now = Date()
        func priority(_ encounter: StudyPlan.Encounter, isQuestion: Bool = true) -> Double {
            StudyPlan.priority(for: encounter, isQuestion: isQuestion, now: now)
        }
        func daysAgo(_ days: Double) -> Date {
            now.addingTimeInterval(-days * 86400)
        }

        let unseen = priority(.init())
        XCTAssertEqual(unseen, StudyPlan.noveltyPriority)

        // Settled and shown yesterday: nothing wants it.
        XCTAssertLessThan(
            priority(.init(sightings: 4, lastSeen: daysAgo(1), answered: 4, run: 2)),
            unseen,
            "a card he saw yesterday and knows must not outrank one he has never met"
        )
        // Missed, and four days stale: it beats new material.
        XCTAssertGreaterThan(
            priority(.init(sightings: 3, lastSeen: daysAgo(4), answered: 3, misses: 1, run: 0)),
            unseen,
            "a question he got wrong last week is worth more than a card he has never seen"
        )
        // And nothing runs away with the queue forever.
        XCTAssertEqual(
            priority(.init(sightings: 1, lastSeen: daysAgo(4000), answered: 1, run: 1)),
            StudyPlan.priorityCeiling,
            accuracy: 0.0001,
            "priority is capped, or one forgotten card would sit at the top of the queue for ever"
        )
    }

    // MARK: - What each slot asks for

    func testTheFreshSlotTakesUnseenCardsAndFallsBackRatherThanReturningNothing() {
        let now = Date()
        let deck = Array(Cards.all.prefix(20))
        let met = Dictionary(uniqueKeysWithValues: deck.prefix(15).map {
            ($0.id, StudyPlan.Encounter(sightings: 1, lastSeen: now))
        })

        let fresh = StudyPlan.candidates(deck, intent: .fresh, encounters: met, now: now)
        XCTAssertEqual(fresh.count, 5)
        XCTAssertTrue(fresh.allSatisfy { met[$0.id] == nil }, "the fresh slot must draw only unseen cards")

        // NEVER NOTHING. A slot that cannot be filled falls through to an
        // ordinary draw; an empty rest is a worse outcome than an off one.
        let everythingSeen = Dictionary(uniqueKeysWithValues: deck.map {
            ($0.id, StudyPlan.Encounter(sightings: 1, lastSeen: now))
        })
        XCTAssertEqual(
            StudyPlan.candidates(deck, intent: .fresh, encounters: everythingSeen, now: now).count,
            deck.count,
            "a deck he has met entirely must still yield a card"
        )
        XCTAssertTrue(StudyPlan.candidates([], intent: .fresh, encounters: [:], now: now).isEmpty)
    }

    func testTheReviewSlotTakesWhatHeGotWrong() throws {
        let now = Date()
        let deck = Array(Cards.all.filter { $0.choices != nil }.prefix(20))
        let shakyOne = try XCTUnwrap(deck.first)
        let settledOne = try XCTUnwrap(deck.last)

        let history = [
            shakyOne.id: StudyPlan.Encounter(sightings: 2, lastSeen: now, answered: 2, misses: 1, run: 0),
            settledOne.id: StudyPlan.Encounter(sightings: 3, lastSeen: now, answered: 3, misses: 1, run: 2),
        ]

        let review = StudyPlan.candidates(deck, intent: .review, encounters: history, now: now)
        XCTAssertEqual(review.map(\.id), [shakyOne.id], "review means a question he is still getting wrong")

        // With nothing shaky it takes whatever is genuinely overdue instead, so
        // the slot still earns its place on a deck with no misses in it yet.
        let none = StudyPlan.candidates(deck, intent: .review, encounters: [:], now: now)
        XCTAssertEqual(none.count, deck.count, "an unseen deck is entirely overdue")
    }

    /// THE LAST CARD OF THE MORNING REVIEWS ONLY WHILE HE IS BEHIND.
    ///
    /// One review slot could not keep up: misses arrive faster than one card a
    /// session settles them, so a backlog grew and every missed question waited
    /// behind it. Ordering that queue changed nothing, because every shaky card
    /// sits at the priority ceiling — the wait was throughput, not order.
    ///
    /// Reviewing on the third slot ALWAYS fixes it and costs coverage.
    /// Reviewing only over a threshold costs nothing measurable and takes the
    /// median wait from six days to four.
    func testTheOpenSlotReviewsOnlyWhileTheBacklogIsBigEnough() {
        let now = Date()
        let deck = Array(Cards.all.filter { $0.choices != nil }.prefix(30))

        func shaky(_ count: Int) -> [String: StudyPlan.Encounter] {
            Dictionary(uniqueKeysWithValues: deck.prefix(count).map {
                ($0.id, StudyPlan.Encounter(sightings: 2, lastSeen: now, answered: 2, misses: 1, run: 0))
            })
        }

        // Under the threshold the last card of the morning is free to be
        // anything, which is why coverage survives this.
        let relaxed = shaky(StudyPlan.reviewBacklog - 1)
        XCTAssertEqual(
            StudyPlan.candidates(deck, intent: .open, encounters: relaxed, now: now).count,
            deck.count,
            "with a small backlog the summary's card must still be able to be anything"
        )

        // At it, it reviews.
        let behind = shaky(StudyPlan.reviewBacklog)
        let narrowed = StudyPlan.candidates(deck, intent: .open, encounters: behind, now: now)
        XCTAssertEqual(narrowed.count, StudyPlan.reviewBacklog)
        XCTAssertTrue(
            narrowed.allSatisfy { behind[$0.id]?.isShaky == true },
            "carrying a backlog, the last card of the morning is not free"
        )
    }

    // MARK: - The draw itself

    func testTheDrawIsWeightedTowardsTheFrontOfTheQueueAndAlwaysReturnsACard() throws {
        let now = Date()
        let deck = Array(Cards.all.prefix(40))
        let wanted = try XCTUnwrap(deck.last)

        // One card far past its interval, everything else shown this morning.
        var history = Dictionary(uniqueKeysWithValues: deck.map {
            ($0.id, StudyPlan.Encounter(sightings: 2, lastSeen: now, answered: 2, run: 2))
        })
        history[wanted.id] = StudyPlan.Encounter(
            sightings: 2,
            lastSeen: now.addingTimeInterval(-400 * 86400),
            answered: 2,
            misses: 2,
            run: 0
        )

        // `randomness` returning ~0 takes the front of the shortlist.
        XCTAssertEqual(
            StudyPlan.choose(from: deck, encounters: history, now: now, randomness: { 0.0001 })?.id,
            wanted.id,
            "the most overdue card must be at the front of the queue"
        )
        // And whatever the dice say, a non-empty deck always yields a card.
        for roll in stride(from: 0.0, through: 0.999, by: 0.05) {
            XCTAssertNotNil(StudyPlan.choose(from: deck, encounters: history, now: now, randomness: { roll }))
        }
        XCTAssertNil(StudyPlan.choose(from: [], encounters: [:], now: now))
    }

    /// NOTHING IS STRANDED, AND THE DECK KEEPS OPENING UP.
    ///
    /// This is the property that replaced "one cycle shows every card exactly
    /// once". That one was a guarantee about ORDER; this is the guarantee that
    /// actually mattered — no card is unreachable, and review does not crowd
    /// out new material.
    ///
    /// A year of five sessions a week, three cards each, played against the
    /// real deck. He answers about 62% of questions right cold and 85% of ones
    /// he has already missed once, which is the shape of someone learning.
    func testAYearOfSessionsMeetsMostOfTheDeckAndStillBringsBackMisses() throws {
        var history: [String: StudyPlan.Encounter] = [:]
        var recent: [String] = []
        var missedOn: [String: Int] = [:]
        var gaps: [Int] = []
        var random = SeededRandom(seed: 20_260_909)
        let start = Date()

        var sessions = 0
        var day = 0
        while day < 365 {
            // Five sessions a week.
            if day % 7 >= 5 {
                day += 1
                continue
            }
            sessions += 1
            let now = start.addingTimeInterval(Double(day) * 86400)
            var metThisSession = 0
            for slot in 0 ..< 3 {
                let pool = Cards.all.filter { !recent.contains($0.id) }
                let intent = Deck.intent(forCardNumber: slot)
                let candidates = StudyPlan.candidates(pool, intent: intent, encounters: history, now: now)
                let card = try XCTUnwrap(
                    StudyPlan.choose(from: candidates, encounters: history, now: now, randomness: { random.next() })
                )

                if let missed = missedOn.removeValue(forKey: card.id) {
                    gaps.append(day - missed)
                }
                recent.append(card.id)
                if recent.count > 6 {
                    recent.removeFirst()
                }

                if history[card.id] == nil {
                    metThisSession += 1
                }
                var entry = history[card.id] ?? StudyPlan.Encounter()
                entry.sightings += 1
                entry.lastSeen = now
                if card.choices != nil {
                    let right = random.next() < (entry.answered == 0 ? 0.62 : 0.85)
                    entry.answered += 1
                    if right {
                        entry.run += 1
                    } else {
                        entry.misses += 1
                        entry.run = 0
                        missedOn[card.id] = day
                    }
                }
                history[card.id] = entry
            }
            // THE FRESH SLOT'S GUARANTEE, CHECKED EVERY SINGLE SESSION rather
            // than in aggregate: while the deck still holds a card he has never
            // met, one of them is drawn. This is what stops review from closing
            // the deck in around what he already half-knows, and it is a
            // property rather than a statistic.
            XCTAssertGreaterThanOrEqual(
                metThisSession,
                1,
                "session \(sessions) showed nothing new, with \(Cards.all.count - history.count) cards unmet"
            )
            day += 1
        }

        // COVERAGE, which is the axis the old draw was supposed to be good at.
        // Simulated the same way it met 256 cards in a year — and only by never
        // reviewing anything, which is the whole reason it was replaced.
        //
        // Bounded below by the sessions rather than by a share of the deck: the
        // deck is written by agents and grows between runs, so a percentage
        // would fail on the morning a writing group lands rather than on the
        // morning the scheduler breaks.
        XCTAssertGreaterThanOrEqual(
            history.count,
            min(sessions, Cards.all.count),
            "a year of \(sessions) sessions met \(history.count) cards — at least one a session is the promise"
        )
        XCTAssertGreaterThan(history.count, 256, "and it must beat what the draw it replaced managed")

        // REVIEW. The old draw brought a missed card back after a median of 57
        // sessions, and stranded twenty a year entirely.
        let sorted = gaps.sorted()
        let median = try XCTUnwrap(sorted[safe: sorted.count / 2])
        let ninetieth = try XCTUnwrap(sorted[safe: Int(Double(sorted.count) * 0.9)])
        // FOUR DAYS, WHICH EDEN ASKED FOR BY NUMBER.
        //
        // The bound is five rather than four because this is ONE seed of a
        // stochastic year: four is the median across eight of them, and pinning
        // a simulation to its own mean is a test that fails on arithmetic
        // rather than on behaviour. Five or under is the adaptive review slot
        // working. The draw this replaced sat at eleven weeks.
        XCTAssertLessThanOrEqual(
            median,
            5,
            "a question he got wrong took a median of \(median) days to come back"
        )
        XCTAssertLessThanOrEqual(
            ninetieth,
            9,
            "the slow tail is what a backlog looks like: 90th percentile \(ninetieth) days"
        )
        XCTAssertLessThan(
            missedOn.count,
            5,
            "\(missedOn.count) questions he got wrong were never asked again all year"
        )
    }

    // MARK: - Folding the logs

    /// THE TWO LOGS ARE ONE READING, AND ORDER MATTERS.
    func testEncountersFoldBothLogsInOrder() {
        let history = StudyPlan.encounters(
            sightings: [
                StudySighting(card: "w-a", ts: 1000, opened: true),
                StudySighting(card: "w-a", ts: 3000),
                StudySighting(card: "t-b", ts: 2000),
            ],
            answers: [
                StudyAnswer(card: "w-a", ts: 1100, picked: 2, right: false, pickedText: "Chenin Blanc"),
                StudyAnswer(card: "w-a", ts: 3100, picked: 0, right: true, pickedText: "Chardonnay"),
            ]
        )

        let a = history["w-a"]
        XCTAssertEqual(a?.sightings, 2)
        XCTAssertEqual(a?.opened, 1, "being shown a card twice and opening it once is two different numbers")
        XCTAssertEqual(a?.answered, 2)
        XCTAssertEqual(a?.misses, 1)
        XCTAssertEqual(a?.run, 1, "a run counts the rights SINCE the last miss, so the order is load-bearing")
        XCTAssertEqual(a?.wrongWordings, ["Chenin Blanc": 1], "the WORDS he chose are worth the most")
        XCTAssertEqual(a?.lastSeen, Date(timeIntervalSince1970: 3.1))

        // A factoid: seen, never answered, and that is not a failure state.
        XCTAssertEqual(history["t-b"]?.sightings, 1)
        XCTAssertEqual(history["t-b"]?.answered, 0)
        XCTAssertFalse(history["t-b"]?.isShaky ?? true)
    }

    /// AN ANSWER PROVES A SIGHTING — THE MIGRATION CASE.
    ///
    /// The sighting log is newer than the answer log. Every answer Eden gave
    /// before it existed, and every one that comes back from a backup written
    /// before it existed, arrives with no sighting beside it. Without this the
    /// scheduler would call a question he answered last month unseen, and the
    /// `fresh` slot would spend a year re-introducing cards he already knows.
    func testAnAnswerWithNoSightingStillCountsAsHavingMetTheCard() throws {
        let history = StudyPlan.encounters(
            sightings: [],
            answers: [StudyAnswer(card: "w-a", ts: 1_756_000_000_000, picked: 1, right: true)]
        )

        let imported = try XCTUnwrap(history["w-a"])
        XCTAssertEqual(imported.sightings, 1, "he cannot have answered a card he was never shown")
        XCTAssertNotNil(imported.lastSeen, "and the schedule has to know roughly when")
        XCTAssertEqual(imported.run, 1)
        XCTAssertNotEqual(
            StudyPlan.priority(
                for: imported,
                isQuestion: true,
                now: Date(timeIntervalSince1970: 1_756_000_100)
            ),
            StudyPlan.noveltyPriority,
            "an imported answer must not leave the card looking brand new"
        )
    }

    /// THE SAME WRONG ANSWER, TWICE, IS A FACT ABOUT HIM.
    func testARepeatedWrongAnswerIsRecognisedAsAConfusion() {
        func wrong(_ ts: Int, _ index: Int, _ text: String) -> StudyAnswer {
            StudyAnswer(card: "w-a", ts: ts, picked: index, right: false, pickedText: text)
        }

        var history = StudyPlan.encounters(
            sightings: [],
            answers: [wrong(1, 3, "Chenin Blanc"), wrong(2, 1, "Sémillon")]
        )
        XCTAssertNil(history["w-a"]?.confusion, "two different wrong answers are two slips, not a confusion")

        history = StudyPlan.encounters(
            sightings: [],
            answers: [wrong(1, 3, "Chenin Blanc"), wrong(2, 3, "Chenin Blanc"), wrong(3, 1, "Sémillon")]
        )
        let confusion = history["w-a"]?.confusion
        XCTAssertEqual(confusion?.wording, "Chenin Blanc")
        XCTAssertEqual(confusion?.times, 2, "he keeps reaching for the same wrong answer")
    }

    /// IT IS KEYED ON THE WORDS, WHICH IS WHY IT SURVIVES THE DECK CHANGING.
    ///
    /// The deck is rewritten by content agents — options get rephrased and
    /// reordered. Counting by index would call two different answers the same
    /// confusion the moment a card was shuffled, and would name an option he
    /// never chose. This app does not tell those.
    func testTheConfusionIsKeyedOnTheWordsNotTheIndex() {
        // The same words at two different indices: one confusion.
        let moved = StudyPlan.encounters(
            sightings: [],
            answers: [
                StudyAnswer(card: "w-a", ts: 1, picked: 3, right: false, pickedText: "Chenin Blanc"),
                StudyAnswer(card: "w-a", ts: 2, picked: 0, right: false, pickedText: "Chenin Blanc"),
            ]
        )
        XCTAssertEqual(moved["w-a"]?.confusion?.wording, "Chenin Blanc")
        XCTAssertEqual(moved["w-a"]?.confusion?.times, 2)

        // The same index, two different answers: not a confusion.
        let reworded = StudyPlan.encounters(
            sightings: [],
            answers: [
                StudyAnswer(card: "w-a", ts: 1, picked: 2, right: false, pickedText: "Chenin Blanc"),
                StudyAnswer(card: "w-a", ts: 2, picked: 2, right: false, pickedText: "Sémillon"),
            ]
        )
        XCTAssertNil(reworded["w-a"]?.confusion, "one index, two different answers, no confusion")
    }

    /// AN ANSWER FROM BEFORE THE WORDING WAS RECORDED IS A MISS IT CANNOT NAME.
    ///
    /// Every answer logged before `StudyAnswer.pickedText` existed arrives with
    /// none. Those still count — the scheduler is unaffected — and they say
    /// nothing about WHICH answer, because the only way to guess would be to
    /// read the card's options as they stand today, which is exactly the lie
    /// the field exists to prevent.
    func testAnAnswerWithNoWordingCountsAsAMissAndNamesNothing() throws {
        let history = StudyPlan.encounters(
            sightings: [],
            answers: [
                StudyAnswer(card: "w-a", ts: 1, picked: 3, right: false),
                StudyAnswer(card: "w-a", ts: 2, picked: 3, right: false),
            ]
        )
        let entry = try XCTUnwrap(history["w-a"])
        XCTAssertEqual(entry.misses, 2, "it is still a miss, and the schedule still reacts to it")
        XCTAssertTrue(entry.isShaky)
        XCTAssertTrue(entry.wrongWordings.isEmpty)
        XCTAssertNil(entry.confusion, "it cannot say which answer, so it says nothing")
    }

    // MARK: - The confusion, on the card

    private func confusable(_ correct: Int = 1) -> Card {
        Card(
            id: "w-x",
            subject: "wine",
            topic: "Loire",
            q: "What is it?",
            a: "Because.",
            options: ["Chenin Blanc", "Chardonnay", "Sémillon", "Viognier"],
            correct: correct
        )
    }

    private func confused(_ wording: String, _ times: Int) -> StudyPlan.Encounter {
        StudyPlan.Encounter(
            sightings: times + 1,
            lastSeen: Date(),
            answered: times,
            misses: times,
            wrongWordings: [wording: times]
        )
    }

    /// WHAT THE CARD SAYS ABOUT A WRONG ANSWER HE KEEPS REACHING FOR.
    func testTheConfusionIsSaidOnlyWhenItIsTheThingThatJustHappened() {
        let card = confusable()
        let prior = confused("Chenin Blanc", 2)

        // He got it right this morning. This is the moment the loop closes.
        let closed = StudyConfusion.of(prior, card: card, justPicked: 1)
        XCTAssertEqual(closed?.wording, "Chenin Blanc")
        XCTAssertEqual(closed?.times, 2)
        XCTAssertEqual(closed?.repeated, false)
        XCTAssertEqual(closed?.label, "Twice before")

        // He reached for it again.
        let again = StudyConfusion.of(prior, card: card, justPicked: 0)
        XCTAssertEqual(again?.times, 3, "the count includes this morning")
        XCTAssertEqual(again?.repeated, true)
        XCTAssertEqual(again?.label, "That answer, 3 times now")
        XCTAssertEqual(
            again?.showsWording,
            false,
            "the option is already struck four lines up — printing it again reads as a fault"
        )
        XCTAssertEqual(closed?.showsWording, true, "nothing else on the card names the answer he used to give")

        // A DIFFERENT wrong answer. His old confusion is not what just
        // happened, and saying it would bury the mistake he actually made.
        XCTAssertNil(StudyConfusion.of(prior, card: card, justPicked: 2))

        // The rest ran out and the answer arrived on its own. Still true.
        XCTAssertEqual(StudyConfusion.of(prior, card: card, justPicked: nil)?.repeated, false)

        // Three times before reads as three, not as "twice".
        XCTAssertEqual(
            StudyConfusion.of(confused("Chenin Blanc", 3), card: card, justPicked: 1)?.label,
            "3 times before"
        )
    }

    /// ONE WRONG ANSWER IS A SLIP AND THE CARD SAYS NOTHING.
    func testOneWrongAnswerIsNotWorthInterruptingARestFor() {
        XCTAssertNil(StudyConfusion.of(confused("Chenin Blanc", 1), card: confusable(), justPicked: 1))
        XCTAssertNil(StudyConfusion.of(nil, card: confusable(), justPicked: 1))
        // An out-of-range pick cannot happen — `picked` is only ever set from
        // an index the card offered — so the question is what it should do if
        // it ever did. It degrades to the reading for a rest that ran out: a
        // true statement about the past, rather than swallowing one because a
        // caller was wrong about something else.
        XCTAssertEqual(
            StudyConfusion.of(confused("Chenin Blanc", 2), card: confusable(), justPicked: 9),
            StudyConfusion.of(confused("Chenin Blanc", 2), card: confusable(), justPicked: nil)
        )
    }

    /// AN OPTION THE DECK NO LONGER CARRIES GOES UNSAID.
    ///
    /// A content agent can rewrite or drop an option between the morning he
    /// chose it and the morning he would be told about it. The words are still
    /// what he answered — that is why they are stored — but a struck line
    /// matching nothing above it reads as a bug rather than as a memory.
    func testAConfusionWhoseOptionIsGoneIsNotShown() {
        XCTAssertNil(
            StudyConfusion.of(confused("Melon de Bourgogne", 3), card: confusable(), justPicked: 1),
            "the deck no longer offers that answer, so the card does not raise it"
        )
        // A factoid has no options at all and therefore no confusion.
        let factoid = Card(id: "w-f", subject: "wine", topic: "Loire", q: "What?", a: "Because.")
        XCTAssertNil(StudyConfusion.of(confused("Chenin Blanc", 3), card: factoid, justPicked: nil))
    }

    // MARK: - The mark on the card

    /// THE MARK STATES A FACT AND NEVER CONGRATULATES.
    ///
    /// It is the visible half of all of this: the scheduler is invisible by
    /// construction, so without a mark the only way to know any of it works is
    /// to trust it.
    func testTheMarkSaysWhatIsTrueAndSaysNothingOnAFirstMeeting() {
        let card = confusable()
        let factoid = Card(id: "w-f", subject: "wine", topic: "Loire", q: "What?", a: "Because.")

        XCTAssertEqual(StudyMark.of(nil, card: card), .none)
        XCTAssertEqual(
            StudyMark.of(.init(sightings: 1, opened: 1), card: card),
            .none,
            "a first meeting has no fact to state — a mark on every card is furniture"
        )

        func opened(_ times: Int) -> StudyPlan.Encounter {
            .init(sightings: times, opened: times)
        }
        XCTAssertEqual(StudyMark.of(opened(2), card: card), .returning(times: 2))
        XCTAssertEqual(StudyMark.of(opened(2), card: card).label, "2nd time")
        XCTAssertEqual(StudyMark.of(opened(3), card: card).label, "3rd time")
        XCTAssertEqual(StudyMark.of(opened(11), card: card).label, "11th time")
        XCTAssertEqual(StudyMark.of(opened(21), card: card).label, "21st time")

        // A FACTOID IS STUDIED BY BEING SHOWN. It reveals itself and there is
        // nothing to do with one but read it, so demanding a tap would count
        // every factoid he has ever read as unread.
        XCTAssertEqual(
            StudyMark.of(.init(sightings: 3, opened: 0), card: factoid).label,
            "3rd time"
        )

        // THE REMATCH: the mark is on the card while it is still a question.
        let missedOnce = StudyPlan.Encounter(sightings: 3, opened: 3, answered: 3, misses: 1, run: 0)
        XCTAssertEqual(StudyMark.of(missedOnce, card: card), .missed(times: 1))
        XCTAssertEqual(StudyMark.of(missedOnce, card: card).label, "Missed last time")
        XCTAssertTrue(
            StudyMark.of(missedOnce, card: card).isMiss,
            "a miss is the one case drawn in the pen's red"
        )

        let missedTwice = StudyPlan.Encounter(sightings: 5, opened: 5, answered: 5, misses: 2, run: 1)
        XCTAssertEqual(StudyMark.of(missedTwice, card: card).label, "Missed 2×")

        // Settling it says so, on the beat the ink lands — and only for a
        // question he actually used to miss.
        XCTAssertEqual(StudyMark.of(missedTwice, card: card, answeredRight: true), .settled)
        XCTAssertEqual(
            StudyMark.of(missedOnce, card: card, answeredRight: true),
            .missed(times: 1),
            "one right answer out of four options is a 25% accident, not mastery"
        )
        XCTAssertEqual(
            StudyMark.of(.init(sightings: 2, opened: 2, answered: 1, run: 1), card: card, answeredRight: true),
            .returning(times: 2),
            "a question he has never missed cannot be settled — there was nothing to settle"
        )
        XCTAssertEqual(StudyMark.of(missedOnce, card: card, answeredRight: false), .missed(times: 1))
    }

    /// A QUESTION HE NEVER OPENED WAS NOT STUDIED.
    ///
    /// Eden's rule: *"if i didn't interact and answer then it shouldn't be
    /// recorded."* A question sits as a prompt for almost the whole rest so
    /// that opening it is a CHOICE — `Deck.answerDue` exists to protect that
    /// choice — and a choice not made is information, not a study.
    ///
    /// The sighting is still logged. The log keeps what happened; this is the
    /// reading that decides what it meant. Dropping the record would leave the
    /// card looking unseen, so it would come back two sessions later, be
    /// ignored again, and nothing would ever know that was the pattern.
    func testAQuestionHeNeverOpenedDoesNotCountAsHavingStudiedIt() {
        let card = confusable()
        let factoid = Card(id: "w-f", subject: "wine", topic: "Loire", q: "What?", a: "Because.")

        // Shown three times, opened once: he has studied it once.
        let ignoredTwice = StudyPlan.Encounter(sightings: 3, opened: 1)
        XCTAssertEqual(ignoredTwice.engagements(isQuestion: true), 1)
        XCTAssertEqual(
            StudyMark.of(ignoredTwice, card: card),
            .none,
            "three appearances and one study is a first meeting, and says nothing"
        )

        // Never opened at all.
        let neverOpened = StudyPlan.Encounter(sightings: 4, opened: 0)
        XCTAssertEqual(neverOpened.engagements(isQuestion: true), 0)
        XCTAssertEqual(StudyMark.of(neverOpened, card: card), .none)

        // And the sighting count itself is untouched — the log still knows.
        XCTAssertEqual(neverOpened.sightings, 4, "what happened is still recorded")

        // The same encounter on a FACTOID is four studies, because a factoid
        // has nothing to open.
        XCTAssertEqual(neverOpened.engagements(isQuestion: false), 4)
        XCTAssertEqual(StudyMark.of(neverOpened, card: factoid), .returning(times: 4))
    }

    func testNoMarkEverCongratulates() {
        let marks: [StudyMark] = [
            .none, .returning(times: 4), .missed(times: 1), .missed(times: 3), .settled,
        ]
        for mark in marks {
            guard let label = mark.label else { continue }
            for token in ["!", "great", "well done", "nice", "keep it up", "%"] {
                XCTAssertFalse(
                    label.localizedCaseInsensitiveContains(token),
                    "the mark states a fact and does not praise — found \(token) in \(label)"
                )
            }
        }
    }
}

// MARK: - Support

/// A deterministic stand-in for `Double.random`, so the year-long simulation
/// fails for a reason rather than on a Tuesday.
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/* ===========================================================================
 *  THE STUDY PAGE'S FACTS
 *  `plans/010`. Everything the surface shows is a value, so it is assertable
 *  without rendering one.
 * ======================================================================== */

@MainActor
final class StudyReportAcceptanceTests: XCTestCase {
    private func card(
        _ id: String,
        _ subject: String,
        _ topic: String,
        question: Bool = true
    ) -> Card {
        Card(
            id: id,
            subject: subject,
            topic: topic,
            q: "Question \(id)?",
            a: "Because.",
            options: question ? ["Chenin Blanc", "Chardonnay", "Sémillon", "Viognier"] : nil,
            correct: question ? 1 : nil
        )
    }

    private func met(opened: Int = 1) -> StudyPlan.Encounter {
        .init(sightings: opened, opened: opened, lastSeen: Date())
    }

    /// THE INDEX IS ALPHABETICAL, WINE FIRST — AND THE ORDER IS DECLARED.
    ///
    /// It used to fall out of `"tea" < "wine"`, which is a string comparison
    /// nobody decided. Wine leads because it is the larger half of the deck and
    /// the half Eden is studying towards a qualification in.
    func testTheIndexIsWineThenTeaAlphabeticalInsideEach() {
        let cards = [
            card("t-1", "tea", "Oolong"),
            card("w-1", "wine", "Rioja"),
            card("t-2", "tea", "Anhui"),
            card("w-2", "wine", "Burgundy"),
        ]
        let report = StudyReport.of(
            cards,
            encounters: Dictionary(uniqueKeysWithValues: cards.map { ($0.id, met()) })
        )
        XCTAssertEqual(report.topics.map(\.name), ["Burgundy", "Rioja", "Anhui", "Oolong"])
        XCTAssertEqual(report.topics.map(\.subject), ["wine", "wine", "tea", "tea"])
    }

    /// THE PAGE ADDS UP.
    ///
    /// The index prints `met / cards` per topic and accounts only for topics he
    /// has opened; the headline counts the whole deck. The difference used to be
    /// stated as a number of TOPICS, so the two figures could not be reconciled
    /// from anything on screen — Eden, reading it: *"the deck shows me quite a
    /// few subjects but they don't sum up to the 350 questions we built."*
    ///
    /// This is the invariant that makes the page readable, asserted against the
    /// REAL deck rather than a fixture, because the real deck is what he was
    /// adding up.
    func testTheIndexAndTheUnmetCountSumToTheWholeDeck() {
        let cards = Cards.all
        // Two topics opened, one card each: enough to split the deck into an
        // index and a remainder without hand-building either.
        let opened = [cards[0], cards[cards.count / 2]]
        let report = StudyReport.of(
            cards,
            encounters: Dictionary(uniqueKeysWithValues: opened.map { ($0.id, met()) })
        )

        let inTheIndex = report.topics.reduce(0) { $0 + $1.cards }
        XCTAssertEqual(
            inTheIndex + report.unmetCards,
            report.standing.cards,
            "every card is either in a topic the index prints or in the unmet count"
        )
        XCTAssertEqual(report.standing.cards, cards.count)
        XCTAssertGreaterThan(report.unmetCards, 0, "the fixture must actually leave a remainder")
    }

    /// A TOPIC HE HAS NOT STUDIED IS NOT IN THE INDEX.
    ///
    /// It is in `unmet`, which the page renders as one sentence rather than a
    /// list — `plans/010`: a list of everything he has not done is the shape
    /// this screen spends its design avoiding.
    func testUnstudiedTopicsAreCountedRatherThanListedInTheIndex() {
        let cards = [
            card("w-1", "wine", "Rioja"),
            card("w-2", "wine", "Alsace"),
            card("w-3", "wine", "Champagne"),
        ]
        let report = StudyReport.of(cards, encounters: ["w-1": met()])

        XCTAssertEqual(report.topics.map(\.name), ["Rioja"])
        XCTAssertEqual(report.unmet, ["Alsace", "Champagne"], "and alphabetical, so it reads as an index")
        XCTAssertEqual(report.standing.met, 1)
        XCTAssertEqual(report.standing.cards, 3)
    }

    /// BEING SHOWN A CARD IS NOT MEETING IT, HERE EITHER.
    ///
    /// The page counts engagements, exactly as the card's mark and the Summary
    /// line do. A question shown four times and never opened is not a topic he
    /// has studied, and an index that said otherwise would be the one place the
    /// app disagreed with itself about the same fact.
    func testTheIndexCountsWhatHeStudiedNotWhatAppeared() {
        let cards = [card("w-1", "wine", "Rioja"), card("w-2", "wine", "Alsace", question: false)]
        let report = StudyReport.of(
            cards,
            encounters: [
                // A question, shown four times, never opened.
                "w-1": .init(sightings: 4, opened: 0, lastSeen: Date()),
                // A factoid, shown twice. Nothing to open, so that is two studies.
                "w-2": .init(sightings: 2, opened: 0, lastSeen: Date()),
            ]
        )
        XCTAssertEqual(report.topics.map(\.name), ["Alsace"], "the unopened question is not a topic he has met")
        XCTAssertEqual(report.unmet, ["Rioja"])
        XCTAssertEqual(report.standing.met, 1)
    }

    /// WHAT HE KEEPS MISSING IS RANKED, AND CARRIES THE ANSWER HE KEEPS GIVING.
    func testTroublesAreWorstFirstAndCarryTheConfusion() {
        let cards = [card("w-1", "wine", "Rioja"), card("w-2", "wine", "Alsace")]
        let report = StudyReport.of(
            cards,
            encounters: [
                "w-1": .init(sightings: 2, opened: 2, lastSeen: Date(), answered: 2, misses: 1, run: 0),
                "w-2": .init(
                    sightings: 4,
                    opened: 4,
                    lastSeen: Date(),
                    answered: 4,
                    misses: 3,
                    run: 0,
                    wrongWordings: ["Chenin Blanc": 3]
                ),
            ]
        )
        XCTAssertEqual(report.troubles.map(\.card), ["w-2", "w-1"], "the worst one is the answer")
        XCTAssertEqual(report.troubles.first?.confusion, "Chenin Blanc")
        XCTAssertNil(report.troubles.last?.confusion, "one miss with no repeated answer names nothing")
    }

    /// AN ANSWER THE DECK NO LONGER OFFERS IS NOT NAMED.
    ///
    /// The same rule `StudyConfusion` applies on the card itself, applied again
    /// here rather than trusted: two surfaces showing the same fact must not be
    /// able to disagree about whether it is safe to show.
    func testAConfusionWhoseOptionIsGoneIsNotNamedOnThePage() {
        let cards = [card("w-1", "wine", "Rioja")]
        let report = StudyReport.of(
            cards,
            encounters: [
                "w-1": .init(
                    sightings: 3,
                    opened: 3,
                    lastSeen: Date(),
                    answered: 3,
                    misses: 2,
                    run: 0,
                    wrongWordings: ["Melon de Bourgogne": 2]
                ),
            ]
        )
        XCTAssertEqual(report.troubles.count, 1, "it is still something he keeps missing")
        XCTAssertNil(report.troubles.first?.confusion, "but the deck no longer offers that answer")
    }

    /// EMPTY IS THE NORMAL CASE AND IT IS NOT A ZERO.
    func testAnUnstudiedDeckReportsNothingRatherThanZeroes() {
        let report = StudyReport.of([card("w-1", "wine", "Rioja")], encounters: [:])
        XCTAssertEqual(report.standing.met, 0)
        XCTAssertTrue(report.topics.isEmpty)
        XCTAssertTrue(report.troubles.isEmpty)
        XCTAssertNil(report.standing.line, "and the Summary still says nothing about a deck he has not opened")
    }

    /// THE REAL DECK BUILDS A REPORT, whatever the writing agents have done to it.
    func testTheShippedDeckProducesACoherentIndex() {
        let encounters = Dictionary(
            uniqueKeysWithValues: Cards.all.prefix(40).map { ($0.id, met()) }
        )
        let report = StudyReport.of(Cards.all, encounters: encounters)

        XCTAssertEqual(report.standing.cards, Cards.all.count)
        XCTAssertEqual(report.standing.met, 40)
        XCTAssertFalse(report.topics.isEmpty)
        XCTAssertEqual(
            report.topics.map(\.name).count,
            Set(report.topics.map(\.name)).count,
            "a topic appears in the index once"
        )
        for topic in report.topics {
            XCTAssertLessThanOrEqual(topic.met, topic.cards, "\(topic.name) claims more met than it holds")
            XCTAssertGreaterThan(topic.met, 0, "\(topic.name) is in the index without having been met")
        }
        XCTAssertTrue(
            Set(report.topics.map(\.name)).isDisjoint(with: Set(report.unmet)),
            "a topic is either met or unmet, never both"
        )
    }
}
