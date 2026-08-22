/* Runs an iOS export through the WEB APP'S OWN PARSER.
 *
 *   node --import ./scripts/alias-hook.mjs scripts/verify-export.ts <export.json>
 *
 * `07-acceptance.md` asks that an export "opens in the web app's Restore box and
 * parses". That check was manual, which meant it was checked once and then
 * assumed forever. This imports the real `parseData` from src/lib/storage.ts —
 * not a copy of its rules — so the day the two formats drift, this fails.
 *
 * It asserts more than "did not throw": every record must survive, and survive
 * UNCHANGED. parseData is lenient by design and silently drops malformed
 * entries, so a parse that returns fewer records than it was given is exactly
 * the failure this is looking for.
 */
import fs from "node:fs";
import { parseData } from "@/lib/storage";

const path = process.argv[2];
if (!path) {
  console.error("usage: verify-export.ts <export.json>");
  process.exit(2);
}

const raw = JSON.parse(fs.readFileSync(path, "utf8"));
const parsed = parseData(raw);

if (!parsed) {
  console.error(`FAIL  the web app's parser rejected ${path} outright`);
  process.exit(1);
}

const given = Array.isArray(raw.history) ? raw.history.length : 0;
const kept = parsed.history.length;
let failures = 0;

const fail = (message: string) => {
  console.error(`FAIL  ${message}`);
  failures++;
};

if (kept !== given) {
  fail(`${given - kept} of ${given} records were dropped as malformed`);
}

for (let i = 0; i < Math.min(given, kept); i++) {
  const before = raw.history[i];
  const after = parsed.history[i];

  if (before.d !== after.d) fail(`record ${i}: date ${before.d} -> ${after.d}`);
  if (before.s !== after.s) fail(`record ${i}: session ${before.s} -> ${after.s}`);
  if (before.ts !== after.ts) fail(`record ${i}: ts ${before.ts} -> ${after.ts} (identity changed)`);
  if (before.min !== after.min) fail(`record ${i}: minutes ${before.min} -> ${after.min}`);
  if (before.reps !== after.reps) fail(`record ${i}: reps ${before.reps} -> ${after.reps}`);

  // A missing kg is meaningful and must NOT be invented on the way through.
  if (before.kg === undefined && after.kg !== undefined) {
    fail(`record ${i}: kg was backfilled to ${after.kg} — tonnage would be rewritten`);
  }
  if (before.kg !== undefined && before.kg !== after.kg) {
    fail(`record ${i}: kg ${before.kg} -> ${after.kg}`);
  }

  const slots = Object.keys(before.log ?? {});
  for (const slot of slots) {
    if (before.log[slot] !== after.log[slot]) {
      fail(`record ${i}: slot ${slot} reps ${before.log[slot]} -> ${after.log[slot]}`);
    }
  }
  if (Object.keys(after.log).length !== slots.length) {
    fail(`record ${i}: logged slots ${slots.length} -> ${Object.keys(after.log).length}`);
  }
}

if (raw.lastBackup !== undefined && raw.lastBackup !== parsed.lastBackup) {
  fail(`lastBackup ${raw.lastBackup} -> ${parsed.lastBackup}`);
}
for (const [key, kg] of Object.entries(raw.loads ?? {})) {
  if (parsed.loads?.[key as "A" | "B"] !== kg) fail(`loads.${key} ${kg} -> ${parsed.loads?.[key as "A" | "B"]}`);
}

if (failures > 0) {
  console.error(`\n${failures} problem(s). This export would not restore faithfully.`);
  process.exit(1);
}

console.log(`OK  ${kept} record(s) round-trip through the web app's parser unchanged.`);
