import Foundation

/* ===========================================================================
 *  THE DECK, READ BACK
 *  ---------------------------------------------------------------------------
 *  Everything the study surface shows, as VALUES — so the screen is a layout
 *  and the facts are assertable without one.
 *
 *  `plans/010` sets the question this surface exists to answer, and it is one
 *  sentence: **what do I know, what am I getting wrong, and what have I not met
 *  yet?** Anything here that does not answer it is decoration.
 *
 *  Not a score. `009` settled that the app states knowledge rather than keeping
 *  one, and a whole screen is a much easier place to break that than a single
 *  line — a percentage, a chart of settled-over-time, a ranking of his worst
 *  topics are each one step from here and each is a score wearing a fact's
 *  clothes. See `plans/010` for what this deliberately does not propose.
 * ======================================================================== */

struct StudyReport: Equatable {
    /// One topic, as an index entry.
    struct Topic: Equatable, Identifiable {
        let name: String
        /// "wine" | "tea". Free-form, like `Card.subject`.
        let subject: String
        /// Cards the deck holds under this topic.
        let cards: Int
        /// Of those, how many he has actually studied — engagements, not
        /// appearances. See `StudyPlan.Encounter.engagements`.
        let met: Int
        /// Questions here he has settled, and questions he keeps missing.
        let settled: Int
        let shaky: Int

        var id: String {
            name
        }
    }

    /// A question he keeps getting wrong, with the answer he keeps giving.
    struct Trouble: Equatable, Identifiable {
        let card: String
        let question: String
        let misses: Int
        /// The wrong answer he has reached for more than once, if there is one,
        /// and only if the deck still offers it — see `StudyConfusion`, which
        /// applies the same rule on the card itself. A struck line naming an
        /// option that no longer exists reads as a fault rather than a memory.
        let confusion: String?

        var id: String {
            card
        }
    }

    var standing = Deck.Standing()
    /// Topics he has met at least one card in, wine first then tea, alphabetical
    /// inside each.
    ///
    /// **Alphabetical, not ranked.** Ordering an index by how badly he is doing
    /// turns it into a list of his weaknesses, which is the one shape `plans/010`
    /// rules out: *"a to-do list of things you are bad at is the closest thing
    /// to a score in this whole plan."* An index is alphabetical because that is
    /// how you find things in it.
    var topics: [Topic] = []
    /// Questions he keeps missing, worst first. THIS one is ranked, because it
    /// is not an index — it is the answer to "what am I getting wrong", and the
    /// worst thing is the answer.
    var troubles: [Trouble] = []
    /// Topics the deck holds and he has never studied a card in.
    var unmet: [String] = []
    /// How many CARDS those topics hold between them.
    ///
    /// Without this the page does not add up, and Eden noticed: *"the deck shows
    /// me quite a few subjects but they don't sum up to the 350 questions we
    /// built."* He was reading the index, which prints `met / cards` per topic
    /// and therefore accounts only for topics he has already opened, against a
    /// headline counting the whole deck. The difference was stated as a number
    /// of TOPICS, so there was no way to reconcile the two from anything on
    /// screen.
    ///
    /// `topics.reduce(cards) + unmetCards == standing.cards`, always, and the
    /// suite asserts it. A page of true numbers that cannot be added up still
    /// reads as a page of wrong numbers.
    var unmetCards = 0

    /// How many troubles the screen prints before it stops.
    ///
    /// Five. Enough to be a real list rather than a headline, and few enough
    /// that it cannot become a wall of everything he is bad at — which is a
    /// different feeling from "here are the five to fix".
    static let troubleLimit = 5
}

extension StudyReport {
    /// Built from the deck and the two logs. Pure: no `UserDefaults` reached
    /// from here, so every rule above can be asserted against a fixture.
    static func of(_ cards: [Card], encounters: [String: StudyPlan.Encounter]) -> StudyReport {
        var report = StudyReport()

        // MARK: the standing

        let questions = cards.filter { $0.choices != nil }
        func studied(_ card: Card) -> Int {
            encounters[card.id]?.engagements(isQuestion: card.choices != nil) ?? 0
        }
        report.standing = Deck.Standing(
            met: cards.count { studied($0) > 0 },
            cards: cards.count,
            answered: questions.count { (encounters[$0.id]?.answered ?? 0) > 0 },
            settled: questions.count { (encounters[$0.id]?.run ?? 0) >= StudyPlan.settledRun },
            shaky: questions.count { encounters[$0.id]?.isShaky == true }
        )

        // MARK: the index

        var byTopic: [String: [Card]] = [:]
        for card in cards {
            byTopic[card.topic, default: []].append(card)
        }
        var met: [Topic] = []
        var unmet: [String] = []
        for (name, group) in byTopic {
            let seen = group.count { studied($0) > 0 }
            guard seen > 0 else {
                unmet.append(name)
                continue
            }
            met.append(
                Topic(
                    name: name,
                    // A topic's subject is its cards' — they do not mix, and if
                    // one ever did, the first card's is a better answer than
                    // inventing a third subject to describe it.
                    subject: group.first?.subject ?? "",
                    cards: group.count,
                    met: seen,
                    settled: group.count { (encounters[$0.id]?.run ?? 0) >= StudyPlan.settledRun },
                    shaky: group.count { encounters[$0.id]?.isShaky == true }
                )
            )
        }
        // Wine, then tea, alphabetical inside each. Two parts to one index.
        //
        // The order is DECLARED, not taken from string comparison — which put
        // tea first, because "tea" < "wine", and nobody decided that. Wine
        // leads because it is the larger half of the deck and the half Eden is
        // studying towards a qualification in. A subject the list has never
        // seen sorts after both rather than disappearing.
        report.topics = met.sorted {
            $0.subject == $1.subject
                ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                : rank(of: $0.subject) < rank(of: $1.subject)
        }
        report.unmet = unmet.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        report.unmetCards = unmet.reduce(0) { $0 + (byTopic[$1]?.count ?? 0) }

        // MARK: what he keeps missing

        let shaky = cards.filter { encounters[$0.id]?.isShaky == true }
        report.troubles = shaky
            .map { card in
                let entry = encounters[card.id]
                let wording = entry?.confusion?.wording
                return Trouble(
                    card: card.id,
                    question: card.q,
                    misses: entry?.misses ?? 0,
                    // Only if the deck still offers it. Same rule the card
                    // itself applies.
                    confusion: wording.flatMap { (card.choices?.contains($0) ?? false) ? $0 : nil }
                )
            }
            .sorted { left, right in
                left.misses == right.misses ? left.card < right.card : left.misses > right.misses
            }

        return report
    }

    /// The order subjects appear in the index. Anything unlisted follows.
    static let subjectOrder = ["wine", "tea"]

    private static func rank(of subject: String) -> Int {
        subjectOrder.firstIndex(of: subject) ?? subjectOrder.count
    }

    @MainActor
    static func current(using defaults: UserDefaults = .standard) -> StudyReport {
        of(Cards.all, encounters: Deck.encounters(using: defaults))
    }
}
