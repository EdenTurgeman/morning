import { PLATE_INVENTORY } from "@/program";

/* ---------------------------------------------------------------------------
 * Plate maths.
 *
 * The loadout strings used to be literals ("4×1.25 + 2×2.5"), correct only for
 * the weight the session was written for. Now that the weight is adjustable
 * the breakdown has to be derived, or the card tells you to load plates you
 * aren't using.
 *
 * It is bounded by what you actually own. An unbounded greedy fit returns
 * "3×2.5" for 7.5 kg, which is wrong with only two 2.5s per handle — the real
 * answer is 2×2.5 + 2×1.25. Respecting the inventory also makes the derived
 * strings match the program's original hand-written ones exactly.
 * ------------------------------------------------------------------------- */

/** Smallest change you can make to one handle, given the lightest plate. */
export const STEP_KG = Math.min(...PLATE_INVENTORY.map((p) => p.kg));

/** Heaviest you can load one handle with the plates you own. */
export const MAX_KG = PLATE_INVENTORY.reduce((t, p) => t + p.kg * p.count, 0);

/** "2×2.5 + 2×1.25" for one handle, or null if the plates can't make it. */
export function platesFor(kg: number): string | null {
  if (kg <= 0) return "bare handle";

  const parts: string[] = [];
  let left = kg;
  // Heaviest first, but never more of a plate than exist. Exact because every
  // denomination is a multiple of the next one down.
  for (const { kg: plate, count } of [...PLATE_INVENTORY].sort((a, b) => b.kg - a.kg)) {
    const n = Math.min(count, Math.floor(left / plate + 1e-9));
    if (n > 0) {
      parts.push(`${n}×${plate}`);
      left -= n * plate;
    }
  }
  return left > 1e-9 ? null : parts.join(" + ");
}

export function formatKg(kg: number): string {
  return Number.isInteger(kg) ? String(kg) : String(Number(kg.toFixed(2)));
}
