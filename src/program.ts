/* ===========================================================================
 *  THE PROGRAM
 *  ---------------------------------------------------------------------------
 *  This is the only file you need to touch to change the workout. Everything
 *  is a literal — exercise names, set counts, rest seconds, loads, cues. No ID
 *  lookups, no indirection, no second file to keep in sync.
 *
 *  Weights are PLATES ONLY. Add your handle weight mentally.
 *
 *  The `load` on each movement is the weight the session is WRITTEN for. Your
 *  actual working weight is set in the app (tap the loadout on the home
 *  screen) and overrides every loaded movement in the session.
 *
 *  Keep ONE weight per session. The whole premise is that load is fixed and
 *  reps are the only variable, and practically you should never be changing
 *  plates mid-workout at 6am. scripts/verify-program.ts enforces it.
 *
 *  Careful when changing these numbers: sessions logged BEFORE the app started
 *  recording weight have no weight of their own, so they fall back to this
 *  default — editing it silently re-values their tonnage. Sessions logged since
 *  carry their own figure and are unaffected.
 *
 *  ── how to edit ──────────────────────────────────────────────────────────
 *  Blocks run top to bottom. There are three kinds:
 *
 *    { kind: "warmup",   seconds, title, cues }
 *        A countdown. Auto-advances at zero.
 *
 *    { kind: "straight", exercise, sub, sets, rest, load|bodyweight,
 *                        target | targets[], cues }
 *        N sets of one exercise with `rest` seconds between them. Pass
 *        `targets` (one string per set) instead of `target` when the sets
 *        differ — that's how the myo-rep block works.
 *
 *    { kind: "superset", sets, rest, items: [ {...}, {...} ] }
 *        `sets` rounds of the listed exercises back to back. There is NO rest
 *        between partners — rest comes only after the round.
 *
 *  ── after editing ────────────────────────────────────────────────────────
 *  Run `npm run build`, then push. Nothing else to update.
 *
 *  ── one caveat ───────────────────────────────────────────────────────────
 *  "What did I do last time on this exact set" is resolved by a slot id of the
 *  form `blockIndex.itemIndex.setIndex`. If you reorder blocks or change set
 *  counts, old slots stop matching and the rep counter quietly falls back to a
 *  default. History totals are never lost — only the per-set prefill resets.
 *  Adding or editing cues, names, loads and targets is always safe.
 * ======================================================================== */

