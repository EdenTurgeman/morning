// @generated-scaffold — delete this line once you start implementing this suite.
//
//  StudyDeckAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Study deck"
//
//  7 assertions. Each one was once a real bug, which is why it is
//  written down. Implement them BEFORE the UI work, not after — a mis-ported
//  rule caught here takes seconds; caught in the Ledger six weeks from now it
//  takes an afternoon and a lost weekend of history.
//
//  To implement: delete the `throw XCTSkip` line and write the assertion.
//  The golden fixture is available as `GoldenSteps.load()`.
//

import XCTest
@testable import Morning

final class StudyDeckAcceptanceTests: XCTestCase {
    /// Every card id is unique and every card is phrased as a question.
    func test_everyCardIdIsUniqueAndEveryCardIsAQuestion() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Two cards per session on rests, plus one on the summary.
    func test_twoCardsPerSessionOnRestsPlusOneOnTheSummary() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// No card on any rest under 45 seconds — the 20s myo rest in particular.
    func test_noCardOnAnyRestUnder45Seconds() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Not on the first long rest; the two are spread apart.
    func test_notOnTheFirstLongRestAndTheTwoAreSpreadApart() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Draws without replacement; a run of eight draws never repeats.
    func test_drawsWithoutReplacementSoEightDrawsNeverRepeat() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Reveal delay scales with rest length and stays within 6.5–11 s.
    func test_revealDelayScalesWithRestLengthAndStaysWithin6point5To11Seconds() throws {
        throw XCTSkip("Not implemented yet.")
    }

    /// Adding a card to the deck requires exactly one edit and no other change.
    func test_addingACardRequiresExactlyOneEdit() throws {
        throw XCTSkip("Not implemented yet.")
    }
}
