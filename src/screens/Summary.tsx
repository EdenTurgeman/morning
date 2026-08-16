import { useMemo } from "react";
import { BlurFade } from "@/components/ui/blur-fade";
import { Button } from "@/components/Button";
import { Card } from "@/components/Card";
import { Celebration } from "@/components/Celebration";
import { WeekMeter } from "@/components/WeekMeter";
import { NUTRITION_REMINDER } from "@/program";
import { celebrationFor } from "@/lib/celebration";
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

  const sets = Object.keys(record.log).length;

  return (
    <div className="flex min-h-full flex-col py-4">
      <div className="flex flex-1 flex-col justify-center">
        <Celebration data={celebration} reps={record.reps} />

        <BlurFade delay={0.45} inView>
          <p className="tnum mt-6 text-center text-[0.86rem] text-dim">
            Session {record.s} · {record.min} {plural(record.min, "minute")} · {sets}{" "}
            {plural(sets, "set")}
          </p>
        </BlurFade>
      </div>

      <BlurFade delay={0.55} inView>
        {/* Seeing the week tick over on the screen where you earned it is the
            whole point of tracking it. */}
        <Card className="mt-6 py-4">
          <WeekMeter week={celebration.week} onPress={() => onNavigate("history")} />
        </Card>

        <Card className="mt-3">
          <p className="text-[0.87rem] leading-relaxed text-muted">
            {NUTRITION_REMINDER}
          </p>
        </Card>
      </BlurFade>

      {/* Primary action pinned low — this screen is read standing up, phone in
          one hand, and the thumb never has to travel. */}
      <BlurFade delay={0.65} inView>
        <div className="mt-7">
          <Button variant="primary" onClick={() => onNavigate("home")}>
            Done
          </Button>
          <button
            onClick={() => onNavigate("backup")}
            className="mt-2 w-full py-3 text-center text-[0.88rem] text-dim"
          >
            Back up now
          </button>
        </div>
      </BlurFade>
    </div>
  );
}
