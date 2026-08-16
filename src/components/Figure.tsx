import { cn } from "@/lib/utils";

/* ---------------------------------------------------------------------------
 * EXERCISE FIGURES
 *
 * Original artwork, drawn as SVG rather than sourced. Two reasons: the app has
 * a hard no-runtime-network rule, and anything fetched from a stock library is
 * someone else's copyright. Drawing them also buys something a photo can't —
 * these move at the tempo the cues prescribe, so "3s down · 1s PAUSE · fast
 * up" is shown rather than described.
 *
 * Construction: a side-on figure whose limbs are `<g>` elements rotated about
 * their joint. Animating a rotation is what makes it read as a movement
 * instead of a crossfade between two poses. Everything is CSS keyframes on
 * transform, so it runs on the compositor and costs nothing during a set.
 *
 * Each exercise supplies its own keyframe name; the shared skeleton is the
 * same. Stroke uses the live accent, so the figures belong to the sunrise.
 * ------------------------------------------------------------------------- */

import { FIGURE_LABELS, type FigureKind } from "@/lib/figures";

export { figureFor } from "@/lib/figures";
export type { FigureKind } from "@/lib/figures";

const STROKE = "var(--accent)";
const BODY = "rgb(255 255 255 / 0.55)";

interface Props {
  kind: FigureKind;
  className?: string;
  /** Pause the animation — used when the set screen isn't the active step. */
  still?: boolean;
}

export function Figure({ kind, className, still = false }: Props) {
  return (
    <svg
      viewBox="0 0 200 130"
      className={cn("h-full w-full", className)}
      role="img"
      aria-label={FIGURE_LABELS[kind]}
      style={still ? { animationPlayState: "paused" } : undefined}
    >
      <defs>
        <linearGradient id="floor" x1="0" x2="1" y1="0" y2="0">
          <stop offset="0%" stopColor="transparent" />
          <stop offset="30%" stopColor="rgb(255 255 255 / 0.16)" />
          <stop offset="70%" stopColor="rgb(255 255 255 / 0.16)" />
          <stop offset="100%" stopColor="transparent" />
        </linearGradient>
      </defs>
      <g
        fill="none"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={4.5}
      >
        {RENDER[kind]()}
      </g>
    </svg>
  );
}

/* --- the drawings ---------------------------------------------------------
 * Coordinates are hand-placed rather than computed; a figure is a small
 * enough thing that being able to read the numbers matters more than being
 * able to parameterise them. */

const floor = (y = 112) => (
  <line x1="14" y1={y} x2="186" y2={y} stroke="url(#floor)" strokeWidth={3} />
);

