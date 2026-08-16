/* Checks the step compiler against the structural items in spec.md §11.
 * Run with:  npm run test:program
 *
 * This exists because the superset/rest rules are the easiest thing to break
 * when editing the program, and the failure mode is silent — you just get a
 * rest step where there shouldn't be one, months into using the app. */

import { buildSteps, countSets, type Step } from "@/lib/steps";
import { PROGRAM, SESSION_KEYS, nextSessionAfter } from "@/program";

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
// spec.md §11 claims B is also 21 steps. It isn't, and can't be: §3 gives B
// 14 sets to A's 13, and the myo block contributes 5 sets + 4 interleaved
// rests. 1 warm-up + 14 sets + 10 rests = 25. The checklist line predates the
// myo block; the program data is the source of truth.
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

check("B: myo-rep block produces 5 sets", myo.length === 5, `got ${myo.length}`);
check(
  "B: myo set 1 is all-out, sets 2–5 are 4–5 reps",
  myo[0]?.target === "all-out to failure" &&
    myo.slice(1).every((s) => s.target === "4–5 reps"),
);
check(
  "B: myo rests are 20 s",
  b.filter((s) => s.kind === "rest" && s.seconds === 20).length === 4,
);

console.log("\n\x1b[1mSession alternation\x1b[0m\n");
check("fresh install proposes A", nextSessionAfter(null) === "A");
check("after A comes B", nextSessionAfter("A") === "B");
check("after B comes A", nextSessionAfter("B") === "A");

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
  check(`${key}: loadout is non-empty`, session.loadout.length > 0);
}

console.log(
  failures === 0
    ? "\n\x1b[32m\x1b[1mAll checks passed.\x1b[0m\n"
    : `\n\x1b[31m\x1b[1m${failures} check(s) failed.\x1b[0m\n`,
);

process.exit(failures === 0 ? 0 : 1);
