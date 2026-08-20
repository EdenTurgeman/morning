/* Checks the study-card deck and how often it interrupts you.
 *
 * Two things here are easy to regress and expensive to notice:
 *   1. a card landing on the 20-second myo rest, which would wreck the one
 *      exercise whose rest period IS the training stimulus;
 *   2. the dose creeping back up to a card on every long rest — session A has
 *      seven of them, and eight cards in twenty minutes is homework.
 *
 * Run with: npm run test:deck
 */

import { CARDS, SUBJECTS, type Card } from "@/lib/cards";
import { cardRestIndices, drawCard, revealDelayFor, MIN_REST_FOR_CARD } from "@/lib/deck";
import { buildSteps } from "@/lib/steps";
import type { Step } from "@/lib/steps";
import { SESSION_KEYS, type SessionKey } from "@/program";

let failures = 0;
function check(label: string, ok: boolean, detail = "") {
  if (ok) console.log(`  \x1b[32m✓\x1b[0m ${label}`);
  else {
    failures++;
    console.log(`  \x1b[31m✗ ${label}\x1b[0m${detail ? `\n      ${detail}` : ""}`);
  }
}
const head = (s: string) => console.log(`\n\x1b[1m${s}\x1b[0m\n`);

/* --- the cards themselves -------------------------------------------------- */

head("The deck");

const ids = CARDS.map((c) => c.id);
const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
check(
  "every id is unique",
  dupes.length === 0,
  dupes.length ? `repeated: ${[...new Set(dupes)].join(", ")}` : "",
);

check(
  "every subject has a label",
  CARDS.every((c) => c.subject in SUBJECTS),
  CARDS.filter((c) => !(c.subject in SUBJECTS))
    .map((c) => c.id)
    .join(", "),
);

const notAsked = CARDS.filter((c) => !c.q.trim().endsWith("?"));
check(
  "every card is phrased as a question",
  notAsked.length === 0,
  notAsked.map((c) => c.id).join(", "),
);

/* Length is a proxy for the rule these are written to: a one-line answer is
 * almost always a fact rather than a mechanism, and a very long one won't be
 * read inside a rest. */
const tooThin = CARDS.filter((c) => c.a.length < 90);
check(
  "no answer is a bare fact",
  tooThin.length === 0,
  tooThin.map((c) => `${c.id} (${c.a.length} chars)`).join(", "),
);

/* The ceiling is a measurement, not a guess. On a 780pt screen the rest
 * screen gives a card 497px once the ring has shrunk; the longest card in the
 * deck — 86 characters of question over three lines, 276 of answer over six —
 * fills exactly that. Longer cards still work, they just scroll, which is
 * worth avoiding on the one screen you read while catching your breath. */
const CARD_BUDGET = 370;
const tooLong = CARDS.filter((c) => c.q.length + c.a.length > CARD_BUDGET);
check(
  "no card is too long to read during a rest without scrolling",
  tooLong.length === 0,
  tooLong.map((c) => `${c.id} (${c.q.length + c.a.length} chars)`).join(", "),
);

const longest = [...CARDS].sort((a, b) => b.q.length + b.a.length - (a.q.length + a.a.length))[0];
console.log(
  `
      longest: ${longest.id} at ${longest.q.length + longest.a.length} of ${CARD_BUDGET}`,
);

const badTopic = CARDS.filter((c) => !c.topic || c.topic.length > 14);
check(
  "topics fit on the eyebrow line",
  badTopic.length === 0,
  badTopic.map((c) => `${c.id} ("${c.topic}")`).join(", "),
);

const bySubject = new Map<string, number>();
for (const c of CARDS) bySubject.set(c.subject, (bySubject.get(c.subject) ?? 0) + 1);
console.log(
  `\n      ${CARDS.length} cards — ` +
    [...bySubject].map(([s, n]) => `${SUBJECTS[s as Card["subject"]]} ${n}`).join(", "),
);

/* --- rotation -------------------------------------------------------------- */

head("Rotation");

/* localStorage doesn't exist under node, so the persistent half of the
 * rotation is inert here and this exercises the short-term buffer — which is
 * the part that stops a repeat inside one session. */
const run = Array.from({ length: 8 }, () => drawCard()).filter(Boolean) as Card[];
check("eight draws produce eight cards", run.length === 8);
check(
  "a run of draws never repeats",
  new Set(run.map((c) => c.id)).size === run.length,
  run.map((c) => c.id).join(" → "),
);

check("reveal delay scales with the rest", revealDelayFor(45) < revealDelayFor(90));
check(
  "reveal always leaves time to read",
  [20, 45, 60, 90, 300].every((s) => revealDelayFor(s) <= 11_000),
);
check(
  "reveal is never so fast the question is pointless",
  [20, 45, 60, 90].every((s) => revealDelayFor(s) >= 6_500),
);

/* --- placement ------------------------------------------------------------- */

head("Placement");

for (const key of SESSION_KEYS as readonly SessionKey[]) {
  const steps = buildSteps(key);
  const picked = cardRestIndices(steps);
  const rests = steps
    .map((s, i) => ({ s, i }))
    .filter((x): x is { s: Extract<Step, { kind: "rest" }>; i: number } => x.s.kind === "rest");
  const long = rests.filter((r) => r.s.seconds >= MIN_REST_FOR_CARD).map((r) => r.i);

  check(
    `session ${key}: exactly two cards`,
    picked.length === 2,
    `picked ${picked.length} of ${long.length} long rests`,
  );

  check(
    `session ${key}: never on a short rest`,
    picked.every((i) => {
      const step = steps[i];
      return step.kind === "rest" && step.seconds >= MIN_REST_FOR_CARD;
    }),
    picked
      .map((i) => {
        const step = steps[i];
        return step.kind === "rest" ? `${step.seconds}s` : step.kind;
      })
      .join(", "),
  );

  const myo = rests.filter((r) => r.s.seconds <= 20).map((r) => r.i);
  check(
    `session ${key}: the myo rest is left alone`,
    picked.every((i) => !myo.includes(i)),
  );

  check(
    `session ${key}: not on the first long rest`,
    long.length < 2 || picked[0] !== long[0],
    `first long rest is step ${long[0]}, picked ${picked.join(", ")}`,
  );

  const sorted = [...picked].sort((a, b) => a - b);
  const gapInLongRests =
    long.indexOf(sorted[1] ?? sorted[0]) - long.indexOf(sorted[0]);
  check(
    `session ${key}: the two are spread apart`,
    long.length < 4 || gapInLongRests >= 2,
    `${gapInLongRests} long rests between them`,
  );

  console.log(
    `\n      ${key}: ${long.length} long rests, cards on steps ${sorted.join(" and ")}` +
      ` (of ${steps.length})`,
  );
}

/* --- verdict --------------------------------------------------------------- */

console.log("");
if (failures) {
  console.log(`\x1b[31m\x1b[1m${failures} check${failures === 1 ? "" : "s"} failed.\x1b[0m`);
  process.exit(1);
}
console.log("\x1b[32m\x1b[1mAll checks passed.\x1b[0m");
