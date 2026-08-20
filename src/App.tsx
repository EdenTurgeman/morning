import { useCallback, useEffect, useMemo, useState } from "react";
import { Toaster } from "sonner";
import { Sky } from "@/components/Sky";
import { Daybreak } from "@/components/Daybreak";
import { weeklyProgress } from "@/lib/week";
import { celebrationFor } from "@/lib/celebration";
import { setWeekBadge } from "@/lib/badge";
import { Home } from "@/screens/Home";
import { Workout } from "@/screens/Workout";
import { Summary } from "@/screens/Summary";
import { History } from "@/screens/History";
import { Ledger } from "@/screens/Ledger";
import { Guide } from "@/screens/Guide";
import { Backup } from "@/screens/Backup";
import { useAppData } from "@/hooks/useAppData";
import { useWorkout, type FinishedSession } from "@/hooks/useWorkout";
import { unlockAudio } from "@/lib/audio";
import { requestPersistence, type SessionRecord } from "@/lib/storage";
import {
  applySunrise,
  oklchToHex,
  sunriseAt,
  DONE_PROGRESS,
  IDLE_PROGRESS,
} from "@/lib/sunrise";
import { defaultLoadFor, type SessionKey } from "@/program";

export type View =
  | "home"
  | "history"
  | "ledger"
  | "guide"
  | "backup"
  | "summary";

export default function App() {
  const [view, setView] = useState<View>("home");
  const [lastResult, setLastResult] = useState<SessionRecord | null>(null);
  const [celebrating, setCelebrating] = useState(false);
  const {
    data,
    addSession,
    deleteSession,
    setLoad,
    markBackedUp,
    replaceAll,
    eraseAll,
  } = useAppData();

  /* The working weight for a session: your setting if you've set one, else the
   * weight the program was written for. */
  const loadFor = useCallback(
    (key: SessionKey) => data.loads?.[key] ?? defaultLoadFor(key) ?? undefined,
    [data.loads],
  );

  const handleFinish = useCallback(
    (result: FinishedSession) => {
      const record = addSession({
        s: result.key,
        log: result.log,
        min: result.minutes,
        reps: result.reps,
        ...(typeof result.kg === "number" ? { kg: result.kg } : {}),
      });
      setLastResult(record);
      setView("summary");
      // Daybreak plays over the summary, which is already mounted underneath,
      // so dismissing it is instant rather than another screen transition.
      setCelebrating(true);
    },
    [addSession],
  );

  const workout = useWorkout({ onFinish: handleFinish, loadFor });

  /* The sunrise. One number decides the app's entire colour: how far through
     the session you are. Outside a workout it sits just before dawn; the
     summary screen is full sunrise, because you've finished. */
  const progress = workout.isActive
    ? workout.progress
    : view === "summary"
      ? DONE_PROGRESS
      : IDLE_PROGRESS;

  useEffect(() => {
    applySunrise(progress);
  }, [progress]);

  /* Keep the iOS status bar tinted to match the top of the sky. Without this
     the notch area stays a fixed colour while the app warms underneath it,
     and the seam is very visible in standalone mode. */
  useEffect(() => {
    const meta = document.querySelector<HTMLMetaElement>('meta[name="theme-color"]');
    if (!meta) return;
    const { l, c, h } = sunriseAt(progress);
    meta.content = oklchToHex({ l: 0.09 + l * 0.045, c: c * 0.35, h });
  }, [progress]);

  /* Sessions still owed this week, on the home-screen icon. Installed iOS web
     apps support this from 16.4, so the badge answers "am I behind?" without
     opening anything. */
  const week = useMemo(() => weeklyProgress(data.history), [data.history]);
  useEffect(() => {
    setWeekBadge(week.remaining);
  }, [week.remaining]);

  /* iOS won't make a sound until the page has had a gesture, so arm the audio
     context on the very first touch anywhere. */
  useEffect(() => {
    const arm = () => unlockAudio();
    document.addEventListener("touchstart", arm, { once: true, passive: true });
    document.addEventListener("click", arm, { once: true });
    void requestPersistence();
    return () => {
      document.removeEventListener("touchstart", arm);
      document.removeEventListener("click", arm);
    };
  }, []);

  const navigate = useCallback((next: View) => {
    setView(next);
    window.scrollTo(0, 0);
  }, []);

  const start = useCallback(
    (key: SessionKey) => {
      unlockAudio();
      workout.start(key);
      window.scrollTo(0, 0);
    },
    [workout],
  );

  return (
    <>
      <Sky progress={progress} />

      <main
        className="mx-auto min-h-full w-full max-w-[34rem] px-5"
        style={{
          paddingTop: "calc(var(--safe-t) + 1rem)",
          paddingBottom: "calc(var(--safe-b) + 1.75rem)",
        }}
      >
        {workout.isActive && workout.step && workout.live ? (
          <Workout
            sessionKey={workout.live.key}
            steps={workout.steps}
            step={workout.step}
            index={workout.index}
            endsAt={workout.live.endsAt}
            data={data}
            log={workout.log}
            onAdvance={workout.advance}
            onBack={workout.back}
            onExtend={workout.extend}
            onAbandon={() => {
              workout.abandon();
              navigate("home");
            }}
          />
        ) : view === "summary" && lastResult ? (
          <Summary record={lastResult} data={data} onNavigate={navigate} />
        ) : view === "history" ? (
          <History data={data} onDelete={deleteSession} onNavigate={navigate} />
        ) : view === "ledger" ? (
          <Ledger data={data} onNavigate={navigate} />
        ) : view === "guide" ? (
          <Guide onNavigate={navigate} />
        ) : view === "backup" ? (
          <Backup
            data={data}
            onBackedUp={markBackedUp}
            onRestore={replaceAll}
            onErase={eraseAll}
            onNavigate={navigate}
          />
        ) : (
          <Home
            data={data}
            onStart={start}
            onNavigate={navigate}
            onSetLoad={setLoad}
          />
        )}
      </main>

      {celebrating && lastResult && (
        <Daybreak
          week={week}
          intensity={
            celebrationFor(lastResult, data.history).confetti
              ? "milestone"
              : "burst"
          }
          onDone={() => setCelebrating(false)}
        />
      )}

      <Toaster
        theme="dark"
        position="bottom-center"
        offset={16}
        toastOptions={{
          style: {
            background: "rgb(18 20 31 / 0.92)",
            border: "1px solid var(--color-hairline)",
            color: "var(--color-ink)",
            backdropFilter: "blur(16px)",
          },
        }}
      />
    </>
  );
}
