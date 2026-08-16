import { INTENSITY_WORDS } from "@/program";
import { cn } from "@/lib/utils";

/* Form cues. The ones containing "failure", "PAUSE", "FULL" or "mechanism"
 * carry the training effect, so they're pulled forward — brighter ink, heavier
 * weight, a filled marker. Deliberately *not* a separate colour: the accent is
 * already doing a job, and a second hue at 6am is noise. */

export function Cues({ cues }: { cues: readonly string[] }) {
  return (
    <ul className="my-5 space-y-2.5">
      {cues.map((cue) => {
        const key = INTENSITY_WORDS.test(cue);
        return (
          <li
            key={cue}
            className={cn(
              "relative pl-5 text-[1rem] leading-snug",
              key ? "font-medium text-ink" : "text-muted",
            )}
          >
            <span
              aria-hidden
              className={cn(
                "absolute top-[0.55em] left-0 h-[6px] w-[6px] rounded-full",
                key
                  ? "bg-[var(--accent)] shadow-[0_0_8px_var(--accent-glow)]"
                  : "bg-white/40",
              )}
            />
            {cue}
          </li>
        );
      })}
    </ul>
  );
}
