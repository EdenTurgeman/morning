import { useEffect, useMemo, useRef, useState } from "react";
import { Chrome } from "@/components/Chrome";
import { Cues } from "@/components/Cues";
import { Figure, figureFor } from "@/components/Figure";
import { Ring } from "@/components/Ring";
import { RepDial } from "@/components/RepDial";
import { Button } from "@/components/Button";
import { Confirm } from "@/components/Confirm";
import { StudyCard } from "@/components/StudyCard";
import { useCountdown } from "@/hooks/useCountdown";
import { buzz, confirmTone } from "@/lib/audio";
import { lastRepsFor, previousSameSession, type AppData } from "@/lib/storage";
import type { SetStep, Step } from "@/lib/steps";
import type { SessionKey } from "@/program";
import { clock } from "@/lib/format";
import { cardRestIndices, drawCard, revealDelayFor } from "@/lib/deck";
import type { Card } from "@/lib/cards";

interface Props {
  sessionKey: SessionKey;
  steps: readonly Step[];
  step: Step;
  index: number;
  endsAt: number | null;
  data: AppData;
  /** Reps logged so far in *this* session, slot → reps. */
  log: Record<string, number>;
  onAdvance: (logged?: { slot: string; reps: number }) => void;
  onBack: () => void;
  onExtend: (seconds: number) => void;
  onAbandon: () => void;
}

export function Workout(props: Props) {
  const { steps, step, index, onBack, onAbandon } = props;
  const [confirmEnd, setConfirmEnd] = useState(false);

  /* Two cards a session, on rests picked up front so they land spread out.
   * Drawn lazily and cached by step index, so tapping Back onto a rest you've
   * already had returns the same question instead of burning a new one — and
   * so a StrictMode double render doesn't quietly mark two cards seen. */
  const cardSteps = useMemo(() => new Set(cardRestIndices(steps)), [steps]);
  const drawn = useRef(new Map<number, Card | null>());
  let card: Card | null = null;
  if (cardSteps.has(index)) {
    if (!drawn.current.has(index)) drawn.current.set(index, drawCard());
    card = drawn.current.get(index) ?? null;
  }

  /* h-full + overflow-hidden, not min-h-full: a workout screen must fit
     exactly. "One screen, one action" stops being true the moment you have to
     scroll to find the Done button mid-set. The figure below is the flexible
     element that absorbs whatever slack is left. */
  return (
    <div className="flex h-full flex-col overflow-hidden">
      <Chrome
        index={index}
        total={steps.length}
        steps={steps}
        onBack={onBack}
        onEnd={() => setConfirmEnd(true)}
      />

      {/* Each step is its own keyed subtree, so React tears down the old timer
          and rep counter rather than trying to reconcile them.

          The entrance is a plain CSS animation rather than an AnimatePresence
          exit/enter pair, deliberately: mode="wait" gates mounting the next
          step on the previous one finishing its exit, which means a stalled
          animation frame leaves you tapping Done and watching nothing happen.
          A CSS keyframe runs on the compositor and can't block the mount. */}
      <div key={index} className="step-enter flex min-h-0 flex-1 flex-col">
        {step.kind === "timer" && <TimerStepView {...props} step={step} />}
        {step.kind === "set" && <SetStepView {...props} step={step} />}
        {step.kind === "rest" && (
          <RestStepView {...props} step={step} card={card} />
        )}
      </div>

      <Confirm
        open={confirmEnd}
        onOpenChange={setConfirmEnd}
        title="End this session?"
        description="Nothing will be saved — not even the sets you've already logged."
        confirmLabel="End and discard"
        cancelLabel="Keep going"
        destructive
        onConfirm={onAbandon}
      />
    </div>
  );
}

/* --- warm-up --------------------------------------------------------------- */

function TimerStepView({
  step,
  endsAt,
  onAdvance,
}: Props & { step: Extract<Step, { kind: "timer" }> }) {
  const remaining = useCountdown({ endsAt, onComplete: onAdvance });

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <h2 className="text-[2rem] leading-[1.08] font-bold tracking-[-0.03em] text-ink">
        {step.title}
      </h2>
      <p className="mt-1.5 text-[0.95rem] text-muted">
        90 seconds. Don&apos;t skip it, don&apos;t extend it.
      </p>

      <Cues cues={step.cues} />

      <div className="my-auto py-2 text-center">
        <div className="mx-auto h-[92px] w-full max-w-[220px] opacity-80">
          <Figure kind="warmup" />
        </div>
        <div className="tnum mt-2 text-[4.4rem] leading-none font-bold tracking-[-0.05em] text-ink">
          {clock(remaining)}
        </div>
      </div>

      <Button variant="primary" onClick={() => onAdvance()}>
        Done — start lifting
      </Button>
    </div>
  );
}

