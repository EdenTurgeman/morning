import { motion } from "motion/react";
import type { Step } from "@/lib/steps";

/* Top bar for the workout screen: back, position, end. The progress bar
 * carries a tick per set, so you can see at a glance how many sets are left
 * rather than decoding "step 14 of 25" — rests aren't work, and shouldn't
 * read as progress. */

interface Props {
  index: number;
  total: number;
  steps: readonly Step[];
  onBack: () => void;
  onEnd: () => void;
}

export function Chrome({ index, total, steps, onBack, onEnd }: Props) {
  const setPositions = steps
    .map((s, i) => (s.kind === "set" ? i : -1))
    .filter((i) => i >= 0);

  return (
    <div className="mb-6">
      <div className="flex items-center justify-between">
        <button
          onClick={onBack}
          disabled={index === 0}
          className="-ml-2 rounded-full px-3 py-2 text-[0.82rem] text-muted disabled:opacity-25"
        >
          ‹ Back
        </button>

        <div className="tnum text-[0.7rem] tracking-[0.14em] text-dim uppercase">
          step {index + 1} / {total}
        </div>

        <button
          onClick={onEnd}
          className="-mr-2 rounded-full px-3 py-2 text-[0.82rem] text-muted"
        >
          End
        </button>
      </div>

      <div className="relative mt-3 h-[3px] w-full overflow-hidden rounded-full bg-white/[0.07]">
        <motion.div
          className="absolute inset-y-0 left-0 rounded-full bg-[var(--accent)]"
          style={{ boxShadow: "0 0 12px var(--accent-glow)" }}
          animate={{ width: `${(index / Math.max(1, total - 1)) * 100}%` }}
          transition={{ type: "spring", stiffness: 180, damping: 30 }}
        />
      </div>

      {/* one tick per set */}
      <div className="relative mt-1.5 h-[3px] w-full">
        {setPositions.map((pos) => (
          <span
            key={pos}
            className="absolute top-0 h-[3px] w-[3px] rounded-full transition-colors duration-500"
            style={{
              left: `${(pos / Math.max(1, total - 1)) * 100}%`,
              transform: "translateX(-50%)",
              background:
                pos < index ? "var(--accent)" : "rgb(255 255 255 / 0.16)",
            }}
          />
        ))}
      </div>
    </div>
  );
}
