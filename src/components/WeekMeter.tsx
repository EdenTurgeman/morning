import { motion } from "motion/react";
import { cn } from "@/lib/utils";
import type { WeeklyProgress } from "@/lib/week";
import { plural } from "@/lib/format";

/* The home screen's answer to "am I on track?", readable without counting.
 *
 * Five pips, one per session in the week. Deliberately not a percentage bar:
 * the target is a small whole number, and discrete marks let you see "three
 * done, two to go" at a glance instead of decoding a fill level. */

export function WeekMeter({
  week,
  onPress,
}: {
  week: WeeklyProgress;
  onPress?: () => void;
}) {
  const pips = Array.from({ length: week.target });
  const over = Math.max(0, week.done - week.target);

  return (
    <button
      onClick={onPress}
      className="flex w-full items-center justify-between gap-4 py-1 text-left"
    >
      <div>
        <div className="flex items-center gap-1.5">
          {pips.map((_, i) => {
            const filled = i < week.done;
            return (
              <motion.span
                key={i}
                initial={false}
                animate={{ scale: filled ? 1 : 0.72 }}
                transition={{ type: "spring", stiffness: 420, damping: 24, delay: i * 0.04 }}
                className={cn(
                  "block h-2.5 w-2.5 rounded-full",
                  filled
                    ? "bg-[var(--accent)] shadow-[0_0_10px_var(--accent-glow)]"
                    : "bg-white/18",
                )}
              />
            );
          })}
          {over > 0 && (
            <span className="tnum ml-1 text-[0.72rem] font-semibold text-[var(--accent)]">
              +{over}
            </span>
          )}
        </div>

        {/* "13 of 5 this week" is nonsense. Once you're past target the
            sentence has to change, not just the number. */}
        <div className="tnum mt-2 text-[0.82rem] text-muted">
          {week.done > week.target ? (
            <>
              <b className="font-semibold text-ink">{week.done}</b> sessions this
              week
            </>
          ) : (
            <>
              <b className="font-semibold text-ink">{week.done}</b> of {week.target}{" "}
              this week
            </>
          )}
        </div>
      </div>

      {week.streak > 0 && (
        <div className="text-right">
          <div className="tnum text-[1.5rem] leading-none font-bold tracking-[-0.03em] text-ink">
            {week.streak}
          </div>
          <div className="mt-1 text-[0.66rem] tracking-[0.12em] text-dim uppercase">
            {plural(week.streak, "week")} running
          </div>
        </div>
      )}
    </button>
  );
}

/** Twelve-week strip for the History screen — one mark per week, filled when
 *  that week hit target. Makes a stalled month obvious at a glance. */
export function WeekStrip({ week }: { week: WeeklyProgress }) {
  return (
    <div className="flex items-end gap-[3px]">
      {week.recent.map((w) => (
        <div
          key={w.key}
          title={`${w.key}: ${w.count}`}
          className={cn(
            "flex-1 rounded-[2px] transition-all",
            w.complete ? "bg-[var(--accent)]" : w.count > 0 ? "bg-white/28" : "bg-white/10",
          )}
          style={{ height: `${8 + Math.min(w.count, 7) * 3.5}px` }}
        />
      ))}
    </div>
  );
}
