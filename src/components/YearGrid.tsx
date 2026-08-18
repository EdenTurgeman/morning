import { useMemo } from "react";
import { localISODate, type SessionRecord } from "@/lib/storage";
import { startOfWeek } from "@/lib/week";
import { oklchString, sunriseAt } from "@/lib/sunrise";
import { formatDate } from "@/lib/format";

/* ---------------------------------------------------------------------------
 * A year of mornings as one picture.
 *
 * Each cell is a day. A day you trained is painted from the sunrise ramp, with
 * position on the ramp set by how hard that session was relative to your own
 * range — your quietest is pre-dawn indigo, your best is full gold. Scaled to
 * you rather than to an arbitrary target, so a good month literally looks
 * warmer than a bad one.
 *
 * The grid is FLUID, not scrollable. A fixed-cell version was wider than a
 * phone, which put the recent weeks off the right edge — you had to scroll to
 * find today, and the whole point of showing a year is seeing it at once.
 * Columns are fractions of the container, so the year always fits whatever
 * it's given. Cells end up around 5px on a phone, which is what these charts
 * look like at this density anyway.
 * ------------------------------------------------------------------------- */

const WEEKS = 53;

interface Cell {
  date: string;
  reps: number;
  count: number;
  future: boolean;
}

export function YearGrid({ history }: { history: readonly SessionRecord[] }) {
  const { cells, min, max, months } = useMemo(() => {
    const byDate = new Map<string, { reps: number; count: number }>();
    for (const h of history) {
      const cur = byDate.get(h.d) ?? { reps: 0, count: 0 };
      byDate.set(h.d, { reps: cur.reps + h.reps, count: cur.count + 1 });
    }

    const today = new Date();
    // Start on a week boundary so every column is a whole week.
    const first = startOfWeek(today);
    first.setDate(first.getDate() - (WEEKS - 1) * 7);

    // Week-major order: with 7 grid rows and column flow, this fills the grid
    // one week per column, oldest on the left.
    const cells: Cell[] = [];
    const months: { col: number; label: string }[] = [];
    let lastMonth = -1;

    for (let w = 0; w < WEEKS; w++) {
      for (let d = 0; d < 7; d++) {
        const day = new Date(first);
        day.setDate(first.getDate() + w * 7 + d);
        const iso = localISODate(day);
        const hit = byDate.get(iso);
        cells.push({
          date: iso,
          reps: hit?.reps ?? 0,
          count: hit?.count ?? 0,
          future: day > today,
        });

        if (d === 0 && day.getMonth() !== lastMonth && day.getDate() <= 7) {
          lastMonth = day.getMonth();
          months.push({
            col: w + 1,
            label: day.toLocaleDateString(undefined, { month: "short" }),
          });
        }
      }
    }

    const reps = history.map((h) => h.reps).filter((r) => r > 0);
    return {
      cells,
      months,
      min: reps.length ? Math.min(...reps) : 0,
      max: reps.length ? Math.max(...reps) : 1,
    };
  }, [history]);

  const colourFor = (cell: Cell): string => {
    if (cell.count === 0) return "rgb(255 255 255 / 0.05)";
    const span = max - min;
    const t = span > 0 ? (cell.reps - min) / span : 1;
    return oklchString(sunriseAt(0.18 + t * 0.82));
  };

  const columns = { gridTemplateColumns: `repeat(${WEEKS}, minmax(0, 1fr))` };

  return (
    <div>
      {/* Every other month, so the labels don't collide at this density. */}
      <div className="mb-1 grid gap-[1px]" style={columns}>
        {months
          .filter((_, i) => i % 2 === 0)
          .map((m) => (
            <span
              key={m.col}
              className="overflow-visible text-[0.52rem] whitespace-nowrap text-dim"
              style={{ gridColumn: `${m.col} / span 4` }}
            >
              {m.label}
            </span>
          ))}
      </div>

      <div
        className="grid grid-flow-col gap-[1px]"
        style={{ ...columns, gridTemplateRows: "repeat(7, minmax(0, 1fr))" }}
      >
        {cells.map((cell) => (
          <span
            key={cell.date}
            title={
              cell.count
                ? `${formatDate(cell.date)} — ${cell.reps} reps`
                : formatDate(cell.date)
            }
            className="aspect-square rounded-[1px]"
            style={{
              background: cell.future ? "transparent" : colourFor(cell),
              boxShadow:
                cell.count > 1 ? "0 0 0 1px rgb(255 255 255 / 0.35) inset" : undefined,
            }}
          />
        ))}
      </div>

      <div className="mt-2.5 flex items-center gap-1.5 text-[0.62rem] text-dim">
        <span>quieter</span>
        {[0.18, 0.38, 0.58, 0.78, 1].map((t) => (
          <span
            key={t}
            className="block h-[8px] w-[8px] rounded-[2px]"
            style={{ background: oklchString(sunriseAt(t)) }}
          />
        ))}
        <span>your best</span>
      </div>
    </div>
  );
}
