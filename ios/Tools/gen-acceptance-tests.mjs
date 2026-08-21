/* Generates XCTest skeletons from ios-port/07-acceptance.md.
 *
 * Every item in the acceptance checklist becomes one test that THROWS XCTSkip.
 * The suite therefore compiles and passes green from day one, and shows up in
 * Xcode's test navigator as a list of everything still to prove. As an agent
 * implements a rule it deletes the `throw XCTSkip(...)` line and writes the
 * assertion. Skipped-count going down is the port's real progress bar.
 *
 * Device checks are NOT generated — they cannot be automated. They go to
 * ios/Docs/device-checklist.md instead.
 *
 * Re-running this is safe: it will not overwrite a file that no longer
 * contains the generator banner, so implemented suites are never clobbered.
 */
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const BANNER = "// @generated-scaffold — delete this line once you start implementing this suite.";

const suites = [
  {
    file: "ProgramCompilerAcceptanceTests",
    section: "Program and step compiler",
    tests: [
      ["sessionACompilesTo21StepsAndBTo25", "Session A compiles to 21 steps; B to 25. Assert the full list against compiled-steps.json, not just the counts."],
      ["noRestBetweenSupersetPartners", "No rest step appears between superset partners."],
      ["restAfterEachSupersetRoundIncludingTheLast", "A rest appears after each superset round, including the last of a block."],
      ["noDanglingRestAtTheEndOfASession", "No rest is left dangling at the very end of a session."],
      ["myoBlockProduces3SetsWithPerSetTargetsAnd20sRests", "The myo block produces 3 sets with per-set targets and 20s rests."],
      ["oneWeightPerSession", "One weight per session — no session contains two different loads."],
      ["lateralRaisesAreUnderHalfOfSessionBWorkingSets", "Lateral raises are under 50% of session B's working sets."],
      ["floorFlyIsPresentInSessionB", "The floor fly is present in B."],
      ["slotIdsAreStableUniqueAndMatchTheGoldenFixture", "Slot IDs are stable and unique, and match the golden fixture exactly."],
      ["plateBreakdownsAreDerivedFromInventoryAndAchievable", "Plate breakdowns are derived from the inventory and are achievable: 7.5 kg resolves to 2×2.5 + 2×1.25, never 3×2.5."],
    ],
  },
  {
    file: "WeekAndStreakAcceptanceTests",
    section: "Week and streak",
    tests: [
      ["theWeekStartsOnSunday", "The week starts on Sunday."],
      ["fiveSessionsOnAnyDaysCompletesAWeek", "Five sessions on any days completes a week; five consecutive days is not required and six days with four sessions does not count."],
      ["incompleteWeekInProgressNeverBreaksAStreak", "An incomplete week in progress never breaks a streak."],
      ["completeWeekInProgressExtendsTheStreak", "A complete week in progress extends it."],
      ["longestRunSurvivesTheCurrentStreakDroppingToZero", "Longest run survives the current streak dropping to zero."],
      ["canRestTodayIsFalseWhenDaysLeftEqualSessionsLeft", "canRestToday is false when the remaining days exactly equal the remaining sessions."],
      ["theNudgeNamesTheCorrectWeekdays", "The nudge names the correct weekdays."],
      ["completedThisWeekFiresOnlyOnTheSessionThatReachesTarget", "completedThisWeek fires only on the session that reaches target, not on the ones after it."],
    ],
  },
  {
    file: "LedgerAcceptanceTests",
    section: "Ledger",
    tests: [
      ["tonnageCountsTwiceLoadPerRep", "Tonnage counts 2 × load per rep (two dumbbells, load is per handle)."],
      ["bodyweightRepsContributeZeroKgButCountAsReps", "Bodyweight reps contribute 0 kg but do count toward total reps."],
      ["eachSessionIsValuedAtItsOwnRecordedKg", "Each session is valued at its own recorded kg; changing the working weight does not re-value past sessions."],
      ["eachMilestoneFiresExactlyOnce", "Each milestone fires exactly once, on the session that crossed it."],
    ],
  },
  {
    file: "CelebrationAcceptanceTests",
    section: "Celebration",
    tests: [
      ["exactlyOneTierFiresInPriorityOrder", "Exactly one tier fires, in the documented priority order."],
      ["repDeltasAreSuppressedWhenTheWorkingWeightChanged", "Rep deltas are suppressed entirely when the working weight changed."],
      ["plateauRequiresThreeSameLetterSessionsOnAnIdenticalTotal", "plateau requires three same-letter sessions on an identical total."],
      ["cleanSweepRequiresEveryComparableSetToImprove", "clean-sweep requires every comparable set to improve, at least three of them, at the same weight."],
      ["noHeadlineOrEyebrowRestatesWhatIsRenderedAboveIt", "No headline restates the rep total that is rendered directly above it, and no eyebrow restates its headline."],
      ["ordinaryConfettiFiresOnEveryFinishedSession", "Ordinary confetti fires on every finished session; the milestone burst only on week completions and lifetime thresholds."],
    ],
  },
  {
    file: "StudyDeckAcceptanceTests",
    section: "Study deck",
    tests: [
      ["everyCardIdIsUniqueAndEveryCardIsAQuestion", "Every card id is unique and every card is phrased as a question."],
      ["twoCardsPerSessionOnRestsPlusOneOnTheSummary", "Two cards per session on rests, plus one on the summary."],
      ["noCardOnAnyRestUnder45Seconds", "No card on any rest under 45 seconds — the 20s myo rest in particular."],
      ["notOnTheFirstLongRestAndTheTwoAreSpreadApart", "Not on the first long rest; the two are spread apart."],
      ["drawsWithoutReplacementSoEightDrawsNeverRepeat", "Draws without replacement; a run of eight draws never repeats."],
      ["revealDelayScalesWithRestLengthAndStaysWithin6point5To11Seconds", "Reveal delay scales with rest length and stays within 6.5–11 s."],
      ["addingACardRequiresExactlyOneEdit", "Adding a card to the deck requires exactly one edit and no other change."],
    ],
  },
  {
    file: "SessionLifecycleAcceptanceTests",
    section: "Session lifecycle",
    tests: [
      ["freshInstallProposesAThenAlternates", "A fresh install proposes A; completing A proposes B, and vice versa."],
      ["repCounterPrefillsFromMostRecentSameSessionSameSlot", "Rep counter pre-fills from the most recent same-session, same-slot value."],
      ["backReturnsWithoutLosingLoggedReps", "Back returns to the previous step without losing logged reps, and shows the number actually entered this session rather than last week's."],
      ["rapidTapsNeverCollapseIntoASingleIncrement", "Rapid taps on the rep control never collapse into a single increment."],
      ["endMidSessionDiscardsEverythingAfterAConfirm", "End mid-session discards everything after a confirm, including sets already logged."],
      ["forceQuitMidSessionRestoresStepRepsAndRemainingTime", "Force-quitting mid-session and relaunching restores the same step, the same logged reps, and a correct remaining time."],
      ["aPhoneCallMidRestLeavesTheTimerCorrect", "A phone call mid-rest leaves the timer correct on return."],
      ["finishingASessionWritesExactlyOneHistoryRecord", "Finishing a session writes exactly ONE history record. The web build briefly wrote two — this is a real failure mode."],
    ],
  },
  {
    file: "DataAcceptanceTests",
    section: "Data",
    tests: [
      ["freshInstallWorksEndToEndAndFiresTheFirstTier", "A fresh install works end to end: start, log a session, see the first celebration tier, land on a Home screen with one session behind it."],
      ["everyScreenIsReviewedAtEmptyOneWeekAndSixMonths", "Every screen is reviewed at empty, one week and six months of seeded data. Empty states are designed screens with their own copy, not a fallback label."],
      ["setScreenWithNoHistoryShowsTheFirstRunMessage", "The set screen with no history shows the first-run message and a sensible default, and does not look broken."],
      ["localDatesDoNotShiftUnderAnyDeviceTimezone", "Local dates do not shift by a day under any device timezone."],
      ["recordsWithoutKgFallBackToTheProgramDefaultAndAreNotBackfilled", "Records without kg fall back to the program default and are not backfilled."],
      ["exportWipeRestoreReproducesTheHistoryExactly", "Export → wipe → restore reproduces the history exactly."],
      ["aFailedWriteSurfacesAnErrorAndNeverDropsASession", "A failed write surfaces an error and never silently drops a session."],
      ["exportedJsonIsByteCompatibleWithTheWebAppFormat", "Exported JSON is byte-compatible with the web app's format — open it in the web app's Restore box and confirm it parses."],
      ["phase2ImportingTheRealBackupReproducesEveryDerivedNumber", "PHASE 2, not v1: importing the real backup reproduces, exactly: total tonnage, total reps, session count, current streak, longest run, and the year grid."],
      ["phase2MalformedRecordsAreSkippedAndTheRestSucceeds", "PHASE 2, not v1: malformed records are skipped; the rest of the import succeeds."],
    ],
  },
];