/* --- a working set --------------------------------------------------------- */

function SetStepView({
  step,
  steps,
  index,
  sessionKey,
  data,
  log,
  onAdvance,
}: Props & { step: SetStep }) {
  const previous = lastRepsFor(data.history, sessionKey, step.slot);

  /* If the working weight has changed since that number was set, reps aren't
   * comparable — 12 at 7.5 kg is not 12 at 10 kg — so the dial says so
   * instead of quietly implying a like-for-like target. */
  const prevSession = previousSameSession(data.history, sessionKey, 0);
  const previousKg = prevSession?.kg;
  const weightChanged =
    previous !== null &&
    typeof previousKg === "number" &&
    typeof step.load === "number" &&
    Math.abs(previousKg - step.load) > 0.01;

  /* Priority order matters:
   *   1. what you already logged for this slot in THIS session — so tapping
   *      Back to fix a mistap shows the number you actually entered, not the
   *      one from last week
   *   2. what you did on this exact set last time — the whole point of the app
   *   3. a plausible default, so a first run is still one tap
   */
  const seed = () => log[step.slot] ?? previous ?? (step.bodyweight ? 10 : 12);
  const [reps, setReps] = useState(seed);

  useEffect(() => {
    setReps(seed());
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [step.slot]);

  const meta: string[] = [];
  if (step.load) meta.push(`${step.load} kg`);
  else if (step.bodyweight) meta.push("bodyweight");
  meta.push(`set ${step.n} of ${step.of}`);
  if (step.superset) meta.push(`superset ${step.superset[0]} of ${step.superset[1]}`);

  // "4 sets to go" orients you far better than "step 14 of 25" — rests aren't
  // work, so they shouldn't count toward what's left.
  const setsLeft = steps
    .slice(index + 1)
    .filter((s): s is SetStep => s.kind === "set").length;

  const figure = figureFor(step.exercise);

  /* Three bands: a fixed header, a scrollable middle, and pinned controls.
   *
   * The controls must never move or clip — an earlier version sized the whole
   * screen to the viewport and let the figure absorb the slack, which works
   * right up until the viewport is shorter than the fixed content. On an
   * iPhone in standalone mode the usable area is around 90pt less than the
   * screen, and Done ended up cut off below the fold. Now only the figure and
   * cues scroll, so the rep dial and Done are reachable at any height. */
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <div className="shrink-0">
        <div className="flex items-start gap-2">
          <h2 className="flex-1 text-[1.9rem] leading-[1.06] font-bold tracking-[-0.032em] text-ink">
            {step.exercise}
          </h2>
          {step.intense && (
            <span className="mt-1.5 rounded-full border border-[var(--accent-line)] bg-[var(--accent-soft)] px-2.5 py-1 text-[0.62rem] font-semibold tracking-[0.12em] text-[var(--accent)] uppercase">
              myo
            </span>
          )}
        </div>

        {step.sub && <p className="mt-0.5 text-[1.02rem] text-muted">{step.sub}</p>}

        <p className="tnum mt-1.5 text-[0.94rem] text-dim">{meta.join("  ·  ")}</p>

        {step.straightIntoNext && (
          <p className="mt-1.5 text-[0.86rem] text-[var(--accent)]">
            No rest after this — straight into the next one.
          </p>
        )}
      </div>

      {/* The only part that may scroll. */}
      <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain">
        {figure && (
          <div className="h-[clamp(70px,16vh,130px)] w-full opacity-90">
            <Figure kind={figure} />
          </div>
        )}
        <Cues cues={step.cues} />
      </div>

      <div className="shrink-0 pt-1">
        <div className="mb-3 text-center text-[0.8rem] tracking-[0.14em] text-dim uppercase">
          Target · <span className="text-muted">{step.target}</span>
        </div>

        <RepDial
          value={reps}
          onStep={(delta) => setReps((r) => Math.max(0, r + delta))}
          previous={previous}
          previousKg={weightChanged ? previousKg : undefined}
        />

        <Button
          variant="primary"
          className="mt-4"
          onClick={() => {
            confirmTone();
            buzz(14);
            onAdvance({ slot: step.slot, reps });
          }}
        >
          Done
        </Button>

        <p className="tnum mt-2.5 text-center text-[0.86rem] text-dim">
          {setsLeft === 0
            ? "Last set of the session."
            : `${setsLeft} ${setsLeft === 1 ? "set" : "sets"} to go`}
        </p>
      </div>
    </div>
  );
}

