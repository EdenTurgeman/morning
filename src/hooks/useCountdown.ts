import { useEffect, useRef, useState } from "react";
import { beep, tick } from "@/lib/audio";

/* ---------------------------------------------------------------------------
 * A countdown driven by an absolute end time, not by counting setInterval
 * ticks. Two reasons that matters here:
 *
 *  1. iOS throttles timers hard in a backgrounded tab. A tick-counting timer
 *     would pause when you put the phone down and resume when you pick it up,
 *     silently stretching the 20 s myo-rep rest — the one rest the spec says
 *     must not stretch.
 *  2. requestAnimationFrame gives the ring a smooth sub-second value to
 *     deplete against, instead of it jumping once a second.
 * ------------------------------------------------------------------------- */

interface Options {
  /** Absolute wall-clock ms when this countdown ends. Null = not running. */
  endsAt: number | null;
  onComplete: () => void;
  /** Play a soft tick on each of the final three seconds. */
  countIn?: boolean;
}

export function useCountdown({ endsAt, onComplete, countIn = false }: Options) {
  // Fractional seconds remaining, for the ring.
  const [remaining, setRemaining] = useState(() =>
    endsAt === null ? 0 : Math.max(0, (endsAt - Date.now()) / 1000),
  );

  // Kept in refs so the rAF loop never needs to be torn down and rebuilt when
  // the parent re-renders with a new callback identity.
  const onCompleteRef = useRef(onComplete);
  onCompleteRef.current = onComplete;

  const firedRef = useRef(false);
  const lastTickRef = useRef(-1);

  useEffect(() => {
    if (endsAt === null) {
      setRemaining(0);
      return;
    }

    firedRef.current = false;
    lastTickRef.current = -1;
    let raf = 0;
    let done = false;

    const settle = () => {
      const left = (endsAt - Date.now()) / 1000;
      setRemaining(Math.max(0, left));

      if (countIn && left > 0 && left <= 3) {
        const whole = Math.ceil(left);
        if (whole !== lastTickRef.current) {
          lastTickRef.current = whole;
          tick();
        }
      }

      if (left <= 0 && !firedRef.current) {
        firedRef.current = true;
        done = true;
        beep(3);
        onCompleteRef.current();
      }
      return left;
    };

    const frame = () => {
      if (done) return;
      if (settle() > 0) raf = requestAnimationFrame(frame);
    };
    raf = requestAnimationFrame(frame);

    // rAF is the smooth path, but it stops dead in a backgrounded tab and can
    // be throttled in low-power mode. This interval is the floor that
    // guarantees the step still advances — without it, a rest could hang
    // forever on a phone that decided not to paint.
    const interval = setInterval(() => {
      if (done) return;
      settle();
    }, 250);

    // Coming back from a locked screen: settle up immediately rather than
    // waiting for the next frame or tick.
    const onVisible = () => {
      if (document.visibilityState === "visible" && !done) {
        cancelAnimationFrame(raf);
        if (settle() > 0) raf = requestAnimationFrame(frame);
      }
    };
    document.addEventListener("visibilitychange", onVisible);

    return () => {
      done = true;
      cancelAnimationFrame(raf);
      clearInterval(interval);
      document.removeEventListener("visibilitychange", onVisible);
    };
  }, [endsAt, countIn]);

  return remaining;
}
