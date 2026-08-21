# 06 — Data contract and migration

## The rule

> **The history is sacred.** There is real data — several months of mornings,
> over a thousand reps, more than twelve tonnes on the Ledger. The native app
> must import it on first launch and reproduce every derived number exactly.

An app that starts the Ledger at zero is worse than the one it replaces, however
good it looks. The Ledger and the streak are the reason the user opens it.

---

## The schema

Exactly what the web app stores in `localStorage` under `mub_v1`, and exactly
what its Backup screen exports:

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

- **`ts` is the identity of a record.** Deletion, "previous same session"
  lookups and milestone diffing all key off it. Preserve it exactly; do not
  regenerate.
- **`d` is a local date string**, produced from the device's local calendar day,
  not a UTC date. Week bucketing and the year grid depend on this. Parsing it as
  UTC will shift sessions across day and week boundaries for anyone east or west
  of GMT. Parse as local, or at local noon.
- **`kg` is optional and its absence is meaningful.** It means "logged before the
  weight became adjustable" — fall back to the program's default for that
  session. Do not backfill it; that would retroactively rewrite tonnage.
- **`loads` is optional.** Absent means "use the program's default". It lives in
  data rather than in the program so changing it needs no rebuild.
- **`log` is keyed by bare slot id** (`block.item.set`). The ledger's internal
  load table keys by `"{sessionKey}:{slot}"`. Two different shapes — keep them
  straight or the import will mis-value.
- **`reps` is stored, not derived.** Recompute it from `log` only when it is
  missing.

### Parsing must be lenient

The reference parser drops malformed entries rather than throwing, on the
principle that **a half-readable backup is better than none**. Match that: skip
bad records, keep good ones, never fail the whole import because one field is
wrong.

---

## The in-progress session

Stored separately under `mub_session_v1`, so a crash, phone call or force-quit
mid-workout costs nothing:

```jsonc
{
  "key": "A",           // which session
  "i": 7,               // index into the compiled step list
  "log": { "1.0.0": 11 },
  "endsAt": 1786899156550, // epoch ms the current timer ends, or null
  "startedAt": 1786898000000
}
```

Two things to preserve:

- **Remaining time is computed from `endsAt`, never counted down.** A tick
  counter drifts, and stops entirely when the app is suspended.
- Restoring mid-session must land on the same step with the same logged reps.

This does **not** need to be imported from the web app — nobody will be
mid-session across the switch. It does need to exist natively.

---

## The migration path

There is no shared storage between a web app and a native app, so the handoff is
a file.

1. Before switching, the user taps **Back up now** in the web app. It produces a
   JSON file through the share sheet.
2. On first launch, the native app offers **Import**: a document picker, or
   accepting the JSON via share sheet / Files / AirDrop.
3. Validate, show the session count and the resulting lifetime totals, confirm,
   and write.
4. Verify the derived numbers match what the web app shows on its Ledger screen
   — tonnage, total reps, session count, streak, longest run. **Check these
   against the real device before declaring the port done.** They are the test
   that the whole import is correct.

Register the app for `.json` so the exported file opens straight into it.

Keep the same export shape going forward. The user should be able to move data
back and forth while both apps exist, and he will run both for a couple of weeks.

---

## Recommended native storage

- One `Codable` struct mirroring the schema above, written as JSON to Application
  Support. A few tens of KB per year — SwiftData and Core Data buy nothing here
  and cost migration work.
- Write atomically. If a write fails, surface it; do not silently drop a session.
  This is the one unacceptable failure mode in the app.
- Keep the JSON field names identical (`d`, `s`, `log`, `min`, `reps`, `ts`,
  `kg`) via `CodingKeys`, so export and import are the same code path and stay
  compatible with the web build.
- iCloud is a genuine upgrade here — see `05-platform.md` §6 — but manual export
  stays, because it is the only copy that survives losing the phone and the
  account together.
