import { Particles } from "@/components/ui/particles";
import { Meteors } from "@/components/ui/meteors";

/* ---------------------------------------------------------------------------
 * THE SKY
 *
 * A dawn, layered the way a real one is. Earlier versions were all smooth
 * radial gradients, which is why it read as flat — actual dawn skies have
 * structure: haze banding near the horizon, wispy cloud catching the light
 * from underneath, and rays fanning up from a sun that hasn't cleared the
 * ground yet.
 *
 * The cloud texture is fractal noise (feTurbulence) baked into a data URI and
 * used as a *mask* over a coloured layer, so the cloud takes the sky's live
 * colour instead of being painted on top of it. Baked rather than live: the
 * filter is rasterised once by the browser, and after that the layer is just
 * a bitmap being translated, which the compositor handles for free. Animating
 * turbulence parameters directly would re-run the filter every frame — far
 * too expensive for a screen held awake for twenty minutes.
 *
 * Everything here animates on transform and opacity only. Nothing triggers
 * layout, and there is no filter: blur() on any full-size layer.
 * ------------------------------------------------------------------------- */

/** Wispy horizontal cloud. Low vertical frequency stretches the noise into
 *  streaks; the colour matrix pushes most of it transparent so only the
 *  denser parts survive as cloud. */
const CLOUD =
  "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='900' height='420'%3E%3Cfilter id='c' x='0' y='0' width='100%25' height='100%25'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.006 0.021' numOctaves='5' seed='11' stitchTiles='stitch'/%3E%3CfeColorMatrix type='matrix' values='0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 1.7 0 0 0 -0.66'/%3E%3C/filter%3E%3Crect width='900' height='420' filter='url(%23c)'/%3E%3C/svg%3E\")";

/** Coarser, higher-contrast noise for the nearer cloud bank. */
const CLOUD_NEAR =
  "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='700' height='300'%3E%3Cfilter id='d' x='0' y='0' width='100%25' height='100%25'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.011 0.032' numOctaves='4' seed='29' stitchTiles='stitch'/%3E%3CfeColorMatrix type='matrix' values='0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 2.1 0 0 0 -0.95'/%3E%3C/filter%3E%3Crect width='700' height='300' filter='url(%23d)'/%3E%3C/svg%3E\")";

function CloudBand({
  texture,
  size,
  top,
  height,
  tint,
  opacity,
  animation,
}: {
  texture: string;
  size: string;
  top: string;
  height: string;
  tint: string;
  opacity: number;
  animation: string;
}) {
  return (
    <div
      className="absolute -left-1/2 w-[200%] will-change-transform"
      style={{
        top,
        height,
        opacity,
        animation,
        background: tint,
        WebkitMaskImage: texture,
        maskImage: texture,
        WebkitMaskSize: size,
        maskSize: size,
        WebkitMaskRepeat: "repeat-x",
        maskRepeat: "repeat-x",
      }}
    />
  );
}

