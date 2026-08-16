import { BlurFade } from "@/components/ui/blur-fade";
import { Card } from "@/components/Card";
import { ScreenHeader } from "@/components/ScreenHeader";
import { formatDate, plural } from "@/lib/format";
import type { AppData } from "@/lib/storage";
import type { View } from "@/App";

/* Reverse-chronological. Enough to see a streak and spot a stall — the spec
 * explicitly rules out charts and per-set drill-down for v1. The only extra
 * here is a sparkline-free "same as last time" marker, because three identical
 * sessions is the signal to move up the ladder and it's easy to miss. */

export function History({
  data,
  onNavigate,
}: {
  data: AppData;
  onNavigate: (view: View) => void;
}) {
  const rows = [...data.history].reverse().slice(0, 80);

  return (
    <div>
      <ScreenHeader title="History" onNavigate={onNavigate} />

      {rows.length === 0 ? (
        <Card>
          <p className="text-[0.94rem] text-muted">
            Nothing yet. Your first session will show up here.
          </p>
        </Card>
      ) : (
        <BlurFade delay={0.05} inView>
          <Card className="py-1">
            {rows.map((h, i) => {
              // Compare against the previous session of the same letter.
              const earlier = rows.slice(i + 1).find((r) => r.s === h.s);
              const delta = earlier ? h.reps - earlier.reps : null;

              return (
                <div
                  // ts alone isn't guaranteed unique — a restored backup can
                  // carry whatever the file contained.
                  key={`${h.ts}-${i}`}
                  className="flex items-center justify-between gap-3 border-b border-hairline py-3.5 last:border-b-0"
                >
                  <div className="flex items-center gap-2.5">
                    <span className="grid h-7 w-7 place-items-center rounded-full border border-[var(--accent-line)] bg-[var(--accent-soft)] text-[0.72rem] font-bold text-[var(--accent)]">
                      {h.s}
                    </span>
                    <span className="text-[0.92rem] text-ink">
                      {formatDate(h.d)}
                    </span>
                  </div>

                  <div className="flex items-baseline gap-2.5">
                    {delta !== null && (
                      <span
                        className={
                          delta > 0
                            ? "tnum text-[0.78rem] text-emerald"
                            : delta < 0
                              ? "tnum text-[0.78rem] text-dim"
                              : "tnum text-[0.78rem] text-muted"
                        }
                      >
                        {delta > 0 ? `+${delta}` : delta < 0 ? delta : "="}
                      </span>
                    )}
                    <span className="tnum text-[0.92rem] font-semibold text-ink">
                      {h.reps}
                    </span>
                    <span className="tnum text-[0.8rem] text-dim">
                      {h.min}m
                    </span>
                  </div>
                </div>
              );
            })}
          </Card>
        </BlurFade>
      )}

      {data.history.length > 0 && (
        <p className="mt-5 text-center text-[0.78rem] text-dim">
          {data.history.length} {plural(data.history.length, "session")} logged
          {data.history.length > rows.length && ` · showing ${rows.length}`}
        </p>
      )}
    </div>
  );
}
