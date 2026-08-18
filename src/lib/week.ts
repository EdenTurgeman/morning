import { WEEKLY_TARGET, WEEK_STARTS_ON } from "@/program";
import { localISODate, type SessionRecord } from "@/lib/storage";

/* ---------------------------------------------------------------------------
 * The streak is measured in WEEKS, not consecutive days.
 *
 * The program is six mornings a week with a rest day, so a consecutive-day
 * streak punishes you for following it correctly. A week counts if it contains
 * WEEKLY_TARGET sessions, whichever days those land on — miss Tuesday, train
 * Saturday, nothing is lost.
 *
 * The week in progress can never break a streak. It hasn't finished yet, so it
 * only ever adds: if it's already complete it extends the count, and if it
 * isn't, the streak simply reads from last week backwards.
 * ------------------------------------------------------------------------- */

/** Midnight on the first day of the week containing `d`, in local time. */
export function startOfWeek(d: Date): Date {
  const x = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const back = (x.getDay() - WEEK_STARTS_ON + 7) % 7;
  x.setDate(x.getDate() - back);
  return x;
}

/** Stable id for a week: the ISO date of its first day. Sorts chronologically
 *  as a plain string, and sidesteps every ISO-week-number edge case. */
export function weekKey(isoDate: string): string {
  return localISODate(startOfWeek(new Date(`${isoDate}T12:00:00`)));
}

export function weekKeyOf(d: Date): string {
  return localISODate(startOfWeek(d));
}

function shiftWeeks(key: string, delta: number): string {
  const d = new Date(`${key}T12:00:00`);
  d.setDate(d.getDate() + delta * 7);
  return localISODate(d);
}

export interface WeekSummary {
  key: string;
  count: number;
  complete: boolean;
}

export interface WeeklyProgress {
  /** Sessions logged in the current week. */
  done: number;
  target: number;
  /** Consecutive complete weeks, including this one if it's already complete. */
  streak: number;
  /** Still needed this week to make target. */
  remaining: number;
  /** Days left including today. */
  daysLeft: number;
  /** Enough days left to still make it, but only just. */
  atRisk: boolean;
  /** Target can no longer be reached this week. */
  missed: boolean;
  /** Most recent weeks, oldest first — for the history sparkline. */
  recent: WeekSummary[];
  /** Best run of complete weeks you have ever had. A missed week drops the
   *  current streak to zero, which is exactly the moment people stop — so the
   *  number you built stays on screen as something to chase back rather than
   *  disappearing as if it never happened. */
  longestRun: number;
  /** You could skip today and still reach target on the days remaining. */
  canRestToday: boolean;
  /** Weekday names left after today, e.g. ["Thu","Fri","Sat"]. */
  daysAhead: string[];
  /** True when the session just logged is the one that completed the week. */
  completedThisWeek: boolean;
}

export function weeklyProgress(
  history: readonly SessionRecord[],
  today = new Date(),
): WeeklyProgress {
  const counts = new Map<string, number>();
  for (const h of history) {
    const k = weekKey(h.d);
    counts.set(k, (counts.get(k) ?? 0) + 1);
  }

  const current = weekKeyOf(today);
  const done = counts.get(current) ?? 0;

  // The current week only ever adds to the streak; an unfinished week is not
  // a broken one.
  let streak = 0;
  let cursor = current;
  if (done >= WEEKLY_TARGET) {
    streak++;
    cursor = shiftWeeks(current, -1);
  } else {
    cursor = shiftWeeks(current, -1);
  }
  while ((counts.get(cursor) ?? 0) >= WEEKLY_TARGET) {
    streak++;
    cursor = shiftWeeks(cursor, -1);
  }

  const dayInWeek = (today.getDay() - WEEK_STARTS_ON + 7) % 7;
  const daysLeft = 7 - dayInWeek;
  const remaining = Math.max(0, WEEKLY_TARGET - done);

  /* Longest run ever: walk every week from the first one with a session up to
   * the current week, so weeks with no sessions at all correctly break it. ISO
   * date keys sort lexicographically, which is why the cursor comparison
   * works. */
  let longestRun = 0;
  const keys = [...counts.keys()].sort();
  if (keys.length) {
    let cursor = keys[0];
    let run = 0;
    while (cursor <= current) {
      if ((counts.get(cursor) ?? 0) >= WEEKLY_TARGET) {
        run++;
        longestRun = Math.max(longestRun, run);
      } else {
        run = 0;
      }
      cursor = shiftWeeks(cursor, 1);
    }
  }

  const daysAhead: string[] = [];
  for (let i = 1; i < daysLeft; i++) {
    const d = new Date(today);
    d.setDate(d.getDate() + i);
    daysAhead.push(d.toLocaleDateString(undefined, { weekday: "short" }));
  }

  const recent: WeekSummary[] = [];
  for (let i = 11; i >= 0; i--) {
    const k = shiftWeeks(current, -i);
    const count = counts.get(k) ?? 0;
    recent.push({ key: k, count, complete: count >= WEEKLY_TARGET });
  }

  return {
    done,
    target: WEEKLY_TARGET,
    streak,
    remaining,
    daysLeft,
    atRisk: remaining > 0 && remaining === daysLeft,
    missed: remaining > daysLeft,
    recent,
    longestRun,
    // Skipping today still leaves daysLeft - 1 chances.
    canRestToday: remaining <= daysLeft - 1,
    daysAhead,
    completedThisWeek: done === WEEKLY_TARGET,
  };
}

/** Plain-language nudge for the home screen.
 *
 *  The question at 6am isn't "how am I doing" — it's "can I skip today?" So
 *  that's what this answers, with the actual arithmetic rather than
 *  encouragement. Null when there's nothing useful to say; silence beats
 *  filler at that hour. */
export function weekNudge(p: WeeklyProgress): string | null {
  if (p.missed) return "This week's out of reach. Next week starts clean.";

  if (p.done >= p.target)
    return p.done === p.target
      ? "Week complete. Rest is part of it."
      : `Week complete, +${p.done - p.target} over.`;

  if (p.remaining === 1 && p.daysLeft > 1) return "One more makes the week.";

  // Nothing left but today — say so plainly.
  if (!p.canRestToday)
    return p.daysLeft === 1
      ? "Last day. This one makes the week."
      : `Train today or the week's gone — ${p.remaining} left, ${p.daysLeft} days.`;

  // There is room to skip. Name the days it would cost you.
  const needed = p.daysAhead.slice(-p.remaining);
  if (needed.length === p.daysAhead.length && needed.length > 0)
    return `Rest today and you still make ${p.target} — but you'd need ${listOf(needed)}.`;

  const spare = p.daysAhead.length - p.remaining;
  return `${p.remaining} to go, ${p.daysLeft - 1} days after today. ${spare} spare.`;
}

function listOf(items: string[]): string {
  if (items.length <= 1) return items[0] ?? "";
  return `${items.slice(0, -1).join(", ")} and ${items[items.length - 1]}`;
}
