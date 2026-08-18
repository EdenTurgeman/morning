import { BlurFade } from "@/components/ui/blur-fade";
import { Card } from "@/components/Card";
import { ScreenHeader } from "@/components/ScreenHeader";
import { GUIDE } from "@/program";
import type { View } from "@/App";

/* Read maybe monthly, never during a session — so this is the one screen
 * allowed to be a scrollable list of prose. */

export function Guide({ onNavigate }: { onNavigate: (view: View) => void }) {
  return (
    <div>
      <ScreenHeader title="Guide" onNavigate={onNavigate} />

      <div className="space-y-3">
        {GUIDE.map((entry, i) => (
          <BlurFade key={entry.heading} delay={0.03 + i * 0.035} inView>
            <Card>
              <h2 className="text-[1.02rem] font-semibold tracking-[-0.01em] text-ink">
                {entry.heading}
              </h2>
              <p className="mt-1.5 text-[0.89rem] leading-relaxed text-muted">
                {entry.body}
              </p>
            </Card>
          </BlurFade>
        ))}
      </div>

      <p className="mt-6 text-center text-[0.76rem] text-dim">
        Full detail, sources and the equipment ranking are in the PDF.
      </p>
    </div>
  );
}
