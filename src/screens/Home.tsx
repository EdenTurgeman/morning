import { useMemo, useState } from "react";
import { Card } from "@/components/Card";
import { WeightPicker } from "@/components/WeightPicker";
import { formatKg, platesFor } from "@/lib/plates";
import { Button } from "@/components/Button";
import { WeekMeter } from "@/components/WeekMeter";
import { BlurFade } from "@/components/ui/blur-fade";
import {
  defaultLoadFor,
  getSession,
  nextSessionAfter,
  type SessionKey,
} from "@/program";
import { daysSince, localISODate, type AppData } from "@/lib/storage";
import { weeklyProgress, weekNudge } from "@/lib/week";
import { computeLedger } from "@/lib/ledger";
import { relativeDay } from "@/lib/format";
import type { View } from "@/App";

/* Answers "what am I doing and what do I set up?" in under two seconds:
 * session letter, loadout, one button.
 *
 * Layout is a full-height flex column with a spacer above the CTA, so
 * "Start Session" always lands in the bottom third of the screen — within
 * thumb reach one-handed, on any phone size, regardless of how much the
 * loadout card and nudges push down from above. */

interface Props {
  data: AppData;
  onStart: (key: SessionKey) => void;
  onNavigate: (view: View) => void;
  onSetLoad: (key: SessionKey, kg: number) => void;
}

export function Home({ data, onStart, onNavigate, onSetLoad }: Props) {
  const [editingLoad, setEditingLoad] = useState(false);
  const last = data.history.at(-1) ?? null;
  const key = nextSessionAfter(last?.s ?? null);
  const other = nextSessionAfter(key);
  const session = getSession(key);

  const kg = data.loads?.[key] ?? defaultLoadFor(key) ?? 0;
  const plates = platesFor(kg);

  const week = useMemo(() => weeklyProgress(data.history), [data.history]);
  const ledger = useMemo(() => computeLedger(data.history), [data.history]);
  const nudge = weekNudge(week);

  const sinceBackup = daysSince(data.lastBackup);
  const nagBackup =
    data.history.length >= 3 && (sinceBackup === null || sinceBackup > 14);

  return (
    <div className="flex min-h-full flex-col">
      <BlurFade delay={0.04} inView>
        <header className="flex items-start justify-between gap-4">
          <div>
            <h1 className="text-[1.6rem] leading-none font-bold tracking-[-0.03em] text-ink">
              Morning
            </h1>
            {last && (
              <p className="mt-1.5 text-[0.84rem] text-dim">
                last session {relativeDay(last.d, localISODate())}
              </p>
            )}
          </div>

          <div className="rounded-full border border-[var(--accent-line)] bg-[var(--accent-soft)] px-3 py-1.5 text-[0.7rem] font-semibold tracking-[0.1em] text-[var(--accent)] uppercase">
            Next · {key}
          </div>
        </header>
      </BlurFade>

      {data.history.length > 0 && (
        <BlurFade delay={0.08} inView>
          <Card className="mt-4 py-4">
            <WeekMeter week={week} onPress={() => onNavigate("history")} />

            {nudge && (
              <>
                <div className="rule my-3" />
                <p className="text-[0.84rem] text-muted">{nudge}</p>
              </>
            )}

            {/* The lifetime total is its own invitation — a number this big is
                a better door into the Ledger than a nav button would be. */}
            {ledger.tonnes >= 0.1 && (
              <>
                <div className="rule my-3" />
                <button
                  onClick={() => onNavigate("ledger")}
                  className="flex w-full items-baseline justify-between gap-3 text-left"
                >
                  <span className="tnum text-[0.84rem] text-muted">
                    <b className="font-semibold text-ink">
                      {ledger.tonnes.toFixed(1)}
                    </b>{" "}
                    tonnes moved ·{" "}
                    <b className="font-semibold text-ink">
                      {ledger.reps.toLocaleString("en-US")}
                    </b>{" "}
                    reps
                  </span>
                  <span className="text-[0.9rem] text-[var(--accent)]">›</span>
                </button>
              </>
            )}
          </Card>
        </BlurFade>
      )}

      {nagBackup && (
        <BlurFade delay={0.1} inView>
          <button
            onClick={() => onNavigate("backup")}
            className="mt-3 w-full rounded-[var(--radius-control)] border border-hairline border-l-2 border-l-rose bg-white/[0.035] px-4 py-3 text-left text-[0.86rem] text-muted"
          >
            You haven&apos;t backed up{" "}
            {sinceBackup === null ? "yet" : `in ${sinceBackup} days`}. It takes one
            tap.
          </button>
        </BlurFade>
      )}

      <BlurFade delay={0.12} inView>
        <Card beam className="mt-3">
          <div className="mb-3 flex items-end justify-between">
            <div>
              <div className="text-[0.68rem] tracking-[0.16em] text-[var(--accent)] uppercase">
                Session {key}
              </div>
              <div className="mt-0.5 text-[1.45rem] font-bold tracking-[-0.025em] text-ink">
                {session.name}
              </div>
            </div>
            <div className="pb-1 text-[0.85rem] text-dim">{session.minutes}</div>
          </div>

          <div className="rule mb-1" />

          {/* The weight is a setting, not a fixed instruction. The program's
              number is a starting guess, and it is only useful if it matches
              what you can actually lift for the prescribed reps. */}
          <button
            onClick={() => setEditingLoad((e) => !e)}
            className="flex w-full items-baseline justify-between gap-4 py-2.5 text-left"
          >
            <span className="text-[0.92rem] text-muted">Dumbbells</span>
            <span className="flex items-baseline gap-2">
              <span className="tnum text-[0.96rem] font-semibold text-ink">
                {formatKg(kg)} kg each
              </span>
              <span className="text-[0.86rem] text-[var(--accent)]">
                {editingLoad ? "close" : "change"}
              </span>
            </span>
          </button>

          {editingLoad ? (
            <WeightPicker
              kg={kg}
              onChange={(next) => onSetLoad(key, next)}
              onClose={() => setEditingLoad(false)}
            />
          ) : (
            <>
              {plates && (
                <div className="-mt-1 flex items-baseline justify-between gap-4">
                  <span className="text-[0.76rem] text-dim">per handle</span>
                  <span className="tnum text-[0.76rem] text-dim">{plates}</span>
                </div>
              )}
              <p className="mt-3 text-[0.78rem] leading-relaxed text-dim">
                Set it while you warm up. Nothing moves after that.
              </p>
            </>
          )}
        </Card>
      </BlurFade>

      {/* Pushes the CTA to the bottom of the viewport on tall screens without
          stranding it below the fold on short ones. */}
      <div className="min-h-4 flex-1" />

      <BlurFade delay={0.18} inView>
        <Button variant="primary" shine onClick={() => onStart(key)}>
          Start Session {key}
        </Button>

        <button
          onClick={() => onStart(other)}
          className="mt-2 w-full py-3 text-center text-[0.88rem] text-dim"
        >
          Do session {other} instead
        </button>

        <nav className="mt-4 grid grid-cols-3 gap-2.5">
          {(
            [
              ["History", "history"],
              ["Guide", "guide"],
              ["Backup", "backup"],
            ] as const
          ).map(([label, view]) => (
            <Button key={view} onClick={() => onNavigate(view)}>
              {label}
            </Button>
          ))}
        </nav>
      </BlurFade>
    </div>
  );
}