export const PROGRAM = {
  A: {
    key: "A",
    name: "Heavy",
    minutes: "~16 min",
    blocks: [
      {
        kind: "warmup",
        seconds: 90,
        title: "Warm-up",
        cues: [
          "20 arm circles forward, 20 back",
          "10 half-effort push-ups",
          "10 towel dislocates — grip a towel wide, sweep it overhead and behind you",
        ],
      },
      {
        kind: "straight",
        exercise: "Push-up",
        sub: "feet elevated",
        sets: 3,
        rest: 60,
        bodyweight: true,
        target: "8–15 reps",
        cues: [
          "3s down · 1s PAUSE at the bottom · fast up",
          "Elbows 45° from your torso, glutes squeezed",
          "Go to failure, or one rep short",
        ],
      },
      {
        kind: "superset",
        sets: 3,
        rest: 45,
        items: [
          {
            exercise: "Overhead press",
            sub: "standing, strict",
            load: 7.5,
            target: "8–15 reps",
            cues: [
              "Ribs down. No leg drive, no leaning back",
              "Start at ear height, finish biceps by your ears",
            ],
          },
          {
            exercise: "Curl",
            load: 7.5,
            target: "10–18 reps",
            cues: [
              "3 seconds lowering",
              "FULL arm extension at the bottom of every rep",
              "That bottom inch is the whole exercise",
            ],
          },
        ],
      },
      {
        kind: "superset",
        sets: 2,
        rest: 45,
        items: [
          {
            exercise: "Bent-over row",
            load: 7.5,
            target: "15–20 reps",
            cues: [
              "Hinge to 45°, flat back",
              "Pull to your hips and squeeze",
              "Shoulder insurance — don't skip it",
            ],
          },
          {
            exercise: "Hammer curl",
            load: 7.5,
            target: "12–20 reps",
            cues: ["Palms facing each other", "Full stretch at the bottom"],
          },
        ],
      },
    ],
  },

  B: {
    key: "B",
    name: "Light",
    minutes: "~19 min",
    blocks: [
      {
        kind: "warmup",
        seconds: 90,
        title: "Warm-up",
        cues: [
          "20 arm circles forward, 20 back",
          "10 half-effort push-ups",
          "10 towel dislocates",
          "Set the dumbbells while you do this",
        ],
      },
      {
        // Was a 10 kg backpack. Dropped — the backpack was this block's only
        // progressive overload, so the deficit is now the escalation: hands on
        // books, then feet elevated, then the ladder in the Guide.
        kind: "straight",
        exercise: "Push-up",
        sub: "deficit — hands on books",
        sets: 3,
        rest: 60,
        bodyweight: true,
        target: "8–15 reps",
        cues: [
          "Hands on books or blocks, chest sinking below them",
          "3s down · 1s PAUSE at the bottom · fast up",
          "Too easy → elevate your feet as well. Go to failure",
        ],
      },
      {
        kind: "superset",
        sets: 3,
        rest: 45,
        items: [
          {
            exercise: "Lateral raise",
            load: 5,
            target: "15–25 reps",
            cues: [
              "Lead with your elbows, stop at shoulder height",
              "No swinging",
              "At failure → 5–8 partial reps in the bottom third",
            ],
          },
          {
            exercise: "Rear-delt fly",
            load: 5,
            target: "15–25 reps",
            cues: [
              "Hinge until almost parallel to the floor",
              "Open your arms wide like a curtain, squeeze the blades",
            ],
          },
        ],
      },
      {
        // Trimmed from 5 sets to 3. Side delts were getting ~20 sets a week
        // from lateral raises alone, plus more from pressing in A — past the
        // point of useful return, and all from one movement. The freed volume
        // goes to the floor fly below.
        kind: "straight",
        exercise: "Lateral raise",
        sub: "myo-reps",
        sets: 3,
        rest: 20,
        load: 5,
        intense: true,
        targets: ["all-out to failure", "4–5 reps", "4–5 reps"],
        cues: [
          "Set 1 is all-out. Then 20s rest, 4–5 reps, repeat",
          "Stop when you can't get 4 clean reps",
          "The 20-second rest IS the mechanism — don't stretch it",
        ],
      },
      {
        /* Added deliberately, and appended rather than inserted: slot ids are
         * blockIndex.itemIndex.setIndex, so putting this anywhere earlier
         * would have shifted every later block's ids and handed this exercise
         * the myo block's rep history as its starting target.
         *
         * Why it's here: pecs are a stated goal but had exactly one movement
         * (push-ups) and no isolation — nothing loading the chest in a
         * stretched position. On the floor with light dumbbells the fly is the
         * movement that does that, and the floor itself caps the range safely. */
        kind: "straight",
        exercise: "Floor fly",
        sub: "lying on your back",
        // Two sets, not three: three pushed the session past the 20-minute cap,
        // which is a hard constraint. Two also lands total chest volume at
        // exactly 20 sets a week rather than overshooting.
        sets: 2,
        rest: 60,
        load: 5,
        // High reps on purpose. Pecs are far stronger than side delts, so the
        // session's fixed light weight will never be heavy here — the tempo is
        // what makes it hard, not the load.
        target: "15–25 reps",
        cues: [
          "Elbows slightly bent and locked there — a fly, not a press",
          "Lower until your triceps touch the floor · 1s PAUSE in the stretch",
          "Past 25 clean reps? Slow the lowering to 4s. Go to failure",
        ],
      },
    ],
  },
} as const satisfies Record<string, Session>;

/* --- the reference content on the Guide screen ---------------------------- */

export const GUIDE = [
  {
    heading: "The one rule",
    body: "Every working set goes to failure or one rep short. Your load stays fixed for weeks at a time, so effort is your only variable. Light loads taken to failure grow muscle as well as heavy ones (7.8% vs 8.1% CSA in Lasevicius et al.) — light loads stopped short grow almost nothing (2.8%).",
  },
  {
    heading: "Beat reps, not weight",
    body: "The number under each set is what you did last time. That's your target. Match it three sessions running and it's time to move up the ladder. Set the weight to something you can genuinely take to failure — if the prescribed number isn't that, change it on the home screen. Reps at a weight you can't finish aren't a measurement of anything.",
  },
  {
    heading: "Why B looks lopsided",
    body: "With 5 kg in each hand there is almost nothing you can train hard except small muscles, so B is a delt and chest-isolation day while A carries the compounds. It used to be 57% lateral raises, which pushed side delts past ~20 sets a week — the point where extra volume stops paying — while your pecs had one movement and no isolation at all. The myo block came down to 3 sets and the floor fly took the difference.",
  },
  {
    heading: "Progression ladder",
    body: "1. Add reps.  2. Slow the eccentric to 4–5s and add a 2s pause in the stretch.  3. Add post-failure partials in the bottom third.  4. Go up a notch in weight — tap the loadout on the home screen; the smallest step is 1.25 kg a side, and reps restart from a fresh baseline.  5. Switch to a no-ceiling variant: pike push-ups, Z-press, archer push-ups, chin-ups.",
  },
  {
    heading: "Protein — 120 g/day",
    body: "2.0 g/kg, roughly 30 g across four meals. Anywhere in 105–140 g is fine.",
  },
  {
    heading: "Calories — +250/day",
    body: "You're lean and already burning through cycling and yoga. Target +150–250 g on the scale per week. If the weekly average is flat, eat more. This is the bottleneck, not the training.",
  },
  {
    heading: "Creatine — 5 g/day",
    body: "Any time of day, no loading needed. The only supplement worth the money. Expect +1–1.5 kg in the first fortnight from intracellular water — that's fullness, not fat.",
  },
  {
    heading: "Fasted is fine",
    body: "Total daily intake beats timing. Don't rebuild your morning around a pre-workout meal. A coffee 20 minutes before does more for this session than food will.",
  },
  {
    heading: "The two ways this fails",
    body: "① You don't go to failure, because 5 or 10 kg doesn't feel like it deserves that much effort.  ② You don't eat more.",
  },
];

