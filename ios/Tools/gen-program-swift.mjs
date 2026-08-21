/* One-shot scaffolding generator.
 *
 * Transcribes ios-port/content/program.json into ios/Morning/Program.swift as
 * Swift literals, per ios-port/03-program.md: the program must live as one
 * plainly-structured object in one file that the user edits by hand.
 *
 * Run this ONCE, at the start of the port. After that, Program.swift is the
 * source of truth and this script is dead weight — do not wire it into the
 * build, and do not re-run it over hand edits.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const p = JSON.parse(readFileSync(`${root}/ios-port/content/program.json`, "utf8"));

const sp = (n) => " ".repeat(n);
const str = (v) => {
  if (typeof v !== "string") throw new Error(`not a string: ${v}`);
  if (v.includes('"') || v.includes("\\")) throw new Error(`needs escaping, refusing: ${v}`);
  return `"${v}"`;
};
const num = (v) => (Number.isInteger(v) ? String(v) : String(v));
const list = (items, ind) =>
  items.length === 0 ? "[]" : `[\n${items.map((i) => sp(ind + 4) + str(i)).join(",\n")},\n${sp(ind)}]`;

/* Emits initialiser arguments in DECLARED ORDER — Swift requires it. */
function movementArgs(m, ind) {
  const a = [];
  a.push(`exercise: ${str(m.exercise)}`);
  if (m.sub != null) a.push(`sub: ${str(m.sub)}`);
  if (m.load != null) a.push(`load: ${num(m.load)}`);
  if (m.bodyweight) a.push(`bodyweight: true`);
  if (m.target != null) a.push(`target: ${str(m.target)}`);
  if (m.targets != null) a.push(`targets: ${list(m.targets, ind)}`);
  if (m.intense) a.push(`intense: true`);
  a.push(`cues: ${list(m.cues, ind)}`);
  return a;
}

function straightArgs(b, ind) {
  const a = [];
  a.push(`exercise: ${str(b.exercise)}`);
  if (b.sub != null) a.push(`sub: ${str(b.sub)}`);
  a.push(`sets: ${b.sets}`);
  a.push(`rest: ${b.rest}`);
  if (b.load != null) a.push(`load: ${num(b.load)}`);
  if (b.bodyweight) a.push(`bodyweight: true`);
  if (b.target != null) a.push(`target: ${str(b.target)}`);
  if (b.targets != null) a.push(`targets: ${list(b.targets, ind)}`);
  if (b.intense) a.push(`intense: true`);
  a.push(`cues: ${list(b.cues, ind)}`);
  return a;
}

function block(b, ind) {
  const i = sp(ind);
  const inner = ind + 4;
  if (b.kind === "warmup") {
    return `${i}.warmup(Warmup(\n${sp(inner)}seconds: ${b.seconds},\n${sp(inner)}title: ${str(b.title)},\n${sp(inner)}cues: ${list(b.cues, inner)}\n${i})),`;
  }
  if (b.kind === "straight") {
    const a = straightArgs(b, inner).map((x) => sp(inner) + x).join(",\n");
    return `${i}.straight(Straight(\n${a}\n${i})),`;
  }
  if (b.kind === "superset") {
    const items = b.items
      .map((m) => {
        const a = movementArgs(m, inner + 8).map((x) => sp(inner + 8) + x).join(",\n");
        return `${sp(inner + 4)}Movement(\n${a}\n${sp(inner + 4)})`;
      })
      .join(",\n");
    return `${i}.superset(Superset(\n${sp(inner)}sets: ${b.sets},\n${sp(inner)}rest: ${b.rest},\n${sp(inner)}items: [\n${items},\n${sp(inner)}]\n${i})),`;
  }
  throw new Error(`unknown block kind: ${b.kind}`);
}

function session(s) {
  const blocks = s.blocks.map((b) => block(b, 12)).join("\n");
  return `    Session(
        key: ${str(s.key)},
        name: ${str(s.name)},
        minutes: ${str(s.minutes)},
        blocks: [
${blocks}
        ]
    ),`;
}

