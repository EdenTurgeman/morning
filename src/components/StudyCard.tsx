import { useEffect, useRef, useState } from "react";
import { cn } from "@/lib/utils";
import type { Card, Subject } from "@/lib/cards";

/* ---------------------------------------------------------------------------
 * A question in the dead time.
 *
 * The one constraint that shapes everything here: you must never miss the
 * timer because you were thinking. So the answer AUTO-REVEALS — tapping only
 * brings it forward if you already have it. Nothing is gated behind an
 * interaction, because at 6am mid-rest you will not reliably perform one, and
 * a card you never got the answer to is worse than no card.
 *
 * The thinking bar is the honest part of the design: it shows that an answer
 * is coming and roughly when, so the pause reads as deliberate rather than as
 * the app having stalled. When the answer lands, the bar stops being a timer
 * and becomes the rule the answer sits under — one element, both jobs.
 *
 * Deliberately silent. The app's audio vocabulary is entirely about time —
 * beeps mean the rest is ending — and a card that made a noise during the last
 * five seconds of a countdown would be actively misleading.
 * ------------------------------------------------------------------------- */

interface Props {
  card: Card;
  /** Milliseconds of thinking time before the answer appears by itself. */
  autoRevealMs?: number;
  /**
   * Tighter type and spacing, for the summary — which has to hold the
   * celebration, the week and a pinned Done button on the same screen. The
   * rest screen has room and uses the larger default.
   */
  compact?: boolean;
  /** Fires once, whether the answer was tapped for or arrived on its own. The
   *  rest screen uses it to hand the card the space the ring was holding. */
  onReveal?: () => void;
  className?: string;
}

export function StudyCard({
  card,
  autoRevealMs = 9000,
  compact = false,
  onReveal,
  className,
}: Props) {
  const [revealed, setRevealed] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Held in a ref so the auto-reveal timer never has to be torn down and
  // restarted just because the parent re-rendered with a new closure — the
  // countdown above re-renders this component sixty times a second.
  const notify = useRef(onReveal);
  notify.current = onReveal;

  useEffect(() => {
    setRevealed(false);
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => {
      setRevealed(true);
      notify.current?.();
    }, autoRevealMs);
    return () => {
      if (timer.current) clearTimeout(timer.current);
    };
  }, [card.id, autoRevealMs]);

  const reveal = () => {
    if (revealed) return;
    if (timer.current) clearTimeout(timer.current);
    setRevealed(true);
    notify.current?.();
  };

  return (
    <div
      // Interactive only while there's something left to reveal; afterwards it
      // goes back to being text you can select and read.
      {...(revealed
        ? {}
        : {
            role: "button" as const,
            tabIndex: 0,
            "aria-label": "Reveal the answer",
            onClick: reveal,
            onKeyDown: (e: React.KeyboardEvent) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                reveal();
              }
            },
          })}
      className={cn("select-none", className)}
    >
      <div className="flex items-center gap-2">
        <Glyph subject={card.subject} />
        <span className="text-[0.64rem] tracking-[0.17em] text-[var(--accent)] uppercase">
          {card.topic}
        </span>
      </div>

      <p
        key={`${card.id}-q`}
        className={cn(
          "sc-q font-semibold text-balance text-ink",
          compact ? "mt-1.5 text-[0.99rem] leading-snug" : "mt-2 text-[1.06rem] leading-snug",
        )}
      >
        {card.q}
      </p>

      <div
        className={cn(
          "relative h-px w-full overflow-hidden bg-white/10",
          compact ? "mt-2.5" : "mt-3",
        )}
      >
        <span
          className={
            revealed
              ? "absolute inset-0 bg-white/20 transition-colors duration-700"
              : "sc-think absolute inset-y-0 left-0 bg-[var(--accent)]"
          }
          style={revealed ? undefined : { animationDuration: `${autoRevealMs}ms` }}
        />
      </div>

      <div aria-live="polite">
        {revealed ? (
          <p
            key={`${card.id}-a`}
            className={cn(
              "sc-a text-muted",
              compact
                ? "mt-2.5 text-[0.875rem] leading-[1.55]"
                : "mt-3 text-[0.92rem] leading-relaxed",
            )}
          >
            {card.a}
          </p>
        ) : (
          <p className={cn("sc-hint text-[0.78rem] text-dim", compact ? "mt-2.5" : "mt-3")}>
            Tap if you have it
          </p>
        )}
      </div>
    </div>
  );
}

/* A small mark rather than the word "Wine" or "Tea": at a glance you know
 * which world the question is from without reading anything, and it keeps the
 * eyebrow line to a single piece of text. */
function Glyph({ subject }: { subject: Subject }) {
  const common = {
    width: 15,
    height: 15,
    viewBox: "0 0 16 16",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: 1.15,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
    "aria-hidden": true,
    className: "shrink-0 text-[var(--accent)] opacity-80",
  };

  if (subject === "wine") {
    return (
      <svg {...common}>
        <path d="M4.3 2.2h7.4l-.7 4.3a3.05 3.05 0 0 1-6 0z" />
        <path d="M8 9.6v3.5M5.9 13.5h4.2" />
      </svg>
    );
  }

  return (
    <svg {...common}>
      <path d="M13.2 2.6c.5 5.3-2.9 9.3-7.2 9.3-1.6 0-2.4-.9-2.4-2.2 0-3.9 4.4-7.1 9.6-7.1z" />
      <path d="M4.4 13.2c1.6-2.6 4-5 6.8-6.6" />
    </svg>
  );
}
