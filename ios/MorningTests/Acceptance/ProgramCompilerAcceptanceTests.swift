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
    /// Both sessions compile to 21 steps. Assert the full list against
    /// compiled-steps.json, not just the counts.
    ///
    /// B was 25 until the 2026-09-19 restructure moved its push-ups into a
    /// superset with the lateral raise and its rear-delt fly in with the floor
    /// fly. Same movements, one fewer set, four fewer rests, and the two
    /// numbers matching is a coincidence rather than a rule.
    func testBothSessionsCompileTo21StepsAndMatchTheGoldenList() throws {
        let fixture = try GoldenSteps.load()
        XCTAssertEqual(fixture.counts["A"], 21)
        XCTAssertEqual(fixture.counts["B"], 21)

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
        // B has two superset blocks since the restructure. Every round is
        // followed by a rest — including the last round of block 1, whose rest
        // is the gap before the myo block rather than an intra-block pause.
        // The one exception is a round that ENDS THE SESSION, where the
        // trailing rest is deliberately stripped; in B that is block 3's
        // second round, and in A its last superset round.
        let steps = StepCompiler.build(session: "B")
        var roundsChecked = 0

        for (index, step) in steps.enumerated() {
            guard let set = step.asSet,
                  let superset = set.superset,
                  superset.index == superset.of,
                  index < steps.count - 1
            else {
                continue
            }
            let next = try XCTUnwrap(steps[safe: index + 1], "B: nothing follows round-ending \(set.slot)")
            XCTAssertTrue(next.isRest, "B: no rest after superset round ending at \(set.slot)")
            roundsChecked += 1
        }

        // 3 rounds in block 1 plus the first of block 2's two — the second one
        // ends the session and is excluded above.
        XCTAssertEqual(roundsChecked, 4, "B should have 5 superset rounds, 4 of them followed by a rest")
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
        // 4–6, not 4–5: the block sat at 6, 6, 6 for three sessions running
        // with no rung above it to climb to.
        XCTAssertEqual(myo.map(\.target), ["all-out to failure", "4–6 reps", "4–6 reps"])

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

        // It used to have to be the LAST block: it was appended rather than
        // inserted so that it could not shift every later slot id. The
        // 2026-09-19 restructure moved it anyway and paid for that with
        // `History.bSlotMoves`, so its position is no longer load-bearing —
        // what is load-bearing now is that the map stays complete.
        //
        // Every set in B must find its own movement's reps in a record written
        // against the old shape — all thirteen of them.
        let legacy = History.currentSlotLog(of: legacyBRecord())
        XCTAssertEqual(
            sets.filter { legacy[$0.slot] != nil }.count,
            sets.count,
            "some B set has no legacy history to read, so the map has a hole in it"
        )
    }

    /// The legacy map is a bijection: no two slots collapse into one.
    func testTheLegacySlotMapLosesNothingAndCollapsesNothing() {
        let record = legacyBRecord()
        let translated = History.currentSlotLog(of: record)

        XCTAssertEqual(
            translated.count,
            record.log.count,
            "translating collapsed two of the old slots onto one current slot"
        )

        // The rear-delt fly's third set is the one movement-set the restructure
        // dropped — the block runs two rounds now, not three — so its number
        // translates to a slot no longer in the program. Nothing else is
        // orphaned.
        let live = Set(StepCompiler.build(session: "B").compactMap(\.asSet).map(\.slot))
        XCTAssertEqual(translated.keys.filter { !live.contains($0) }.sorted(), ["3.1.2"])

        let slots = StepCompiler.build(session: "B").compactMap(\.asSet).map(\.slot)
        XCTAssertEqual(Set(slots).count, slots.count, "duplicate current slots")
    }

    /// The exercise a slot's history came from is the exercise it lands on.
    ///
    /// This is the whole point of the map. Before it, B's floor fly read the
    /// myo block's numbers and told him he was beating a set he had never done.
    func testLegacyHistoryLandsOnTheSameMovementItWasLoggedFor() {
        let steps = StepCompiler.build(session: "B").compactMap(\.asSet)
        let history = [legacyBRecord()]

        // The old record logged, by movement:
        //   push-up 10/11/12 · lateral raise 8/8/7 · rear-delt 7/7/7
        //   myo 8/6/6        · floor fly 12/12
        let expected: [String: Int] = [
            "1.0.0": 10, "1.0.1": 11, "1.0.2": 12, // push-up, never moved
            "1.1.0": 8, "1.1.1": 8, "1.1.2": 7, // lateral raise, was block 2
            "2.0.0": 8, "2.0.1": 6, "2.0.2": 6, // myo, was block 3
            "3.0.0": 12, "3.0.1": 12, // floor fly, was block 4
            "3.1.0": 7, "3.1.1": 7, // rear-delt fly, was 2.1
        ]

        for set in steps {
            let found = History.previousSet(slot: set.slot, sessionKey: "B", in: history)
            XCTAssertEqual(
                found?.reps,
                expected[set.slot],
                "\(set.exercise) at \(set.slot) read the wrong movement's history"
            )
        }
    }

    /// A record in the CURRENT shape is read directly, with no translation.
    func testCurrentShapedRecordsAreNotTranslated() {
        let current = SessionRecord(
            date: "2026-09-20",
            sessionKey: "B",
            log: ["1.1.0": 9, "3.0.0": 14],
            minutes: 17,
            reps: 23,
            timestamp: 1_790_000_000_000,
            kg: 5
        )
        XCTAssertFalse(History.isLegacyB(current))
        XCTAssertEqual(History.previousSet(slot: "1.1.0", sessionKey: "B", in: [current])?.reps, 9)
        XCTAssertEqual(History.previousSet(slot: "3.0.0", sessionKey: "B", in: [current])?.reps, 14)
    }

    /// One of his real sessions, in the shape B had before 2026-09-19.
    private func legacyBRecord() -> SessionRecord {
        SessionRecord(
            date: "2026-08-27",
            sessionKey: "B",
            log: [
                "1.0.0": 10, "1.0.1": 11, "1.0.2": 12, // push-up
                "2.0.0": 8, "2.0.1": 8, "2.0.2": 7, // lateral raise
                "2.1.0": 7, "2.1.1": 7, "2.1.2": 7, // rear-delt fly
                "3.0.0": 8, "3.0.1": 6, "3.0.2": 6, // myo
                "4.0.0": 12, "4.0.1": 12, // floor fly
            ],
            minutes: 18,
            reps: 121,
            timestamp: 1_787_000_000_000,
            kg: 5
        )
    }

    /// Slot IDs are stable and unique, and match the golden fixture exactly.
    /// SUPERSET PARTNERS ARE ADJACENT STEPS, WITH NO REST BETWEEN THEM.
    ///
    /// `Steps.swift`: *"Partners run back to back; rest comes only after the
    /// round."* `WorkoutHost` keys the Set branch to `session.stepIndex`
    /// BECAUSE of this — two adjacent `.set` steps share one branch, so without
    /// an explicit identity the step transition never fires between them.
    ///
    /// If the compiler ever stops emitting adjacent sets, that `.id` becomes
    /// dead weight and should be reconsidered rather than left. See plans/012.
    func testSupersetPartnersAreAdjacentSteps() {
        for key in ["A", "B"] {
            let steps = StepCompiler.build(session: key)
            let adjacent = zip(steps, steps.dropFirst()).count { left, right in
                if case .set = left, case .set = right {
                    return true
                }
                return false
            }
            XCTAssertGreaterThan(
                adjacent,
                0,
                "\(key) has no adjacent sets — the set-to-set transition has nothing to serve"
            )
        }
    }

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

    /// The one-line summary shared by the Rest screen and the Live Activity.
    ///
    /// It is a test rather than a comment because the Live Activity grew its
    /// own copy of this and the copy was wrong in two ways at once — the load
    /// before the set position, and "reps" appended to a `target` that already
    /// ends in "reps". Neither was visible: the Lock Screen cannot be reached
    /// from this machine, and the preview built to check it used a hardcoded
    /// sample string that happened to be correct.
    func testTheNextUpSummaryReadsTheSameEverywhereItAppears() throws {
        let sets = StepCompiler.build(session: "A").compactMap(\.asSet)

        let loaded = try XCTUnwrap(sets.first { $0.load != nil })
        XCTAssertEqual(
            loaded.summaryLine,
            "set \(loaded.n) of \(loaded.of) · \(Plates.format(loaded.load ?? 0)) kg · \(loaded.target)",
            "set position first, then the load, then the target"
        )

        let bodyweight = try XCTUnwrap(sets.first { $0.load == nil })
        XCTAssertEqual(
            bodyweight.summaryLine,
            "set \(bodyweight.n) of \(bodyweight.of) · \(bodyweight.target)",
            "no load means no load segment, not a zero"
        )

        for set in sets {
            XCTAssertFalse(
                set.summaryLine.hasSuffix("reps reps"),
                "target already carries its unit: \(set.summaryLine)"
            )
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
