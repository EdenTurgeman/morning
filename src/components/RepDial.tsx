import { useEffect, useRef, useState } from "react";
import { motion } from "motion/react";
import { cn } from "@/lib/utils";

/* The most-tapped control in the app. Two 78px targets — comfortably past the
 * spec's 64px floor, because this gets hit with a knuckle — and a digit that
 * rolls in the direction you pushed it, so a mistap is obvious.
 *
 * Once you pass what you did last time the number turns green. That's the
 * entire point of the program in one piece of feedback. */

interface Props {
  value: number;
  /** Reports a delta rather than an absolute value: two taps landing in the
   *  same React batch would both compute from the same stale `value` and
   *  collapse into a single increment. Hold-to-repeat accelerates to 60ms, so
   *  that collapse is reachable in normal use. */
  onStep: (delta: number) => void;
  /** Reps logged on this exact set last time, or null on a first run. */
  previous: number | null;
}

export function RepDial({ value, onStep, previous }: Props) {
  const [direction, setDirection] = useState(1);
  const beating = previous !== null && value > previous;

  const step = (delta: number) => {
    setDirection(delta);
    onStep(delta);
  };

  return (
    <div className="select-none">
      <div className="flex items-center justify-center gap-5">
        <HoldButton label="One rep fewer" onPress={() => step(-1)}>
          −
        </HoldButton>

        <div className="min-w-[132px] text-center">
          {/* Keyed on the value so React swaps the digit outright — exactly
              one number is ever in the DOM. An AnimatePresence pair would
              leave the outgoing digit on screen until its exit animation
              finished, which on a stalled frame means the number you read is
              not the number you're about to log. */}
          <div className="relative h-[74px] overflow-hidden">
            <div
              key={value}
              className={cn(
                "tnum absolute inset-0 text-[3.5rem] leading-[74px] font-bold tracking-[-0.04em]",
                direction > 0 ? "roll-up" : "roll-down",
                beating ? "text-emerald" : "text-ink",
              )}
            >
              {value}
            </div>
          </div>
          <div className="mt-1 text-[0.68rem] tracking-[0.16em] text-dim uppercase">
            reps
          </div>
        </div>

        <HoldButton label="One rep more" onPress={() => step(1)}>
          +
        </HoldButton>
      </div>

      <div className="mt-4 text-center text-[0.92rem]">
        {previous !== null ? (
          <span className={beating ? "text-emerald" : "text-muted"}>
            {beating ? (
              <>Beating last time&apos;s {previous}</>
            ) : (
              <>
                Last time:{" "}
                <b className="tnum font-semibold text-ink">{previous}</b> — beat it
              </>
            )}
          </span>
        ) : (
          <span className="text-muted">First time — just go to failure</span>
        )}
      </div>
    </div>
  );
}

/** Tap to step once; hold to repeat, accelerating. Saves a dozen taps the
 *  first time you run a session with no history to prefill from. */
function HoldButton({
  children,
  onPress,
  label,
}: {
  children: React.ReactNode;
  onPress: () => void;
  label: string;
}) {
  const timers = useRef<ReturnType<typeof setTimeout>[]>([]);
  const pressRef = useRef(onPress);
  pressRef.current = onPress;

  const clear = () => {
    timers.current.forEach(clearTimeout);
    timers.current = [];
  };
  useEffect(() => clear, []);

  const begin = () => {
    clear();
    pressRef.current();
    let delay = 380;
    const schedule = () => {
      const t = setTimeout(() => {
        pressRef.current();
        delay = Math.max(60, delay * 0.72);
        schedule();
      }, delay);
      timers.current.push(t);
    };
    schedule();
  };

  return (
    <motion.button
      type="button"
      aria-label={label}
      onPointerDown={begin}
      onPointerUp={clear}
      onPointerLeave={clear}
      onPointerCancel={clear}
      onContextMenu={(e) => e.preventDefault()}
      whileTap={{ scale: 0.93 }}
      transition={{ type: "spring", stiffness: 700, damping: 30 }}
      className="grid h-[78px] w-[78px] place-items-center rounded-[24px] border border-hairline bg-white/[0.055] text-[2rem] leading-none font-medium text-ink shadow-[inset_0_1px_0_rgb(255_255_255/0.06)]"
    >
      {children}
    </motion.button>
  );
}