let written = 0;
let skippedExisting = 0;
let total = 0;

for (const suite of suites) {
  const path = `${root}/ios/MorningTests/Acceptance/${suite.file}.swift`;
  total += suite.tests.length;

  if (existsSync(path) && !readFileSync(path, "utf8").includes(BANNER)) {
    skippedExisting++;
    continue;
  }

  for (const [name] of suite.tests) {
    // SwiftLint's identifier_name rejects anything non-alphanumeric, and
    // --strict is off but the error severity is not worth relying on.
    if (!/^[a-z][A-Za-z0-9]*$/.test(name)) {
      throw new Error(`test name must be lowerCamelCase alphanumeric: ${name}`);
    }
  }

  const body = suite.tests
    .map(([name, text]) => {
      const doc = text.replace(/(.{1,74})(\s|$)/g, "$1\n").trim().split("\n").map((l) => `    /// ${l}`).join("\n");
      return `${doc}\n    func test${name[0].toUpperCase()}${name.slice(1)}() throws {\n        throw XCTSkip("Not implemented yet.")\n    }`;
    })
    .join("\n\n");

  const out = `${BANNER}
//
//  ${suite.file}.swift
//  Generated from ios-port/07-acceptance.md § "${suite.section}"
//
//  ${suite.tests.length} assertions. Each one was once a real bug, which is why it is
//  written down. Implement them BEFORE the UI work, not after — a mis-ported
//  rule caught here takes seconds; caught in the Ledger six weeks from now it
//  takes an afternoon and a lost weekend of history.
//
//  To implement: delete the \`throw XCTSkip\` line and write the assertion.
//  The golden fixture is available as \`GoldenSteps.load()\`.
//

import XCTest
@testable import Morning

final class ${suite.file}: XCTestCase {
${body}
}
`;
  writeFileSync(path, out, "utf8");
  written++;
}

console.log(`acceptance suites: ${written} written, ${skippedExisting} left alone (already implemented), ${total} assertions total`);
