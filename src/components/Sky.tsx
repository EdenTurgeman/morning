import { Particles } from "@/components/ui/particles";

/* ---------------------------------------------------------------------------
 * The backdrop is a dawn, layered the way a real one is:
 *
 *   1. a vertical sky gradient — near-black at the zenith, warming toward the
 *      horizon, tinted by the live accent so the whole screen shares one
 *      light source
 *   2. stars, which fade out as the sun comes up
 *   3. the belt of Venus — the soft counter-coloured band that sits above the
 *      horizon before sunrise. It's the detail that makes a dawn read as a
 *      dawn rather than as a gradient
 *   4. the sun itself, climbing as the session progresses
 *   5. two slow cloud masses
 *   6. film grain, which stops the large soft gradients banding on OLED
 *
 * Everything is a radial or linear gradient with its own falloff — there is
 * deliberately no `filter: blur()` on any of the large elements. Blurring a
 * viewport-sized layer every frame is expensive, and this screen is held
 * awake for twenty minutes on a phone. Gradients are effectively free.
 *
 * Motion is transform and opacity only, so nothing here triggers layout.
 * ------------------------------------------------------------------------- */

export function Sky({ progress }: { progress: number }) {
  const t = Math.min(1, Math.max(0, progress));

  return (
    <div
      aria-hidden
      className="pointer-events-none fixed inset-0 -z-10 overflow-hidden"
      style={{ background: "#04050a" }}
    >
      {/* 1. the sky */}
      <div
        className="absolute inset-0 transition-[opacity] duration-1000"
        style={{
          background: `linear-gradient(to bottom,
            #04050a 0%,
            color-mix(in oklab, var(--night-tinted) 55%, #04050a) 38%,
            color-mix(in oklab, var(--accent) 9%, #05060c) 66%,
            color-mix(in oklab, var(--accent) 20%, #06070e) 86%,
            color-mix(in oklab, var(--accent) 34%, #07080f) 100%)`,
        }}
      />

      {/* 2. stars, fading as the sun rises */}
      <div
        className="absolute inset-0 transition-opacity duration-[1400ms] ease-out"
        style={{ opacity: 0.9 * (1 - t) + 0.05 }}
      >
        <Particles
          className="absolute inset-0"
          quantity={46}
          staticity={70}
          ease={80}
          size={0.5}
          color="#ffffff"
        />
      </div>

      {/* 3. belt of Venus — the counter-hue band that precedes sunrise */}
      <div
        className="absolute right-0 -left-[10%] w-[120%] transition-all duration-[1400ms] ease-out"
        style={{
          bottom: "18%",
          height: "34vh",
          opacity: 0.5 * Math.sin(Math.PI * Math.min(1, t * 0.9 + 0.05)),
          background: `linear-gradient(to top,
            transparent,
            color-mix(in oklab, oklch(0.72 0.11 calc(var(--accent-h) + 34)) 40%, transparent) 45%,
            transparent)`,
        }}
      />

      {/* 4. the sun. Translated rather than repositioned, so it never lays out. */}
      <div
        className="absolute bottom-0 left-1/2 h-[78vh] w-[190vw] rounded-[50%] will-change-transform"
        style={{
          transform: `translate(-50%, ${46 - t * 30}%)`,
          opacity: 0.5 + t * 0.42,
          transition:
            "transform 1400ms var(--ease-out-expo), opacity 1400ms ease-out",
          background: `radial-gradient(ellipse at 50% 50%,
            var(--accent) 0%,
            color-mix(in oklab, var(--accent) 52%, transparent) 26%,
            color-mix(in oklab, var(--accent) 18%, transparent) 46%,
            transparent 68%)`,
        }}
      />

      {/* the horizon itself — a hairline of concentrated light */}
      <div
        className="absolute right-0 left-0 h-px transition-all duration-[1400ms] ease-out"
        style={{
          bottom: `${13 + t * 15}%`,
          opacity: 0.25 + t * 0.45,
          background: `linear-gradient(90deg, transparent,
            var(--accent) 26%, var(--accent) 74%, transparent)`,
        }}
      />

      {/* 5. cloud masses */}
      <div
        className="absolute -top-[16vh] -left-[24vw] h-[68vh] w-[92vw] [animation:drift_52s_ease-in-out_infinite]"
        style={{
          background: `radial-gradient(closest-side ellipse at 45% 45%,
            color-mix(in oklab, var(--accent) 15%, transparent), transparent 72%)`,
        }}
      />
      <div
        className="absolute top-[26vh] -right-[28vw] h-[56vh] w-[84vw] [animation:drift-slow_67s_ease-in-out_infinite]"
        style={{
          background: `radial-gradient(closest-side ellipse at 55% 50%,
            color-mix(in oklab, oklch(0.7 0.13 calc(var(--accent-h) + 26)) 13%, transparent),
            transparent 74%)`,
        }}
      />

      {/* 6. grain */}
      <div className="grain" />
    </div>
  );
}
