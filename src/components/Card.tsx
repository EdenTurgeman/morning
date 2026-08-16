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

interface LoadoutItem {
  readonly item: string;
  readonly value: string;
  readonly indent?: boolean;
}

/* The loadout list.
 *
 * "per handle" is a detail of the line above it, not a row in its own right.
 * It used to render as an indented lowercase row WITH its own separator,
 * which cut it away from the line it belongs to — so it read as a broken row
 * rather than a sub-item. Now the detail is grouped inside its parent's row:
 * no rule between them, the value right-aligned under its parent's value, and
 * the grouping is visible rather than implied by indentation. */
export function Loadout({ items }: { items: readonly LoadoutItem[] }) {
  const groups: { main: LoadoutItem; detail?: LoadoutItem }[] = [];
  for (const item of items) {
    if (item.indent && groups.length > 0) groups[groups.length - 1].detail = item;
    else groups.push({ main: item });
  }

  return (
    <div>
      {groups.map(({ main, detail }) => (
        <div
          key={main.item}
          className="border-b border-dashed border-hairline py-2.5 last:border-b-0"
        >
          <div className="flex items-baseline justify-between gap-4">
            <span className="text-[0.92rem] text-muted">{main.item}</span>
            <span className="tnum text-[0.96rem] font-semibold whitespace-nowrap text-ink">
              {main.value}
            </span>
          </div>
          {detail && (
            <div className="mt-1 flex items-baseline justify-between gap-4">
              <span className="text-[0.76rem] text-dim">{detail.item}</span>
              <span className="tnum text-[0.76rem] whitespace-nowrap text-dim">
                {detail.value}
              </span>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
