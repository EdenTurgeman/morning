//
//  StudyDeckAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Study deck"
//
//  7 assertions. The dosing numbers are deliberate and not to be rounded off —
//  `04-rules.md §6` explains what each of them is protecting.
//

import XCTest
@testable import Morning

/// `@MainActor` because the app module builds with
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
@MainActor
final class StudyDeckAcceptanceTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        // An isolated suite per test: rotation state is global, and one test's
        // leftovers are the next one's mystery failure.
        let name = "morning.deck.tests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        Deck.reset(using: defaults)
    }

    override func tearDownWithError() throws {
        Deck.reset(using: defaults)
    }

    /// Every card id is unique and every card is phrased as a question.
    func testEveryCardIdIsUniqueAndEveryCardIsAQuestion() {
        let cards = Cards.all
        XCTAssertFalse(cards.isEmpty, "the deck did not load from the bundle")
        XCTAssertEqual(Set(cards.map(\.id)).count, cards.count, "duplicate card ids")

        for card in cards {
            XCTAssertTrue(
                card.q.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("?"),
                "\(card.id) is not phrased as a question: \(card.q)"
            )
            XCTAssertFalse(card.a.isEmpty, "\(card.id) has no answer")
            XCTAssertFalse(card.topic.isEmpty, "\(card.id) has no topic")
        }
    }

    /// Two cards per session on rests, plus one on the summary.
    func testTwoCardsPerSessionOnRestsPlusOneOnTheSummary() {
        for key in ["A", "B"] {
            let indices = Deck.cardRestIndices(in: StepCompiler.build(session: key))
            XCTAssertEqual(
                indices.count,
                2,
                "\(key) carries \(indices.count) cards on rests — eight cards in twenty minutes is homework"
            )
        }
        // The exact steps, so a change to the fraction maths shows up here
        // rather than as a card that silently stops appearing.
        XCTAssertEqual(Deck.cardRestIndices(in: StepCompiler.build(session: "A")), [6, 15])
        XCTAssertEqual(Deck.cardRestIndices(in: StepCompiler.build(session: "B")), [6, 15])

        // The summary's card is drawn by the summary, which is W7. What the
        // deck owes it is a longer think, because there is no timer to beat.
        XCTAssertEqual(Deck.summaryRevealDelay, 14)
        XCTAssertGreaterThan(Deck.summaryRevealDelay, Deck.revealDelay(forRestOf: 90))
    }

    /// No card on any rest under 45 seconds — the 20s myo rest in particular.
    func testNoCardOnAnyRestUnder45Seconds() {
        XCTAssertEqual(Deck.minimumRestForCard, 45)

        for key in ["A", "B"] {
            let steps = StepCompiler.build(session: key)
            for index in Deck.cardRestIndices(in: steps) {
                guard case let .rest(rest) = steps[index] else {
                    return XCTFail("\(key): index \(index) is not a rest")
                }
                XCTAssertGreaterThanOrEqual(rest.seconds, 45, "\(key): a card on a \(rest.seconds)s rest")
            }
        }

        // Session B's myo block is the reason the rule exists: that rest IS the
        // training stimulus, and anything inviting you to linger breaks it.
        let stepsB = StepCompiler.build(session: "B")
        let myoRests = stepsB.enumerated().compactMap { index, step -> Int? in
            guard case let .rest(rest) = step, rest.seconds == 20 else { return nil }
            return index
        }
        XCTAssertFalse(myoRests.isEmpty, "B should have 20-second myo rests")
        for index in myoRests {
            XCTAssertFalse(
                Deck.cardRestIndices(in: stepsB).contains(index),
                "a card landed on the 20-second myo rest"
            )
        }
    }

    /// Not on the first long rest; the two are spread apart.
    func testNotOnTheFirstLongRestAndTheTwoAreSpreadApart() throws {
        for key in ["A", "B"] {
            let steps = StepCompiler.build(session: key)
            let long = steps.enumerated().compactMap { index, step -> Int? in
                guard case let .rest(rest) = step, rest.seconds >= 45 else { return nil }
                return index
            }
            let carrying = Deck.cardRestIndices(in: steps)

            let first = try XCTUnwrap(long.first)
            XCTAssertFalse(
                carrying.contains(first),
                "\(key): a card on the first long rest — that one is for getting your breath back"
            )

            // Spread across the session rather than back to back.
            let positions = carrying.compactMap { long.firstIndex(of: $0) }
            XCTAssertEqual(positions.count, 2)
            XCTAssertGreaterThan(
                positions[1] - positions[0],
                1,
                "\(key): the two cards are adjacent long rests, not spread"
            )
        }
    }

    /// A SITTING NEVER REPEATS A CARD, AND NEVER REPEATS A TOPIC EITHER.
    ///
    /// This replaces an assertion that one full cycle showed every card exactly
    /// once. That guarantee was real and it is deliberately gone: at 302 cards
    /// a cycle is twenty weeks, and holding every seen card out of the pool for
    /// twenty weeks is precisely what made "a question you missed comes back
    /// sooner" unreachable. See `StudyPlan` for the measurement.
    ///
    /// What survives is the part that was ever about the experience of a
    /// morning — you are not asked the same thing twice in one sitting — plus
    /// the half Eden asked for on top of it: *"so it's always diverse"*. Three
    /// cards from the same topic is a narrow morning even when they are three
    /// different cards.
    func testASittingNeverRepeatsACardOrATopic() throws {
        var drawn: [Card] = []
        for _ in 0 ..< 8 {
            try drawn.append(XCTUnwrap(Deck.draw(using: defaults)))
        }
        XCTAssertEqual(
            Set(drawn.map(\.id)).count,
            8,
            "a card repeated within eight draws: \(drawn.map(\.id))"
        )

        // The topic guard holds the last three, so any four consecutive draws
        // are four different topics — comfortably more than the three cards a
        // session actually shows.
        for start in 0 ... (drawn.count - 4) {
            let window = drawn[start ..< (start + 4)].map(\.topic)
            XCTAssertEqual(
                Set(window).count,
                4,
                "four consecutive draws shared a topic: \(window)"
            )
        }
    }

    /// EVERY DRAW IS WRITTEN DOWN.
    ///
    /// Eden: *"i want to start remembering which questions i saw, how many
    /// times i saw each."* Logged inside `draw` rather than by the screens, so
    /// a new surface that shows a card cannot forget to record it.
    func testEveryDrawIsLoggedAsASighting() throws {
        let first = try XCTUnwrap(Deck.draw(using: defaults))
        let second = try XCTUnwrap(Deck.draw(using: defaults))

        let log = Deck.sightings(using: defaults)
        XCTAssertEqual(log.map(\.card), [first.id, second.id], "oldest first")
        XCTAssertTrue(log.allSatisfy { $0.ts > 0 }, "every sighting is stamped")
        XCTAssertTrue(
            log.allSatisfy { !$0.opened },
            "being shown a card is not the same as engaging with it"
        )

        XCTAssertEqual(Deck.encounter(for: first.id, using: defaults)?.sightings, 1)
        XCTAssertEqual(Deck.standing(using: defaults).cards, Cards.all.count)

        // BEING SHOWN A CARD IS NOT MEETING IT. Eden's rule: *"if i didn't
        // interact and answer then it shouldn't be recorded."* Both cards are
        // in the log; neither counts towards what he has studied until he
        // engages with one — unless it is a factoid, which has nothing to open
        // and is studied by being read.
        let questionsDrawn = [first, second].count { $0.choices != nil }
        XCTAssertEqual(
            Deck.standing(using: defaults).met,
            2 - questionsDrawn,
            "an unopened question is a card he was shown, not one he has met"
        )

        Deck.markOpened(first.id, using: defaults)
        XCTAssertEqual(
            Deck.standing(using: defaults).met,
            first.choices == nil ? 2 - questionsDrawn : 3 - questionsDrawn,
            "opening it is what makes it a study"
        )
    }

    /// OPENING A CARD IS RECORDED; THE CLOCK OPENING IT IS NOT.
    ///
    /// The one write in either log that is not an append, and the only signal
    /// that separates a card he engaged with from one that merely ran out in
    /// front of him.
    func testOpeningACardByHandIsRecordedAndIsIdempotent() throws {
        let card = try XCTUnwrap(Deck.draw(using: defaults))

        Deck.markOpened(card.id, using: defaults)
        Deck.markOpened(card.id, using: defaults)

        let log = Deck.sightings(using: defaults)
        XCTAssertEqual(log.count, 1, "marking a sighting open must never append a second one")
        XCTAssertTrue(log[0].opened)
        XCTAssertEqual(Deck.encounter(for: card.id, using: defaults)?.opened, 1)

        // A card that was never drawn cannot be opened.
        Deck.markOpened("nothing-like-this", using: defaults)
        XCTAssertEqual(Deck.sightings(using: defaults).count, 1)
    }

    /// THE THREE CARDS OF A SESSION ARE ASKED FOR DIFFERENT THINGS.
    func testTheSessionsThreeCardsAreAskedForDifferentThings() {
        XCTAssertEqual(Deck.intent(forCardNumber: 0), .fresh, "the first opens the deck up")
        XCTAssertEqual(Deck.intent(forCardNumber: 1), .review, "the second brings back a miss")
        XCTAssertEqual(
            Deck.intent(forCardNumber: 2),
            .open,
            "the summary's card has no timer to beat and can take the hardest thing"
        )
    }

    /// Reveal delay scales with rest length and stays within 6.5–11 s.
    func testRevealDelayScalesWithRestLengthAndStaysWithin6point5To11Seconds() {
        for seconds in 45 ... 120 {
            let delay = Deck.revealDelay(forRestOf: seconds)
            XCTAssertGreaterThanOrEqual(delay, 6.5, "\(seconds)s rest revealed too fast")
            XCTAssertLessThanOrEqual(delay, 11.0, "\(seconds)s rest revealed too slow")
        }

        // It scales rather than being a constant with a clamp on each end.
        XCTAssertEqual(Deck.revealDelay(forRestOf: 45), 7.2, accuracy: 0.001)
        XCTAssertEqual(Deck.revealDelay(forRestOf: 60), 9.6, accuracy: 0.001)
        XCTAssertLessThan(Deck.revealDelay(forRestOf: 45), Deck.revealDelay(forRestOf: 60))
        XCTAssertEqual(Deck.revealDelay(forRestOf: 30), 6.5, accuracy: 0.001, "clamped at the bottom")
        XCTAssertEqual(Deck.revealDelay(forRestOf: 300), 11.0, accuracy: 0.001, "clamped at the top")
    }

    /// Adding a card to the deck requires exactly one edit and no other change.
    func testAddingACardRequiresExactlyOneEdit() throws {
        // The deck is read from JSON with no id registry, no count constant and
        // no enum of subjects — so appending one object to `cards` is the whole
        // edit. This asserts the properties that would break if any of those
        // were reintroduced.
        let url = try XCTUnwrap(
            Bundle(for: type(of: self)).url(forResource: "cards", withExtension: "json")
                ?? Bundle.main.url(forResource: "cards", withExtension: "json"),
            "cards.json is not in a reachable bundle"
        )
        let raw = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        let array = try XCTUnwrap(raw?["cards"] as? [[String: Any]])

        XCTAssertEqual(array.count, Cards.all.count, "the loader drops or invents cards")

        // Nothing anywhere hard-codes how many there are.
        XCTAssertEqual(Deck.standing(using: defaults).cards, array.count)

        // Subject is free-form: a new subject must not need a new case.
        let subjects = Set(Cards.all.map(\.subject))
        XCTAssertFalse(subjects.isEmpty)
        let invented = Card(id: "x-new", subject: "coffee", topic: "Extraction", q: "Why?", a: "Because.")
        XCTAssertEqual(invented.subject, "coffee", "subject must accept an unseen value")
    }

    // MARK: - Study questions and mastery

    private func scratchDefaults(_ name: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    /// A missed question comes back; two rights running settle it.
    ///
    /// Two rather than one is deliberate: one correct guess out of four options
    /// is a 25% accident, twice running is 6%. Three would be more certain and
    /// would also mean a 26-card deck almost never settles anything.
    func testAMissedQuestionIsDueUntilAnsweredRightTwice() {
        let defaults = scratchDefaults("study.mastery.\(#function)")
        let id = "w-madeira-estufagem"

        XCTAssertFalse(Deck.isDue(id, using: defaults), "an unseen question is not due")

        Deck.record(id, picked: 0, right: false, wording: "opt 0", using: defaults)
        XCTAssertTrue(Deck.isDue(id, using: defaults), "a missed question must come back")

        Deck.record(id, picked: 0, right: true, wording: "opt 0", using: defaults)
        XCTAssertTrue(Deck.isDue(id, using: defaults), "one right answer is a 25% guess, not mastery")

        Deck.record(id, picked: 0, right: true, wording: "opt 0", using: defaults)
        XCTAssertFalse(Deck.isDue(id, using: defaults), "twice right running settles it")
    }

    /// Missing it again reopens it.
    func testSettlingIsNotPermanent() {
        let defaults = scratchDefaults("study.relapse.\(#function)")
        let id = "w-madeira-estufagem"

        Deck.record(id, picked: 0, right: false, wording: "opt 0", using: defaults)
        Deck.record(id, picked: 0, right: true, wording: "opt 0", using: defaults)
        Deck.record(id, picked: 0, right: true, wording: "opt 0", using: defaults)
        XCTAssertFalse(Deck.isDue(id, using: defaults))

        Deck.record(id, picked: 0, right: false, wording: "opt 0", using: defaults)
        XCTAssertTrue(Deck.isDue(id, using: defaults), "a later miss must reopen a settled question")
    }

    /// A malformed question degrades to a factoid rather than rendering an
    /// unanswerable card.
    ///
    /// The deck is about to be written by a separate authoring agent, so this
    /// is the guard that a bad `options`/`correct` pair costs one question
    /// rather than crashing a rest. The prose answer is always present, so the
    /// fallback still teaches.
    func testAMalformedQuestionFallsBackToAFactoid() throws {
        let threeOptions = try decodeCard(options: #"["a","b","c"]"#, correct: "1")
        XCTAssertNil(threeOptions.choices, "four options or it is not a question")

        let outOfRange = try decodeCard(options: #"["a","b","c","d"]"#, correct: "9")
        XCTAssertNil(outOfRange.choices, "an out-of-range answer index is not a question")

        let good = try decodeCard(options: #"["a","b","c","d"]"#, correct: "2")
        XCTAssertEqual(good.choices?.count, 4)
        XCTAssertEqual(good.correctIndex, 2)
    }

    /// Every question shipped in the deck is well formed.
    func testEveryShippedQuestionIsWellFormed() {
        for card in Cards.all where card.options != nil {
            XCTAssertNotNil(
                card.choices,
                "\(card.id) has options but is malformed — it will silently render as a factoid"
            )
        }
    }

    /// A QUESTION STAYS A PROMPT; A FACTOID REVEALS ITSELF.
    ///
    /// The regression this exists for: both kinds shared one deadline, so a
    /// question opened itself about eight seconds into the rest and answered
    /// itself. Eden: *"what happened to reading the question and choosing if i
    /// wanna answer or not by clicking"*. The prompt IS the feature — being
    /// asked and deciding to engage is the whole difference between a question
    /// and a factoid.
    func testAQuestionKeepsTheWholeRestToBeDecidedOn() {
        // A 60-second rest: thinking time is 9.6s.
        let thinking = Deck.revealDelay(forRestOf: 60)

        XCTAssertEqual(
            Deck.answerDue(isQuestion: false, thinking: thinking, restRemaining: 60),
            thinking,
            "a factoid is passive and its answer arrives after the thinking time"
        )
        XCTAssertEqual(
            Deck.answerDue(isQuestion: true, thinking: thinking, restRemaining: 60),
            60 - thinking,
            "a question stays a prompt until the far end of the rest"
        )
        XCTAssertGreaterThan(
            Deck.answerDue(isQuestion: true, thinking: thinking, restRemaining: 60),
            thinking * 3,
            "he must get most of the rest to decide, not a few seconds"
        )
        // A rest too short to hold both windows keeps the prompt rather than
        // snatching the card open at the last second.
        XCTAssertEqual(
            Deck.answerDue(isQuestion: true, thinking: thinking, restRemaining: 12),
            thinking
        )
    }

    /// A REVEALED QUESTION IS NEVER A PROMPT AGAIN.
    ///
    /// The regression: the reveal clock ran from the start of the REST, so on a
    /// 45-second rest the answer was out at 6.5s while the card still read "Tap
    /// to answer". Eden opened one with 28 seconds left and found it already
    /// marked, with the rows disabled. He could not have answered it.
    ///
    /// The window now starts when the question is opened, and the schedule
    /// opens an untouched one rather than revealing underneath it. This asserts
    /// the value that backs both: `revealed` beats `expanded`.
    func testARevealedQuestionIsNeverStillAPrompt() throws {
        let question = try XCTUnwrap(Cards.all.first { $0.choices != nil })

        XCTAssertEqual(
            StudyCardBody.of(question, revealed: false, expanded: false),
            .unopened,
            "unopened and unanswered is the only state that may say 'Tap to answer'"
        )
        XCTAssertEqual(
            StudyCardBody.of(question, revealed: true, expanded: false),
            .options(answered: true),
            "once the answer is out the card must show it, never re-offer the tap"
        )
    }

    /// EVERY CARD SHOWS ITS ANSWER. All four states, both kinds of card.
    ///
    /// The regression this exists for: the branch chain in `StudyCard.body`
    /// lost the factoid's revealed case, so twenty-five of the twenty-six cards
    /// in the deck drew "Tap if you have it" forever — tapped, timed out, or
    /// read to the end of the rest. Nothing caught it. There is no
    /// view-rendering test here, and the one card the review flags open is the
    /// single question, which is the one case that still worked.
    ///
    /// So the decision is a value now, and this is the assertion that a card
    /// which has been answered actually SAYS something.
    func testEveryCardShowsItsAnswerOnceItIsOut() throws {
        let factoid = try XCTUnwrap(Cards.all.first { $0.options == nil })
        let question = try XCTUnwrap(Cards.all.first { $0.choices != nil })

        // A factoid ignores `expanded` entirely — it has nothing to open.
        for expanded in [false, true] {
            XCTAssertEqual(
                StudyCardBody.of(factoid, revealed: false, expanded: expanded),
                .prompt
            )
            XCTAssertEqual(
                StudyCardBody.of(factoid, revealed: true, expanded: expanded),
                .answer,
                "a revealed factoid must show its answer — this is the case that went missing"
            )
        }

        XCTAssertEqual(
            StudyCardBody.of(question, revealed: false, expanded: false),
            .unopened
        )
        XCTAssertEqual(
            StudyCardBody.of(question, revealed: false, expanded: true),
            .options(answered: false)
        )
        XCTAssertEqual(
            StudyCardBody.of(question, revealed: true, expanded: true),
            .options(answered: true)
        )
    }

    /// A malformed question takes the FACTOID path, not a broken question path.
    ///
    /// `Card.choices` already refuses to call it a question; this asserts the
    /// screen agrees, which is the half that actually reaches the reader. The
    /// deck is about to be written by a separate authoring agent, so the
    /// degraded card still has to teach.
    func testAMalformedQuestionStillRevealsItsProse() throws {
        let broken = try decodeCard(options: #"["a","b","c"]"#, correct: "1")
        XCTAssertEqual(StudyCardBody.of(broken, revealed: false, expanded: false), .prompt)
        XCTAssertEqual(
            StudyCardBody.of(broken, revealed: true, expanded: true),
            .answer,
            "a malformed question must fall all the way back to a readable factoid"
        )
    }

    /// THE SUMMARY'S LINE STATES A FACT, AND SAYS NOTHING WHEN IT HAS NONE.
    ///
    /// `plans/004`: *"Progress reads as a true statement about knowledge — '19
    /// of 26 solid, 4 you keep missing' — never as a score."* The sentence lives
    /// on `Standing` rather than in the view precisely so this test can see it.
    func testTheSummaryLineStatesFactsAndStaysSilentWithoutThem() {
        // Nothing to say: nothing met yet. "0 of 302" on the first morning is
        // a zero dressed as a fact.
        XCTAssertNil(Deck.Standing(met: 0, cards: 0).line)
        XCTAssertNil(
            Deck.Standing(met: 0, cards: 302).line,
            "a deck he has not opened yet has nothing true to say about him"
        )

        // THE DENOMINATOR IS WHAT HE HAS ANSWERED, NOT THE WHOLE DECK.
        //
        // The old line counted settled questions against every question in the
        // deck. At 26 cards that read as knowledge; at 302 it reads "41 of 214
        // solid" — nineteen percent — which is a score, and one that would get
        // WORSE every time a writing group added a card. The deck growing must
        // not look like him getting worse.
        XCTAssertEqual(
            Deck.Standing(met: 84, cards: 302, answered: 47, settled: 41, shaky: 6).line,
            "84 of 302 cards met. 41 questions solid, 6 you keep missing."
        )
        XCTAssertEqual(
            Deck.Standing(met: 84, cards: 302, answered: 47, settled: 41, shaky: 0).line,
            "84 of 302 cards met. 41 questions solid."
        )
        // Nothing settled yet leads with the misses rather than with "0 solid".
        XCTAssertEqual(
            Deck.Standing(met: 84, cards: 302, answered: 6, settled: 0, shaky: 6).line,
            "84 of 302 cards met. 6 questions you keep missing."
        )
        // Met some, answered none — every card so far was a factoid, or every
        // question ran out of rest. Coverage alone is still true.
        XCTAssertEqual(
            Deck.Standing(met: 9, cards: 302, answered: 0).line,
            "9 of 302 cards met."
        )

        // Singulars, which the first morning hits immediately.
        XCTAssertEqual(
            Deck.Standing(met: 1, cards: 302, answered: 1, settled: 1).line,
            "1 of 302 cards met. 1 question solid."
        )
        XCTAssertEqual(
            Deck.Standing(met: 1, cards: 302, answered: 1, shaky: 1).line,
            "1 of 302 cards met. 1 question you keep missing."
        )
    }

    /// It is never a score: no digits-over-digits, no percentage, no streak.
    func testTheSummaryLineIsNeverAScore() {
        let line = try? XCTUnwrap(
            Deck.Standing(met: 84, cards: 302, answered: 47, settled: 41, shaky: 6).line
        )
        let banned = ["%", "/", "streak", "points", "level", "XP", "!"]
        for token in banned {
            XCTAssertFalse(
                (line ?? "").localizedCaseInsensitiveContains(token),
                "the study line must state knowledge, not keep score — found \(token)"
            )
        }
    }

    /// EVERY ANSWER HE GIVES IS KEPT, AS AN EVENT.
    ///
    /// Eden: *"can you make sure the app also records all the question and
    /// answer references i made so that if i wanna gamify it later i can?"* The
    /// point of that is that the shape of the game is undecided, so the log
    /// records what happened rather than what it is worth.
    func testEveryAnswerIsLoggedWithTheOptionHeChose() {
        Deck.record("w-a", picked: 2, right: false, wording: "opt 2", using: defaults)
        Deck.record("w-a", picked: 1, right: true, wording: "opt 1", using: defaults)
        Deck.record("t-b", picked: 0, right: true, wording: "opt 0", using: defaults)

        let log = Deck.answers(using: defaults)
        XCTAssertEqual(log.count, 3, "the log is append-only; nothing is collapsed or trimmed")
        XCTAssertEqual(log.map(\.card), ["w-a", "w-a", "t-b"], "oldest first")
        XCTAssertEqual(
            log.map(\.picked),
            [2, 1, 0],
            "which option he chose separates 'he missed this' from 'he keeps confusing it with THAT'"
        )
        XCTAssertEqual(
            log.map(\.pickedText),
            ["opt 2", "opt 1", "opt 0"],
            "and WHAT it said, because an index into a deck agents rewrite cannot be read back safely"
        )
        XCTAssertEqual(log.map(\.right), [false, true, true])
        XCTAssertTrue(log.allSatisfy { $0.ts > 0 }, "every event is stamped")
    }

    /// Mastery is a READING of the log, and the two must never disagree.
    func testMasteryCanBeRebuiltFromTheLogAlone() {
        Deck.record("w-a", picked: 0, right: false, wording: "opt 0", using: defaults)
        Deck.record("w-a", picked: 1, right: true, wording: "opt 1", using: defaults)
        Deck.record("w-a", picked: 1, right: true, wording: "opt 1", using: defaults)
        Deck.record("t-b", picked: 3, right: false, wording: "opt 3", using: defaults)

        let live = Deck.mastery(using: defaults)
        let rebuilt = Deck.masteryFrom(Deck.answers(using: defaults))
        XCTAssertEqual(rebuilt, live, "the summary must be derivable from the events")
        XCTAssertEqual(rebuilt["w-a"], Deck.Mastery(misses: 1, run: 2))
        XCTAssertEqual(rebuilt["t-b"], Deck.Mastery(misses: 1, run: 0))
    }

    /// An import restores study PROGRESS, not just study history.
    func testRestoringALogRebuildsWhatTheDeckKeepsAsking() throws {
        let card = try XCTUnwrap(Cards.all.first { $0.choices != nil })
        Deck.restoreAnswers(
            [
                StudyAnswer(card: card.id, ts: 1_756_000_000_000, picked: 0, right: false),
                StudyAnswer(card: card.id, ts: 1_756_000_001_000, picked: 1, right: true),
            ],
            using: defaults
        )

        XCTAssertEqual(Deck.answers(using: defaults).count, 2)
        XCTAssertEqual(Deck.mastery(using: defaults)[card.id], Deck.Mastery(misses: 1, run: 1))
        XCTAssertTrue(
            Deck.isDue(card.id, using: defaults),
            "one right answer since a miss is not settled yet, and a restore must know that"
        )
    }

    /// AN IMPORT NEVER DESTROYS WHAT IT HAS NO REPLACEMENT FOR.
    ///
    /// Checked against Eden's own phone export, which has neither log in it:
    /// `{v, history, lastBackup}`, twelve sessions, 1607 reps. Every web export
    /// and every backup this app wrote before the logs existed is that shape,
    /// and restoring one must leave study progress standing. Absent is not the
    /// same as empty.
    func testRestoringAFileWithNoStudyLogsLeavesBothAlone() throws {
        let card = try XCTUnwrap(Cards.all.first { $0.choices != nil })
        Deck.sight(card.id, using: defaults)
        Deck.record(card.id, picked: 0, right: false, wording: "a wrong answer", using: defaults)

        // Exactly what his file decodes to: no `studyAnswers`, no
        // `studySightings`, so `AppModel.restore` calls neither restore.
        let incoming = try JSONDecoder().decode(
            AppData.self,
            from: Data(#"{"v":1,"history":[],"lastBackup":null}"#.utf8)
        )
        XCTAssertNil(incoming.studyAnswers)
        XCTAssertNil(incoming.studySightings)

        if let log = incoming.studyAnswers {
            Deck.restoreAnswers(log, using: defaults)
        }
        if let log = incoming.studySightings {
            Deck.restoreSightings(log, using: defaults)
        }

        XCTAssertEqual(Deck.answers(using: defaults).count, 1, "the answer log survived the import")
        XCTAssertEqual(Deck.sightings(using: defaults).count, 1, "and so did the sighting log")
        XCTAssertTrue(Deck.isDue(card.id, using: defaults), "and the deck still knows what to ask him")
    }

    private func decodeCard(options: String, correct: String) throws -> Card {
        let json = """
        {"id":"x","subject":"wine","topic":"t","q":"q","a":"a",
         "options":\(options),"correct":\(correct)}
        """
        return try JSONDecoder().decode(Card.self, from: Data(json.utf8))
    }
}
