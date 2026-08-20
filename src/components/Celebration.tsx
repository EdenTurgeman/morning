import { useEffect } from "react";
import { motion } from "motion/react";
import { CountUp } from "@/components/CountUp";
import { celebrate } from "@/lib/burst";
import type { Celebration as CelebrationData } from "@/lib/celebration";

/* The summary's hero. What it renders is driven entirely by which tier the
 * session earned — see lib/celebration.ts. Sun rays and confetti are held back
 * for completing a week and hitting a milestone, so they keep meaning
 * something the twentieth time you see this screen. */

export function Celebration({
  data,
  reps,
  yielded = false,
}: {
  data: CelebrationData;
  reps: number;
  /** Collapse the supporting copy. The summary sets this once the study card's
   *  answer is showing: by then the sentence has done its job, and the space it
   *  was holding is the difference between that screen fitting and not. */
  yielded?: boolean;
}) {
  useEffect(() => {
    if (!data.confetti) return;
    const t = setTimeout(
      () => celebrate(data.tier === "streak-milestone" ? "milestone" : "burst"),
      420,
    );
    return () => clearTimeout(t);
  }, [data.confetti, data.tier]);

  return (
    <div className="relative text-center">

      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
        className="relative text-[0.7rem] tracking-[0.18em] text-[var(--accent)] uppercase"
      >
        {data.eyebrow}
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 14, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ delay: 0.08, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        className="relative mt-3 flex items-baseline justify-center gap-2"
      >
        <CountUp
          value={reps}
          className="text-[4.2rem] leading-none font-bold tracking-[-0.05em] text-ink"
        />
        <span className="text-[1rem] text-muted">reps</span>
      </motion.div>

      <motion.h2
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.18, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
        className="relative mt-4 text-[1.35rem] leading-tight font-bold tracking-[-0.025em] text-ink"
      >
        {data.headline}
      </motion.h2>

      <div
        className="relative overflow-hidden transition-[max-height,opacity] duration-[550ms] ease-[var(--ease-out-expo)]"
        style={{ maxHeight: yielded ? 0 : "12rem", opacity: yielded ? 0 : 1 }}
      >
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.26, duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
          className="mx-auto mt-2 max-w-[21rem] text-[0.92rem] leading-[1.5] text-muted"
        >
          {data.body}
        </motion.p>
      </div>
    </div>
  );
}

/**
 * Slowly turning sunburst behind the number. Pure decoration, so it's the
 * first thing to go under prefers-reduced-motion (handled globally in CSS).
 *
 * Rendered by the summary rather than from in here, and deliberately: it is
 * 420px tall behind a block half that size, and an absolutely positioned
 * descendant still counts toward an ancestor scroller's overflow. Left inside
 * the celebration it made the summary permanently scrollable by ~130px of
 * empty space, which in turn stopped the screen centring itself.
 */
export function Rays() {
  const rays = Array.from({ length: 16 });
  return (
    <div
      aria-hidden
      className="pointer-events-none absolute top-1/2 left-1/2 h-[420px] w-[420px] -translate-x-1/2 -translate-y-1/2"
    >
      <div className="absolute inset-0 [animation:spin_64s_linear_infinite]">
        {rays.map((_, i) => (
          <span
            key={i}
            className="absolute top-1/2 left-1/2 origin-left"
            style={{
              width: "210px",
              height: "2px",
              transform: `rotate(${(360 / rays.length) * i}deg)`,
              background:
                "linear-gradient(90deg, hsl(var(--accent-h) var(--accent-s) var(--accent-l) / 0.34), transparent 78%)",
            }}
          />
        ))}
      </div>
      <div
        className="absolute inset-[26%] rounded-full blur-[46px]"
        style={{
          background: "radial-gradient(circle, var(--accent-glow), transparent 70%)",
          opacity: 0.5,
        }}
      />
    </div>
  );
}
