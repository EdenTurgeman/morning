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
 *  · Drawn WITHOUT REPLACEMENT. Random-with-replacement shows the same card
 *    twice in a session often enough to be irritating; a fixed order makes the
 *    first cards familiar and the last ones perpetually unseen.
 *
 *  Rotation state is disposable and deliberately NOT in `AppData`. Losing it
 *  just restarts the cycle, and keeping it out keeps the backup file about
 *  training — the thing that actually matters if it is ever lost.
 * ======================================================================== */

@MainActor
enum Deck {
    /// Rests shorter than this get no card.
    static let minimumRestForCard = 45

    private static let seenKey = "morning.cards.seen.v1"
    /// Short-term memory, so the same card cannot turn up twice in one sitting
    /// even across a cycle boundary. In memory on purpose: a relaunch ends the
    /// sitting.
    private static let recentLimit = 8
    private static var recent: [String] = []

    // MARK: - Dosing

    /// Which rest steps carry a card.
    ///
    /// Taken from roughly the first and third quarter of the long rests so they
    /// land spread across the session, and never from the very first one.
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
        return Array(Set([at(0.25), at(0.72)])).sorted()
    }

    /// How long to think before the answer appears by itself.
    ///
    /// Scaled to the rest, then clamped: never so fast that a 45s rest gives no
    /// chance to work it out, never so slow that a 90s rest runs out before the
    /// answer has been read.
    static func revealDelay(forRestOf seconds: Int) -> TimeInterval {
        min(11.0, max(6.5, Double(seconds) * 0.160))
    }

    /// The summary card gets longer, because there is no timer to beat.
    static let summaryRevealDelay: TimeInterval = 14

    // MARK: - Rotation

    /// Draw one card and mark it seen. Recently drawn cards are held back, so a
    /// session showing three cards never shows the same one twice.
    static func draw(using defaults: UserDefaults = .standard) -> Card? {
        guard !Cards.all.isEmpty else { return nil }

        var seen = Set(defaults.stringArray(forKey: seenKey) ?? [])
        var pool = Cards.all.filter { !seen.contains($0.id) && !recent.contains($0.id) }

        if pool.isEmpty {
            // Cycle exhausted: reshuffle, still holding back what was just seen.
            seen.removeAll()
            pool = Cards.all.filter { !recent.contains($0.id) }
            if pool.isEmpty {
                pool = Cards.all
            }
        }

        guard let card = pool.randomElement() else { return nil }
        seen.insert(card.id)
        defaults.set(Array(seen), forKey: seenKey)
        remember(card.id)
        return card
    }

    /// How far through the current cycle. Ids no longer in the deck are
    /// ignored, so removing a card can never strand the rotation.
    static func progress(using defaults: UserDefaults = .standard) -> (seen: Int, total: Int) {
        let seen = Set(defaults.stringArray(forKey: seenKey) ?? [])
        return (Cards.all.count { seen.contains($0.id) }, Cards.all.count)
    }

    static func reset(using defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: seenKey)
        recent.removeAll()
    }

    private static func remember(_ id: String) {
        recent.append(id)
        if recent.count > recentLimit {
            recent.removeFirst()
        }
    }
}
