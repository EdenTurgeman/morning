import { useMemo } from "react";
import { WEEK_STARTS_ON } from "@/program";
import { localISODate, type SessionRecord } from "@/lib/storage";
import { startOfWeek } from "@/lib/week";
import { oklchString, sunriseAt } from "@/lib/sunrise";
import { formatDate } from "@/lib/format";

/* ---------------------------------------------------------------------------
 * A year of mornings as one picture.
 *
 * Each cell is a day. A day you trained is painted from the sunrise ramp, with
 * position on the ramp set by how hard that session was relative to your own
 * range — your quietest session is pre-dawn indigo, your best is full gold. So
 * the grid is scaled to you, not to an arbitrary target, and a good month
 * literally looks warmer than a bad one.
 * ------------------------------------------------------------------------- */

const DAY_LABELS = ["S", "M", "T", "W", "T", "F", "S"];
const WEEKS = 53;

interface Cell {
  date: string;
  reps: number;
  count: number;
  future: boolean;
}

export function YearGrid({ history }: { history: readonly SessionRecord[] }) {
  const { columns, min, max, monthMarks } = useMemo(() => {
    const byDate = new Map<string, { reps: number; count: number }>();
    for (const h of history) {
      const cur = byDate.get(h.d) ?? { reps: 0, count: 0 };
      byDate.set(h.d, { reps: cur.reps + h.reps, count: cur.count + 1 });
    }

    const today = new Date();
    // Start on the week boundary 52 weeks back, so columns are whole weeks.
    const first = startOfWeek(today);
    first.setDate(first.getDate() - (WEEKS - 1) * 7);

    const columns: Cell[][] = [];
    const monthMarks: { col: number; label: string }[] = [];
    let lastMonth = -1;

    for (let w = 0; w < WEEKS; w++) {
      const col: Cell[] = [];
      for (let d = 0; d < 7; d++) {
        const day = new Date(first);
        day.setDate(first.getDate() + w * 7 + d);
        const iso = localISODate(day);
        const hit = byDate.get(iso);
        col.push({
          date: iso,
          reps: hit?.reps ?? 0,
          count: hit?.count ?? 0,
          future: day > today,
        });

        if (d === 0 && day.getMonth() !== lastMonth && day.getDate() <= 7) {
          lastMonth = day.getMonth();
          monthMarks.push({
            col: w,
            label: day.toLocaleDateString(undefined, { month: "short" }),
          });
        }
      }
      columns.push(col);
    }

    const reps = history.map((h) => h.reps).filter((r) => r > 0);
    return {
      columns,
      monthMarks,
      min: reps.length ? Math.min(...reps) : 0,
      max: reps.length ? Math.max(...reps) : 1,
    };
  }, [history]);

  const colourFor = (cell: Cell): string => {
    if (cell.count === 0) return "rgb(255 255 255 / 0.05)";
    // Scale to this user's own range; a flat history still gets full sunrise.
    const span = max - min;
    const t = span > 0 ? (cell.reps - min) / span : 1;
    return oklchString(sunriseAt(0.18 + t * 0.82));
  };

  return (
    <div className="overflow-x-auto pb-1">
      <div className="min-w-max">
        <div className="mb-1.5 flex gap-[3px] pl-[14px]">
          {columns.map((_, i) => {
            const mark = monthMarks.find((m) => m.col === i);
            return (
              <span
                key={i}
                className="w-[9px] shrink-0 text-[0.56rem] tracking-wide text-dim"
              >
                {mark ? mark.label.slice(0, 1) : ""}
              </span>
            );
          })}
        </div>

        <div className="flex gap-[3px]">
          <div className="flex w-[11px] shrink-0 flex-col gap-[3px]">
            {DAY_LABELS.map((_, i) => (
              <span
                key={i}
                className="h-[9px] text-[0.52rem] leading-[9px] text-dim"
              >
                {/* every other row, so the column stays readable at 9px */}
                {i % 2 === 1 ? DAY_LABELS[(i + WEEK_STARTS_ON) % 7] : ""}
              </span>
            ))}
          </div>

          {columns.map((col, w) => (
            <div key={w} className="flex flex-col gap-[3px]">
              {col.map((cell) => (
                <span
                  key={cell.date}
                  title={
                    cell.count
                      ? `${formatDate(cell.date)} — ${cell.reps} reps`
                      : formatDate(cell.date)
                  }
                  className="block h-[9px] w-[9px] shrink-0 rounded-[2px]"
                  style={{
                    background: cell.future ? "transparent" : colourFor(cell),
                    boxShadow:
                      cell.count > 1
                        ? "0 0 0 1px rgb(255 255 255 / 0.35) inset"
                        : undefined,
                  }}
                />
              ))}
            </div>
          ))}
        </div>

        <div className="mt-3 flex items-center gap-2 pl-[14px] text-[0.6rem] text-dim">
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
    </div>
  );
}
