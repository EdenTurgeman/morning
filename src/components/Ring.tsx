import { clock } from "@/lib/format";

/* A depleting ring. The value it's given is fractional seconds straight off
 * requestAnimationFrame, so the arc moves continuously rather than stepping
 * once a second — the difference between "a timer" and something that feels
 * alive at 6am. */

interface Props {
  /** Fractional seconds remaining. */
  remaining: number;
  /** Full duration of this rest, for the arc fraction. */
  total: number;
  /** Diameter in px. */
  size?: number;
}

export function Ring({ remaining, total, size = 250 }: Props) {
  const stroke = 10;
  const r = (size - stroke * 2) / 2 - 2;
  const circumference = 2 * Math.PI * r;
  const fraction = total > 0 ? Math.max(0, Math.min(1, remaining / total)) : 0;
  const offset = circumference * (1 - fraction);

  // The last five seconds pull the glow up sharply — peripheral warning that
  // the rest is nearly over without needing to read the number.
  const urgency = remaining <= 5 ? 1 - remaining / 5 : 0;

  return (
    <div
      className="relative mx-auto grid place-items-center"
      style={{ width: size, height: size }}
    >
      {/* glow pad behind the ring */}
      <div
        className="absolute inset-6 rounded-full blur-[34px] transition-opacity duration-500"
        style={{
          background: `radial-gradient(circle, var(--accent-glow), transparent 70%)`,
          opacity: 0.2 + urgency * 0.45,
        }}
      />

      <svg
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        className="absolute -rotate-90"
        aria-hidden
      >
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="rgb(255 255 255 / 0.07)"
          strokeWidth={stroke}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="var(--accent)"
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          style={{
            filter: `drop-shadow(0 0 ${8 + urgency * 14}px var(--accent-glow))`,
          }}
        />
      </svg>

      <div className="relative text-center">
        <div
          className="tnum leading-none font-bold tracking-[-0.045em] text-ink"
          style={{ fontSize: size * 0.3 }}
        >
          {clock(remaining)}
        </div>
        <div className="mt-1.5 text-[0.68rem] tracking-[0.16em] text-dim uppercase">
          {/* Read off the same ceiled value the numeral shows, or 59.4s
              displays as "1:00" labelled "sec". */}
          {Math.ceil(remaining) >= 60 ? "min" : "sec"}
        </div>
      </div>
    </div>
  );
}
