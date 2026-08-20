/* The exercise → figure mapping, kept out of the .tsx so it can be verified
 * by scripts/verify-program.ts. A typo here fails silently — the set screen
 * just renders no artwork — so it's worth a test rather than a glance. */

export type FigureKind =
  | "pushup"
  | "overhead-press"
  | "curl"
  | "row"
  | "hammer-curl"
  | "lateral-raise"
  | "rear-delt-fly"
  | "floor-fly"
  | "warmup";

export function figureFor(exercise: string): FigureKind | null {
  const name = exercise.toLowerCase();
  // Order matters: "hammer curl" must be tested before the generic "curl".
  if (name.includes("push-up") || name.includes("pushup")) return "pushup";
  if (name.includes("overhead") || name.includes("press")) return "overhead-press";
  if (name.includes("hammer")) return "hammer-curl";
  if (name.includes("curl")) return "curl";
  if (name.includes("row")) return "row";
  if (name.includes("lateral")) return "lateral-raise";
  // "floor" must be tested before the generic "fly", or a floor fly silently
  // renders the rear-delt figure.
  if (name.includes("floor")) return "floor-fly";
  if (name.includes("rear-delt") || name.includes("fly")) return "rear-delt-fly";
  if (name.includes("warm")) return "warmup";
  return null;
}

export const FIGURE_LABELS: Record<FigureKind, string> = {
  pushup: "Push-up: lower for three seconds, pause at the bottom, push up fast",
  "overhead-press": "Overhead press: from ear height to arms locked overhead",
  curl: "Curl: full extension at the bottom, three seconds lowering",
  row: "Bent-over row: hinged at 45 degrees, pull to the hips",
  "hammer-curl": "Hammer curl: palms facing each other, full stretch at the bottom",
  "lateral-raise": "Lateral raise: lead with the elbows to shoulder height",
  "rear-delt-fly": "Rear-delt fly: hinged forward, open the arms wide",
  "floor-fly": "Floor fly: lying on your back, arms opening wide until the triceps touch the floor",
  warmup: "Warm-up: arm circles and shoulder dislocates",
};