const RENDER: Record<FigureKind, () => React.ReactNode> = {
  /* Deficit push-up: hands raised on blocks, chest sinking between them. */
  pushup: () => (
    <>
      {floor()}
      {/* blocks under the hands */}
      <rect x="140" y="96" width="20" height="16" rx="3" stroke={BODY} opacity={0.5} />
      <g className="fig-pushup" style={{ transformOrigin: "150px 100px" }}>
        {/* back line: heels → hips → shoulders → head */}
        <path d="M34 92 L86 84 L134 76" stroke={BODY} />
        <circle cx="146" cy="72" r="8" stroke={STROKE} />
        {/* arm: shoulder → elbow → hand on the block */}
        <path d="M134 76 L142 90 L150 98" stroke={STROKE} />
        {/* trailing leg */}
        <path d="M34 92 L28 104" stroke={BODY} />
      </g>
    </>
  ),

  /* Standing strict press: forearm rotates from ear height to lockout. */
  "overhead-press": () => (
    <>
      {floor()}
      <path d="M100 112 L100 62" stroke={BODY} />
      <circle cx="100" cy="50" r="9" stroke={STROKE} />
      <path d="M100 112 L88 112 M100 112 L112 112" stroke={BODY} />
      {/* both arms rotate about the shoulder */}
      <g className="fig-press" style={{ transformOrigin: "100px 66px" }}>
        <path d="M100 66 L78 56 L80 34" stroke={STROKE} />
        <path d="M100 66 L122 56 L120 34" stroke={STROKE} />
        <rect x="68" y="26" width="24" height="8" rx="4" stroke={STROKE} />
        <rect x="108" y="26" width="24" height="8" rx="4" stroke={STROKE} />
      </g>
    </>
  ),

  /* Curl: forearm swings up from full extension. */
  curl: () => (
    <>
      {floor()}
      <path d="M100 112 L100 56" stroke={BODY} />
      <circle cx="100" cy="44" r="9" stroke={STROKE} />
      <path d="M100 112 L88 112 M100 112 L112 112" stroke={BODY} />
      {/* upper arm stays pinned; forearm rotates about the elbow */}
      <path d="M100 62 L92 88" stroke={BODY} />
      <g className="fig-curl" style={{ transformOrigin: "92px 88px" }}>
        <path d="M92 88 L96 112" stroke={STROKE} />
        <rect x="84" y="108" width="24" height="8" rx="4" stroke={STROKE} />
      </g>
    </>
  ),

  /* Hammer curl: same movement, neutral grip drawn end-on. */
  "hammer-curl": () => (
    <>
      {floor()}
      <path d="M100 112 L100 56" stroke={BODY} />
      <circle cx="100" cy="44" r="9" stroke={STROKE} />
      <path d="M100 112 L88 112 M100 112 L112 112" stroke={BODY} />
      <path d="M100 62 L92 88" stroke={BODY} />
      <g className="fig-curl" style={{ transformOrigin: "92px 88px" }}>
        <path d="M92 88 L96 112" stroke={STROKE} />
        {/* neutral grip: dumbbell drawn along the forearm, not across it */}
        <rect x="90" y="100" width="8" height="24" rx="4" stroke={STROKE} />
      </g>
    </>
  ),

  /* Bent-over row: torso hinged, arms pull to the hips. */
  row: () => (
    <>
      {floor()}
      {/* hinged torso */}
      <path d="M118 108 L112 74 L74 62" stroke={BODY} />
      <circle cx="62" cy="59" r="8" stroke={STROKE} />
      <path d="M118 108 L112 112 M118 108 L128 112" stroke={BODY} />
      <g className="fig-row" style={{ transformOrigin: "80px 64px" }}>
        <path d="M80 64 L84 90" stroke={STROKE} />
        <rect x="72" y="86" width="24" height="8" rx="4" stroke={STROKE} />
      </g>
    </>
  ),

  /* Lateral raise: arms sweep out to shoulder height, elbows leading. */
  "lateral-raise": () => (
    <>
      {floor()}
      <path d="M100 112 L100 58" stroke={BODY} />
      <circle cx="100" cy="46" r="9" stroke={STROKE} />
      <path d="M100 112 L88 112 M100 112 L112 112" stroke={BODY} />
      <g className="fig-lateral-l" style={{ transformOrigin: "100px 64px" }}>
        <path d="M100 64 L74 74" stroke={STROKE} />
        <rect x="62" y="70" width="20" height="8" rx="4" stroke={STROKE} />
      </g>
      <g className="fig-lateral-r" style={{ transformOrigin: "100px 64px" }}>
        <path d="M100 64 L126 74" stroke={STROKE} />
        <rect x="118" y="70" width="20" height="8" rx="4" stroke={STROKE} />
      </g>
    </>
  ),

  /* Rear-delt fly: hinged near-parallel, arms open like a curtain. */
  "rear-delt-fly": () => (
    <>
      {floor()}
      <path d="M126 108 L120 76 L72 68" stroke={BODY} />
      <circle cx="60" cy="66" r="8" stroke={STROKE} />
      <path d="M126 108 L120 112 M126 108 L136 112" stroke={BODY} />
      <g className="fig-fly-l" style={{ transformOrigin: "84px 70px" }}>
        <path d="M84 70 L70 94" stroke={STROKE} />
        <rect x="58" y="90" width="20" height="8" rx="4" stroke={STROKE} />
      </g>
      <g className="fig-fly-r" style={{ transformOrigin: "84px 70px" }}>
        <path d="M84 70 L100 94" stroke={STROKE} />
        <rect x="94" y="90" width="20" height="8" rx="4" stroke={STROKE} />
      </g>
    </>
  ),

  /* Warm-up: a full arm circle. */
  warmup: () => (
    <>
      {floor()}
      <path d="M100 112 L100 58" stroke={BODY} />
      <circle cx="100" cy="46" r="9" stroke={STROKE} />
      <path d="M100 112 L88 112 M100 112 L112 112" stroke={BODY} />
      <circle
        cx="100"
        cy="64"
        r="30"
        stroke={STROKE}
        opacity={0.22}
        strokeDasharray="4 7"
      />
      <g className="fig-warmup" style={{ transformOrigin: "100px 64px" }}>
        <path d="M100 64 L100 34" stroke={STROKE} />
        <circle cx="100" cy="32" r="4.5" stroke={STROKE} fill={STROKE} />
      </g>
    </>
  ),
};
