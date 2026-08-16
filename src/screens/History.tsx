import { useMemo, useState } from "react";
import { motion } from "motion/react";
import { toast } from "sonner";
import { BlurFade } from "@/components/ui/blur-fade";
import { Card } from "@/components/Card";
import { Confirm } from "@/components/Confirm";
import { ScreenHeader } from "@/components/ScreenHeader";
import { WeekStrip } from "@/components/WeekMeter";
import { YearGrid } from "@/components/YearGrid";
import { weeklyProgress } from "@/lib/week";
import { formatDate, plural } from "@/lib/format";
import type { AppData, SessionRecord } from "@/lib/storage";
import type { View } from "@/App";

/* Reverse-chronological. Enough to see a streak and spot a stall.
 *
 * Deleting is behind an explicit Edit toggle rather than a swipe gesture: this
 * is used with sweaty hands, and an accidental swipe that destroys a logged
 * session is exactly the failure this app cannot afford. */

interface Props {
  data: AppData;
  onDelete: (ts: number) => void;
  onNavigate: (view: View) => void;
}

export function History({ data, onDelete, onNavigate }: Props) {
  const [editing, setEditing] = useState(false);
  const [pending, setPending] = useState<SessionRecord | null>(null);

  const week = useMemo(() => weeklyProgress(data.history), [data.history]);
  const rows = useMemo(() => [...data.history].reverse().slice(0, 80), [data.history]);

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
        <>
          <BlurFade delay={0.04} inView>
            <Card className="mb-3">
              <div className="mb-3 flex items-baseline justify-between">
                <span className="text-[0.68rem] tracking-[0.14em] text-dim uppercase">
                  Last 12 weeks
                </span>
                <span className="tnum text-[0.8rem] text-muted">
                  <b className="font-semibold text-ink">{week.streak}</b>{" "}
                  {plural(week.streak, "week")} running
                </span>
              </div>
              <WeekStrip week={week} />
            </Card>
          </BlurFade>

          <BlurFade delay={0.05} inView>
            <Card className="mb-3">
              <div className="mb-3 text-[0.68rem] tracking-[0.14em] text-dim uppercase">
                The year
              </div>
              <YearGrid history={data.history} />
            </Card>
          </BlurFade>

          <div className="mb-2 flex items-center justify-between px-1">
            <span className="tnum text-[0.78rem] text-dim">
              {data.history.length} {plural(data.history.length, "session")} logged
            </span>
            <button
              onClick={() => setEditing((e) => !e)}
              className="rounded-full px-2 py-1 text-[0.82rem] text-muted"
            >
              {editing ? "Done" : "Edit"}
            </button>
          </div>

          <BlurFade delay={0.06} inView>
            <Card className="py-1">
              {rows.map((h, i) => {
                const earlier = rows.slice(i + 1).find((r) => r.s === h.s);
                const delta = earlier ? h.reps - earlier.reps : null;

                return (
                  <div
                    key={`${h.ts}-${i}`}
                    className="flex items-center gap-3 border-b border-hairline py-3.5 last:border-b-0"
                  >
                    <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full border border-[var(--accent-line)] bg-[var(--accent-soft)] text-[0.72rem] font-bold text-[var(--accent)]">
                      {h.s}
                    </span>
                    <span className="flex-1 text-[0.92rem] text-ink">
                      {formatDate(h.d)}
                    </span>

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
                    <span className="tnum w-10 text-right text-[0.92rem] font-semibold text-ink">
                      {h.reps}
                    </span>
                    <span className="tnum w-8 text-right text-[0.8rem] text-dim">
                      {h.min}m
                    </span>

                    {editing && (
                      <motion.button
                        initial={{ opacity: 0, width: 0 }}
                        animate={{ opacity: 1, width: 34 }}
                        transition={{ type: "spring", stiffness: 420, damping: 32 }}
                        onClick={() => setPending(h)}
                        aria-label={`Delete session ${h.s} on ${formatDate(h.d)}`}
                        className="grid h-8 shrink-0 place-items-center rounded-lg border border-rose/30 bg-rose/10 text-[1rem] leading-none text-rose"
                      >
                        ×
                      </motion.button>
                    )}
                  </div>
                );
              })}
            </Card>
          </BlurFade>

          {data.history.length > rows.length && (
            <p className="mt-4 text-center text-[0.76rem] text-dim">
              showing the most recent {rows.length}
            </p>
          )}
        </>
      )}

      <Confirm
        open={pending !== null}
        onOpenChange={(open) => !open && setPending(null)}
        title="Delete this session?"
        description={
          pending && (
            <>
              Session <b className="text-ink">{pending.s}</b> from{" "}
              <b className="text-ink">{formatDate(pending.d)}</b> —{" "}
              <b className="tnum text-ink">{pending.reps} reps</b>. This also removes
              it from your weekly count, and any set prefills it was providing.
            </>
          )
        }
        confirmLabel="Delete"
        destructive
        onConfirm={() => {
          if (pending) {
            onDelete(pending.ts);
            toast.success("Session deleted");
          }
          setPending(null);
        }}
      />
    </div>
  );
}
