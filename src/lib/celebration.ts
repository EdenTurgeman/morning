import type { SessionRecord } from "@/lib/storage";
import { previousSameSession } from "@/lib/storage";
import { weeklyProgress, type WeeklyProgress } from "@/lib/week";
import { computeLedger, milestoneCrossed } from "@/lib/ledger";

/* ---------------------------------------------------------------------------
 * What the summary screen celebrates, in priority order. Only one fires — the
 * highest thing you actually earned.
 *
 * The rule I'm holding to: every headline states something TRUE and specific.
 * No points, no badges, no levels, no "great job!". The reward for finishing is
 * being told exactly what you did, well. That keeps this the opposite of a
 * gamified fitness app while still making the moment feel earned.
 * ------------------------------------------------------------------------- */

export type CelebrationTier =
  | "lifetime-milestone"
  | "clean-sweep"
  | "streak-milestone"
  | "week-complete"
  | "record"
  | "improved"
  | "plateau"
  | "matched"
  | "first"
  | "done";

export interface Celebration {
  tier: CelebrationTier;
  /** Small line above the number. */
  eyebrow: string;
  /** The main statement. Short — read at a glance, sweaty. */
  headline: string;
  /** One or two sentences of substance. */
  body: string;
  /** Big visual moment: a confetti burst in the accent hue. Reserved for the
   *  genuinely rare — completing a week, and streak milestones. */
  confetti: boolean;
  /** Radiating sun rays behind the number. */
  rays: boolean;
  /** Signed rep delta vs the last same-letter session, when there is one. */
  delta: number | null;
  week: WeeklyProgress;
}

/** Week counts that get their own headline. */
const MILESTONES: Record<number, { headline: string; body: string }> = {
  2: {
    headline: "Two weeks straight.",
    body: "The first one is willpower. The second is the start of a habit.",
  },
  4: {
    headline: "A month of mornings.",
    body: "Four full weeks. This is the point where most people have already stopped.",
  },
  8: {
    headline: "Two months.",
    body: "Long enough that the strength you've added is real tissue, not just practice.",
  },
  12: {
    headline: "A quarter of a year.",
    body: "Twelve weeks is the length of most training studies. You've run a full one on yourself.",
  },
  26: {
    headline: "Half a year.",
    body: "Twenty-six weeks. Go back and look at what your first session's numbers were.",
  },
  52: {
    headline: "A year of mornings.",
    body: "Fifty-two weeks. Nothing to add — just don't stop.",
  },
};

export function celebrationFor(
  record: SessionRecord,
  history: readonly SessionRecord[],
): Celebration {
  const week = weeklyProgress(history);
  const previous = previousSameSession(history, record.s, record.ts);
  const delta = previous ? record.reps - previous.reps : null;

  const sameLetter = history.filter((h) => h.s === record.s && h.ts !== record.ts);
  const isFirstEver = history.length <= 1;
  const bestBefore = sameLetter.reduce((max, h) => Math.max(max, h.reps), 0);
  const isRecord = sameLetter.length > 0 && record.reps > bestBefore;

  // Three same-letter sessions ending on the identical total is the signal the
  // program is built around — it means reps have stopped moving.
  const lastTwo = sameLetter.slice(-2);
  const isPlateau =
    delta === 0 && lastTwo.length === 2 && lastTwo.every((h) => h.reps === record.reps);

  const base = { delta, week };

  /* Lifetime thresholds outrank everything — crossing 10 tonnes or a
   * hundredth session is far rarer than completing a week, and it should
   * never be hidden behind one. Computed by diffing the ledger with and
   * without this session, so a threshold fires exactly once. */
  const withoutThis = history.filter((h) => h.ts !== record.ts);
  const crossed = milestoneCrossed(
    computeLedger(withoutThis),
    computeLedger(history),
  );
  if (crossed) {
    return {
      ...base,
      tier: "lifetime-milestone",
      eyebrow: "All time",
      headline: crossed.headline,
      body: crossed.body,
      confetti: true,
      rays: true,
    };
  }

  /* Beating every single set in a session. Rare, unambiguous, and entirely
   * measured against your own past — the best thing in here. */
  if (previous && sameLetter.length > 0) {
    const slots = Object.keys(record.log);
    const comparable = slots.filter((s) => typeof previous.log[s] === "number");
    const beatEvery =
      comparable.length >= 3 &&
      comparable.length === slots.length &&
      comparable.every((s) => record.log[s] > previous.log[s]);

    if (beatEvery) {
      return {
        ...base,
        tier: "clean-sweep",
        eyebrow: `${slots.length} of ${slots.length} sets improved`,
        headline: "Clean sweep.",
        body: `Not one set matched last time — every single one went up. On a fixed load that is as good as this program gets.`,
        confetti: true,
        rays: true,
      };
    }
  }

  // A week just completed AND that completion hit a milestone count.
  const milestone = MILESTONES[week.streak];
  if (week.completedThisWeek && milestone) {
    return {
      ...base,
      tier: "streak-milestone",
      eyebrow: `${week.streak} weeks running`,
      headline: milestone.headline,
      body: milestone.body,
      confetti: true,
      rays: true,
    };
  }

  if (week.completedThisWeek) {
    return {
      ...base,
      tier: "week-complete",
      eyebrow: `${week.target} of ${week.target} this week`,
      headline: "Week complete.",
      body:
        week.streak > 1
          ? `That's ${week.streak} weeks in a row. Rest properly — it's part of the program.`
          : "Rest properly. The adaptation happens between sessions, not during them.",
      confetti: true,
      rays: true,
    };
  }

  if (isRecord) {
    return {
      ...base,
      tier: "record",
      eyebrow: `Best ${record.s} yet`,
      headline: `${record.reps} reps.`,
      body: `Your previous best on ${record.s} was ${bestBefore}. That's the number to beat now.`,
      confetti: false,
      rays: true,
    };
  }

  if (isFirstEver) {
    return {
      ...base,
      tier: "first",
      eyebrow: "First session logged",
      headline: "You started.",
      body: "From now on this screen tells you whether you beat the last one. That's the whole game.",
      confetti: false,
      rays: true,
    };
  }

  if (isPlateau) {
    return {
      ...base,
      tier: "plateau",
      eyebrow: `Third ${record.s} at ${record.reps}`,
      headline: "Reps have stopped moving.",
      body: "Time for the next rung: slow the eccentric to 4–5s and add a 2s pause in the stretch. Same weight, more tension.",
      confetti: false,
      rays: false,
    };
  }

  if (delta !== null && delta > 0) {
    return {
      ...base,
      tier: "improved",
      eyebrow: `+${delta} on your last ${record.s}`,
      headline: `${record.reps} reps.`,
      body: "Load stayed the same and you did more work. That's the only progress signal this program has, and you moved it.",
      confetti: false,
      rays: false,
    };
  }

  if (delta === 0) {
    return {
      ...base,
      tier: "matched",
      eyebrow: `Same as your last ${record.s}`,
      headline: `${record.reps} reps.`,
      body: "Matched it exactly. One more identical session and it's time to move up the ladder.",
      confetti: false,
      rays: false,
    };
  }

  return {
    ...base,
    tier: "done",
    eyebrow: delta !== null ? `${delta} vs your last ${record.s}` : "Session logged",
    headline: `${record.reps} reps.`,
    body:
      delta !== null && delta < 0
        ? "Down on last time. Sleep, food and stress all show up here — one dip means nothing, three in a row means something."
        : "Logged. Eat, shower, get on with the day.",
    confetti: false,
    rays: false,
  };
}
