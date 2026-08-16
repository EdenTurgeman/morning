import { getSession, type SessionKey } from "@/program";

/* ---------------------------------------------------------------------------
 * A session compiles down to a flat, linear list of steps. The workout screen
 * then only ever has to render steps[i] — it never knows about blocks,
 * supersets or rounds. That's what keeps "one screen, one action" honest.
 * ------------------------------------------------------------------------- */

export interface TimerStep {
  kind: "timer";
  seconds: number;
  title: string;
  cues: readonly string[];
}

export interface SetStep {
  kind: "set";
  exercise: string;
  sub?: string;
  load?: number;
  bodyweight?: boolean;
  target: string;
  cues: readonly string[];
  intense?: boolean;
  /** 1-based set number and total, for "set 2 of 3". */
  n: number;
  of: number;
  /** `blockIndex.itemIndex.setIndex` — the key history is stored under. */
  slot: string;
  /** Position within a superset round, e.g. [1, 2] → "superset 1 of 2". */
  superset?: [number, number];
  /** True when the next partner follows immediately with no rest. */
  straightIntoNext?: boolean;
}

export interface RestStep {
  kind: "rest";
  seconds: number;
}

export type Step = TimerStep | SetStep | RestStep;

export function buildSteps(key: SessionKey): Step[] {
  const steps: Step[] = [];

  getSession(key).blocks.forEach((block, bi) => {
    if (block.kind === "warmup") {
      steps.push({
        kind: "timer",
        seconds: block.seconds,
        title: block.title,
        cues: block.cues,
      });
      return;
    }

    if (block.kind === "straight") {
      for (let i = 0; i < block.sets; i++) {
        steps.push({
          kind: "set",
          exercise: block.exercise,
          sub: block.sub,
          load: block.load,
          bodyweight: block.bodyweight,
          target: block.targets?.[i] ?? block.target ?? "to failure",
          cues: block.cues,
          intense: block.intense,
          n: i + 1,
          of: block.sets,
          slot: `${bi}.0.${i}`,
        });
        // Rest after every set, including the last — that last one is the
        // gap before the next exercise. A trailing rest at the very end of
        // the session is stripped below.
        steps.push({ kind: "rest", seconds: block.rest });
      }
      return;
    }

    // superset: partners run back to back, rest only after the round.
    for (let i = 0; i < block.sets; i++) {
      block.items.forEach((item, j) => {
        steps.push({
          kind: "set",
          exercise: item.exercise,
          sub: item.sub,
          load: item.load,
          bodyweight: item.bodyweight,
          target: item.targets?.[i] ?? item.target ?? "to failure",
          cues: item.cues,
          intense: item.intense,
          n: i + 1,
          of: block.sets,
          slot: `${bi}.${j}.${i}`,
          superset: [j + 1, block.items.length],
          straightIntoNext: j < block.items.length - 1,
        });
      });
      steps.push({ kind: "rest", seconds: block.rest });
    }
  });

  // Never leave the user staring at a countdown after the last set.
  while (steps.length && steps[steps.length - 1].kind === "rest") steps.pop();

  return steps;
}

/** Total number of logged sets in a session — used to size the progress bar's
 *  set ticks and to sanity-check a restored session. */
export function countSets(steps: readonly Step[]): number {
  return steps.filter((s) => s.kind === "set").length;
}
