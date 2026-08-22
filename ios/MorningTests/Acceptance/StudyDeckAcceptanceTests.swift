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

    /// Draws without replacement; a run of eight draws never repeats.
    func testDrawsWithoutReplacementSoEightDrawsNeverRepeat() throws {
        var drawn: [String] = []
        for _ in 0 ..< 8 {
            let card = try XCTUnwrap(Deck.draw(using: defaults))
            drawn.append(card.id)
        }
        XCTAssertEqual(Set(drawn).count, 8, "a card repeated within eight draws: \(drawn)")

        // And across a whole cycle: every card appears before any repeats.
        Deck.reset(using: defaults)
        var cycle: [String] = []
        for _ in 0 ..< Cards.all.count {
            try cycle.append(XCTUnwrap(Deck.draw(using: defaults)).id)
        }
        XCTAssertEqual(
            Set(cycle).count,
            Cards.all.count,
            "one cycle did not show every card exactly once"
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
        XCTAssertEqual(Deck.progress(using: defaults).total, array.count)

        // Subject is free-form: a new subject must not need a new case.
        let subjects = Set(Cards.all.map(\.subject))
        XCTAssertFalse(subjects.isEmpty)
        let invented = Card(id: "x-new", subject: "coffee", topic: "Extraction", q: "Why?", a: "Because.")
        XCTAssertEqual(invented.subject, "coffee", "subject must accept an unseen value")
    }
}
