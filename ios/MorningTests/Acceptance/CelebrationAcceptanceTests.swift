//
//  CelebrationAcceptanceTests.swift
//  Generated from ios-port/07-acceptance.md § "Celebration"
//
//  6 assertions. The tier table and priority order are `04-rules.md §5`; the
//  copy is verbatim from `src/lib/celebration.ts` and not ours to rewrite.
//
//  The rule underneath all of them: every headline states something TRUE and
//  specific. A generic congratulation is worth nothing by the third session.
//

import XCTest
@testable import Morning

/// `@MainActor` because the app module builds with
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
@MainActor
final class CelebrationAcceptanceTests: XCTestCase {
    /// A fixed "today" inside a week that is deliberately NOT complete, so
    /// week-based tiers do not fire unless a test asks for them.
    private let today = DateComponents(
        calendar: Calendar(identifier: .gregorian),
        year: 2026, month: 8, day: 18, hour: 9
    ).date ?? Date(timeIntervalSince1970: 1_787_050_800)

    /// Exactly one tier fires, in the documented priority order.
    func testExactlyOneTierFiresInPriorityOrder() throws {
        // A session that qualifies for several tiers at once must return the
        // highest. This one is a personal best AND completes a week AND is a
        // clean sweep — week-complete outranks record, clean-sweep outranks
        // both, and a lifetime milestone would outrank all three.
        let history = fiveSessionsThisWeek()
        let latest = try XCTUnwrap(history.last)
        let celebration = Celebrations.forSession(latest, history: history, today: saturday)

        XCTAssertEqual(
            celebration.tier,
            .weekComplete,
            "the highest earned tier must win, not the first one checked"
        )

        // And the returned value is a single tier, not a set — there is one
        // headline on the screen and this is it.
        XCTAssertFalse(celebration.headline.isEmpty)
        XCTAssertFalse(celebration.body.isEmpty)
    }

    /// Rep deltas are suppressed entirely when the working weight changed.
    func testRepDeltasAreSuppressedWhenTheWorkingWeightChanged() {
        let earlier = record(day: 16, key: "A", reps: 150, kg: 7.5, ts: 1000)
        let heavier = record(day: 17, key: "A", reps: 120, kg: 10, ts: 2000)

        let celebration = Celebrations.forSession(heavier, history: [earlier, heavier], today: today)

        XCTAssertEqual(celebration.tier, .weightChanged)
        XCTAssertNil(
            celebration.delta,
            "-30 reps for adding 2.5 kg a side is not a regression, and showing it as one lies"
        )
        XCTAssertEqual(celebration.headline, "Heavier than last time.")
        XCTAssertTrue(celebration.body.contains("fresh baseline"))

        // And the other direction is not framed as a failure either.
        let lighter = record(day: 17, key: "A", reps: 180, kg: 5, ts: 2000)
        let dropped = Celebrations.forSession(lighter, history: [earlier, lighter], today: today)
        XCTAssertEqual(dropped.headline, "Lighter than last time.")
        XCTAssertTrue(dropped.body.contains("the right call"), "dropping weight to reach failure is correct")
        XCTAssertNil(dropped.delta)
    }

    /// plateau requires three same-letter sessions on an identical total.
    func testPlateauRequiresThreeSameLetterSessionsOnAnIdenticalTotal() {
        let first = record(day: 10, key: "A", reps: 150, kg: 7.5, ts: 1000)
        let second = record(day: 12, key: "A", reps: 150, kg: 7.5, ts: 2000)
        let third = record(day: 14, key: "A", reps: 150, kg: 7.5, ts: 3000)

        // Two identical sessions is "dead level", not a plateau.
        let two = Celebrations.forSession(second, history: [first, second], today: today)
        XCTAssertEqual(two.tier, .matched)

        // Three is the signal the program is built around.
        let three = Celebrations.forSession(third, history: [first, second, third], today: today)
        XCTAssertEqual(three.tier, .plateau)
        XCTAssertEqual(three.headline, "Reps have stopped moving.")

        // And it must NOT read as a failure — the copy names the rung to move
        // to. This is the app's most valuable output.
        XCTAssertTrue(
            three.body.contains("next rung"),
            "plateau must be an instruction, not a verdict: \(three.body)"
        )
        XCTAssertFalse(three.milestoneBurst)

        // A different letter in between does not break it; a different total does.
        let different = record(day: 14, key: "A", reps: 151, kg: 7.5, ts: 3000)
        XCTAssertNotEqual(
            Celebrations.forSession(different, history: [first, second, different], today: today).tier,
            .plateau
        )
    }

