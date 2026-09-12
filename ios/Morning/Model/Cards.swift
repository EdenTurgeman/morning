import Foundation

/* ===========================================================================
 *  THE STUDY DECK'S CONTENT
 *  ---------------------------------------------------------------------------
 *  26 cards, wine and tea, in `Resources/Content/cards.json`. Ported verbatim —
 *  `CLAUDE.md` rule 3: card text is not ours to improve.
 *
 *  Exam-style on purpose: every card teaches a MECHANISM, not a fact. "Why is
 *  Fino fortified to about 15% and Oloroso to about 17%" rather than "what abv
 *  is Fino". A fact you can look up; a mechanism you can reason from.
 *
 *  Eden will add more over time, so adding a card must be a ONE-LINE APPEND to
 *  the JSON with no other edit anywhere — no id registry, no count constant, no
 *  enum case. There is an acceptance test for exactly that, because a deck that
 *  needs two edits will eventually get one.
 * ======================================================================== */

struct Card: Codable, Equatable, Identifiable {
    let id: String
    /// "wine" | "tea". Free-form on purpose: a new subject is another
    /// one-line append, not a new enum case.
    let subject: String
    let topic: String
    /// The question. Always phrased as one.
    let q: String
    let a: String

    /// Four answers to choose between. **A card with `options` is a QUESTION;
    /// a card without is a factoid**, and both go on working.
    ///
    /// Optional so every existing card decodes untouched and so adding a
    /// question stays the ONE-LINE APPEND this file's header promises — two
    /// more keys on the object, no registry, no enum, no count constant.
    ///
    /// Defaulted to nil so constructing a factoid stays a one-liner at every
    /// call site — the same promise this file's header makes about the JSON,
    /// kept for code.
    var options: [String]? = nil
    /// Index into `options` of the right answer.
    var correct: Int? = nil

    /// A card is a question only if it is a WELL-FORMED one.
    ///
    /// Four options and an in-range index, checked here rather than trusted,
    /// because the deck is about to be written by a separate authoring agent
    /// and a malformed question must degrade to a factoid rather than crash or
    /// render an unanswerable card. The prose answer is always there, so the
    /// fallback is a card that still teaches.
    var choices: [String]? {
        guard let options, let correct,
              options.count == 4, options.indices.contains(correct)
        else {
            return nil
        }
        return options
    }

    var correctIndex: Int? {
        choices == nil ? nil : correct
    }
}

enum Cards {
    /// Loaded once. The file is a few KB and never changes at runtime.
    static let all: [Card] = load()

    private struct File: Decodable {
        let cards: [Card]
    }

    private static func load() -> [Card] {
        // The app bundle in the app, the test bundle under XCTest.
        let bundles = [Bundle.main, Bundle(for: BundleToken.self)]
        for bundle in bundles {
            guard let url = bundle.url(forResource: "cards", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let file = try? JSONDecoder().decode(File.self, from: data)
            else {
                continue
            }
            return file.cards
        }
        assertionFailure("cards.json is in neither the app nor the test bundle")
        return []
    }

    private final class BundleToken {}
}
