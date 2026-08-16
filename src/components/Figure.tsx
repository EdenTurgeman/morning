import { FIGURE_LABELS, type FigureKind } from "@/lib/figures";
import { cn } from "@/lib/utils";

export { figureFor } from "@/lib/figures";
export type { FigureKind } from "@/lib/figures";

/* ---------------------------------------------------------------------------
 * EXERCISE FIGURES
 *
 * Original artwork. Drawn rather than sourced: the app has a hard
 * no-runtime-network rule, and stock fitness art is someone else's copyright.
 *
 * These are skeletons posed at each phase of the movement, interpolated with
 * SVG <animate>. That's deliberate — an earlier version rotated whole limb
 * groups with CSS transforms, which meant the push-up's entire body slid down
 * as one rigid piece. It didn't articulate, so it didn't read as a push-up.
 *
 * Posing directly fixes that: the hand stays pinned on the block, the elbow
 * folds backward, the body pivots about the toes, and the head travels with
 * the shoulders. Every joint is where I put it at every phase, rather than
 * wherever a rotation happened to throw it.
 *
 * The keyTimes encode the prescribed tempo, so the drawing teaches it: the
 * push-up spends 3s lowering, holds 1s at the bottom, then snaps up.
 * ------------------------------------------------------------------------- */

const ACCENT = "var(--accent)";
const BODY = "rgb(255 255 255 / 0.5)";
const JOINT = "rgb(255 255 255 / 0.28)";

type Pt = readonly [number, number];
const pts = (p: readonly Pt[]) => p.map(([x, y]) => `${x},${y}`).join(" ");

/** ease-in-out, for a limb decelerating into position. */
const EASE = "0.42 0 0.58 1";
const LINEAR = "0 0 1 1";

interface BoneProps {
  poses: readonly (readonly Pt[])[];
  keyTimes: readonly number[];
  dur: string;
  splines?: readonly string[];
  stroke?: string;
  width?: number;
  still?: boolean;
}

/** A limb or body segment, interpolated between explicit poses. */
function Bone({
  poses,
  keyTimes,
  dur,
  splines,
  stroke = ACCENT,
  width = 4.5,
  still,
}: BoneProps) {
  const spline = splines ?? Array.from({ length: poses.length - 1 }, () => EASE);
  return (
    <polyline
      points={pts(poses[0])}
      fill="none"
      stroke={stroke}
      strokeWidth={width}
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {!still && (
        <animate
          attributeName="points"
          values={poses.map(pts).join(";")}
          keyTimes={keyTimes.join(";")}
          keySplines={spline.join(";")}
          calcMode="spline"
          dur={dur}
          repeatCount="indefinite"
        />
      )}
    </polyline>
  );
}

interface DotProps {
  path: readonly Pt[];
  keyTimes: readonly number[];
  dur: string;
  r: number;
  splines?: readonly string[];
  fill?: string;
  still?: boolean;
}

/** A head or a dumbbell — travels along its own keyframed path. */
function Dot({ path, keyTimes, dur, r, splines, fill = "none", still }: DotProps) {
  const spline = splines ?? Array.from({ length: path.length - 1 }, () => EASE);
  const anim = (attr: "cx" | "cy", i: 0 | 1) =>
    !still && (
      <animate
        attributeName={attr}
        values={path.map((p) => p[i]).join(";")}
        keyTimes={keyTimes.join(";")}
        keySplines={spline.join(";")}
        calcMode="spline"
        dur={dur}
        repeatCount="indefinite"
      />
    );
  return (
    <circle cx={path[0][0]} cy={path[0][1]} r={r} fill={fill} stroke={ACCENT} strokeWidth={4}>
      {anim("cx", 0)}
      {anim("cy", 1)}
    </circle>
  );
}

/** The trajectory the working end travels. Faint, but it's what makes the
 *  movement legible at a glance before the loop comes round again. */
function Arc({ d }: { d: string }) {
  return (
    <path
      d={d}
      fill="none"
      stroke={ACCENT}
      strokeWidth={2}
      strokeDasharray="3 6"
      opacity={0.28}
      strokeLinecap="round"
    />
  );
}

/* The gradient id must be unique per figure: SVG ids are document-global, so
 * two figures on screen at once would both resolve to whichever defined it
 * first. Only one renders at a time today, but that's a coincidence of the
 * current layout rather than something to rely on. */