    /// clean-sweep requires every comparable set to improve, at least three of
    /// them, at the same weight.
    func testCleanSweepRequiresEveryComparableSetToImprove() {
        let before = record(day: 10, key: "A", log: ["1.0.0": 10, "1.0.1": 10, "1.0.2": 10], kg: 7.5, ts: 1000)
        let every = record(day: 12, key: "A", log: ["1.0.0": 11, "1.0.1": 11, "1.0.2": 11], kg: 7.5, ts: 2000)

        let sweep = Celebrations.forSession(every, history: [before, every], today: today)
        XCTAssertEqual(sweep.tier, .cleanSweep)
        XCTAssertEqual(sweep.headline, "Clean sweep.")

        // One set merely matching is not a sweep.
        let almost = record(day: 12, key: "A", log: ["1.0.0": 11, "1.0.1": 10, "1.0.2": 11], kg: 7.5, ts: 2000)
        XCTAssertNotEqual(Celebrations.forSession(almost, history: [before, almost], today: today).tier, .cleanSweep)

        // Two sets is below the floor, however well they went.
        let twoSets = record(day: 10, key: "A", log: ["1.0.0": 10, "1.0.1": 10], kg: 7.5, ts: 1000)
        let twoUp = record(day: 12, key: "A", log: ["1.0.0": 12, "1.0.1": 12], kg: 7.5, ts: 2000)
        XCTAssertNotEqual(Celebrations.forSession(twoUp, history: [twoSets, twoUp], today: today).tier, .cleanSweep)

        // And it cannot fire across a weight change, because nothing is
        // comparable across one.
        let atNewWeight = record(day: 12, key: "A", log: ["1.0.0": 11, "1.0.1": 11, "1.0.2": 11], kg: 10, ts: 2000)
        XCTAssertEqual(
            Celebrations.forSession(atNewWeight, history: [before, atNewWeight], today: today).tier,
            .weightChanged
        )
    }

    /// No headline restates the rep total that is rendered directly above it, and
    /// no eyebrow restates its headline.
    func testNoHeadlineOrEyebrowRestatesWhatIsRenderedAboveIt() {
        // Every tier that can be reached without a lifetime threshold.
        let cases = allTierExamples()
        XCTAssertGreaterThanOrEqual(cases.count, 8, "cover most of the table, not a couple of tiers")

        for (celebration, record) in cases {
            // The summary renders the rep total as a large number directly
            // above. A headline of "252 reps." prints the same figure twice —
            // a real bug Eden caught in the shipped build.
            XCTAssertFalse(
                celebration.headline.contains(String(record.reps)),
                "\(celebration.tier.rawValue) headline restates the rep total: \(celebration.headline)"
            )

            // And an eyebrow that restates its headline is the same mistake one
            // line higher. The rule is that it must ADD something — "Best A yet"
            // over "A personal best." earns its line by naming the letter, and
            // an eyebrow sharing a word is not by itself the bug.
            let added = words(celebration.eyebrow).subtracting(words(celebration.headline))
            XCTAssertFalse(
                added.isEmpty,
                "\(celebration.tier.rawValue): eyebrow \"\(celebration.eyebrow)\" adds nothing "
                    + "to headline \"\(celebration.headline)\""
            )

            // Nothing congratulates without saying something.
            XCTAssertFalse(celebration.body.isEmpty, "\(celebration.tier.rawValue) has no substance")
            for empty in ["Great job", "Well done", "Awesome", "Nice work", "Keep it up"] {
                XCTAssertFalse(
                    celebration.headline.localizedCaseInsensitiveContains(empty)
                        || celebration.body.localizedCaseInsensitiveContains(empty),
                    "\(celebration.tier.rawValue) contains empty praise: \(empty)"
                )
            }
        }
    }

