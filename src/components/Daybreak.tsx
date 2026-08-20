import { useEffect, useState } from "react";
import { cn } from "@/lib/utils";
import { plural } from "@/lib/format";
import { celebrate } from "@/lib/burst";
import { chime } from "@/lib/audio";
import type { WeeklyProgress } from "@/lib/week";

/* ---------------------------------------------------------------------------
 * DAYBREAK — the moment you finish.
 *
 * Duolingo hands you a flame. The flame works because it's that product's own
 * symbol, not because streaks need fire. This app's symbol is already a
 * sunrise, and it's been warming underneath you for the whole session — so the
 * payoff is that sun finally clearing the horizon.
 *
 * CHOREOGRAPHY. The first version ran its stages back to back, finished at
 * 3.2s, sat dead for 1.4s and then cut out in 320ms. Rebuilt around what
 * actually makes a reward moment land:
 *
 *   0.00s  overlay in
 *   0.12s  ANTICIPATION — the horizon draws outward from the centre. Nothing
 *          else has happened yet; this is the beat that says something is
 *          coming, and it's what the old version had no equivalent of.
 *   0.38s  the sun rises, overshooting slightly at the top and settling —
 *          weight, rather than a linear slide.
 *   0.70s  rays bloom outward (scale + opacity, never rotation)
 *   0.90s  a brief warm flash at the moment the sun breaks the horizon
 *   1.00s  the number springs in
 *   1.35s  pips pop, staggered 120ms apart
 *   1.90s  supporting copy
 *   2.60s  the dismiss hint
 *   —      stages OVERLAP throughout, so there's never a gap with nothing
 *          moving, and the sun keeps breathing once it's arrived
 *   4.40s  a 520ms exit that fades and drifts, rather than a hard cut
 *
 * Everything is CSS keyframes with delays: compositor-driven, and it can't
 * half-play if a frame is dropped.
 * ------------------------------------------------------------------------- */

interface Props {
  week: WeeklyProgress;
  /* Confetti fires on EVERY finished session — you did the work, you get the
   * payoff. What's still held back is the SIZE of it: the milestone burst is
   * reserved for completing a week or crossing a lifetime threshold, so the
   * rare things still feel different from the ordinary ones. */
  intensity: "burst" | "milestone";
  onDone: () => void;
}

export function Daybreak({ week, intensity, onDone }: Props) {
  const [leaving, setLeaving] = useState(false);

  const dismiss = () => {
    if (leaving) return;
    setLeaving(true);
    setTimeout(onDone, 520);
  };

  useEffect(() => {
    chime();
    // Fires as the sun breaks the horizon, not on mount — the burst should
    // punctuate the peak of the animation, not precede it.
    const t0 = setTimeout(() => celebrate(intensity), 1150);
    const t = setTimeout(dismiss, 4400);
    return () => {
      clearTimeout(t0);
      clearTimeout(t);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const headline = week.streak > 0 ? week.streak : week.done;
  const label =
    week.streak > 0
      ? `${plural(week.streak, "week")} running`
      : `${plural(week.done, "session")} this week`;

  return (
    <div
      onClick={dismiss}
      role="presentation"
      className={cn(
        "fixed inset-0 z-40 overflow-hidden bg-[#04050a]",
        leaving
          ? "animate-[dbOut_520ms_cubic-bezier(0.4,0,1,1)_forwards]"
          : "animate-[dbIn_180ms_ease-out]",
      )}
    >
      {/* atmosphere first, so everything else sits in it */}
      <div className="db-wash" />

      {/* rays. A masked conic gradient rather than 18 rotating spans: the
          spans pointing sideways swept across the screen edges as the group
          scaled, which is what read as a weird in-and-out at the sides. This
          blooms from the centre and is faded out well before the edges. */}
      <div className="db-rays">
        <div className="db-rays-spin" />
      </div>

      {/* the sun */}
      <div className="db-sun" />

      {/* haze below the horizon, over the sun's lower half */}
      <div className="db-ground" />

      {/* the flash as it breaks the horizon */}
      <div className="db-flash" />

      {/* horizon — the anticipation beat, drawn outward from the centre */}
      <div className="db-horizon" />

      {/* Content sits in the upper third. Centring it put the copy directly
          over the sun, which blew out the message and erased the middle pips. */}
      <div className="relative flex h-full flex-col items-center px-8 pt-[15vh] text-center">
        <div className="animate-[dbNumber_760ms_cubic-bezier(0.34,1.56,0.64,1)_1000ms_both]">
          <div className="tnum text-[6.5rem] leading-none font-bold tracking-[-0.055em] text-ink">
            {headline}
          </div>
          <div className="mt-2 text-[0.78rem] tracking-[0.22em] text-[var(--accent)] uppercase">
            {label}
          </div>
        </div>

        <div className="mt-9 flex items-center gap-2.5">
          {Array.from({ length: week.target }).map((_, i) => (
            <span
              key={i}
              className={cn(
                "block h-3.5 w-3.5 rounded-full",
                i < week.done
                  ? "animate-[dbPip_520ms_cubic-bezier(0.34,1.56,0.64,1)_both] bg-[var(--accent)] shadow-[0_0_14px_var(--accent-glow)]"
                  : "bg-white/12",
              )}
              style={i < week.done ? { animationDelay: `${1350 + i * 120}ms` } : undefined}
            />
          ))}
        </div>

        <p className="mt-5 animate-[dbRise_620ms_cubic-bezier(0.16,1,0.3,1)_1900ms_both] text-[0.92rem] text-muted">
          {week.done >= week.target
            ? "Week complete."
            : `${week.remaining} more ${plural(week.remaining, "session")} this week.`}
        </p>

        {/* Shadowed, because it sits over the glow at the bottom of the
            screen where plain dim text stops being readable. */}
        <p className="absolute bottom-[max(2.5rem,var(--safe-b))] animate-[dbFade_800ms_ease-out_2600ms_both] text-[0.76rem] text-muted [text-shadow:0_1px_10px_rgb(0_0_0/0.7)]">
          tap to continue
        </p>
      </div>

      <div className="grain" />
    </div>
  );
}
