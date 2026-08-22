//
//  ProgramCompilerAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Program and step compiler"
//
//  10 assertions. Each one was once a real bug, which is why it is
//  written down. Implement them BEFORE the UI work, not after — a mis-ported
//  rule caught here takes seconds; caught in the Ledger six weeks from now it
//  takes an afternoon and a lost weekend of history.
//
//  The golden fixture is available as `GoldenSteps.load()`.
//

import XCTest
@testable import Morning

/// `@MainActor` because the app module builds with
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — the whole model is main-actor
/// isolated by design, which is correct for a single-user app with no
/// background work. Running the tests there is the honest fix; scattering
/// `nonisolated` through `Program.swift` to satisfy a test target is not.
@MainActor
final class ProgramCompilerAcceptanceTests: XCTestCase {
    /// Session A compiles to 21 steps; B to 25. Assert the full list against
    /// compiled-steps.json, not just the counts.
    func testSessionACompilesTo21StepsAndBTo25() throws {
        let fixture = try GoldenSteps.load()
        XCTAssertEqual(fixture.counts["A"], 21)
        XCTAssertEqual(fixture.counts["B"], 25)

        for key in ["A", "B"] {
            let golden = try XCTUnwrap(fixture.steps[key], "no golden steps for \(key)")
            let built = StepCompiler.build(session: key)

            XCTAssertEqual(
                built.count,
                golden.count,
                "session \(key) compiled to \(built.count) steps, fixture says \(golden.count)"
            )

            // The counts were right once in a build whose slot ids were not, so
            // every step is compared field by field.
            for (index, expected) in golden.enumerated() where index < built.count {
                assertMatches(built[index], expected, key: key, index: index)
            }
        }
    }

    /// No rest step appears between superset partners.
    func testNoRestBetweenSupersetPartners() throws {
        for key in ["A", "B"] {
            let steps = StepCompiler.build(session: key)
            for (index, step) in steps.enumerated() {
                guard let set = step.asSet, set.straightIntoNext == true else { continue }
                let next = try XCTUnwrap(steps[safe: index + 1], "\(key): nothing follows \(set.slot)")
                XCTAssertFalse(
                    next.isRest,
                    "\(key): a rest follows \(set.slot), which is straight into its partner"
                )
            }
        }
    }

    /// A rest appears after each superset round, including the last of a block.
    func testRestAfterEachSupersetRoundIncludingTheLast() throws {
        // B's superset block is followed by more blocks, so every one of its
        // rounds must be followed by a rest — including the final round, whose
        // rest is the gap before the next exercise rather than an intra-block
        // pause. A's last superset round is the end of the session, where the
        // trailing rest is deliberately stripped.
        let steps = StepCompiler.build(session: "B")
        var roundsChecked = 0

        for (index, step) in steps.enumerated() {
            guard let set = step.asSet,
                  let superset = set.superset,
                  superset.index == superset.of
            else {
                continue
            }
            let next = try XCTUnwrap(steps[safe: index + 1], "B: nothing follows round-ending \(set.slot)")
            XCTAssertTrue(next.isRest, "B: no rest after superset round ending at \(set.slot)")
            roundsChecked += 1
        }

        XCTAssertEqual(roundsChecked, 3, "B's superset block should have 3 rounds")
    }

    /// No rest is left dangling at the very end of a session.
    func testNoDanglingRestAtTheEndOfASession() throws {
        for key in ["A", "B"] {
            let steps = StepCompiler.build(session: key)
            let last = try XCTUnwrap(steps.last, "\(key) compiled to nothing")
            XCTAssertFalse(last.isRest, "\(key) ends on a rest — the user stares at a countdown")
        }
    }

    /// The myo block produces 3 sets with per-set targets and 20s rests.
    func testMyoBlockProduces3SetsWithPerSetTargetsAnd20sRests() {
        let steps = StepCompiler.build(session: "B")
        let myo = steps.compactMap(\.asSet).filter(\.intense)

        XCTAssertEqual(myo.count, 3, "the myo block should produce 3 sets")
        XCTAssertEqual(myo.map(\.target), ["all-out to failure", "4–5 reps", "4–5 reps"])

        // The 20-second rest IS the training stimulus, not a convenience.
        for (index, step) in steps.enumerated() {
            guard let set = step.asSet, set.intense, set.n < set.of else { continue }
            guard case let .rest(rest)? = steps[safe: index + 1] else {
                return XCTFail("no rest after myo set \(set.slot)")
            }
            XCTAssertEqual(rest.seconds, 20, "myo rest after \(set.slot) must be 20s")
        }
    }

    /// One weight per session — no session contains two different loads.
    func testOneWeightPerSession() {
        for key in ["A", "B"] {
            let loads = Set(StepCompiler.build(session: key).compactMap(\.asSet).compactMap(\.load))
            XCTAssertLessThanOrEqual(
                loads.count,
                1,
                "\(key) contains \(loads.sorted()) — you should never change plates mid-workout at 6am"
            )
        }
    }

    /// Lateral raises are under 50% of session B's working sets.
    func testLateralRaisesAreUnderHalfOfSessionBWorkingSets() {
        let sets = StepCompiler.build(session: "B").compactMap(\.asSet)
        let lateral = sets.filter { $0.exercise == "Lateral raise" }.count
        XCTAssertLessThan(
            Double(lateral),
            Double(sets.count) / 2,
            "\(lateral) of \(sets.count) working sets are lateral raises"
        )
    }

