import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { buildSteps, type Step } from "@/lib/steps";
import { setWakeLock } from "@/lib/wakelock";
import { unlockAudio } from "@/lib/audio";
import {
  clearLiveSession,
  loadLiveSession,
  saveLiveSession,
  type LiveSession,
} from "@/lib/storage";
import type { SessionKey } from "@/program";

export interface FinishedSession {
  key: SessionKey;
  log: Record<string, number>;
  minutes: number;
  reps: number;
}

interface Options {
  onFinish: (result: FinishedSession) => void;
}

/* ---------------------------------------------------------------------------
 * The step machine. Every state change is mirrored to localStorage, so a
 * refresh, a phone call or an OS-killed tab drops you back on the step you
 * were on with your logged reps intact (spec §5.5). The prototype held this
 * purely in memory and lost the session on reload.
 * ------------------------------------------------------------------------- */

export function useWorkout({ onFinish }: Options) {
  const [live, setLive] = useState<LiveSession | null>(() => loadLiveSession());

  /* A synchronous mirror of `live`.
   *
   * Every mutation below reads from this ref and writes through `update`,
   * rather than using a setState updater callback. That is deliberate:
   * finishing a session has to write to history, and a side effect inside a
   * setState updater runs twice under StrictMode — which logged every
   * completed session to history twice. Updaters must stay pure, so the
   * decision to finish is made out here where it runs exactly once. */
  const liveRef = useRef(live);

  const update = useCallback((next: LiveSession | null) => {
    liveRef.current = next;
    setLive(next);
  }, []);

  const steps: Step[] = useMemo(
    () => (live ? buildSteps(live.key) : []),
    [live?.key],
  );

  const step: Step | null = live ? (steps[live.i] ?? null) : null;

  const onFinishRef = useRef(onFinish);
  onFinishRef.current = onFinish;

  // Persist on every change, and hold the screen awake only while active.
  useEffect(() => {
    if (live) {
      saveLiveSession(live);
      void setWakeLock(true);
    } else {
      void setWakeLock(false);
    }
  }, [live]);

  // Losing an in-progress session to an accidental swipe-away is worse than a
  // stray dialog, so warn — but only while a workout is actually running.
  useEffect(() => {
    if (!live) return;
    const handler = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener("beforeunload", handler);
    return () => window.removeEventListener("beforeunload", handler);
  }, [live !== null]);

  /** The `endsAt` a given step should carry when you arrive on it. Set steps
   *  have no clock; timers and rests start counting the moment you land. */
  const endsAtFor = (s: Step | undefined, now: number): number | null =>
    s && (s.kind === "rest" || s.kind === "timer") ? now + s.seconds * 1000 : null;

  const start = useCallback(
    (key: SessionKey) => {
      unlockAudio();
      const compiled = buildSteps(key);
      const now = Date.now();
      update({
        key,
        i: 0,
        log: {},
        startedAt: now,
        endsAt: endsAtFor(compiled[0], now),
      });
    },
    [update],
  );

  const finish = useCallback(
    (session: LiveSession) => {
      const reps = Object.values(session.log).reduce((a, b) => a + b, 0);
      const minutes = Math.max(
        1,
        Math.round((Date.now() - session.startedAt) / 60_000),
      );
      // Clear first: any second call now sees a null ref and bails, so a
      // double-tap on the final Done can't write two history entries.
      clearLiveSession();
      update(null);
      void setWakeLock(false);
      onFinishRef.current({ key: session.key, log: session.log, minutes, reps });
    },
    [update],
  );

  /** Advance one step, optionally logging reps for the step being left. */
  const advance = useCallback(
    (loggedReps?: { slot: string; reps: number }) => {
      const prev = liveRef.current;
      if (!prev) return;

      const compiled = buildSteps(prev.key);
      const log = loggedReps
        ? { ...prev.log, [loggedReps.slot]: loggedReps.reps }
        : prev.log;
      const next = prev.i + 1;

      if (next >= compiled.length) {
        finish({ ...prev, log });
        return;
      }
      update({
        ...prev,
        i: next,
        log,
        endsAt: endsAtFor(compiled[next], Date.now()),
      });
    },
    [finish, update],
  );

  const back = useCallback(() => {
    const prev = liveRef.current;
    if (!prev || prev.i === 0) return;
    const compiled = buildSteps(prev.key);
    const i = prev.i - 1;
    // Logged reps are deliberately kept — going back to fix a mistap
    // shouldn't wipe what you already recorded (spec §11).
    update({ ...prev, i, endsAt: endsAtFor(compiled[i], Date.now()) });
  }, [update]);

  /** Add time to the running rest. */
  const extend = useCallback(
    (seconds: number) => {
      const prev = liveRef.current;
      if (!prev || prev.endsAt === null) return;
      update({ ...prev, endsAt: prev.endsAt + seconds * 1000 });
    },
    [update],
  );

  /** Abandon. Nothing is written to history (spec §4.2). */
  const abandon = useCallback(() => {
    clearLiveSession();
    update(null);
    void setWakeLock(false);
  }, [update]);

  const progress = live && steps.length ? live.i / steps.length : 0;

  return {
    live,
    steps,
    step,
    index: live?.i ?? 0,
    total: steps.length,
    progress,
    log: live?.log ?? {},
    start,
    advance,
    back,
    extend,
    abandon,
    isActive: live !== null,
  };
}