function Floor({ uid }: { uid: string }) {
  const id = `fg-floor-${uid}`;
  return (
    <>
      <defs>
        <linearGradient id={id} x1="0" x2="1" y1="0" y2="0">
          <stop offset="0%" stopColor="rgb(255 255 255 / 0)" />
          <stop offset="25%" stopColor="rgb(255 255 255 / 0.18)" />
          <stop offset="75%" stopColor="rgb(255 255 255 / 0.18)" />
          <stop offset="100%" stopColor="rgb(255 255 255 / 0)" />
        </linearGradient>
      </defs>
      <line x1={16} y1={114} x2={184} y2={114} stroke={`url(#${id})`} strokeWidth={3} />
    </>
  );
}

/** Standing torso, head and legs — shared by every front-view movement. */
function Standing({ headY = 40, torsoTop = 50, hip = 92 }) {
  return (
    <>
      <circle cx={100} cy={headY} r={9} fill="none" stroke={ACCENT} strokeWidth={4} />
      <polyline
        points={pts([
          [100, torsoTop],
          [100, hip],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={4.5}
        strokeLinecap="round"
      />
      <polyline
        points={pts([
          [88, 114],
          [100, hip],
          [112, 114],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={4.5}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </>
  );
}

interface Props {
  kind: FigureKind;
  className?: string;
  still?: boolean;
}

export function Figure({ kind, className, still = false }: Props) {
  return (
    <svg
      viewBox="0 0 200 130"
      className={cn("h-full w-full", className)}
      role="img"
      aria-label={FIGURE_LABELS[kind]}
    >
      {DRAW[kind](still, kind)}
    </svg>
  );
}

/* --- the movements ---------------------------------------------------------
 * Coordinates are hand-placed. A figure is small enough that being able to
 * read the numbers beats being able to parameterise them. */

type Draw = (still: boolean, uid: FigureKind) => React.ReactNode;

/** Two mirrored arms sharing one pose pair — presses, raises and flyes are all
 *  this shape. */
function Pair({
  still,
  down,
  up,
  keyTimes,
  dur,
  weights = true,
}: {
  still: boolean;
  down: readonly [readonly Pt[], readonly Pt[]];
  up: readonly [readonly Pt[], readonly Pt[]];
  keyTimes: readonly number[];
  dur: string;
  weights?: boolean;
}) {
  return (
    <>
      {[0, 1].map((i) => (
        <Bone
          key={`arm${i}`}
          still={still}
          poses={[down[i], up[i], up[i], down[i], down[i]]}
          keyTimes={keyTimes}
          dur={dur}
        />
      ))}
      {weights &&
        [0, 1].map((i) => {
          const a = down[i][down[i].length - 1];
          const b = up[i][up[i].length - 1];
          return (
            <Dot
              key={`w${i}`}
              still={still}
              r={5}
              fill={ACCENT}
              path={[a, b, b, a, a]}
              keyTimes={keyTimes}
              dur={dur}
            />
          );
        })}
    </>
  );
}

const DRAW: Record<FigureKind, Draw> = {
  /* Deficit push-up, side view, facing right. The hand stays pinned to the
   * block, the elbow folds backward, and the chest sinks below hand level —
   * which is the entire point of the deficit. 3s down, 1s pause, fast up. */
  pushup: (still, uid) => {
    const dur = "5.2s";
    const kt = [0, 0.577, 0.769, 0.904, 1];
    const sp = [EASE, LINEAR, "0.3 0 0.2 1", LINEAR];
    const bodyUp: Pt[] = [
      [22, 112],
      [66, 102],
      [100, 92],
      [140, 78],
    ];
    const bodyDown: Pt[] = [
      [22, 112],
      [66, 105],
      [100, 99],
      [140, 96],
    ];
    const armUp: Pt[] = [
      [140, 78],
      [147, 88],
      [150, 98],
    ];
    const armDown: Pt[] = [
      [140, 96],
      [131, 103],
      [150, 98],
    ];
    return (
      <>
        <Floor uid={uid} />
        <rect
          x={140}
          y={98}
          width={22}
          height={16}
          rx={3}
          fill="none"
          stroke={BODY}
          strokeWidth={3}
          opacity={0.55}
        />
        <Arc d="M150 74 Q 138 82 140 94" />
        <Bone
          still={still}
          stroke={BODY}
          poses={[bodyUp, bodyDown, bodyDown, bodyUp, bodyUp]}
          keyTimes={kt}
          splines={sp}
          dur={dur}
        />
        <Bone
          still={still}
          poses={[armUp, armDown, armDown, armUp, armUp]}
          keyTimes={kt}
          splines={sp}
          dur={dur}
        />
        <Dot
          still={still}
          r={7.5}
          path={[
            [156, 71],
            [157, 88],
            [157, 88],
            [156, 71],
            [156, 71],
          ]}
          keyTimes={kt}
          splines={sp}
          dur={dur}
        />
      </>
    );
  },

  /* Strict press, front view. Ear height to lockout, biceps by the ears. */
  "overhead-press": (still, uid) => {
    const dur = "4.4s";
    const kt = [0, 0.34, 0.5, 0.86, 1];
    return (
      <>
        <Floor uid={uid} />
        <Arc d="M80 54 Q 84 36 92 26" />
        <Arc d="M120 54 Q 116 36 108 26" />
        <Standing />
        <Pair
          still={still}
          keyTimes={kt}
          dur={dur}
          down={[
            [
              [84, 58],
              [75, 74],
              [81, 54],
            ],
            [
              [116, 58],
              [125, 74],
              [119, 54],
            ],
          ]}
          up={[
            [
              [84, 58],
              [86, 42],
              [92, 26],
            ],
            [
              [116, 58],
              [114, 42],
              [108, 26],
            ],
          ]}
        />
      </>
    );
  },

  curl: (still, uid) => curlLike(still, uid, "across"),
  "hammer-curl": (still, uid) => curlLike(still, uid, "neutral"),

  /* Bent-over row, side view. Torso hinged, elbow drives back past the ribs,
   * hand finishes at the hip. */
  row: (still, uid) => {
    const dur = "3.8s";
    const kt = [0, 0.32, 0.48, 0.88, 1];
    const hang: Pt[] = [
      [78, 64],
      [82, 84],
      [86, 104],
    ];
    const pull: Pt[] = [
      [78, 64],
      [98, 74],
      [104, 90],
    ];
    return (
      <>
        <Floor uid={uid} />
        <Arc d="M86 104 Q 100 100 104 90" />
        <polyline
          points={pts([
            [120, 88],
            [78, 64],
          ])}
          fill="none"
          stroke={BODY}
          strokeWidth={4.5}
          strokeLinecap="round"
        />
        <polyline
          points={pts([
            [120, 88],
            [124, 102],
            [118, 114],
          ])}
          fill="none"
          stroke={BODY}
          strokeWidth={4.5}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <circle cx={64} cy={58} r={8} fill="none" stroke={ACCENT} strokeWidth={4} />
        <Bone
          still={still}
          poses={[hang, pull, pull, hang, hang]}
          keyTimes={kt}
          dur={dur}
        />
        <Dot
          still={still}
          r={5}
          fill={ACCENT}
          path={[
            [86, 104],
            [104, 90],
            [104, 90],
            [86, 104],
            [86, 104],
          ]}
          keyTimes={kt}
          dur={dur}
        />
      </>
    );
  },

  /* Lateral raise, front view. Elbows lead, stop at shoulder height. */
  "lateral-raise": (still, uid) => {
    const dur = "4.2s";
    const kt = [0, 0.36, 0.52, 0.9, 1];
    return (
      <>
        <Floor uid={uid} />
        <Arc d="M70 94 Q 54 84 48 62" />
        <Arc d="M130 94 Q 146 84 152 62" />
        <Standing headY={38} torsoTop={48} />
        <Pair
          still={still}
          keyTimes={kt}
          dur={dur}
          down={[
            [
              [86, 58],
              [78, 78],
              [70, 94],
            ],
            [
              [114, 58],
              [122, 78],
              [130, 94],
            ],
          ]}
          up={[
            [
              [86, 58],
              [64, 56],
              [48, 62],
            ],
            [
              [114, 58],
              [136, 56],
              [152, 62],
            ],
          ]}
        />
      </>
    );
  },

  /* Rear-delt fly. Hinged until almost parallel, arms opening like a curtain. */
  "rear-delt-fly": (still, uid) => {
    const dur = "4.4s";
    const kt = [0, 0.38, 0.56, 0.92, 1];
    return (
      <>
        <Floor uid={uid} />
        <Arc d="M92 104 Q 68 100 46 76" />
        <Arc d="M108 104 Q 132 100 154 76" />
        <Standing headY={44} torsoTop={53} hip={84} />
        <Pair
          still={still}
          keyTimes={kt}
          dur={dur}
          down={[
            [
              [88, 62],
              [90, 84],
              [92, 104],
            ],
            [
              [112, 62],
              [110, 84],
              [108, 104],
            ],
          ]}
          up={[
            [
              [88, 62],
              [66, 66],
              [46, 76],
            ],
            [
              [112, 62],
              [134, 66],
              [154, 76],
            ],
          ]}
        />
      </>
    );
  },

  /* Warm-up: both arms sweeping full circles, one a half-turn behind. */
  warmup: (still, uid) => {
    const dur = "3.6s";
    const kt = [0, 0.25, 0.5, 0.75, 1];
    const circle = (cx: number, cy: number, phase: number): Pt[] =>
      [0, 1, 2, 3, 4].map((i) => {
        const a = (i / 4) * 2 * Math.PI + phase;
        return [
          Math.round(cx + Math.cos(a) * 30),
          Math.round(cy + Math.sin(a) * 30),
        ] as Pt;
      });
    return (
      <>
        <Floor uid={uid} />
        {[84, 116].map((cx) => (
          <circle
            key={cx}
            cx={cx}
            cy={62}
            r={30}
            fill="none"
            stroke={ACCENT}
            strokeWidth={2}
            strokeDasharray="3 6"
            opacity={0.22}
          />
        ))}
        <Standing />
        {[
          { o: [84, 62] as Pt, path: circle(84, 62, -Math.PI / 2) },
          { o: [116, 62] as Pt, path: circle(116, 62, Math.PI / 2) },
        ].map(({ o, path }, i) => (
          <Bone
            key={i}
            still={still}
            poses={path.map((p) => [o, p] as readonly Pt[])}
            keyTimes={kt}
            splines={[LINEAR, LINEAR, LINEAR, LINEAR]}
            dur={dur}
          />
        ))}
      </>
    );
  },
};

/* Curl and hammer curl share a skeleton; only the grip differs. Fast up, then
 * three seconds lowering, then a beat held at FULL extension — the bottom inch
 * the cue keeps insisting on. The elbow is marked so it's obvious it doesn't
 * travel. */
function curlLike(
  still: boolean,
  uid: FigureKind,
  grip: "across" | "neutral",
): React.ReactNode {
  const dur = "4.8s";
  const kt = [0, 0.18, 0.32, 0.86, 1];
  const sp = ["0.3 0 0.2 1", LINEAR, "0.5 0 0.5 1", LINEAR];
  const down: Pt[] = [
    [96, 54],
    [92, 80],
    [95, 106],
  ];
  const up: Pt[] = [
    [96, 54],
    [92, 80],
    [113, 66],
  ];
  return (
    <>
      <Floor uid={uid} />
      <Arc d="M95 106 Q 112 96 113 66" />
      <circle cx={96} cy={36} r={9} fill="none" stroke={ACCENT} strokeWidth={4} />
      <polyline
        points={pts([
          [96, 45],
          [96, 90],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={4.5}
        strokeLinecap="round"
      />
      <polyline
        points={pts([
          [86, 114],
          [96, 90],
          [106, 114],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={4.5}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx={92} cy={80} r={2.5} fill={JOINT} />
      <Bone
        still={still}
        poses={[down, up, up, down, down]}
        keyTimes={kt}
        splines={sp}
        dur={dur}
      />
      {grip === "across" ? (
        <Dot
          still={still}
          r={5}
          fill={ACCENT}
          path={[
            [95, 106],
            [113, 66],
            [113, 66],
            [95, 106],
            [95, 106],
          ]}
          keyTimes={kt}
          splines={sp}
          dur={dur}
        />
      ) : (
        /* Neutral grip: the dumbbell lies along the forearm rather than across
           it, which is the only visual difference between the two lifts. */
        <Bone
          still={still}
          width={7}
          poses={[
            [
              [95, 100],
              [95, 112],
            ],
            [
              [110, 60],
              [116, 72],
            ],
            [
              [110, 60],
              [116, 72],
            ],
            [
              [95, 100],
              [95, 112],
            ],
            [
              [95, 100],
              [95, 112],
            ],
          ]}
          keyTimes={kt}
          splines={sp}
          dur={dur}
        />
      )}
    </>
  );
}