const sessions = Object.values(p.sessions).map(session).join("\n");
const plates = p.plateInventory.map((x) => `    Plate(kg: ${num(x.kg)}, count: ${x.count}),`).join("\n");

const out = `/* ===========================================================================
 *  THE PROGRAM
 *  ---------------------------------------------------------------------------
 *  This is the only file you need to touch to change the workout. Everything
 *  is a literal — exercise names, set counts, rest seconds, loads, cues. No ID
 *  lookups, no indirection, no second file to keep in sync, and deliberately
 *  NOT a JSON resource: you edit Swift, rebuild, and install.
 *
 *  Weights are PLATES ONLY. Add your handle weight mentally.
 *
 *  The \`load\` on each movement is the weight the session is WRITTEN for. Your
 *  actual working weight is set in the app (tap the loadout on the home
 *  screen) and overrides every loaded movement in the session.
 *
 *  Keep ONE weight per session. The whole premise is that load is fixed and
 *  reps are the only variable, and practically you should never be changing
 *  plates mid-workout at 6am. The acceptance tests enforce it.
 *
 *  Careful when changing these numbers: sessions logged BEFORE the app started
 *  recording weight have no weight of their own, so they fall back to this
 *  default — editing it silently re-values their tonnage. Sessions logged since
 *  carry their own figure and are unaffected.
 *
 *  ── how to edit ──────────────────────────────────────────────────────────
 *  Blocks run top to bottom. There are three kinds:
 *
 *    .warmup(Warmup(seconds:title:cues:))
 *        A countdown. Auto-advances at zero.
 *
 *    .straight(Straight(exercise:sub:sets:rest:load:bodyweight:target:targets:cues:intense:))
 *        N sets of one exercise with \`rest\` seconds between them. Pass
 *        \`targets\` (one string per set) instead of \`target\` when the sets
 *        differ — that is how the myo-rep block works.
 *
 *    .superset(Superset(sets:rest:items:))
 *        \`sets\` rounds of the listed exercises back to back. There is NO rest
 *        between partners — rest comes only after the round.
 *
 *  ── one caveat ───────────────────────────────────────────────────────────
 *  "What did I do last time on this exact set" is resolved by a slot id of the
 *  form \`blockIndex.itemIndex.setIndex\`. If you reorder blocks or change set
 *  counts, old slots stop matching and the rep counter quietly falls back to a
 *  default. History totals are never lost — only the per-set prefill resets.
 *  Adding or editing cues, names, loads and targets is always safe.
 *
 *  This is why the floor fly in B was APPENDED rather than inserted: inserting
 *  it earlier would have shifted every later block's slot ids and handed it the
 *  myo block's rep history as its starting target. Preserve that property.
 *
 *  ── provenance ───────────────────────────────────────────────────────────
 *  Transcribed mechanically from ios-port/content/program.json by
 *  ios/Tools/gen-program-swift.mjs. From here on THIS FILE is the source of
 *  truth; the JSON is a frozen snapshot of the web build and is not read at
 *  runtime. Do not re-run the generator over hand edits.
 * ======================================================================== */

import Foundation

// MARK: - Types

struct Movement {
    let exercise: String
    let sub: String?
    let load: Double?
    let bodyweight: Bool
    let target: String?
    let targets: [String]?
    let intense: Bool
    let cues: [String]

    init(
        exercise: String,
        sub: String? = nil,
        load: Double? = nil,
        bodyweight: Bool = false,
        target: String? = nil,
        targets: [String]? = nil,
        intense: Bool = false,
        cues: [String]
    ) {
        self.exercise = exercise
        self.sub = sub
        self.load = load
        self.bodyweight = bodyweight
        self.target = target
        self.targets = targets
        self.intense = intense
        self.cues = cues
    }
}

struct Warmup {
    let seconds: Int
    let title: String
    let cues: [String]

    init(seconds: Int, title: String, cues: [String]) {
        self.seconds = seconds
        self.title = title
        self.cues = cues
    }
}

struct Straight {
    let exercise: String
    let sub: String?
    let sets: Int
    let rest: Int
    let load: Double?
    let bodyweight: Bool
    let target: String?
    let targets: [String]?
    let intense: Bool
    let cues: [String]

    init(
        exercise: String,
        sub: String? = nil,
        sets: Int,
        rest: Int,
        load: Double? = nil,
        bodyweight: Bool = false,
        target: String? = nil,
        targets: [String]? = nil,
        intense: Bool = false,
        cues: [String]
    ) {
        self.exercise = exercise
        self.sub = sub
        self.sets = sets
        self.rest = rest
        self.load = load
        self.bodyweight = bodyweight
        self.target = target
        self.targets = targets
        self.intense = intense
        self.cues = cues
    }
}

struct Superset {
    let sets: Int
    let rest: Int
    let items: [Movement]

    init(sets: Int, rest: Int, items: [Movement]) {
        self.sets = sets
        self.rest = rest
        self.items = items
    }
}

enum Block {
    case warmup(Warmup)
    case straight(Straight)
    case superset(Superset)
}

struct Session {
    let key: String
    let name: String
    let minutes: String
    let blocks: [Block]

    init(key: String, name: String, minutes: String, blocks: [Block]) {
        self.key = key
        self.name = name
        self.minutes = minutes
        self.blocks = blocks
    }
}

struct Plate {
    let kg: Double
    let count: Int

    init(kg: Double, count: Int) {
        self.kg = kg
        self.count = count
    }
}

// MARK: - The program

let program: [Session] = [
${sessions}
]

/* --- how often you're aiming to train ------------------------------------- */

/// Sessions per week that count as a full week. The streak is built on this,
/// not on consecutive days — rest days shouldn't cost you anything.
let weeklyTarget = ${p.weeklyTarget}

/// Which day a week starts on, in Foundation's convention: 1 = Sunday.
/// The web build stored 0 = Sunday; ${p.weekStartsOn} there means Sunday here.
let weekStartsOn = 1

/// Cues containing any of these words carry the training effect, so they get
/// emphasised on the set screen rather than sitting in the grey list.
/// Case-sensitive substring match, exactly like the web build's regex.
let intensityWords = ["failure", "PAUSE", "FULL", "mechanism"]

/* --- equipment -------------------------------------------------------------
 * What you own, PER HANDLE. The loadout card derives its plate breakdown from
 * this, and it bounds how heavy a session can be set. Edit it if you buy more
 * plates.
 *
 * Bounded by this inventory, 7.5 kg resolves to 2×2.5 + 2×1.25. An unbounded
 * greedy fit returns 3×2.5, which is impossible — you only own two 2.5s.
 */

let plateInventory: [Plate] = [
${plates}
]

// MARK: - Derived helpers

extension Session {
    /// The per-handle weight this session is written for — the default before
    /// any in-app adjustment. Read off the first loaded movement, so it stays
    /// correct if you edit the program.
    var defaultLoad: Double? {
        for block in blocks {
            switch block {
            case .warmup:
                continue
            case .straight(let s):
                if let load = s.load { return load }
            case .superset(let s):
                if let load = s.items.first(where: { $0.load != nil })?.load { return load }
            }
        }
        return nil
    }
}

/// The session the app proposes after \`key\` — A/B/A/B for a two-session
/// program, and it keeps working if you ever add a third. A fresh install,
/// where \`key\` is nil, proposes the first session.
func nextSession(after key: String?) -> Session {
    guard let key, let i = program.firstIndex(where: { $0.key == key }) else {
        return program[0]
    }
    return program[(i + 1) % program.count]
}

func session(for key: String) -> Session? {
    program.first { $0.key == key }
}
`;

writeFileSync(`${root}/ios/Morning/Program.swift`, out, "utf8");
console.log(`wrote ios/Morning/Program.swift (${out.split("\n").length} lines)`);
