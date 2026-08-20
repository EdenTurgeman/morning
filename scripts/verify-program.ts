/* Checks the step compiler against the structural items in spec.md §11.
 * Run with:  npm run test:program
 *
 * This exists because the superset/rest rules are the easiest thing to break
 * when editing the program, and the failure mode is silent — you just get a
 * rest step where there shouldn't be one, months into using the app. */

import { buildSteps, countSets, type Step } from "@/lib/steps";
import { PROGRAM, SESSION_KEYS, defaultLoadFor, nextSessionAfter } from "@/program";
import { figureFor } from "@/lib/figures";

let failures = 0;

function check(label: string, ok: boolean, detail = "") {
  if (ok) {
    console.log(`  \x1b[32m✓\x1b[0m ${label}`);
  } else {
    failures++;
    console.log(`  \x1b[31m✗ ${label}\x1b[0m${detail ? `\n      ${detail}` : ""}`);
  }
}

function describe(steps: readonly Step[]): string {
  return steps
    .map((s) =>
      s.kind === "set"
        ? `${s.exercise}#${s.n}`
        : s.kind === "rest"
          ? `rest${s.seconds}`
          : "timer",
    )
    .join(" · ");
}

console.log("\n\x1b[1mProgram structure\x1b[0m");

for (const key of SESSION_KEYS) {
  const steps = buildSteps(key);
  const sets = steps.filter((s) => s.kind === "set");

  console.log(`\n Session ${key} — ${steps.length} steps, ${sets.length} sets`);
  console.log(`\x1b[2m   ${describe(steps)}\x1b[0m`);

  check(
    "no rest step between superset partners",
    steps.every((s, i) => {
      const prev = steps[i - 1];
      return !(
        s.kind === "rest" &&
        prev?.kind === "set" &&
        prev.straightIntoNext === true
      );
    }),
  );

  check(
    "a rest follows every completed superset round",
    steps.every((s, i) => {
      if (s.kind !== "set" || !s.superset) return true;
      const isLastPartner = s.superset[0] === s.superset[1];
      if (!isLastPartner) return true;
      const next = steps[i + 1];
      // last round of the last block legitimately has no trailing rest
      return next === undefined || next.kind === "rest";
    }),
  );

  check("no rest step dangling at the end", steps.at(-1)?.kind !== "rest");
  check("no rest step at the start", steps[0]?.kind === "timer");

  check(
    "no two rest steps in a row",
    steps.every((s, i) => !(s.kind === "rest" && steps[i - 1]?.kind === "rest")),
  );

  check(
    "every set slot id is unique",
    new Set(sets.map((s) => s.slot)).size === sets.length,
  );

  check(
    "every set has a target",
    sets.every((s) => typeof s.target === "string" && s.target.length > 0),
  );

  check("countSets agrees with the step list", countSets(steps) === sets.length);
}

console.log("\n\x1b[1mSession-specific rules\x1b[0m\n");

const a = buildSteps("A");
const b = buildSteps("B");

check("A: 21 steps", a.length === 21, `got ${a.length}`);
// spec.md §11 claims B is 21 steps. It never was: B carries 14 sets to A's 13,
// plus 10 rests. 1 + 14 + 10 = 25. The checklist line predates both the myo
// block and the floor fly; the program data is the source of truth.
check("B: 25 steps (spec §11 says 21 — see note)", b.length === 25, `got ${b.length}`);
check(
  "A: push-up block is 3 sets at 60 s rest",
  a.filter((s) => s.kind === "set" && s.exercise === "Push-up").length === 3 &&
    a.some((s) => s.kind === "rest" && s.seconds === 60),
);
check(
  "A: supersets label positions 1 of 2 / 2 of 2",
  a
    .filter((s): s is Extract<Step, { kind: "set" }> => s.kind === "set")
    .filter((s) => s.superset)
    .every((s) => s.superset![1] === 2),
);

const myo = b.filter(
  (s) => s.kind === "set" && s.exercise === "Lateral raise" && s.sub === "myo-reps",
) as Extract<Step, { kind: "set" }>[];

