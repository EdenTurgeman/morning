import { Particles } from "@/components/ui/particles";

/* ---------------------------------------------------------------------------
 * The backdrop. Literally a sunrise: a sun below the horizon that rises and
 * warms as the session progresses, two drifting cloud masses above it, dust in
 * the air, and a film grain over everything to stop the big soft gradients
 * banding on an OLED screen.
 *
 * Everything here derives from --accent-*, which the app updates as you move
 * through the workout, so the whole sky warms with the accent. Fixed position
 * and transform-only animation, so it never triggers layout during a set.
 * ------------------------------------------------------------------------- */

export function Sky({ progress }: { progress: number }) {
  // The sun climbs from well below the fold to just under the horizon line.
  const sunLift = 6 + progress * 22;
  const sunSpread = 46 + progress * 26;

  return (
    <div
      aria-hidden
      className="pointer-events-none fixed inset-0 -z-10 overflow-hidden"
    >
      {/* deep night base */}
      <div className="absolute inset-0 bg-night" />

      {/* the sun, below the horizon, rising with progress */}
      <div
        className="absolute left-1/2 w-[190vw] -translate-x-1/2 rounded-[50%] blur-[70px] transition-all duration-[1200ms] ease-[var(--ease-out-expo)]"
        style={{
          bottom: `${-34 + sunLift}vh`,
          height: `${sunSpread}vh`,
          background: `radial-gradient(ellipse at 50% 100%,
            hsl(var(--accent-h) var(--accent-s) var(--accent-l) / 0.55) 0%,
            hsl(var(--accent-h) var(--accent-s) var(--accent-l) / 0.20) 42%,
            transparent 72%)`,
        }}
      />

      {/* cloud masses, drifting on very long loops */}
      <div
        className="absolute -top-[18vh] -left-[22vw] h-[62vh] w-[86vw] rounded-full blur-[80px] [animation:drift_46s_ease-in-out_infinite]"
        style={{
          background: `radial-gradient(circle at 40% 40%,
            hsl(var(--accent-h) 70% 60% / 0.16), transparent 68%)`,
        }}
      />
      <div
        className="absolute top-[22vh] -right-[26vw] h-[54vh] w-[78vw] rounded-full blur-[90px] [animation:drift-slow_61s_ease-in-out_infinite]"
        style={{
          background: `radial-gradient(circle at 60% 50%,
            hsl(calc(var(--accent-h) + 34) 72% 62% / 0.13), transparent 70%)`,
        }}
      />

      {/* dust in the air */}
      <Particles
        className="absolute inset-0"
        quantity={38}
        staticity={62}
        ease={70}
        size={0.5}
        color="#ffffff"
      />

      {/* horizon line — a single hairline that catches the accent */}
      <div
        className="absolute right-0 left-0 h-px opacity-40 transition-all duration-[1200ms]"
        style={{
          bottom: `${sunLift - 3}vh`,
          background: `linear-gradient(90deg, transparent,
            hsl(var(--accent-h) var(--accent-s) var(--accent-l) / 0.5) 30%,
            hsl(var(--accent-h) var(--accent-s) var(--accent-l) / 0.5) 70%,
            transparent)`,
        }}
      />

      <div className="grain" />
    </div>
  );
}
