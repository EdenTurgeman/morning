import { BlurFade } from "@/components/ui/blur-fade";
import { CountUp } from "@/components/CountUp";
import { Button } from "@/components/Button";
import { Card } from "@/components/Card";
import { NUTRITION_REMINDER } from "@/program";
import { previousSameSession, type AppData, type SessionRecord } from "@/lib/storage";
import { plural, signed } from "@/lib/format";
import type { View } from "@/App";

/* Shown the moment the last step is done. The one number that matters is the
 * delta against the previous run of this same session — that's the whole
 * progress signal in a program where the load never changes. */

interface Props {
  record: SessionRecord;
  data: AppData;
  onNavigate: (view: View) => void;
}

export function Summary({ record, data, onNavigate }: Props) {
  const previous = previousSameSession(data.history, record.s, record.ts);
  const delta = previous ? record.reps - previous.reps : null;

  return (
    <div className="flex min-h-full flex-col justify-center py-6">
      <BlurFade delay={0.05} inView>
        <div className="text-center">
          <div className="text-[0.7rem] tracking-[0.18em] text-[var(--accent)] uppercase">
            Session {record.s} complete
          </div>

          <div className="mt-4 flex items-baseline justify-center gap-2">
            <CountUp
              value={record.reps}
              className="text-[4.4rem] leading-none font-bold tracking-[-0.05em] text-ink"
            />
            <span className="text-[1rem] text-muted">reps</span>
          </div>

          <div className="tnum mt-3 text-[0.92rem] text-muted">
            {record.min} {plural(record.min, "minute")} · {Object.keys(record.log).length}{" "}
            {plural(Object.keys(record.log).length, "set")}
          </div>
        </div>
      </BlurFade>

      <BlurFade delay={0.35} inView>
        <div className="mt-7">
          {delta === null ? (
            <Card className="text-center">
              <p className="text-[0.94rem] text-muted">
                First {record.s} logged. From here on, this screen tells you
                whether you beat it.
              </p>
            </Card>
          ) : delta === 0 ? (
            <Card className="text-center">
              <p className="text-[1.05rem] font-semibold text-ink">
                Exactly the same as last {record.s}.
              </p>
              <p className="mt-2 text-[0.9rem] leading-relaxed text-muted">
                If that&apos;s three sessions running, stop trying to add reps
                and move up the ladder — slow the eccentric to 4–5s and add a 2s
                pause in the stretch.
              </p>
            </Card>
          ) : (
            <Card className="text-center">
              <p
                className={
                  delta > 0
                    ? "tnum text-[1.5rem] font-bold tracking-[-0.02em] text-emerald"
                    : "tnum text-[1.5rem] font-bold tracking-[-0.02em] text-muted"
                }
              >
                {signed(delta)} {plural(Math.abs(delta), "rep")}
              </p>
              <p className="mt-1 text-[0.9rem] text-muted">
                vs your last {record.s}
                {previous && (
                  <span className="tnum text-dim"> ({previous.reps})</span>
                )}
              </p>
            </Card>
          )}
        </div>
      </BlurFade>

      <BlurFade delay={0.5} inView>
        <Card className="mt-3">
          <p className="text-[0.88rem] leading-relaxed text-muted">
            {NUTRITION_REMINDER}
          </p>
        </Card>

        <div className="mt-6">
          <Button variant="primary" onClick={() => onNavigate("home")}>
            Done
          </Button>
          <button
            onClick={() => onNavigate("backup")}
            className="mt-3 w-full py-3 text-center text-[0.9rem] text-muted"
          >
            Back up now
          </button>
        </div>
      </BlurFade>
    </div>
  );
}
