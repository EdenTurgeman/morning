import { useEffect, useState } from "react";
import { cn } from "@/lib/utils";

/* Counts up to `value` and is guaranteed to land on it.
 *
 * Magic UI's NumberTicker is the off-the-shelf version of this and looks
 * lovely, but it's driven by a spring on requestAnimationFrame and gated on
 * useInView. If frames are throttled — backgrounded tab, low-power mode, the
 * observer not firing — it sits at its start value. For the total-reps number
 * on the summary screen, the whole point of the app, "shows 0 forever" is not
 * an acceptable failure mode. This is interval-driven and ends on `value` even
 * if every frame is dropped. */

interface Props {
  value: number;
  className?: string;
  durationMs?: number;
}

export function CountUp({ value, className, durationMs = 900 }: Props) {
  const [shown, setShown] = useState(value);

  useEffect(() => {
    // Respect the user's motion preference — and don't animate small numbers,
    // where the count-up reads as a glitch rather than a flourish.
    const reduced = window.matchMedia?.(
      "(prefers-reduced-motion: reduce)",
    )?.matches;
    if (reduced || value <= 3) {
      setShown(value);
      return;
    }

    const startedAt = Date.now();
    setShown(0);

    const id = setInterval(() => {
      const t = Math.min(1, (Date.now() - startedAt) / durationMs);
      // easeOutExpo, so it decelerates into the final number
      const eased = t === 1 ? 1 : 1 - Math.pow(2, -10 * t);
      setShown(Math.round(value * eased));
      if (t >= 1) {
        clearInterval(id);
        setShown(value);
      }
    }, 32);

    return () => {
      clearInterval(id);
      setShown(value);
    };
  }, [value, durationMs]);

  return <span className={cn("tnum", className)}>{shown}</span>;
}
