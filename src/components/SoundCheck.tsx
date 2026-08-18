import { useEffect, useState } from "react";
import { Card } from "@/components/Card";
import {
  audioReady,
  beep,
  supportsPlaybackSession,
  unlockAudio,
} from "@/lib/audio";

/* Sound is load-bearing here — the rest timers beep so you don't have to watch
 * the screen, and the 20s myo rest depends on it. But on iOS a web app's audio
 * can be silently blocked by the ring switch, with no indication anywhere. So
 * rather than leaving you to wonder, this says what the state actually is and
 * lets you hear it on demand. */

export function SoundCheck() {
  const [ready, setReady] = useState(false);
  const [tested, setTested] = useState(false);

  useEffect(() => {
    const t = setInterval(() => setReady(audioReady()), 500);
    return () => clearInterval(t);
  }, []);

  const canOverrideSilent = supportsPlaybackSession();

  return (
    <Card>
      <div className="flex items-baseline justify-between gap-3">
        <h2 className="text-[1.02rem] font-semibold tracking-[-0.01em] text-ink">
          Sound
        </h2>
        <span
          className={
            ready
              ? "text-[0.78rem] text-emerald"
              : "text-[0.78rem] text-muted"
          }
        >
          {ready ? "ready" : "not started"}
        </span>
      </div>

      <p className="mt-1.5 text-[0.89rem] leading-relaxed text-muted">
        Rest timers beep at zero so you don&apos;t have to watch the screen.
        {canOverrideSilent
          ? " This phone can play them with the ring switch on silent."
          : " On this phone the ring/silent switch will mute them — Web Audio is muted by the switch on iOS below 16.4, and a web app can't override it."}
      </p>

      <button
        onClick={() => {
          unlockAudio();
          beep(3);
          setTested(true);
          setTimeout(() => setReady(audioReady()), 150);
        }}
        className="mt-3 w-full rounded-[var(--radius-control)] border border-hairline bg-white/[0.055] py-3 text-[0.92rem] font-semibold text-ink"
      >
        Play the rest beep
      </button>

      {tested && !ready && (
        <p className="mt-2.5 text-[0.84rem] leading-relaxed text-rose">
          Still blocked. Check the ring/silent switch on the side of the phone,
          and that the volume isn&apos;t at zero.
        </p>
      )}
      {tested && ready && (
        <p className="mt-2.5 text-[0.84rem] text-muted">
          If you heard nothing, it&apos;s the ring/silent switch or the volume —
          the audio engine itself is running.
        </p>
      )}
    </Card>
  );
}
