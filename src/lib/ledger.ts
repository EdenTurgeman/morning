import { buildSteps } from "@/lib/steps";
import { SESSION_KEYS, type SessionKey } from "@/program";
import type { SessionRecord } from "@/lib/storage";

/* ---------------------------------------------------------------------------
 * THE LEDGER — everything you've done, ever.
 *
 * The headline number is tonnage: reps × load. This program's whole premise is
 * that load is fixed and reps are the only signal, which makes tonnage the one
 * number that turns that signal into something that visibly compounds. Six
 * months of "I did 14 instead of 13" adds up to a figure you can't argue with.
 *
 * Two honesty constraints on it:
 *
 *  - Loaded movements in this program are two dumbbells, one per hand, and the
 *    program's `load` is per handle. So a rep moves 2 × load.
 *  - Bodyweight work contributes 0 kg. Counting it would need your bodyweight,
 *    which isn't in this repo by choice, and a guessed multiplier would make
 *    the headline number fiction. Push-up reps still count toward total reps —
 *    they just don't inflate the tonnage.
 * ------------------------------------------------------------------------- */

/** Every loaded exercise here is a pair of dumbbells. */
const HANDS = 2;

export interface Ledger {
  tonnes: number;
  kilos: number;
  reps: number;
  /** Reps that moved no external load — bodyweight work. */
  bodyweightReps: number;
  sessions: number;
  minutes: number;
  /** First session's ISO date, or null. */
  since: string | null;
  /** Whole weeks between the first session and today. */
  weeks: number;
  perSession: Record<SessionKey, number>;
}

/** slot id → kilos moved per rep, for the program as it currently stands.
 *  Slots that no longer resolve (because the program was edited) contribute
 *  reps but no tonnage — the alternative is inventing a load for them. */
function loadBySlot(kg?: number): Map<string, number> {
  const map = new Map<string, number>();
  for (const key of SESSION_KEYS) {
    for (const step of buildSteps(key, kg)) {
      if (step.kind !== "set") continue;
      map.set(`${key}:${step.slot}`, (step.load ?? 0) * HANDS);
    }
  }
  return map;
}

export function computeLedger(history: readonly SessionRecord[]): Ledger {
  // Sessions record the weight they were actually done at, so a change of
  // working weight doesn't retroactively rewrite what you lifted last month.
  const cache = new Map<string, Map<string, number>>();
  const loadsFor = (kg?: number) => {
    const id = kg === undefined ? "default" : String(kg);
    let m = cache.get(id);
    if (!m) { m = loadBySlot(kg); cache.set(id, m); }
    return m;
  };

  let kilos = 0;
  let reps = 0;
  let bodyweightReps = 0;
  let minutes = 0;
  const perSession = Object.fromEntries(SESSION_KEYS.map((k) => [k, 0])) as Record<
    SessionKey,
    number
  >;

  for (const h of history) {
    minutes += h.min;
    perSession[h.s] = (perSession[h.s] ?? 0) + 1;
    const loads = loadsFor(h.kg);
    for (const [slot, r] of Object.entries(h.log)) {
      reps += r;
      const perRep = loads.get(`${h.s}:${slot}`) ?? 0;
      if (perRep > 0) kilos += r * perRep;
      else bodyweightReps += r;
    }
  }

  const first = history.length ? history.reduce((a, b) => (a.d < b.d ? a : b)) : null;
  const weeks = first
    ? Math.max(
        1,
        Math.round(
          (Date.now() - new Date(`${first.d}T12:00:00`).getTime()) / (7 * 86_400_000),
        ),
      )
    : 0;

  return {
    tonnes: kilos / 1000,
    kilos,
    reps,
    bodyweightReps,
    sessions: history.length,
    minutes,
    since: first?.d ?? null,
    weeks,
    perSession,
  };
}

/* --- milestones ------------------------------------------------------------
 * Deliberately sparse. A milestone you hit every fortnight is a chore; one you
 * hit twice a year is an event. */

export interface Milestone {
  kind: "tonnage" | "reps" | "sessions";
  /** The threshold that was crossed. */
  value: number;
  headline: string;
  body: string;
}

const TONNE_STEPS = [1, 5, 10, 25, 50, 100, 250, 500, 1000];
const REP_STEPS = [1_000, 5_000, 10_000, 25_000, 50_000, 100_000];
const SESSION_STEPS = [10, 25, 50, 100, 200, 365, 500, 1000];

const fmt = (n: number) => n.toLocaleString("en-US");

/** The milestone this session crossed, if any. Compares the ledger before and
 *  after so a threshold fires exactly once, on the session that passed it. */
export function milestoneCrossed(
  before: Ledger,
  after: Ledger,
): Milestone | null {
  for (const step of [...TONNE_STEPS].reverse()) {
    if (before.tonnes < step && after.tonnes >= step) {
      return {
        kind: "tonnage",
        value: step,
        headline: `${fmt(step)} ${step === 1 ? "tonne" : "tonnes"} moved.`,
        body: `That's every rep you've ever logged, multiplied by what was in your hands. It only exists because you kept writing it down.`,
      };
    }
  }
  for (const step of [...REP_STEPS].reverse()) {
    if (before.reps < step && after.reps >= step) {
      return {
        kind: "reps",
        value: step,
        headline: `${fmt(step)} reps.`,
        body: "Every one of them taken to failure, or one short of it. That's the whole program in a single number.",
      };
    }
  }
  for (const step of [...SESSION_STEPS].reverse()) {
    if (before.sessions < step && after.sessions >= step) {
      return {
        kind: "sessions",
        value: step,
        headline: `${fmt(step)} sessions.`,
        body:
          step >= 100
            ? "Roughly the point where this stops being something you're doing and starts being something you are."
            : "Mornings you got up and did it anyway.",
      };
    }
  }
  return null;
}

/** The next threshold you're heading for, for the Ledger screen. */
export function nextMilestone(ledger: Ledger): {
  label: string;
  remaining: string;
  fraction: number;
} | null {
  const nextTonne = TONNE_STEPS.find((s) => s > ledger.tonnes);
  if (nextTonne) {
    const prev = [...TONNE_STEPS].reverse().find((s) => s <= ledger.tonnes) ?? 0;
    return {
      label: `${fmt(nextTonne)} tonnes`,
      remaining: `${(nextTonne - ledger.tonnes).toFixed(1)} t to go`,
      fraction: (ledger.tonnes - prev) / (nextTonne - prev),
    };
  }
  return null;
}

export function formatDuration(minutes: number): string {
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  if (hours < 48) return rest ? `${hours} h ${rest} min` : `${hours} h`;
  return `${hours} hours`;
}