    /// The floor fly is present in B.
    func testFloorFlyIsPresentInSessionB() {
        let sets = StepCompiler.build(session: "B").compactMap(\.asSet)
        XCTAssertTrue(sets.contains { $0.exercise == "Floor fly" }, "B has lost the floor fly")

        // It was APPENDED, not inserted: inserting it earlier would have shifted
        // every later block's slot ids and handed it the myo block's rep
        // history as its starting target.
        let floorFlySlots = sets.filter { $0.exercise == "Floor fly" }.map(\.slot)
        let highestBlock = sets.compactMap { Int($0.slot.split(separator: ".")[0]) }.max()
        for slot in floorFlySlots {
            XCTAssertEqual(
                Int(slot.split(separator: ".")[0]),
                highestBlock,
                "the floor fly must remain the last block — see Program.swift's header"
            )
        }
    }

    /// Slot IDs are stable and unique, and match the golden fixture exactly.
    func testSlotIdsAreStableUniqueAndMatchTheGoldenFixture() throws {
        let fixture = try GoldenSteps.load()

        for key in ["A", "B"] {
            let built = StepCompiler.build(session: key).compactMap(\.asSet).map(\.slot)
            let golden = try GoldenSteps.sets(key).compactMap(\.slot)

            XCTAssertEqual(built, golden, "\(key): slot ids drifted from the fixture")
            XCTAssertEqual(
                Set(built).count,
                built.count,
                "\(key): duplicate slot ids — two sets would share rep history"
            )
        }
    }

    /// Plate breakdowns are derived from the inventory and are achievable: 7.5 kg
    /// resolves to 2×2.5 + 2×1.25, never 3×2.5.
    func testPlateBreakdownsAreDerivedFromInventoryAndAchievable() {
        XCTAssertEqual(Plates.breakdown(for: 7.5), "2×2.5 + 2×1.25")
        XCTAssertEqual(Plates.breakdown(for: 5), "2×2.5")
        XCTAssertEqual(Plates.breakdown(for: 6.25), "2×2.5 + 1×1.25")
        XCTAssertEqual(Plates.breakdown(for: 1.25), "1×1.25")
        XCTAssertEqual(Plates.breakdown(for: 0), "bare handle")

        // Bounded by what is actually owned.
        XCTAssertEqual(Plates.maximum, 10)
        XCTAssertEqual(Plates.step, 1.25)
        XCTAssertNil(Plates.breakdown(for: 11.25), "you do not own enough plates for 11.25 kg")

        // Every breakdown must use no more of a plate than exist.
        for owned in plateInventory {
            for step in stride(from: Plates.step, through: Plates.maximum, by: Plates.step) {
                guard let text = Plates.breakdown(for: step) else { continue }
                let used = countOf(plate: owned.kg, in: text)
                XCTAssertLessThanOrEqual(
                    used,
                    owned.count,
                    "\(text) for \(step) kg uses \(used)×\(owned.kg) and you own \(owned.count)"
                )
            }
        }
    }

    // MARK: - Helpers

    private func countOf(plate: Double, in breakdown: String) -> Int {
        for part in breakdown.split(separator: "+") {
            let pieces = part.trimmingCharacters(in: .whitespaces).split(separator: "×")
            guard pieces.count == 2, Double(pieces[1]) == plate else { continue }
            return Int(pieces[0]) ?? 0
        }
        return 0
    }

    private func assertMatches(
        _ built: Step,
        _ expected: GoldenStep,
        key: String,
        index: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let location = "\(key)[\(index)]"

        switch built {
        case let .timer(timer):
            XCTAssertEqual(expected.kind, "timer", "\(location) kind", file: file, line: line)
            XCTAssertEqual(timer.seconds, expected.seconds, "\(location) seconds", file: file, line: line)
            XCTAssertEqual(timer.title, expected.title, "\(location) title", file: file, line: line)
            XCTAssertEqual(timer.cues, expected.cues, "\(location) cues", file: file, line: line)

        case let .rest(rest):
            XCTAssertEqual(expected.kind, "rest", "\(location) kind", file: file, line: line)
            XCTAssertEqual(rest.seconds, expected.seconds, "\(location) seconds", file: file, line: line)

        case let .set(set):
            XCTAssertEqual(expected.kind, "set", "\(location) kind", file: file, line: line)
            XCTAssertEqual(set.exercise, expected.exercise, "\(location) exercise", file: file, line: line)
            XCTAssertEqual(set.sub, expected.sub, "\(location) sub", file: file, line: line)
            XCTAssertEqual(set.load, expected.load, "\(location) load", file: file, line: line)
            XCTAssertEqual(
                set.bodyweight,
                expected.bodyweight ?? false,
                "\(location) bodyweight",
                file: file,
                line: line
            )
            XCTAssertEqual(set.target, expected.target, "\(location) target", file: file, line: line)
            XCTAssertEqual(set.cues, expected.cues, "\(location) cues", file: file, line: line)
            XCTAssertEqual(set.intense, expected.intense ?? false, "\(location) intense", file: file, line: line)
            XCTAssertEqual(set.n, expected.n, "\(location) n", file: file, line: line)
            XCTAssertEqual(set.of, expected.of, "\(location) of", file: file, line: line)
            XCTAssertEqual(set.slot, expected.slot, "\(location) slot", file: file, line: line)
            XCTAssertEqual(
                set.superset.map { [$0.index, $0.of] },
                expected.superset,
                "\(location) superset",
                file: file,
                line: line
            )
            XCTAssertEqual(
                set.straightIntoNext,
                expected.straightIntoNext,
                "\(location) straightIntoNext",
                file: file,
                line: line
            )
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
