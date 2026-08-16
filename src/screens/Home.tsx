import { motion } from "motion/react";
import { Card, Row } from "@/components/Card";
import { Button } from "@/components/Button";
import { BlurFade } from "@/components/ui/blur-fade";
import { getSession, nextSessionAfter, type SessionKey } from "@/program";
import { computeStreak, daysSince, type AppData } from "@/lib/storage";
import { plural, relativeDay } from "@/lib/format";
import { localISODate } from "@/lib/storage";
import type { View } from "@/App";

/* Answers "what am I doing and what do I set up?" in under two seconds:
 * session letter, loadout, one button. Everything else is subordinate. */

interface Props {
  data: AppData;
  onStart: (key: SessionKey) => void;
  onNavigate: (view: View) => void;
}

export function Home({ data, onStart, onNavigate }: Props) {
  const last = data.history.at(-1) ?? null;
  const key = nextSessionAfter(last?.s ?? null);
  const other = nextSessionAfter(key);
  const session = getSession(key);

  const streak = computeStreak(data.history);
  const sinceBackup = daysSince(data.lastBackup);
  const nagBackup =
    data.history.length >= 3 && (sinceBackup === null || sinceBackup > 14);

  return (
    <div>
      <BlurFade delay={0.04} inView>
        <header className="mb-7 flex items-start justify-between gap-4">
          <div>
            <h1 className="text-[1.6rem] font-bold tracking-[-0.03em] text-ink">
              Morning
            </h1>
            <p className="mt-0.5 text-[0.88rem] text-muted">
              {streak > 0 ? (
                <>
                  <span className="tnum">{streak}</span>-day streak
                </>
              ) : (
                "Let's start."
              )}
              {last && <> · last {relativeDay(last.d, localISODate())}</>}
            </p>
          </div>

          <div className="rounded-full border border-[var(--accent-line)] bg-[var(--accent-soft)] px-3 py-1.5 text-[0.7rem] font-semibold tracking-[0.1em] text-[var(--accent)] uppercase">
            Next · {key}
          </div>
        </header>
      </BlurFade>

      {nagBackup && (
        <BlurFade delay={0.08} inView>
          <button
            onClick={() => onNavigate("backup")}
            className="mb-4 flex w-full items-center gap-3 rounded-[var(--radius-control)] border border-hairline border-l-2 border-l-rose bg-white/[0.035] px-4 py-3 text-left"
          >
            <span className="text-[0.88rem] text-muted">
              You haven&apos;t backed up{" "}
              {sinceBackup === null ? "yet" : `in ${sinceBackup} days`}. It takes
              one tap.
            </span>
          </button>
        </BlurFade>
      )}

      <BlurFade delay={0.1} inView>
        <Card beam className="mb-5">
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

          {session.loadout.map((l) => (
            <Row key={l.item} label={l.item} value={l.value} indent={l.indent} />
          ))}

          <p className="mt-3 text-[0.78rem] leading-relaxed text-dim">
            Set it while you warm up. Nothing moves after that.
          </p>
        </Card>
      </BlurFade>

      <BlurFade delay={0.16} inView>
        <Button variant="primary" shine onClick={() => onStart(key)}>
          Start Session {key}
        </Button>

        <button
          onClick={() => onStart(other)}
          className="mt-3 w-full py-3 text-center text-[0.9rem] text-muted"
        >
          Do session {other} instead
        </button>
      </BlurFade>

      <BlurFade delay={0.22} inView>
        <motion.nav className="mt-7 grid grid-cols-3 gap-2.5">
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
        </motion.nav>
      </BlurFade>

      {data.history.length > 0 && (
        <p className="mt-6 text-center text-[0.76rem] text-dim">
          {data.history.length}{" "}
          {plural(data.history.length, "session")} logged
        </p>
      )}
    </div>
  );
}