/* --- rest ------------------------------------------------------------------ */

/* Ring diameter. A plain rest has nothing to compete with, so the clock is
 * as big as the column allows. A carded rest starts nearly as large and then
 * halves when the answer lands — which is what makes even the longest card in
 * the deck fit without scrolling on a 780pt screen. */
const PLAIN_RING = 280;
const CARD_RING = 230;
const CARD_RING_SHRUNK = 130;

function RestStepView({
  step,
  steps,
  index,
  endsAt,
  card,
  onAdvance,
  onExtend,
}: Props & { step: Extract<Step, { kind: "rest" }>; card: Card | null }) {
  const remaining = useCountdown({ endsAt, onComplete: onAdvance });
  const [answered, setAnswered] = useState(false);

  const next = steps[index + 1];
  // The 20s myo rest is the mechanism of the technique, not a convenience.
  const isMechanism = step.seconds <= 20;

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <div className="shrink-0 text-center text-[0.7rem] tracking-[0.16em] text-dim uppercase">
        Rest
      </div>

      {card ? (
        /* With a card the middle band scrolls instead of centring, and the ring
           gives up some size. Answers vary by a couple of lines; an unusually
           long one must never push Skip off the bottom of the screen, and the
           ring only has to be readable, not enormous — you're looking at the
           question. */
        <div
          className="flex min-h-0 flex-1 flex-col overflow-y-auto overscroll-contain pt-1.5"
          // `safe` so that a card long enough to overflow falls back to
          // top-alignment instead of centring its overflow out of reach.
          style={{ justifyContent: "safe center" }}
        >
          {/* The ring is only the hero while there's nothing else to look at.
              The moment the answer lands it halves and gives its space to the
              text — which is both the reason the answer always fits and, on a
              screen you stare at for a minute, the nicest thing that happens
              on it. Scaled rather than resized: a width/height transition on
              an SVG relayouts every frame, a transform doesn't. */}
          <div
            className="mx-auto shrink-0 origin-top transition-[transform,margin-bottom] duration-[650ms] ease-[var(--ease-out-expo)]"
            style={{
              width: CARD_RING,
              transform: `scale(${answered ? CARD_RING_SHRUNK / CARD_RING : 1})`,
              marginBottom: answered ? `${CARD_RING_SHRUNK - CARD_RING}px` : 0,
            }}
          >
            <Ring remaining={remaining} total={step.seconds} size={CARD_RING} />
          </div>

          <StudyCard
            card={card}
            autoRevealMs={revealDelayFor(step.seconds)}
            onReveal={() => setAnswered(true)}
            className="mt-4 shrink-0"
          />
        </div>
      ) : (
        <div className="my-auto py-2">
          <Ring remaining={remaining} total={step.seconds} size={PLAIN_RING} />

          {isMechanism && (
            <p className="mx-auto mt-4 max-w-[17rem] text-center text-[0.84rem] leading-snug text-[var(--accent)]">
              The 20-second rest IS the mechanism. Don&apos;t stretch it.
            </p>
          )}
        </div>
      )}

      {/* Preview and actions sit at the bottom, so the tap target is in the
          same place it is on a set screen and the thumb never travels. */}
      <div className="mt-auto shrink-0 pt-3">
        {/* Two lines rather than a panel. It carries exactly what it did
            before — what's coming, how heavy, and the target, so you can set
            your intent during the rest instead of reading it cold when the
            timer fires — but a bordered card for it was spending a third of
            the screen on a preview. That space belongs to the clock and to
            whatever you're reading. */}
        {next?.kind === "set" && (
          <div className="mb-3.5 text-center">
            <div className="text-[0.95rem] leading-snug text-ink">
              <span className="text-[0.64rem] tracking-[0.17em] text-dim uppercase">
                Next{" · "}
              </span>
              <span className="font-semibold">{next.exercise}</span>
              {next.sub && <span className="text-muted"> · {next.sub}</span>}
            </div>
            <div className="tnum mt-1 text-[0.86rem] text-dim">
              set {next.n} of {next.of}
              {next.load ? ` · ${next.load} kg` : ""}
              {" · "}
              <span className="text-[var(--accent)]">{next.target}</span>
            </div>
          </div>
        )}

        <div className="flex gap-2.5">
          <Button onClick={() => onExtend(15)}>+15s</Button>
          <Button
            onClick={() => {
              buzz(10);
              onAdvance();
            }}
          >
            Skip →
          </Button>
        </div>
      </div>
    </div>
  );
}
