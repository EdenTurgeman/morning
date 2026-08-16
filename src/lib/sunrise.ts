/* ---------------------------------------------------------------------------
 * The accent colour is a function of one number: how far through the session
 * you are. It walks the hue wheel from pre-dawn indigo to sunrise amber, and
 * every tinted surface in the app reads the same three CSS variables, so this
 * is the only place the app's colour is decided.
 *
 *   t = 0.0  →  252°  indigo    pre-dawn
 *   t = 0.5  →  322°  magenta   first light
 *   t = 1.0  →   32°  amber     sunrise
 *
 * The hue ramp is linear (252 + t·140, wrapped) which is what makes the two
 * intermediate stops fall out for free.
 * ------------------------------------------------------------------------- */

export interface Hsl {
  h: number;
  s: number;
  l: number;
}

export function sunriseAt(t: number): Hsl {
  const p = Math.min(1, Math.max(0, t));
  return {
    h: (252 + p * 140) % 360,
    s: 83 + p * 12,
    l: 68 - p * 6,
  };
}

export function hsl({ h, s, l }: Hsl, alpha = 1): string {
  const base = `${h.toFixed(1)} ${s.toFixed(1)}% ${l.toFixed(1)}%`;
  return alpha === 1 ? `hsl(${base})` : `hsl(${base} / ${alpha})`;
}

/** Writes the live accent onto :root. Because the three properties are
 *  registered with @property in index.css, the browser interpolates them —
 *  the whole app drifts to the new hue over ~900ms instead of snapping. */
export function applySunrise(t: number): void {
  const { h, s, l } = sunriseAt(t);
  const root = document.documentElement.style;
  root.setProperty("--accent-h", h.toFixed(1));
  root.setProperty("--accent-s", `${s.toFixed(1)}%`);
  root.setProperty("--accent-l", `${l.toFixed(1)}%`);
}

/** Progress value used outside a workout. Home/History/Guide sit just before
 *  dawn; the Summary screen is full sunrise, since you've finished. */
export const IDLE_PROGRESS = 0.08;
export const DONE_PROGRESS = 1;
