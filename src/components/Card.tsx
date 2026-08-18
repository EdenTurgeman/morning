import type { ReactNode } from "react";
import { cn } from "@/lib/utils";
import { BorderBeam } from "@/components/ui/border-beam";

interface Props {
  children: ReactNode;
  className?: string;
  /** Traces a light beam around the border. Used on the one card that is the
   *  answer to "what am I doing right now". */
  beam?: boolean;
}

export function Card({ children, className, beam = false }: Props) {
  return (
    <div
      className={cn(
        "surface relative overflow-hidden rounded-[var(--radius-card)] p-5",
        className,
      )}
    >
      {children}
      {beam && (
        <BorderBeam
          size={110}
          duration={7}
          borderWidth={1.4}
          colorFrom="hsl(var(--accent-h) var(--accent-s) var(--accent-l) / 0)"
          colorTo="hsl(var(--accent-h) var(--accent-s) calc(var(--accent-l) + 12%))"
        />
      )}
    </div>
  );
}

/** Label / value row inside a card, hairline-separated. */
export function Row({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="flex items-baseline justify-between gap-4 border-b border-dashed border-hairline py-2.5 last:border-b-0">
      <span className="text-[0.92rem] text-muted">{label}</span>
      <span className="tnum text-[0.96rem] font-semibold whitespace-nowrap text-ink">
        {value}
      </span>
    </div>
  );
}
