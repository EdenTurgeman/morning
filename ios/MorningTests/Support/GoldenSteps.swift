//
//  GoldenSteps.swift
//
//  The golden fixture: what each session MUST compile to, step by step.
//  Copied verbatim from ios-port/content/compiled-steps.json, which was
//  generated from the running web build.
//
//  ios-port/07-acceptance.md: "Assert the full list against
//  content/compiled-steps.json, not just the counts."
//

import Foundation
import XCTest

/// One compiled step, in the shape the fixture uses. Every field beyond `i`
/// and `kind` is optional because the three kinds carry different payloads:
///
///   timer -> seconds, title, cues
///   set   -> exercise, sub, load | bodyweight, target, cues, n, of, slot,
///            superset, straightIntoNext, intense
///   rest  -> seconds
struct GoldenStep: Decodable, Equatable {
    let i: Int
    let kind: String

    // timer + rest
    let seconds: Int?
    let title: String?

    // set
    let exercise: String?
    let sub: String?
    let load: Double?
    let bodyweight: Bool?
    let target: String?
    let cues: [String]?
    /// Set number within its block, 1-based.
    let n: Int?
    /// Total sets in its block.
    let of: Int?
    /// "block.item.set" — how "what did I do last time on this exact set"
    /// resolves. Stable across app updates.
    let slot: String?
    /// [position, total] within a superset round, e.g. [1, 2]. Nil when the
    /// movement is not part of a superset.
    let superset: [Int]?
    /// True on the first partner of a superset round: no rest follows.
    let straightIntoNext: Bool?
    /// Carries the training effect; emphasised on the set screen.
    let intense: Bool?
}

struct GoldenFixture: Decodable {
    let counts: [String: Int]
    let steps: [String: [GoldenStep]]
}

enum GoldenSteps {
    /// Loads the fixture from the test bundle. Fails the test rather than
    /// returning junk — if this cannot load, nothing downstream is meaningful.
    static func load(file: StaticString = #filePath, line: UInt = #line) throws -> GoldenFixture {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: "compiled-steps", withExtension: "json") else {
            XCTFail(
                "compiled-steps.json is not in the test bundle. Check that "
                    + "ios/MorningTests/Fixtures is listed under the MorningTests "
                    + "target's sources in ios/project.yml.",
                file: file,
                line: line
            )
            throw FixtureError.missing
        }
        return try JSONDecoder().decode(GoldenFixture.self, from: Data(contentsOf: url))
    }

    /// Just the set steps, in order, for one session key.
    static func sets(_ key: String) throws -> [GoldenStep] {
        try load().steps[key]?.filter { $0.kind == "set" } ?? []
    }

    enum FixtureError: Error {
        case missing
    }

    private final class BundleToken {}
}
