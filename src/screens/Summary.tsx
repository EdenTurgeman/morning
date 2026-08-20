import { useMemo, useRef, useState } from "react";
import { BlurFade } from "@/components/ui/blur-fade";
import { Button } from "@/components/Button";
import { Celebration, Rays } from "@/components/Celebration";
import { WeekMeter } from "@/components/WeekMeter";
import { StudyCard } from "@/components/StudyCard";
import { celebrationFor } from "@/lib/celebration";
import { drawCard } from "@/lib/deck";
import type { Card as StudyCardData } from "@/lib/cards";
import type { AppData, SessionRecord } from "@/lib/storage";
import { plural } from "@/lib/format";
import type { View } from "@/App";

interface Props {
  record: SessionRecord;
  data: AppData;
  onNavigate: (view: View) => void;
}

export function Summary({ record, data, onNavigate }: Props) {
  const celebration = useMemo(
    () => celebrationFor(record, data.history),
    [record, data.history],
  );

  /* One last card. Drawn through a ref rather than useMemo because drawing has
   * a side effect — it marks the card seen — and a StrictMode double render
   * would quietly consume two. */
  const drawn = useRef<StudyCardData | null | undefined>(undefined);
  if (drawn.current === undefined) drawn.current = drawCard();
  const card = drawn.current;

  const [answered, setAnswered] = useState(false);
  const sets = Object.keys(record.log).length;

  /* Bands, same idea as a workout step: a hero that absorbs the slack, then
   * week / card / controls, all pinned. Only the hero gives — so Done is
   * reachable on the first frame no matter how long the celebration copy or
   * the answer runs. And when the answer does arrive, the celebration's
   * supporting sentence collapses to pay for it: by then it has done its job,
   * and the space it was holding is the difference between this screen
   * fitting and not. */
  return (
    <div className="flex h-full flex-col overflow-hidden py-3">
      <div className="relative flex min-h-0 flex-1 flex-col">
        {/* Rendered here rather than inside Celebration, deliberately: the
            sunburst is 420px tall behind a block half that size, and an
            absolutely positioned descendant still counts toward an ancestor
            scroller's overflow. Inside the scroller it made this screen
            permanently scrollable by ~130px of empty space, which in turn
            stopped it centring itself. */}
        {celebration.rays && <Rays />}

        <div
          className="flex min-h-0 flex-1 flex-col overflow-y-auto overscroll-contain"
          // `safe`, so a celebration tall enough to overflow falls back to
          // top-alignment rather than centring its overflow out of reach.
          style={{ justifyContent: "safe center" }}
        >
          <Celebration data={celebration} reps={record.reps} yielded={answered} />

          <BlurFade delay={0.45} inView>
            <p className="tnum mt-4 text-center text-[0.86rem] text-dim">
              Session {record.s} · {record.min} {plural(record.min, "minute")} ·{" "}
              {sets} {plural(sets, "set")}
            </p>
          </BlurFade>
        </div>
      </div>

      {/* Seeing the week tick over on the screen where you earned it is the
          whole point of tracking it — but it's a status line here, not a panel.
          Unboxed it costs a third of the height and stops competing with the
          number above it. Pinned, too: everything below this line is fixed, so
          the only thing that can ever scroll out of sight is the tail of the
          celebration copy, which is the one part you've already read. */}
      <BlurFade delay={0.55} inView className="shrink-0">
        <div className="rule mt-4" />
        <div className="mt-3">
          <WeekMeter week={celebration.week} onPress={() => onNavigate("history")} />
        </div>
      </BlurFade>

      {card && (
        <BlurFade delay={0.7} inView className="shrink-0">
          <div className="rule mt-3.5" />
          <StudyCard
            card={card}
            compact
            autoRevealMs={14000}
            onReveal={() => setAnswered(true)}
            className="mt-3.5"
          />
        </BlurFade>
      )}

      {/* Primary action pinned low — this screen is read standing up, phone in
          one hand, and the thumb never has to travel. */}
      <BlurFade delay={0.8} inView className="shrink-0">
        <div className="mt-3.5">
          <Button variant="primary" onClick={() => onNavigate("home")}>
            Done
          </Button>
          <button
            onClick={() => onNavigate("backup")}
            className="mt-0.5 w-full py-1.5 text-center text-[0.82rem] text-dim"
          >
            Back up now
          </button>
        </div>
      </BlurFade>
    </div>
  );
}
