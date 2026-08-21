/* Generates the debug seed fixtures required by ios-port/06-data.md §2.
 *
 * "You cannot design the Ledger, the year grid or the history list against
 *  nothing, and you should not design them against three sessions either —
 *  they need to look right after six months."
 *
 * Output: ios/Morning/Resources/Seeds/*.seed.json, in the EXACT v1 schema the
 * web app reads and writes (06-data.md §3), so a seed can also be pasted into
 * the web app's Restore box to sanity-check that the shapes really do match.
 *
 * Deterministic: same anchor date in, same bytes out. Re-anchor with
 *   node ios/Tools/gen-seeds.mjs 2027-01-15
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const outDir = `${root}/ios/Morning/Resources/Seeds`;

const compiled = JSON.parse(readFileSync(`${root}/ios-port/content/compiled-steps.json`, "utf8"));
const program = JSON.parse(readFileSync(`${root}/ios-port/content/program.json`, "utf8"));

const anchor = process.argv[2] ?? new Date().toISOString().slice(0, 10);

/* --- deterministic PRNG (mulberry32) ------------------------------------- */
function rng(seed) {
  let a = seed;
  return () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/* --- slots, with a plausible baseline read off each set's target --------- */
function slotsFor(key) {
  return compiled.steps[key]
    .filter((s) => s.kind === "set")
    .map((s) => {
      const t = s.target ?? "";
      let base = 12;
      const range = t.match(/(\d+)[–-](\d+)/);
      if (range) base = Math.round((Number(range[1]) + Number(range[2])) / 2);
      else if (/failure/i.test(t)) base = 14;
      return { slot: s.slot, base, bodyweight: !!s.bodyweight };
    });
}
const SLOTS = { A: slotsFor("A"), B: slotsFor("B") };
const MINUTES = { A: 16, B: 19 };
const DEFAULT_KG = { A: 7.5, B: 5 };

const iso = (d) => d.toISOString().slice(0, 10);
const addDays = (d, n) => { const x = new Date(d); x.setUTCDate(x.getUTCDate() + n); return x; };

/* Build a run of sessions ending on the anchor date, five per week
 * (Sun-Thu — the week starts on Sunday, and one rest day), alternating A/B. */
function buildDates(weeks, missedWeekIndex) {
  // Noon UTC so the local calendar day of `ts` matches `d` in every timezone
  // 06-data.md: "Parse as local, or at local noon."
  const end = new Date(`${anchor}T12:00:00Z`);
  const dates = [];
  // walk backwards week by week, then reverse
  for (let w = 0; w < weeks; w++) {
    if (w === missedWeekIndex) continue;
    for (let day = 0; day < 5; day++) {
      dates.push(addDays(end, -(w * 7) - day));
    }
  }
  return dates.sort((a, b) => a - b);
}

function build({ weeks, missedWeekIndex = null, weightChangeAt = null, plateauAt = null, pbAt = null, seed = 7 }) {
  const rand = rng(seed);
  const dates = buildDates(weeks, missedWeekIndex);
  const history = [];
  let key = "A";
  let loads = { ...DEFAULT_KG };
  let plateauTotal = null;
  let plateauLeft = 0;

  dates.forEach((date, n) => {
    // Saturating progression: ~+14% reps by six months, ~+18% by a year.
    // A function of sessions actually done, NOT of position in this array —
    // otherwise a five-session seed would show six months of progress.
    const progress = n / (n + 70);

    if (weightChangeAt !== null && n === Math.floor(dates.length * weightChangeAt)) {
      loads = { A: 10, B: 6.25 };
    }

    const log = {};
    let reps = 0;
    for (const { slot, base } of SLOTS[key]) {
      // slow honest progression plus noise; the myo tail sets stay small
      const drift = base <= 5 ? progress * 1 : progress * base * 0.22;
      let v = Math.max(3, Math.round(base + drift + (rand() - 0.5) * 3));
      log[slot] = v;
      reps += v;
    }

    // a deliberate plateau: three same-letter sessions on an identical total
    if (plateauAt !== null && n === Math.floor(dates.length * plateauAt)) { plateauLeft = 3; }
    if (plateauLeft > 0 && key === "A") {
      if (plateauTotal === null) plateauTotal = reps;
      const diff = plateauTotal - reps;
      const firstSlot = SLOTS.A[0].slot;
      log[firstSlot] = Math.max(1, log[firstSlot] + diff);
      reps = Object.values(log).reduce((a, b) => a + b, 0);
      plateauLeft--;
      if (plateauLeft === 0) plateauTotal = null;
    }

    // a personal best late on, so `record` is reachable
    if (pbAt !== null && n === Math.floor(dates.length * pbAt)) {
      for (const k of Object.keys(log)) log[k] += 3;
      reps = Object.values(log).reduce((a, b) => a + b, 0);
    }

    history.push({
      d: iso(date),
      s: key,
      log,
      min: MINUTES[key] + (rand() < 0.4 ? 1 : 0),
      reps,
      ts: date.getTime(),
      kg: loads[key],
    });
    key = key === "A" ? "B" : "A";
  });

  return { v: 1, history, lastBackup: null, loads };
}

const seeds = {
  /* A fresh install. The state the app actually ships in. */
  empty: { v: 1, history: [], lastBackup: null, loads: { ...DEFAULT_KG } },

  /* One session: the `first` tier has fired, one cell in the year grid. */
  "one-session": (() => {
    const d = build({ weeks: 1, seed: 3 });
    d.history = d.history.slice(0, 1); // the FIRST session, at baseline reps
    return d;
  })(),

  /* One week: the week meter completes for the first time. */
  "one-week": build({ weeks: 1, seed: 11 }),

  /* Six months: a plateau, a personal best, a missed week, and a
   * working-weight change partway through, so every celebration tier and
   * every "not comparable" path is reachable. */
  "six-months": build({ weeks: 26, missedWeekIndex: 9, weightChangeAt: 0.55, plateauAt: 0.3, pbAt: 0.86, seed: 23 }),

  /* A year and a bit: the year grid full, a lifetime milestone about to cross. */
  "one-year": build({ weeks: 58, missedWeekIndex: 20, weightChangeAt: 0.4, plateauAt: 0.62, pbAt: 0.93, seed: 41 }),
};

const summary = [];
for (const [name, data] of Object.entries(seeds)) {
  writeFileSync(`${outDir}/${name}.seed.json`, JSON.stringify(data, null, 1) + "\n", "utf8");
  const tonnes = data.history.reduce((sum, r) => {
    const loaded = SLOTS[r.s].filter((s) => !s.bodyweight).map((s) => s.slot);
    const kg = r.kg ?? DEFAULT_KG[r.s];
    return sum + loaded.reduce((a, s) => a + (r.log[s] ?? 0) * kg * 2, 0);
  }, 0) / 1000;
  const reps = data.history.reduce((a, r) => a + r.reps, 0);
  summary.push({ name, sessions: data.history.length, reps, tonnes: Number(tonnes.toFixed(1)), from: data.history[0]?.d ?? "—", to: data.history.at(-1)?.d ?? "—" });
}
console.table(summary);
console.log(`anchored to ${anchor}`);
