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

/** Standing torso, head and legs — shared by every front-view movement.
 *
 *  Draws actual shoulder and hip bars rather than a single vertical line. A
 *  bare line with a circle on top and a V underneath reads as a stick, not a
 *  body, and it gave the arms nothing to visibly hang from. */
function Standing({
  headY = 38,
  shoulderY = 58,
  hip = 90,
  shoulderHalf = 16,
  hipHalf = 10,
}) {
  return (
    <>
      <circle cx={100} cy={headY} r={9.5} fill="none" stroke={ACCENT} strokeWidth={4} />
      {/* neck */}
      <polyline
        points={pts([
          [100, headY + 9.5],
          [100, shoulderY],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={4}
        strokeLinecap="round"
      />
      {/* shoulders */}
      <polyline
        points={pts([
          [100 - shoulderHalf, shoulderY],
          [100 + shoulderHalf, shoulderY],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={5}
        strokeLinecap="round"
      />
      {/* spine */}
      <polyline
        points={pts([
          [100, shoulderY],
          [100, hip],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={5}
        strokeLinecap="round"
      />
      {/* hips */}
      <polyline
        points={pts([
          [100 - hipHalf, hip],
          [100 + hipHalf, hip],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={5}
        strokeLinecap="round"
      />
      {/* legs */}
      <polyline
        points={pts([
          [100 - hipHalf, hip],
          [100 - hipHalf - 2, 114],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={4.5}
        strokeLinecap="round"
      />
      <polyline
        points={pts([
          [100 + hipHalf, hip],
          [100 + hipHalf + 2, 114],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={4.5}
        strokeLinecap="round"
      />
    </>
  );
}

/* --- dumbbells -------------------------------------------------------------
 * Drawn as a short thick bar rather than a dot: a circle at the end of a limb
 * reads as a ball or a fist, and it was impossible to tell a curl from a
 * hammer curl. Derived from the arm pose rather than hand-placed, so the bar
 * stays correctly oriented through the whole movement. */

const r = (n: number) => Math.round(n * 100) / 100;

/** Bar across the palm — the normal grip. Perpendicular to the forearm. */
function barAcross(elbow: Pt, hand: Pt, half = 7.5): readonly Pt[] {
  const dx = hand[0] - elbow[0];
  const dy = hand[1] - elbow[1];
  const len = Math.hypot(dx, dy) || 1;
  const px = (-dy / len) * half;
  const py = (dx / len) * half;
  // Rounded: the raw values carry 15 decimal places into every keyframe of
  // every <animate>, which bloats the markup for no visual difference.
  return [
    [r(hand[0] + px), r(hand[1] + py)],
    [r(hand[0] - px), r(hand[1] - py)],
  ];
}

/** Bar in line with the forearm — the neutral, hammer grip. */
function barAlong(elbow: Pt, hand: Pt, half = 7.5): readonly Pt[] {
  const dx = hand[0] - elbow[0];
  const dy = hand[1] - elbow[1];
  const len = Math.hypot(dx, dy) || 1;
  return [
    [r(hand[0] + (dx / len) * half), r(hand[1] + (dy / len) * half)],
    [r(hand[0] - (dx / len) * half), r(hand[1] - (dy / len) * half)],
  ];
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
          const dBar = barAcross(down[i][down[i].length - 2], down[i][down[i].length - 1]);
          const uBar = barAcross(up[i][up[i].length - 2], up[i][up[i].length - 1]);
          return (
            <Bone
              key={`w${i}`}
              still={still}
              width={7}
              poses={[dBar, uBar, uBar, dBar, dBar]}
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
        {/* hinged spine, hip to shoulder */}
        <polyline
          points={pts([
            [120, 88],
            [78, 64],
          ])}
          fill="none"
          stroke={BODY}
          strokeWidth={5}
          strokeLinecap="round"
        />
        {/* shoulder bar, across the hinge */}
        <polyline
          points={pts([
            [72, 71],
            [84, 58],
          ])}
          fill="none"
          stroke={BODY}
          strokeWidth={5}
          strokeLinecap="round"
        />
        {/* hips */}
        <polyline
          points={pts([
            [114, 94],
            [126, 82],
          ])}
          fill="none"
          stroke={BODY}
          strokeWidth={5}
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
        <circle cx={64} cy={57} r={9} fill="none" stroke={ACCENT} strokeWidth={4} />
        <Bone
          still={still}
          poses={[hang, pull, pull, hang, hang]}
          keyTimes={kt}
          dur={dur}
        />
        {(() => {
          const d = barAcross(hang[1], hang[2]);
          const u = barAcross(pull[1], pull[2]);
          return (
            <Bone still={still} width={7} poses={[d, u, u, d, d]} keyTimes={kt} dur={dur} />
          );
        })()}
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
        <Standing />
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
        <Standing headY={44} shoulderY={62} hip={86} shoulderHalf={14} />
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

  /* Floor fly, seen FROM ABOVE — you're on your back. Top-down is the only
   * view that works: from the side a fly's arm just travels up and down and
   * is indistinguishable from a press, whereas from above the opening and
   * closing arc is the whole movement. The mat behind the figure is what
   * signals "lying down" rather than standing. */
  "floor-fly": (still, uid) => {
    const dur = "4.6s";
    // slow open into the stretch, 1s hold there, faster squeeze back
    const kt = [0, 0.42, 0.6, 0.9, 1];
    const open = [
      [
        [86, 46],
        [64, 52],
        [44, 57],
      ],
      [
        [114, 46],
        [136, 52],
        [156, 57],
      ],
    ] as const;
    const shut = [
      [
        [86, 46],
        [80, 33],
        [95, 27],
      ],
      [
        [114, 46],
        [120, 33],
        [105, 27],
      ],
    ] as const;
    return (
      <>
        <Floor uid={uid} />
        {/* the mat — reads as "on your back" */}
        <rect
          x={72}
          y={12}
          width={56}
          height={104}
          rx={10}
          fill="rgb(255 255 255 / 0.03)"
          stroke={BODY}
          strokeWidth={2}
          opacity={0.4}
        />
        <Arc d="M44 57 Q 62 34 95 27" />
        <Arc d="M156 57 Q 138 34 105 27" />

        {/* head, shoulders, torso, hips, legs — from above */}
        <circle cx={100} cy={26} r={9} fill="none" stroke={ACCENT} strokeWidth={4} />
        <polyline
          points={pts([
            [86, 46],
            [114, 46],
          ])}
          fill="none"
          stroke={BODY}
          strokeWidth={5}
          strokeLinecap="round"
        />
        <polyline
          points={pts([
            [100, 40],
            [100, 84],
          ])}
          fill="none"
          stroke={BODY}
          strokeWidth={5}
          strokeLinecap="round"
        />
        <polyline
          points={pts([
            [91, 84],
            [109, 84],
          ])}
          fill="none"
          stroke={BODY}
          strokeWidth={5}
          strokeLinecap="round"
        />
        <polyline
          points={pts([[91, 84], [89, 112]])}
          fill="none"
          stroke={BODY}
          strokeWidth={4.5}
          strokeLinecap="round"
        />
        <polyline
          points={pts([[109, 84], [111, 112]])}
          fill="none"
          stroke={BODY}
          strokeWidth={4.5}
          strokeLinecap="round"
        />

        <Pair still={still} keyTimes={kt} dur={dur} down={open} up={shut} />
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
      <circle cx={96} cy={34} r={9.5} fill="none" stroke={ACCENT} strokeWidth={4} />
      {/* side view: a shorter shoulder bar, since you're seeing it edge-on */}
      <polyline
        points={pts([
          [96, 43.5],
          [96, 54],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={4}
        strokeLinecap="round"
      />
      <polyline
        points={pts([
          [89, 55],
          [103, 53],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={5}
        strokeLinecap="round"
      />
      <polyline
        points={pts([
          [96, 54],
          [97, 90],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={5}
        strokeLinecap="round"
      />
      <polyline
        points={pts([
          [90, 90],
          [104, 90],
        ])}
        fill="none"
        stroke={BODY}
        strokeWidth={5}
        strokeLinecap="round"
      />
      <polyline
        points={pts([[90, 90], [88, 114]])}
        fill="none"
        stroke={BODY}
        strokeWidth={4.5}
        strokeLinecap="round"
      />
      <polyline
        points={pts([[104, 90], [106, 114]])}
        fill="none"
        stroke={BODY}
        strokeWidth={4.5}
        strokeLinecap="round"
      />
      <circle cx={92} cy={80} r={2.5} fill={JOINT} />
      <Bone
        still={still}
        poses={[down, up, up, down, down]}
        keyTimes={kt}
        splines={sp}
        dur={dur}
      />
      {/* Grip is the ONLY visual difference between these two lifts, so it has
          to be unmistakable: across the palm for a curl, in line with the
          forearm for a hammer curl. Both derived from the arm pose. */}
      {(() => {
        const bar = grip === "across" ? barAcross : barAlong;
        const d = bar(down[1], down[2]);
        const u = bar(up[1], up[2]);
        return (
          <Bone
            still={still}
            width={7}
            poses={[d, u, u, d, d]}
            keyTimes={kt}
            splines={sp}
            dur={dur}
          />
        );
      })()}
    </>
  );
}
