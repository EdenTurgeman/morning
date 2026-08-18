/* Checks the weekly-quota streak rules. Run with: npm run test:week
 *
 * The rule being protected: a week counts if it contains 5 sessions on ANY
 * days, and the week currently in progress can never break a streak. Both are
 * easy to regress into a consecutive-day streak by accident. */

import { weeklyProgress, weekNudge, weekKey, startOfWeek } from "@/lib/week";
import { WEEKLY_TARGET, WEEK_STARTS_ON } from "@/program";
import type { SessionRecord } from "@/lib/storage";

let failures = 0;
function check(label: string, ok: boolean, detail = "") {
  if (ok) console.log(`  \x1b[32m✓\x1b[0m ${label}`);
  else {
    failures++;
    console.log(`  \x1b[31m✗ ${label}\x1b[0m${detail ? `\n      ${detail}` : ""}`);
  }
}

const pad = (n: number) => String(n).padStart(2, "0");
const iso = (d: Date) =>
  `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

/** A session `daysAgo` days before `anchor`. */
function session(anchor: Date, daysAgo: number, s: "A" | "B" = "A"): SessionRecord {
  const d = new Date(anchor);
  d.setDate(d.getDate() - daysAgo);
  return { d: iso(d), s, log: {}, min: 16, reps: 100, ts: d.getTime() };
}

/* Fixed anchors, so this is deterministic regardless of when it runs.
 *
 * SAT = 2026-08-15, the last day of its Sunday-start week (2026-08-09 → 08-15).
 * Anchoring on the final day makes the day offsets line up exactly with week
 * boundaries, which is what makes these cases readable:
 *     daysAgo  0–6   this week
 *     daysAgo  7–13  last week
 *     daysAgo 14–20  the week before
 *
 * WED = 2026-08-12, mid-week, used only for the "days left" arithmetic. */
const SAT = new Date(2026, 7, 15, 12, 0, 0);
const WED = new Date(2026, 7, 12, 12, 0, 0);

console.log("\n\x1b[1mWeek boundaries\x1b[0m\n");
check(
  `week starts on ${WEEK_STARTS_ON === 0 ? "Sunday" : "Monday"}`,
  startOfWeek(WED).getDay() === WEEK_STARTS_ON,
  `got day ${startOfWeek(WED).getDay()}`,
);
check(
  "Sunday and the following Saturday are the same week",
  weekKey("2026-08-09") === weekKey("2026-08-15"),
);
check(
  "Saturday and the next Sunday are different weeks",
  weekKey("2026-08-15") !== weekKey("2026-08-16"),
);

console.log("\n\x1b[1mQuota, not consecutive days\x1b[0m\n");
{
  // 5 sessions this week, consecutive.
  const h = [0, 1, 2, 3, 4].map((n) => session(SAT, n));
  const p = weeklyProgress(h, SAT);
  check("5 sessions in a week completes it", p.done === WEEKLY_TARGET && p.streak === 1);
  check("remaining is 0 when complete", p.remaining === 0);
}
{
  // The same 5 sessions, scattered with gaps — must count identically. This is
  // the whole point: rest days are free.
  const h = [0, 2, 3, 5, 6].map((n) => session(SAT, n));
  const p = weeklyProgress(h, SAT);
  check(
    "a week with gaps counts the same as a consecutive one",
    p.done === WEEKLY_TARGET && p.streak === 1,
    `done=${p.done}, streak=${p.streak}`,
  );
}

console.log("\n\x1b[1mThe in-progress week never breaks a streak\x1b[0m\n");
{
  // Last week complete (5), this week only 1 so far.
  const h = [...[7, 8, 9, 10, 11].map((n) => session(SAT, n)), session(SAT, 0)];
  const p = weeklyProgress(h, SAT);
  check("an unfinished current week keeps last week's streak", p.streak === 1, `got ${p.streak}`);
  check("current week progress is reported separately", p.done === 1);
  check("remaining counts down to target", p.remaining === WEEKLY_TARGET - 1);
}
{
  // Two complete weeks behind, nothing yet this week.
  const h = [
    ...[7, 8, 9, 10, 11].map((n) => session(SAT, n)),
    ...[14, 15, 16, 17, 18].map((n) => session(SAT, n)),
  ];
  const p = weeklyProgress(h, SAT);
  check("two complete prior weeks give a streak of 2", p.streak === 2, `got ${p.streak}`);
  check("an empty current week does not reset it", p.done === 0 && p.streak === 2);
}
{
  // Complete current week on top of two complete weeks.
  const h = [
    ...[0, 1, 2, 3, 4].map((n) => session(SAT, n)),
    ...[7, 8, 9, 10, 11].map((n) => session(SAT, n)),
    ...[14, 15, 16, 17, 18].map((n) => session(SAT, n)),
  ];
  const p = weeklyProgress(h, SAT);
  check("a completed current week extends the streak to 3", p.streak === 3, `got ${p.streak}`);
  check("completedThisWeek fires exactly at target", p.completedThisWeek === true);
}

console.log("\n\x1b[1mBroken streaks\x1b[0m\n");
{
  // Last week missed by one (4 sessions), the week before complete.
  const h = [
    ...[7, 8, 9, 10].map((n) => session(SAT, n)),
    ...[14, 15, 16, 17, 18].map((n) => session(SAT, n)),
  ];
  const p = weeklyProgress(h, SAT);
  check("a week one short of target breaks the streak", p.streak === 0, `got ${p.streak}`);
}
check("empty history has no streak", weeklyProgress([], SAT).streak === 0);

console.log("\n\x1b[1mRisk signalling\x1b[0m\n");
{
  const p = weeklyProgress([session(WED, 0)], WED);
  check("4 days left on Wednesday with a Sunday start", p.daysLeft === 4, `got ${p.daysLeft}`);
  check("1 done, 4 needed, 4 days left → at risk", p.atRisk === true);
  check("not flagged as missed while still reachable", p.missed === false);
}
{
  // Saturday, nothing logged: target unreachable.
  const SAT = new Date(2026, 7, 15, 12, 0, 0);
  const p = weeklyProgress([], SAT);
  check("last day with nothing logged is 'missed'", p.missed === true);
  check("1 day left on Saturday", p.daysLeft === 1, `got ${p.daysLeft}`);
}
{
  // Over-target weeks still count as one week, and report the overflow.
  const h = [0, 1, 2, 3, 4, 5, 6].map((n) => session(SAT, n));
  const p = weeklyProgress(h, SAT);
  check("7 sessions is still one complete week", p.streak === 1, `got ${p.streak}`);
  check("overflow is visible in `done`", p.done === 7, `got ${p.done}`);
  check(
    "completedThisWeek only fires on the session that hits target",
    p.completedThisWeek === false,
  );
}

console.log("\n\x1b[1mLongest run\x1b[0m\n");
{
  // three complete weeks, then a short one, then two complete
  const h = [
    ...[1, 2, 3, 4, 5].map((n) => session(SAT, n)),
    ...[8, 9, 10, 11, 12].map((n) => session(SAT, n)),
    ...[15, 16, 17].map((n) => session(SAT, n)), // 3 only — breaks the run
    ...[22, 23, 24, 25, 26].map((n) => session(SAT, n)),
    ...[29, 30, 31, 32, 33].map((n) => session(SAT, n)),
    ...[36, 37, 38, 39, 40].map((n) => session(SAT, n)),
  ];
  const p = weeklyProgress(h, SAT);
  check("current streak stops at the short week", p.streak === 2, `got ${p.streak}`);
  check("longest run remembers the better stretch", p.longestRun === 3, `got ${p.longestRun}`);
}
check("no history means no best run", weeklyProgress([], SAT).longestRun === 0);
{
  // A week with NO sessions at all must break the run, not be skipped over.
  const h = [
    ...[1, 2, 3, 4, 5].map((n) => session(SAT, n)),
    ...[15, 16, 17, 18, 19].map((n) => session(SAT, n)),
  ];
  check("an entirely empty week breaks the run", weeklyProgress(h, SAT).longestRun === 1);
}

console.log("\n\x1b[1mCan I skip today?\x1b[0m\n");
{
  // Wednesday, Sunday-start: today plus Thu/Fri/Sat.
  const p = weeklyProgress([session(WED, 0)], WED);
  check("1 done, 4 needed, 4 days left -> cannot rest", p.canRestToday === false);
  check("three days named after today", p.daysAhead.length === 3, p.daysAhead.join(","));
  check("nudge says today is mandatory", (weekNudge(p) ?? "").includes("Train today"), weekNudge(p) ?? "(null)");
}
{
  // 2 done, 3 needed, 3 days after today — resting costs every one of them.
  const p = weeklyProgress([session(WED, 0), session(WED, 1)], WED);
  check("2 done -> can rest, but needs every remaining day", p.canRestToday === true);
  check("nudge names the days it would cost", (weekNudge(p) ?? "").includes("you'd need"), weekNudge(p) ?? "(null)");
}
{
  const p = weeklyProgress([0, 1, 2, 3].map((n) => session(WED, n)), WED);
  check("4 done -> one more makes the week", (weekNudge(p) ?? "").includes("One more"), weekNudge(p) ?? "(null)");
}
{
  // Saturday is the last day of a Sunday-start week: nothing comes after it.
  const p = weeklyProgress([1, 2, 3, 4].map((n) => session(SAT, n)), SAT);
  check("no days after today on the last day", p.daysAhead.length === 0);
}

console.log(
  failures === 0
    ? "\n\x1b[32m\x1b[1mAll checks passed.\x1b[0m\n"
    : `\n\x1b[31m\x1b[1m${failures} check(s) failed.\x1b[0m\n`,
);
process.exit(failures === 0 ? 0 : 1);
