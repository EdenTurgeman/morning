/* THE STORAGE FORMAT, FROZEN.
 * ---------------------------------------------------------------------------
 * A byte-for-byte copy of `parseData` from the retired web build's
 * `src/lib/storage.ts`, in plain JavaScript and with its type narrowing turned
 * into the runtime checks it compiled to.
 *
 * WHY A COPY RATHER THAN THE ORIGINAL. `scripts/verify-export.mjs` runs the iOS
 * app's exported JSON through this, and until 2026-09-20 it imported the real
 * function out of `src/` — so the check was "the two implementations still
 * agree", which is the strongest form it could take. Retiring the web build
 * removed the other implementation, and the choice was to delete the check or
 * to freeze what it was checking against. `plans/014` §3a picked freezing, and
 * it is the right call: the point was never that the web app could read the
 * file. It is that the format Eden's six months of history is written in has
 * not quietly moved, and a frozen copy states that better than a live import
 * ever did, because a frozen copy cannot drift along with the thing it guards.
 *
 * SO DO NOT "FIX" THIS FILE. It is not a parser anybody uses; it is a record of
 * what the format was. If `Schema.swift` changes in a way this rejects, that is
 * the check working. Decide whether the change is intended, then change this
 * file DELIBERATELY and say so in the commit — never to make a build go green.
 *
 * Lenient by design: malformed entries are dropped rather than thrown on,
 * because a half-readable backup is better than none. `verify-export.mjs`
 * treats a dropped record as a failure, which is what makes the leniency safe
 * to check against.
 */

const isSessionKey = (value) => value === "A" || value === "B";

export function parseData(raw) {
  if (typeof raw !== "object" || raw === null) return null;
  const o = raw;
  if (!Array.isArray(o.history)) return null;

  const history = [];
  for (const entry of o.history) {
    if (typeof entry !== "object" || entry === null) continue;
    const e = entry;
    if (typeof e.d !== "string" || !isSessionKey(e.s)) continue;

    const log = {};
    if (typeof e.log === "object" && e.log !== null) {
      for (const [slot, reps] of Object.entries(e.log)) {
        if (typeof reps === "number" && Number.isFinite(reps)) log[slot] = reps;
      }
    }
    history.push({
      d: e.d,
      s: e.s,
      log,
      // A missing kg means "logged before the weight was adjustable" and must
      // stay missing. Backfilling it retroactively rewrites tonnage.
      ...(typeof e.kg === "number" && e.kg >= 0 ? { kg: e.kg } : {}),
      min: typeof e.min === "number" ? e.min : 0,
      reps:
        typeof e.reps === "number"
          ? e.reps
          : Object.values(log).reduce((a, b) => a + b, 0),
      // ts is the record's identity. Derived only when absent, never regenerated.
      ts: typeof e.ts === "number" ? e.ts : Date.parse(e.d) || Date.now(),
    });
  }

  const loads = {};
  if (typeof o.loads === "object" && o.loads !== null) {
    for (const [key, kg] of Object.entries(o.loads)) {
      if (isSessionKey(key) && typeof kg === "number" && Number.isFinite(kg) && kg >= 0) {
        loads[key] = kg;
      }
    }
  }

  return {
    v: 1,
    history,
    lastBackup: typeof o.lastBackup === "string" ? o.lastBackup : null,
    ...(Object.keys(loads).length ? { loads } : {}),
  };
}