    /// Ordinary confetti fires on every finished session; the milestone burst
    /// only on week completions and lifetime thresholds.
    func testOrdinaryConfettiFiresOnEveryFinishedSession() throws {
        // Eden asked for this explicitly: do not gate the ordinary celebration.
        XCTAssertTrue(Celebrations.ordinaryConfettiAlways)

        let bursting: Set<CelebrationTier> = [
            .lifetimeMilestone, .cleanSweep, .streakMilestone, .weekComplete,
        ]

        for (celebration, _) in allTierExamples() {
            XCTAssertEqual(
                celebration.milestoneBurst,
                bursting.contains(celebration.tier),
                "\(celebration.tier.rawValue) has the wrong burst setting"
            )
        }

        // The ordinary tiers still celebrate — they just do not get the bigger
        // burst on top.
        let ordinary = try XCTUnwrap(allTierExamples().first { $0.0.tier == .improved })
        XCTAssertFalse(ordinary.0.milestoneBurst)
        XCTAssertEqual(ordinary.0.headline, "You moved it.")
    }

    // MARK: - Helpers

    private var saturday: Date {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2026, month: 8, day: 22, hour: 9
        ).date ?? today
    }

    /// Content words, for asking whether one line adds anything to another.
    ///
    /// Numbers are kept whatever their length: "-10 vs your last A" earns its
    /// line entirely on the 10, and a filter that drops it concludes the
    /// eyebrow says nothing when it is the only line carrying the delta.
    private func words(_ text: String) -> Set<String> {
        let stop: Set = ["a", "an", "the", "at", "on", "of", "in", "to", "your", "and", "is", "it"]
        return Set(
            text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { token in
                    guard !token.isEmpty else { return false }
                    if token.allSatisfy(\.isNumber) {
                        return true
                    }
                    return token.count > 2 && !stop.contains(token)
                }
        )
    }

    // MARK: - The total counts up to itself

    /// IT LANDS ON THE NUMBER, whatever happens to the frames.
    ///
    /// The web build had this and the port drew the number statically — the
    /// third thing this port dropped silently on the way across, after the
    /// crossing wipe and the ALL OUT stamp.
    ///
    /// The property that matters is not the easing, it is that a dropped frame
    /// cannot leave the most important number in the app reading something
    /// other than the truth. Past the duration it returns the total itself, so
    /// the worst a stalled render can do is show the right answer sooner.
    func testTheTotalCountsUpAndIsGuaranteedToLandOnItself() {
        let total = 164

        XCTAssertEqual(Daybreak.countUp(to: total, progress: 0), 0, "starts at nothing")
        XCTAssertEqual(Daybreak.countUp(to: total, progress: 1), total, "lands exactly")
        XCTAssertEqual(Daybreak.countUp(to: total, progress: 1.8), total, "and stays there, overshot clock or not")
        XCTAssertEqual(Daybreak.countUp(to: total, progress: -0.4), 0, "before its beat it has not started")

        // Monotonic, never over, and eased out — more than half the distance is
        // covered in the first third, which is what makes the last few land.
        var last = 0
        for step in 0 ... 40 {
            let shown = Daybreak.countUp(to: total, progress: Double(step) / 40)
            XCTAssertGreaterThanOrEqual(shown, last, "the count went backwards at \(step)/40")
            XCTAssertLessThanOrEqual(shown, total, "the count overshot the total at \(step)/40")
            last = shown
        }
        XCTAssertGreaterThan(Daybreak.countUp(to: total, progress: 1.0 / 3), total / 2)
    }

    /// A SMALL NUMBER DOES NOT COUNT — it reads as a glitch rather than a
    /// flourish, which was the web build's rule and was right.
    func testASmallTotalIsNotCountedUp() {
        XCTAssertEqual(Daybreak.countUpFloor, 20)
        for progress in [0.0, 0.3, 0.7] {
            XCTAssertEqual(
                Daybreak.countUp(to: 12, progress: progress),
                12,
                "a twelve-rep session should just say twelve"
            )
        }
    }

    // MARK: - What has stopped moving

    /// A movement every set of which has read the same for three sessions is
    /// named, with the number it is stuck on.
    ///
    /// This is the case that actually happened: the floor fly was logged at
    /// 12 and 12 in every session it existed for — the app's default for a
    /// loaded set, accepted once and prefilled forever after. Every other
    /// loaded movement in the record was corrected away from its default
    /// within a session or two. Nothing on any screen ever said so.
    func testAMovementThatHasNotMovedForThreeSessionsIsNamed() throws {
        let history = threeIdenticalFloorFlySessions()
        let latest = try XCTUnwrap(history.last)

        let stalls = History.stalls(after: latest, in: history)
        let floorFly = try XCTUnwrap(stalls.first { $0.exercise == "Floor fly" })

        XCTAssertEqual(floorFly.reps, 12)
        XCTAssertEqual(floorFly.sessions, 3)
        XCTAssertEqual(
            History.stallLine([floorFly]),
            "Floor fly has been 12 for three sessions."
        )
    }

    /// Two sessions is not a stall. Three is the threshold `PRODUCT.md` names.
    func testTwoSessionsIsNotYetAStall() throws {
        let history = Array(threeIdenticalFloorFlySessions().dropFirst())
        let latest = try XCTUnwrap(history.last)

        XCTAssertEqual(history.count, 2)
        XCTAssertTrue(History.stalls(after: latest, in: history).isEmpty)
        XCTAssertNil(History.stallLine([]))
    }

    /// One set moving is progress, and it clears the whole movement.
    func testOneSetMovingClearsTheMovement() throws {
        var history = threeIdenticalFloorFlySessions()
        let latest = try XCTUnwrap(history.popLast())
        var log = latest.log
        log["3.0.1"] = 13 // the second floor fly went up by one
        history.append(SessionRecord(
            date: latest.date,
            sessionKey: latest.sessionKey,
            log: log,
            minutes: latest.minutes,
            reps: log.values.reduce(0, +),
            timestamp: latest.timestamp,
            kg: latest.kg
        ))
        let moved = try XCTUnwrap(history.last)

        XCTAssertFalse(
            History.stalls(after: moved, in: history).contains { $0.exercise == "Floor fly" },
            "a movement with one set going up is not stalled"
        )
    }

    /// THE RUN ENDS AT A WEIGHT CHANGE.
    ///
    /// Reps held level under a heavier load are an improvement the arithmetic
    /// cannot see, and calling that a stall would be the same dishonesty as
    /// reporting a rep delta across a weight change.
    func testTheRunEndsAtAWeightChange() throws {
        var history = threeIdenticalFloorFlySessions()
        // Re-value the OLDEST of the three: the load moved before it.
        let oldest = history.removeFirst()
        history.insert(SessionRecord(
            date: oldest.date,
            sessionKey: oldest.sessionKey,
            log: oldest.log,
            minutes: oldest.minutes,
            reps: oldest.reps,
            timestamp: oldest.timestamp,
            kg: 3.75
        ), at: 0)
        let latest = try XCTUnwrap(history.last)

        XCTAssertTrue(
            History.stalls(after: latest, in: history).isEmpty,
            "only two sessions are comparable, so nothing has stalled for three"
        )
    }

    /// The line names two movements, then counts the rest.
    func testTheLineNamesTwoMovementsThenCountsTheRest() {
        let one = History.Stall(exercise: "Floor fly", reps: 12, sessions: 4)
        let two = History.Stall(exercise: "Lateral raise", reps: nil, sessions: 3)
        let three = History.Stall(exercise: "Rear-delt fly", reps: 7, sessions: 5)
        let four = History.Stall(exercise: "Push-up", reps: 10, sessions: 6)

        XCTAssertEqual(
            History.stallLine([one, two]),
            "Floor fly and lateral raise have not moved in three sessions."
        )
        XCTAssertEqual(
            History.stallLine([one, two, three]),
            "Floor fly, lateral raise and one other have not moved in three sessions."
        )
        XCTAssertEqual(
            History.stallLine([one, two, three, four]),
            "Floor fly, lateral raise and two others have not moved in three sessions."
        )

        // The span is the SHORTEST run among them, which is the weakest claim
        // that is true of all of them.
        XCTAssertEqual(
            History.stallLine([one, three]),
            "Floor fly and rear-delt fly have not moved in four sessions."
        )

        // A movement whose sets differ from each other has no single number.
        XCTAssertEqual(
            History.stallLine([two]),
            "Lateral raise has not moved in three sessions."
        )
    }

    /// Three B sessions identical on the floor fly, with everything else moving.
    ///
    /// Slots are B's current shape: `3.0.0`/`3.0.1` is the floor fly.
    private func threeIdenticalFloorFlySessions() -> [SessionRecord] {
        (0 ..< 3).map { index in
            record(
                day: 19 + index * 2,
                key: "B",
                log: [
                    "1.0.0": 10 + index, "1.0.1": 10 + index, "1.0.2": 10 + index,
                    "1.1.0": 8, "1.1.1": 7 + index, "1.1.2": 7,
                    "2.0.0": 8, "2.0.1": 6, "2.0.2": 6 + index,
                    "3.0.0": 12, "3.0.1": 12,
                    "3.1.0": 7, "3.1.1": 7 + index,
                ],
                kg: 5,
                ts: 1_787_000_000_000 + index * 86_400_000
            )
        }
    }

    private func record(
        day: Int,
        key: String,
        reps: Int? = nil,
        log: [String: Int]? = nil,
        kg: Double?,
        ts: Int
    ) -> SessionRecord {
        let entries = log ?? ["1.0.0": reps ?? 0]
        return SessionRecord(
            date: String(format: "2026-08-%02d", day),
            sessionKey: key,
            log: entries,
            minutes: 16,
            reps: reps ?? entries.values.reduce(0, +),
            timestamp: ts,
            kg: kg
        )
    }

    /// Five sessions in the week beginning Sunday 2026-08-16.
    private func fiveSessionsThisWeek() -> [SessionRecord] {
        (0 ..< 5).map { index in
            record(
                day: 16 + index,
                key: index.isMultiple(of: 2) ? "A" : "B",
                reps: 150 + index,
                kg: 7.5,
                ts: (index + 1) * 1000
            )
        }
    }

    /// One reachable example of each tier below the lifetime threshold.
    private func allTierExamples() -> [(Celebration, SessionRecord)] {
        var examples: [(Celebration, SessionRecord)] = []

        func add(_ latest: SessionRecord, _ history: [SessionRecord], _ when: Date) {
            examples.append((Celebrations.forSession(latest, history: history, today: when), latest))
        }

        // first
        let solo = record(day: 16, key: "A", reps: 150, kg: 7.5, ts: 1000)
        add(solo, [solo], today)

        // improved — beats LAST time without being an all-time best, which is
        // what separates it from `record`.
        let base = record(day: 10, key: "A", reps: 150, kg: 7.5, ts: 1000)
        let allTimeBest = record(day: 6, key: "A", reps: 200, kg: 7.5, ts: 400)
        let up = record(day: 12, key: "A", reps: 160, kg: 7.5, ts: 2000)
        add(up, [allTimeBest, base, up], today)

        // matched / done
        let level = record(day: 12, key: "A", reps: 150, kg: 7.5, ts: 2000)
        add(level, [base, level], today)
        let down = record(day: 12, key: "A", reps: 140, kg: 7.5, ts: 2000)
        add(down, [base, down], today)

        // record — needs a prior best that is not the immediately previous one
        let older = record(day: 8, key: "A", reps: 100, kg: 7.5, ts: 500)
        let best = record(day: 12, key: "A", reps: 200, kg: 7.5, ts: 2000)
        add(best, [older, base, best], today)

        // plateau
        let p1 = record(day: 8, key: "A", reps: 150, kg: 7.5, ts: 500)
        let p3 = record(day: 12, key: "A", reps: 150, kg: 7.5, ts: 3000)
        add(p3, [p1, base, p3], today)

        // weight-changed
        let heavier = record(day: 12, key: "A", reps: 120, kg: 10, ts: 2000)
        add(heavier, [base, heavier], today)

        // clean-sweep
        let sweepBefore = record(day: 10, key: "A", log: ["1.0.0": 10, "1.0.1": 10, "1.0.2": 10], kg: 7.5, ts: 1000)
        let sweep = record(day: 12, key: "A", log: ["1.0.0": 11, "1.0.1": 11, "1.0.2": 11], kg: 7.5, ts: 2000)
        add(sweep, [sweepBefore, sweep], today)

        // week-complete
        let week = fiveSessionsThisWeek()
        add(week[4], week, saturday)

        return examples
    }
}