export function Sky({ progress }: { progress: number }) {
  const t = Math.min(1, Math.max(0, progress));

  return (
    <div
      aria-hidden
      className="pointer-events-none fixed inset-0 -z-10 overflow-hidden"
      style={{
        background: "#04050a",
        /* Deliberately over-covers. lvh is the LARGEST viewport — chrome
           hidden — so the sky is never shorter than the screen even when the
           layout viewport and the visible viewport disagree. That mismatch is
           what left a strip of page background showing at the bottom, and
           since this is only a backdrop, painting past the edge costs
           nothing. */
        height: "100lvh",
        minHeight: "100%",
      }}
    >
      {/* 1. THE SKY PROPER — and the important thing here is what it does NOT
             do: it doesn't take the accent hue.

             Rayleigh scattering is wavelength-dependent, so the zenith stays
             deep blue even at the height of a sunrise; only the light coming
             through the thickest atmosphere, at the horizon, turns warm. An
             earlier version tinted the whole sky with the live accent, which
             is why it read as a coloured wash rather than as sky. The zenith
             is now fixed blue and the warmth is confined to the bottom. */}
      <div
        className="absolute inset-0"
        style={{
          background: `linear-gradient(to bottom,
            #04050c 0%,
            oklch(0.19 0.055 268) 24%,
            oklch(0.24 0.07 276) 46%,
            oklch(0.27 0.075 288) 62%,
            oklch(0.29 0.07 300) 78%,
            oklch(0.30 0.06 312) 100%)`,
        }}
      />

      {/* 2. the ozone band. Between the blue zenith and the warm horizon a
             real twilight sky carries a distinct purple-pink band — ozone
             absorption on top of Rayleigh. It's the layer most often missing
             from a painted sky, and it peaks partway through twilight rather
             than at either end, so its opacity follows a curve, not a ramp. */}
      <div
        className="absolute inset-x-0"
        style={{
          bottom: "18vh",
          height: "46vh",
          /* Peaks mid-twilight rather than at either end, so this one is a
             curve. sin() can't be expressed in calc(), so it stays in JS —
             but it shares the same duration and easing as --sun so it still
             moves in step with everything else. */
          opacity: 0.16 + Math.sin(Math.PI * Math.min(1, t * 0.86 + 0.07)) * 0.42,
          transition: "opacity 1600ms linear",
          background: `linear-gradient(to top,
            transparent 0%,
            color-mix(in oklab, oklch(0.55 0.13 344) 55%, transparent) 34%,
            color-mix(in oklab, oklch(0.5 0.11 330) 26%, transparent) 62%,
            transparent 92%)`,
        }}
      />

      {/* 3. haze. Atmosphere is denser near the ground, so the bottom of the
             sky lifts everywhere — not only where the sun is. */}
      <div
        className="sky-haze"
        style={{
          background: `linear-gradient(to top,
            color-mix(in oklab, oklch(0.62 0.05 calc(var(--accent-h) - 18)) 34%, transparent) 0%,
            color-mix(in oklab, oklch(0.6 0.045 calc(var(--accent-h) - 18)) 10%, transparent) 44%,
            transparent 82%)`,
        }}
      />

      {/* 3. stars and meteors, emptying out as the sun comes up */}
      <div className="sky-stars">
        <Particles
          className="absolute inset-0"
          quantity={46}
          staticity={70}
          ease={80}
          size={0.5}
          color="#ffffff"
        />
        {/* Unmount only once the star layer is nearly transparent anyway.
            Cutting these at t=0.5 meant they vanished mid-flight while still
            at half opacity, which read as a glitch. */}
        {t < 0.88 && (
          <div className="absolute inset-0 overflow-hidden">
            <Meteors number={7} minDelay={1.4} maxDelay={7} angle={228} />
          </div>
        )}
      </div>

      {/* 4. crepuscular rays. Feathered stops rather than hard edges — a
             repeating-conic-gradient with abrupt stops reads as a pinwheel,
             not as light. Anchored below the fold so the fan converges
             off-screen. */}
      <div
        className="sun-rays"
        style={{
          animation: "rayDrift 150s ease-in-out infinite",
          background: `repeating-conic-gradient(from 184deg at 50% 112%,
            transparent 0deg,
            color-mix(in oklab, var(--accent) 6%, transparent) 1.4deg,
            color-mix(in oklab, var(--accent) 26%, transparent) 3deg,
            color-mix(in oklab, var(--accent) 6%, transparent) 4.6deg,
            transparent 6deg,
            transparent 9.5deg)`,
          WebkitMaskImage:
            "radial-gradient(ellipse 85% 78% at 50% 112%, #000 6%, rgb(0 0 0 / 0.5) 34%, transparent 66%)",
          maskImage:
            "radial-gradient(ellipse 85% 78% at 50% 112%, #000 6%, rgb(0 0 0 / 0.5) 34%, transparent 66%)",
        }}
      />

      {/* 5. THE SUN, in three parts — which is what stops it reading flat.
             A single radial gradient has no sun in it, only a wash. */}

      {/* 5a. RAYLEIGH SPREAD — broad, saturated, and falling off with angle
              from the sun. Anchored to the bottom EDGE so its falloff runs
              off-screen rather than terminating as a visible lobe: the earlier
              version was a 190vw ellipse floating mid-screen, and its left and
              right edges swept through the frame as it rose. */}
      <div
        className="sun-spread"
        style={{
          background: `radial-gradient(ellipse 118% 92% at 50% 100%,
            color-mix(in oklab, var(--accent) 44%, transparent) 0%,
            color-mix(in oklab, var(--accent) 27%, transparent) 18%,
            color-mix(in oklab, var(--accent) 14%, transparent) 36%,
            color-mix(in oklab, var(--accent) 6%, transparent) 55%,
            color-mix(in oklab, var(--accent) 2%, transparent) 72%,
            transparent 88%)`,
        }}
      />

      {/* 5b. MIE HALO — the tight glow immediately around the sun. Mie
              scattering is essentially wavelength-independent, which is why
              this halo washes toward white-gold rather than staying the
              saturated colour of the sky. Keeping it coloured was a large part
              of why the sun read as a flat disc of accent.

              It rises and grows off --sun, like every other layer here — see
              the sun-* utilities in index.css for why that's a single shared
              custom property rather than per-layer transitions. */}
      <div
        className="sun-bloom"
        style={{
          /* closest-side, NOT the default farthest-corner: with
             farthest-corner the radius reaches 0.707× the box width, so a
             stop at 88% lands at 0.62w — still opaque when the square element
             box clips it. That clipping is what produced the hard-edged
             "halos" that appeared and vanished as the sun moved. */
          background: `radial-gradient(circle closest-side at 50% 50%,
            color-mix(in oklab, var(--accent) 30%, white) 0%,
            color-mix(in oklab, var(--accent) 62%, white) 6%,
            color-mix(in oklab, var(--accent) 78%, transparent) 13%,
            color-mix(in oklab, var(--accent) 46%, transparent) 24%,
            color-mix(in oklab, var(--accent) 22%, transparent) 38%,
            color-mix(in oklab, var(--accent) 8%, transparent) 56%,
            color-mix(in oklab, var(--accent) 2%, transparent) 74%,
            transparent 92%)`,
        }}
      />

      {/* There was a sun disc here that faded in over the last half of the
          session. It sat behind the summary's content as a hard-edged bright
          blob (the farthest-corner clipping above), and a literal sun disc
          only makes sense if the sun is actually rising — which it now does
          only on the Daybreak screen. Removed rather than patched. */}

      {/* 6. cloud. Two banks at different scales and speeds — the parallax is
             what gives the sky depth rather than looking like a backdrop. The
             near bank is lit from below, so it's tinted warmer. */}
      <CloudBand
        texture={CLOUD}
        size="900px 420px"
        top="18vh"
        height="52vh"
        opacity={0.3}
        tint={`linear-gradient(to top,
          color-mix(in oklab, var(--accent) 46%, transparent),
          color-mix(in oklab, var(--accent) 12%, transparent) 62%,
          transparent)`}
        animation="cloudFar 200s linear infinite"
      />
      <CloudBand
        texture={CLOUD_NEAR}
        size="700px 300px"
        top="46vh"
        height="38vh"
        opacity={0.26}
        tint={`linear-gradient(to top,
          color-mix(in oklab, oklch(0.8 0.13 calc(var(--accent-h) + 16)) 62%, transparent),
          color-mix(in oklab, var(--accent) 14%, transparent) 58%,
          transparent)`}
        animation="cloudNear 128s linear infinite"
      />

      {/* 7. legibility scrim. The glow gets bright enough near the bottom at
             full sunrise to swallow secondary text sitting over it — "Back up
             now" on the summary was effectively unreadable. This holds the
             sky back just enough that any text is legible at any progress,
             while leaving the colour and structure intact. */}
      <div
        className="absolute inset-0"
        style={{
          background: `linear-gradient(to bottom,
            rgb(4 5 10 / 0.15) 0%,
            rgb(4 5 10 / 0.05) 34%,
            rgb(4 5 10 / 0.22) 66%,
            rgb(4 5 10 / 0.46) 88%,
            rgb(4 5 10 / 0.6) 100%)`,
        }}
      />

      {/* 8. grain, over everything, so the gradients don't band on OLED */}
      <div className="grain" />
    </div>
  );
}
