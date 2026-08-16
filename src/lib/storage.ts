import { isSessionKey, type SessionKey } from "@/program";

/* ---------------------------------------------------------------------------
 * Everything lives in localStorage under two keys:
 *   mub_v1          the history — the thing that must never be lost
 *   mub_session_v1  a workout in progress, so a refresh / phone call / crash
 *                   mid-session doesn't cost you the session
 * ------------------------------------------------------------------------- */

const DATA_KEY = "mub_v1";
const SESSION_KEY = "mub_session_v1";

export interface SessionRecord {
  /** ISO date, local. */
  d: string;
  /** Session key. */
  s: SessionKey;
  /** slot id → reps. */
  log: Record<string, number>;
  /** Elapsed minutes. */
  min: number;
  /** Sum of log values. */
  reps: number;
  ts: number;
}

export interface AppData {
  v: 1;
  history: SessionRecord[];
  lastBackup: string | null;
}

export const emptyData = (): AppData => ({ v: 1, history: [], lastBackup: null });

/** Narrow unknown parsed JSON to AppData, dropping anything malformed rather
 *  than throwing. A half-readable backup is better than none. */
export function parseData(raw: unknown): AppData | null {
  if (typeof raw !== "object" || raw === null) return null;
  const o = raw as Record<string, unknown>;
  if (!Array.isArray(o.history)) return null;

  const history: SessionRecord[] = [];
  for (const entry of o.history) {
    if (typeof entry !== "object" || entry === null) continue;
    const e = entry as Record<string, unknown>;
    if (typeof e.d !== "string" || !isSessionKey(e.s)) continue;

    const log: Record<string, number> = {};
    if (typeof e.log === "object" && e.log !== null) {
      for (const [slot, reps] of Object.entries(e.log)) {
        if (typeof reps === "number" && Number.isFinite(reps)) log[slot] = reps;
      }
    }
    history.push({
      d: e.d,
      s: e.s,
      log,
      min: typeof e.min === "number" ? e.min : 0,
      reps:
        typeof e.reps === "number"
          ? e.reps
          : Object.values(log).reduce((a, b) => a + b, 0),
      ts: typeof e.ts === "number" ? e.ts : Date.parse(e.d) || Date.now(),
    });
  }

  return {
    v: 1,
    history,
    lastBackup: typeof o.lastBackup === "string" ? o.lastBackup : null,
  };
}

export function loadData(): AppData {
  try {
    const raw = localStorage.getItem(DATA_KEY);
    if (!raw) return emptyData();
    return parseData(JSON.parse(raw)) ?? emptyData();
  } catch {
    return emptyData();
  }
}

/** Returns false if the write failed (quota, private mode) so the caller can
 *  surface it — silently losing a session is the one unacceptable failure. */
export function saveData(data: AppData): boolean {
  try {
    localStorage.setItem(DATA_KEY, JSON.stringify(data));
    return true;
  } catch {
    return false;
  }
}

/* --- workout in progress --------------------------------------------------- */

export interface LiveSession {
  key: SessionKey;
  /** Index into the compiled step list. */
  i: number;
  log: Record<string, number>;
  startedAt: number;
  /** Wall-clock ms at which the current timer/rest step ends. Null on a set
   *  step. Stored as an absolute time so backgrounding can't stretch it. */
  endsAt: number | null;
}

export function loadLiveSession(): LiveSession | null {
  try {
    const raw = localStorage.getItem(SESSION_KEY);
    if (!raw) return null;
    const o = JSON.parse(raw) as Record<string, unknown>;
    if (!isSessionKey(o.key) || typeof o.i !== "number") return null;

    // A session left open overnight is abandoned, not resumed — waking up to
    // yesterday's half-finished workout would be worse than starting fresh.
    const startedAt = typeof o.startedAt === "number" ? o.startedAt : 0;
    if (Date.now() - startedAt > 6 * 60 * 60 * 1000) {
      clearLiveSession();
      return null;
    }

    const log: Record<string, number> = {};
    if (typeof o.log === "object" && o.log !== null) {
      for (const [slot, reps] of Object.entries(o.log)) {
        if (typeof reps === "number") log[slot] = reps;
      }
    }
    return {
      key: o.key,
      i: o.i,
      log,
      startedAt,
      endsAt: typeof o.endsAt === "number" ? o.endsAt : null,
    };
  } catch {
    return null;
  }
}

export function saveLiveSession(s: LiveSession): void {
  try {
    localStorage.setItem(SESSION_KEY, JSON.stringify(s));
  } catch {
    /* the history matters, an in-progress session is nice-to-have */
  }
}

export function clearLiveSession(): void {
  try {
    localStorage.removeItem(SESSION_KEY);
  } catch {
    /* ignore */
  }
}

/* --- derived queries ------------------------------------------------------- */

/** Reps logged on this exact set the last time this session was run. */
export function lastRepsFor(
  history: readonly SessionRecord[],
  key: SessionKey,
  slot: string,
): number | null {
  for (let i = history.length - 1; i >= 0; i--) {
    const h = history[i];
    if (h.s !== key) continue;
    const reps = h.log[slot];
    if (typeof reps === "number") return reps;
  }
  return null;
}

/** The most recent session of the given letter, ignoring `excludeTs`. Used for
 *  the summary's "+7 reps vs last A". */
export function previousSameSession(
  history: readonly SessionRecord[],
  key: SessionKey,
  excludeTs: number,
): SessionRecord | null {
  for (let i = history.length - 1; i >= 0; i--) {
    const h = history[i];
    if (h.s === key && h.ts !== excludeTs) return h;
  }
  return null;
}

/** Consecutive days ending today or yesterday. Missing today doesn't break a
 *  streak until tomorrow — you haven't trained *yet*. */
export function computeStreak(history: readonly SessionRecord[]): number {
  if (history.length === 0) return 0;
  const days = new Set(history.map((h) => h.d));
  let n = 0;
  for (let i = 0; i < 400; i++) {
    const d = localISODate(new Date(Date.now() - i * 86_400_000));
    if (days.has(d)) n++;
    else if (i > 0) break;
  }
  return n;
}

/** Whole days since an ISO timestamp, or null. */
export function daysSince(iso: string | null): number | null {
  if (!iso) return null;
  const t = Date.parse(iso);
  if (Number.isNaN(t)) return null;
  return Math.floor((Date.now() - t) / 86_400_000);
}

/** Local calendar date, not UTC — `toISOString()` rolls over at the wrong
 *  moment for anyone east or west of Greenwich, which would file a 6am
 *  workout under the wrong day. */
export function localISODate(d = new Date()): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

/** Ask the browser to exempt us from storage eviction. WebKit's heuristics
 *  explicitly favour installed home-screen web apps, so this usually succeeds
 *  where it matters. */
export async function requestPersistence(): Promise<void> {
  try {
    if (navigator.storage?.persist && !(await navigator.storage.persisted())) {
      await navigator.storage.persist();
    }
  } catch {
    /* not supported — the backup screen is the real safety net */
  }
}
