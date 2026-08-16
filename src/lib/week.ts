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
    completedThisWeek: done === WEEKLY_TARGET,
  };
}

/** Plain-language nudge for the home screen. Null when there's nothing useful
 *  to say — silence beats filler at 6am. */
export function weekNudge(p: WeeklyProgress): string | null {
  if (p.missed) return "This week's out of reach. Next week starts clean.";
  if (p.done >= p.target)
    return p.done === p.target
      ? "Week complete."
      : `Week complete, +${p.done - p.target} over.`;
  if (p.atRisk)
    return `${p.remaining} left and ${p.daysLeft} ${p.daysLeft === 1 ? "day" : "days"} to do them. No slack.`;
  if (p.remaining === 1) return "One more makes the week.";
  return null;
}