check("B: myo-rep block produces 3 sets", myo.length === 3, `got ${myo.length}`);
check(
  "B: myo set 1 is all-out, the rest are 4–5 reps",
  myo[0]?.target === "all-out to failure" &&
    myo.slice(1).every((s) => s.target === "4–5 reps"),
);
check(
  "B: myo rests are 20 s",
  b.filter((s) => s.kind === "rest" && s.seconds === 20).length === 3,
);

/* Volume balance. The point of trimming the myo block and adding the floor fly
 * was that side delts were over-subscribed while pecs — a stated goal — had no
 * isolation at all. Guard both ends of that so a future edit can't quietly
 * undo it. */
{
  const bSets = b.filter((s): s is Extract<Step, { kind: "set" }> => s.kind === "set");
  const lat = bSets.filter((s) => s.exercise === "Lateral raise").length;
  check(
    "B: lateral raise is under half the session",
    lat / bSets.length < 0.5,
    `${lat} of ${bSets.length} sets`,
  );
  check(
    "B: chest has an isolation movement, not only push-ups",
    bSets.some((s) => s.exercise === "Floor fly"),
  );
  check(
    "B: slot ids of the pre-existing blocks are unchanged",
    ["1.0.0", "2.0.0", "2.1.2", "3.0.0"].every((slot) =>
      bSets.some((s) => s.slot === slot),
    ),
  );
}

console.log("\n\x1b[1mOne weight per session\x1b[0m\n");
/* The program's premise is that load is fixed and reps are the only variable —
 * and practically, nobody swaps plates mid-workout at 6am. A session may mix
 * loaded and bodyweight movements, but every loaded movement in it must use
 * the SAME weight. */
for (const key of SESSION_KEYS) {
  const loaded = buildSteps(key)
    .filter((s): s is Extract<Step, { kind: "set" }> => s.kind === "set")
    .filter((s) => typeof s.load === "number");
  const weights = [...new Set(loaded.map((s) => s.load))];
  check(
    `${key}: every loaded movement uses one weight`,
    weights.length <= 1,
    weights.length > 1 ? `would need a plate change: ${weights.join(", ")} kg` : "",
  );
}
check("A is written for 7.5 kg", defaultLoadFor("A") === 7.5, `got ${defaultLoadFor("A")}`);
check("B is written for 5 kg", defaultLoadFor("B") === 5, `got ${defaultLoadFor("B")}`);

console.log("\n\x1b[1mSession alternation\x1b[0m\n");
check("fresh install proposes A", nextSessionAfter(null) === "A");
check("after A comes B", nextSessionAfter("A") === "B");
check("after B comes A", nextSessionAfter("B") === "A");

console.log("\n\x1b[1mExercise artwork\x1b[0m\n");
{
  const exercises = new Set<string>();
  for (const key of SESSION_KEYS) {
    for (const s of buildSteps(key)) {
      if (s.kind === "set") exercises.add(s.exercise);
    }
  }
  const unmapped = [...exercises].filter((e) => figureFor(e) === null);
  check(
    "every exercise resolves to a figure",
    unmapped.length === 0,
    unmapped.length ? `no figure for: ${unmapped.join(", ")}` : "",
  );
  // The generic "curl" rule would swallow "Hammer curl" if ordered wrongly.
  check(
    "Hammer curl maps to its own figure, not the generic curl",
    figureFor("Hammer curl") === "hammer-curl",
    `got ${figureFor("Hammer curl")}`,
  );
  check("unknown exercises degrade to no artwork", figureFor("Zercher squat") === null);
}

console.log("\n\x1b[1mProgram data integrity\x1b[0m\n");
for (const key of SESSION_KEYS) {
  const session = PROGRAM[key];
  check(
    `${key}: every block has cues`,
    session.blocks.every((blk) =>
      blk.kind === "superset"
        ? blk.items.every((i) => i.cues.length > 0)
        : blk.cues.length > 0,
    ),
  );
  check(
    `${key}: has a working weight, or is entirely bodyweight`,
    defaultLoadFor(key) !== null ||
      buildSteps(key).every((s) => s.kind !== "set" || s.bodyweight === true),
  );
}

console.log(
  failures === 0
    ? "\n\x1b[32m\x1b[1mAll checks passed.\x1b[0m\n"
    : `\n\x1b[31m\x1b[1m${failures} check(s) failed.\x1b[0m\n`,
);

process.exit(failures === 0 ? 0 : 1);
