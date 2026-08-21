# 06 — Data

## Scope for v1

**The app ships starting at zero.** Importing the existing web history is a
follow-up, not a launch requirement — do not build the import flow, the document
picker, or the migration UI in the first pass.

One thing carries over from that decision though:

> **Store data in the schema below anyway.** It costs nothing now and it makes
> the later import a file copy rather than a translation. Inventing a different
> shape and reconciling it afterwards is the only way this becomes expensive.

The two real consequences of starting empty are in §1 and §2. They matter more
than the migration does.

---

## 1. Empty is the normal case on day one

Every screen will have no data the first time it runs, and very little for the
first fortnight. That is not an edge case to handle at the end — it is what the
app actually looks like when the user first sees it.

- **Home** has no last session, no streak, no week progress, no lifetime figures.
  It still has to answer "what am I doing and what do I set up?" in two seconds.
- **The set screen** has no "last time" number for any slot. The rep counter
  falls back to a default and the copy says `First time — just go to failure`
  instead of `Last time: 11 — beat it`. The whole emotional mechanic of the app
  is absent for one session per slot. Make the first run feel deliberate rather
  than broken.
- **Summary** fires the `first` celebration tier: *"You started."* / *"From now
  on this screen tells you whether you beat the last one. That's the whole
  game."* This is the only time that tier ever shows. It is worth designing.
- **History, Ledger and The Year** are empty for real. The Ledger's whole job is
  to make months of work feel like they happened, and on day one there is
  nothing. An empty state that says "0 tonnes" is a bad answer; so is hiding the
  screen. Design something that reads as *the beginning of a record* rather than
  as an error.
- **Week meter** shows 0 of 5 with no streak and no longest run.

Treat these as designed screens with their own copy, not as `if empty { Text("No
data") }`.

## 2. Develop against seeded fixtures

You cannot design the Ledger, the year grid or the history list against nothing,
and you should not design them against three sessions either — they need to look
right after six months.

Build a debug-only seeder that can populate:

- **empty** — a fresh install
- **one session** — the `first` tier, one cell in the year grid
- **one week** — the week meter completing for the first time
- **six months** — a realistic history with a plateau, a personal best, a missed
  week, and a working-weight change partway through, so every celebration tier
  and every "not comparable" path is reachable
- **a year+** — the year grid full, a lifetime milestone about to cross

Wire it to a debug menu or a launch argument. Every screen gets reviewed at
**empty, one week and six months** before it is called done.

---

## 3. The schema

Exactly what the web app stores and exports. Keep the field names identical via
`CodingKeys` so export and the eventual import are the same code path.

```jsonc
{
  "v": 1,
  "history": [
    {
      "d":    "2026-08-16",                 // ISO date, LOCAL time, not UTC
      "s":    "A",                          // session key: "A" | "B"
      "log":  { "1.0.0": 11, "2.0.1": 14 }, // slot id -> reps
      "min":  16,                           // elapsed minutes
      "reps": 163,                          // sum of log values
      "ts":   1786899156550,                // epoch ms; the record's identity
      "kg":   7.5                           // OPTIONAL: plates per handle used
    }
  ],
  "lastBackup": "2026-08-16T06:31:00.000Z", // or null
  "loads": { "A": 7.5, "B": 5 }             // OPTIONAL: current working weights
}
```

### Field notes that matter

- **`ts` is the identity of a record.** Deletion, "previous same session" lookups
  and milestone diffing all key off it.
- **`d` is a local date string**, from the device's local calendar day, not UTC.
  Week bucketing and the year grid depend on it. Parsing it as UTC shifts
  sessions across day and week boundaries. Parse as local, or at local noon.
- **`kg` is optional and its absence is meaningful** — "logged before the weight
  became adjustable", so fall back to the program default. Never backfill it;
  that would retroactively rewrite tonnage.
- **`loads` is optional.** Absent means "use the program's default". It lives in
  data rather than the program so changing it needs no rebuild.
- **`log` is keyed by bare slot id** (`block.item.set`). The ledger's internal
  load table keys by `"{sessionKey}:{slot}"`. Two shapes — keep them straight.
- **`reps` is stored, not derived.** Recompute from `log` only when missing.

### Parsing is lenient by design

The reference parser drops malformed entries rather than throwing, on the
principle that **a half-readable backup is better than none**. Match that.

---

## 4. The in-progress session

Stored separately, so a crash, phone call or force-quit mid-workout costs
nothing. This one **is** required in v1.

```jsonc
{
  "key": "A",              // which session
  "i": 7,                  // index into the compiled step list
  "log": { "1.0.0": 11 },
  "endsAt": 1786899156550, // epoch ms the current timer ends, or null
  "startedAt": 1786898000000
}
```

- **Remaining time is computed from `endsAt`, never counted down.** A tick
  counter drifts and stops entirely when the app is suspended.
- Restoring must land on the same step with the same logged reps.

---

## 5. Storage

- One `Codable` struct mirroring §3, written as JSON to Application Support. A
  few tens of KB per year — SwiftData and Core Data buy nothing here and cost
  migration work.
- Write atomically. If a write fails, surface it; never silently drop a session.
  This is the one unacceptable failure mode in the app.
- Export to a file via the share sheet should work from day one, even with a
  short history. It is cheap, it is the same code path as the later import, and
  it means the native app is never the only copy of anything.
- iCloud is a genuine upgrade — see `05-platform.md` §6 — but manual export
  stays, because it is the only copy that survives losing the phone and the
  account together.

---

## 6. Later: importing the web history

Not v1. Recorded here so the design does not close the door on it.

There is no shared storage between a web app and a native app, so the handoff is
a file. The user taps **Back up now** in the web app, which produces JSON through
the share sheet; the native app accepts it via a document picker or by
registering for `.json`, validates, shows the session count and resulting
lifetime totals, confirms, and writes.

When that lands, the acceptance check is that the derived numbers match what the
web app's Ledger screen shows on the same device: tonnage, total reps, session
count, current streak, longest run, and the year grid. Those five numbers are the
test that the whole import is correct.

Until then the two apps run side by side with separate histories, which is fine —
the user is going to run both for a couple of weeks anyway to decide whether the
native one wins.
