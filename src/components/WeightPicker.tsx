import { motion } from "motion/react";
import { MAX_KG, STEP_KG, formatKg, platesFor } from "@/lib/plates";
import { buzz, confirmTone } from "@/lib/audio";

/* ---------------------------------------------------------------------------
 * Your working weight for a session — what you can actually lift right now,
 * not what the program was written for.
 *
 * This exists because the program's numbers are a starting guess. If 10 kg is
 * more than you can move for the prescribed reps, the honest fix is to tell
 * the app, so that rep counts stay a real measure of effort instead of a
 * record of falling short of an arbitrary target.
 *
 * Changing it is recorded against each session, so the app can tell you when
 * a rep comparison isn't like-for-like.
 * ------------------------------------------------------------------------- */

export function WeightPicker({
  kg,
  onChange,
  onClose,
}: {
  kg: number;
  onChange: (kg: number) => void;
  onClose: () => void;
}) {
  const step = (delta: number) => {
    const next = Math.min(MAX_KG, Math.max(0, Number((kg + delta).toFixed(2))));
    if (next === kg) return;
    onChange(next);
    confirmTone();
    buzz(10);
  };

  const plates = platesFor(kg);

  return (
    <div className="mt-3">
      <div className="rule mb-3" />

      <div className="flex items-center justify-between gap-3">
        <StepButton label="Lighter" onPress={() => step(-STEP_KG)} disabled={kg <= 0}>
          −
        </StepButton>

        <div className="text-center">
          <div className="tnum text-[2.1rem] leading-none font-bold tracking-[-0.03em] text-ink">
            {formatKg(kg)}
            <span className="ml-1 text-[0.9rem] font-medium text-muted">kg</span>
          </div>
          <div className="mt-1 text-[0.68rem] tracking-[0.14em] text-dim uppercase">
            per handle
          </div>
        </div>

        <StepButton label="Heavier" onPress={() => step(STEP_KG)} disabled={kg >= MAX_KG}>
          +
        </StepButton>
      </div>

      <p className="mt-3 text-center text-[0.84rem] text-muted">
        {plates ?? "Not loadable with your plates"}
      </p>

      <button
        onClick={onClose}
        className="mt-3 w-full py-2 text-center text-[0.86rem] text-[var(--accent)]"
      >
        Done
      </button>
    </div>
  );
}

function StepButton({
  children,
  onPress,
  label,
  disabled,
}: {
  children: React.ReactNode;
  onPress: () => void;
  label: string;
  disabled?: boolean;
}) {
  return (
    <motion.button
      type="button"
      aria-label={label}
      onClick={onPress}
      disabled={disabled}
      whileTap={disabled ? undefined : { scale: 0.93 }}
      transition={{ type: "spring", stiffness: 700, damping: 30 }}
      className="grid h-[58px] w-[58px] shrink-0 place-items-center rounded-[18px] border border-hairline bg-white/[0.055] text-[1.6rem] leading-none text-ink disabled:opacity-25"
    >
      {children}
    </motion.button>
  );
}