/* --- how often you're aiming to train ------------------------------------- */

/** Sessions per week that count as a full week. The streak is built on this,
 *  not on consecutive days — rest days shouldn't cost you anything. */
export const WEEKLY_TARGET = 5;

/** Which day a week starts on. 0 = Sunday, 1 = Monday. */
export const WEEK_STARTS_ON = 0;

/* --- the nudge on the summary screen -------------------------------------- */

export const NUTRITION_REMINDER =
  "Eat within a couple of hours: ~30 g protein. Creatine 5 g whenever. Aim 120 g protein and +250 kcal on the day.";

/* ===========================================================================
 *  Types. Nothing below here needs editing to change the workout.
 * ======================================================================== */

/** Cues containing these words carry the training effect, so they get
 *  emphasised on the set screen rather than sitting in the grey list. */
export const INTENSITY_WORDS = /failure|PAUSE|FULL|mechanism/;

export interface Movement {
  readonly exercise: string;
  readonly sub?: string;
  readonly load?: number;
  readonly bodyweight?: boolean;
  readonly target?: string;
  readonly targets?: readonly string[];
  readonly intense?: boolean;
  readonly cues: readonly string[];
}

export interface WarmupBlock {
  readonly kind: "warmup";
  readonly seconds: number;
  readonly title: string;
  readonly cues: readonly string[];
}

export interface StraightBlock extends Movement {
  readonly kind: "straight";
  readonly sets: number;
  readonly rest: number;
}

export interface SupersetBlock {
  readonly kind: "superset";
  readonly sets: number;
  readonly rest: number;
  readonly items: readonly Movement[];
}

export type Block = WarmupBlock | StraightBlock | SupersetBlock;

export interface Session {
  readonly key: string;
  readonly name: string;
  readonly minutes: string;
  readonly blocks: readonly Block[];
}

export type SessionKey = keyof typeof PROGRAM;

export const SESSION_KEYS = Object.keys(PROGRAM) as SessionKey[];

/** Reads a session back as the plain `Session` interface.
 *
 *  PROGRAM is declared `as const` so the session keys ("A", "B", …) are
 *  inferred — add a session and everything downstream picks it up with no
 *  other edit. The cost is that each block narrows to its exact literal shape,
 *  which drops the optional fields it happens not to use. Going through this
 *  accessor widens blocks back to the `Block` union so `kind` narrowing works. */
export function getSession(key: SessionKey): Session {
  return PROGRAM[key];
}

export function isSessionKey(k: unknown): k is SessionKey {
  return typeof k === "string" && k in PROGRAM;
}

/** The session the app proposes after `key` — A/B/A/B for a two-session
 *  program, and it keeps working if you ever add a third. */
export function nextSessionAfter(key: SessionKey | null): SessionKey {
  if (key === null) return SESSION_KEYS[0];
  const i = SESSION_KEYS.indexOf(key);
  return SESSION_KEYS[(i + 1) % SESSION_KEYS.length];
}

/* --- equipment -------------------------------------------------------------
 * What you own, PER HANDLE. The loadout card derives its plate breakdown from
 * this, and it bounds how heavy a session can be set. Edit it if you buy more
 * plates. */

export const PLATE_INVENTORY = [
  { kg: 2.5, count: 2 },
  { kg: 1.25, count: 4 },
] as const;

/** The per-handle weight a session is written for — the default before any
 *  in-app adjustment. Read off the first loaded movement, so it stays correct
 *  if you edit the program. */
export function defaultLoadFor(key: SessionKey): number | null {
  for (const block of getSession(key).blocks) {
    if (block.kind === "straight" && block.load) return block.load;
    if (block.kind === "superset") {
      const item = block.items.find((i) => i.load);
      if (item?.load) return item.load;
    }
  }
  return null;
}
