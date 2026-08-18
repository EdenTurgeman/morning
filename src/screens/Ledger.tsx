import { useMemo } from "react";
import { BlurFade } from "@/components/ui/blur-fade";
import { Card } from "@/components/Card";
import { CountUp } from "@/components/CountUp";
import { ScreenHeader } from "@/components/ScreenHeader";
import {
  computeLedger,
  formatDuration,
  nextMilestone,
} from "@/lib/ledger";
import { weeklyProgress } from "@/lib/week";
import { formatDate, plural } from "@/lib/format";
import type { AppData } from "@/lib/storage";
import type { View } from "@/App";

/* Everything you've done, ever. One staggering true number at the top, the
 * supporting facts under it, and the next threshold you're walking toward. */

export function Ledger({
  data,
  onNavigate,
}: {
  data: AppData;
  onNavigate: (view: View) => void;
}) {
  const ledger = useMemo(() => computeLedger(data.history), [data.history]);
  const week = useMemo(() => weeklyProgress(data.history), [data.history]);
  const next = nextMilestone(ledger);

  if (ledger.sessions === 0) {
    return (
      <div>
        <ScreenHeader title="Ledger" onNavigate={onNavigate} />
        <Card>
          <p className="text-[0.94rem] text-muted">
            Nothing to total up yet. Finish a session and this fills in.
          </p>
        </Card>
      </div>
    );
  }

  return (
    <div>
      <ScreenHeader title="Ledger" onNavigate={onNavigate} />

      <BlurFade delay={0.04} inView>
        <Card beam className="overflow-hidden py-7 text-center">
          {ledger.since && (
            <div className="text-[0.66rem] tracking-[0.18em] text-dim uppercase">
              since {formatDate(ledger.since)}
            </div>
          )}

          <div className="mt-3 flex items-baseline justify-center gap-2">
            <CountUp
              value={Math.round(ledger.tonnes * 10) / 10}
              decimals={1}
              className="text-[3.9rem] leading-none font-bold tracking-[-0.05em] text-ink"
            />
            <span className="text-[1.1rem] font-semibold text-[var(--accent)]">
              {ledger.tonnes === 1 ? "tonne" : "tonnes"}
            </span>
          </div>

          <p className="mt-3 text-[0.86rem] leading-relaxed text-muted">
            lifted, one rep at a time
          </p>

          {next && (
            <div className="mt-6">
              <div className="mx-auto h-[3px] w-40 overflow-hidden rounded-full bg-white/10">
                <div
                  className="h-full rounded-full bg-[var(--accent)] transition-[width] duration-1000"
                  style={{
                    width: `${Math.round(Math.min(1, Math.max(0, next.fraction)) * 100)}%`,
                    boxShadow: "0 0 10px var(--accent-glow)",
                  }}
                />
              </div>
              <p className="tnum mt-2 text-[0.74rem] text-dim">
                next {next.label} · {next.remaining}
              </p>
            </div>
          )}
        </Card>
      </BlurFade>

      <BlurFade delay={0.1} inView>
        <div className="mt-3 grid grid-cols-2 gap-2.5">
          <Stat value={ledger.reps.toLocaleString("en-US")} label="total reps" />
          <Stat value={String(ledger.sessions)} label={plural(ledger.sessions, "session")} />
          <Stat value={formatDuration(ledger.minutes)} label="under the bar" />
          <Stat
            value={String(ledger.weeks)}
            label={`${plural(ledger.weeks, "week")} in`}
          />
        </div>
      </BlurFade>

      <BlurFade delay={0.16} inView>
        <Card className="mt-3">
          <div className="mb-3 text-[0.66rem] tracking-[0.14em] text-dim uppercase">
            Breakdown
          </div>
          {Object.entries(ledger.perSession).map(([key, count]) => (
            <div
              key={key}
              className="flex items-baseline justify-between border-b border-hairline py-2.5 last:border-b-0"
            >
              <span className="text-[0.9rem] text-muted">Session {key}</span>
              <span className="tnum text-[0.92rem] font-semibold text-ink">
                {count} {plural(count, "time")}
              </span>
            </div>
          ))}
          {ledger.bodyweightReps > 0 && (
            <p className="mt-3 text-[0.76rem] leading-relaxed text-dim">
              {ledger.bodyweightReps.toLocaleString("en-US")} of those reps were
              bodyweight, so they count toward the rep total but not the tonnage —
              guessing a load for them would make the headline number fiction.
            </p>
          )}
        </Card>
      </BlurFade>

      {week.longestRun > 0 && (
        <BlurFade delay={0.2} inView>
          <p className="mt-5 text-center text-[0.8rem] text-muted">
            {week.streak > 0 ? (
              <>
                <b className="tnum font-semibold text-ink">{week.streak}</b>{" "}
                {plural(week.streak, "week")} running.{" "}
              </>
            ) : null}
            Longest run{" "}
            <b className="tnum font-semibold text-ink">{week.longestRun}</b>{" "}
            {plural(week.longestRun, "week")}.
          </p>
        </BlurFade>
      )}
    </div>
  );
}

function Stat({ value, label }: { value: string; label: string }) {
  return (
    <div className="surface rounded-[var(--radius-control)] px-4 py-3.5">
      <div className="tnum text-[1.3rem] leading-none font-bold tracking-[-0.03em] text-ink">
        {value}
      </div>
      <div className="mt-1.5 text-[0.7rem] tracking-[0.08em] text-dim uppercase">
        {label}
      </div>
    </div>
  );
}
