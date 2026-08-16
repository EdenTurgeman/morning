import confetti from "canvas-confetti";
import { oklchToHex, sunriseAt } from "@/lib/sunrise";

/* A confetti burst in the app's own palette rather than the library's default
 * rainbow — sampled straight off the sunrise ramp, so the celebration looks
 * like it belongs to the app instead of being bolted on.
 *
 * Reserved for completing a week and hitting a streak milestone. If it fires
 * every session it stops meaning anything. */

const hexAt = (t: number) => oklchToHex(sunriseAt(t));

export function celebrate(intensity: "burst" | "milestone" = "burst"): void {
  const reduced = window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches;
  if (reduced) return;

  // Warm end of the ramp — this fires on the summary screen, which is full
  // sunrise.
  const colors = [hexAt(0.72), hexAt(0.86), hexAt(1), "#ffffff"];

  const shoot = (opts: confetti.Options) =>
    void confetti({
      disableForReducedMotion: true,
      colors,
      scalar: 0.9,
      ticks: 220,
      gravity: 0.9,
      ...opts,
    });

  // Two angled jets from the lower corners, so it reads as light rising rather
  // than something falling on you.
  shoot({ particleCount: 34, spread: 55, angle: 62, origin: { x: 0.08, y: 0.85 } });
  shoot({ particleCount: 34, spread: 55, angle: 118, origin: { x: 0.92, y: 0.85 } });

  if (intensity === "milestone") {
    setTimeout(
      () =>
        shoot({
          particleCount: 70,
          spread: 110,
          startVelocity: 38,
          origin: { x: 0.5, y: 0.72 },
        }),
      220,
    );
    setTimeout(
      () =>
        shoot({
          particleCount: 40,
          spread: 140,
          startVelocity: 26,
          decay: 0.92,
          origin: { x: 0.5, y: 0.68 },
        }),
      520,
    );
  }
}
