import { motion } from "motion/react";
import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

type Variant = "primary" | "secondary" | "ghost" | "danger";

interface Props {
  children: ReactNode;
  onClick?: () => void;
  variant?: Variant;
  className?: string;
  /** Diagonal light sweep across the face. Reserved for the one button on
   *  screen you're meant to hit. */
  shine?: boolean;
  disabled?: boolean;
  "aria-label"?: string;
}

const base =
  "relative w-full overflow-hidden rounded-[var(--radius-control)] font-semibold " +
  "select-none disabled:opacity-40 flex items-center justify-center gap-2";

/* Primary is 68px tall because the spec's floor is 64 and this is tapped with
 * a knuckle. Secondary actions sit at 54 — still comfortably above the 44pt
 * Apple minimum, but visually subordinate. */
const variants: Record<Variant, string> = {
  /* Pinned in px, not rem: the root scale was raised to lift the app's small
     text, and the primary buttons were already the right size. */
  primary:
    "min-h-[68px] px-6 text-[18px] tracking-[-0.01em] " +
    "bg-[var(--accent)] text-[var(--accent-contrast)] " +
    "shadow-[0_10px_34px_-10px_var(--accent-glow),inset_0_1px_0_rgb(255_255_255/0.28)]",
  secondary:
    "min-h-[54px] px-5 text-[0.98rem] text-ink " +
    "bg-white/[0.055] border border-hairline " +
    "shadow-[inset_0_1px_0_rgb(255_255_255/0.06)]",
  ghost: "min-h-[50px] px-5 text-[0.94rem] text-muted",
  danger:
    "min-h-[50px] px-5 text-[0.94rem] text-rose border border-rose/25 bg-rose/[0.06]",
};

export function Button({
  children,
  onClick,
  variant = "secondary",
  className,
  shine = false,
  disabled,
  ...rest
}: Props) {
  return (
    <motion.button
      type="button"
      onClick={onClick}
      disabled={disabled}
      whileTap={disabled ? undefined : { scale: 0.975 }}
      transition={{ type: "spring", stiffness: 700, damping: 32 }}
      className={cn(base, variants[variant], className)}
      {...rest}
    >
      {shine && !disabled && (
        <span
          aria-hidden
          className="pointer-events-none absolute inset-y-0 -left-1/2 w-1/3 bg-linear-to-r from-transparent via-white/25 to-transparent [animation:sweep_3.6s_ease-in-out_infinite]"
        />
      )}
      <span className="relative">{children}</span>
    </motion.button>
  );
}
