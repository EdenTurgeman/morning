import { useEffect, useState } from "react";
import { Chrome } from "@/components/Chrome";
import { Cues } from "@/components/Cues";
import { Figure, figureFor } from "@/components/Figure";
import { Ring } from "@/components/Ring";
import { RepDial } from "@/components/RepDial";
import { Button } from "@/components/Button";
import { Confirm } from "@/components/Confirm";
import { useCountdown } from "@/hooks/useCountdown";
import { buzz, confirmTone } from "@/lib/audio";
import { lastRepsFor, type AppData } from "@/lib/storage";
import type { SetStep, Step } from "@/lib/steps";
import type { SessionKey } from "@/program";
import { clock } from "@/lib/format";

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
        {step.kind === "rest" && <RestStepView {...props} step={step} />}
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
  // Count in the last three seconds here too — knowing the warm-up is about to
  // end lets you be in position rather than reacting to the beep.
  const remaining = useCountdown({ endsAt, onComplete: onAdvance, countIn: true });

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

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <div className="flex items-start gap-2">
        <h2 className="flex-1 text-[2rem] leading-[1.06] font-bold tracking-[-0.032em] text-ink">
          {step.exercise}
        </h2>
        {step.intense && (
          <span className="mt-1.5 rounded-full border border-[var(--accent-line)] bg-[var(--accent-soft)] px-2.5 py-1 text-[0.62rem] font-semibold tracking-[0.12em] text-[var(--accent)] uppercase">
            myo
          </span>
        )}
      </div>

      {step.sub && (
        <p className="mt-1 text-[1.06rem] text-muted">{step.sub}</p>
      )}

      <p className="tnum mt-2.5 text-[0.96rem] text-dim">
        {meta.join("  ·  ")}
      </p>

      {step.straightIntoNext && (
        <p className="mt-2 text-[0.82rem] text-[var(--accent)]">
          No rest after this — straight into the next one.
        </p>
      )}

      {/* The flexible element. It takes whatever height is left after the
          text and the controls, so the screen fits any phone without ever
          scrolling — big on a Pro Max, modest on an SE. min-h-0 is required
          or a flex child refuses to shrink below its content size. */}
      {figure && (
        <div className="min-h-0 w-full flex-1 py-2 opacity-90">
          <Figure kind={figure} />
        </div>
      )}

      <Cues cues={step.cues} />

      <div className="shrink-0">
        <div className="mb-4 text-center text-[0.8rem] tracking-[0.14em] text-dim uppercase">
          Target · <span className="text-muted">{step.target}</span>
        </div>

        <RepDial
          value={reps}
          onStep={(delta) => setReps((r) => Math.max(0, r + delta))}
          previous={previous}
        />

        <Button
          variant="primary"
          className="mt-6"
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

function RestStepView({
  step,
  steps,
  index,
  endsAt,
  onAdvance,
  onExtend,
}: Props & { step: Extract<Step, { kind: "rest" }> }) {
  const remaining = useCountdown({
    endsAt,
    onComplete: onAdvance,
    countIn: true,
  });

  const next = steps[index + 1];
  // The 20s myo rest is the mechanism of the technique, not a convenience.
  const isMechanism = step.seconds <= 20;

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <div className="text-center text-[0.7rem] tracking-[0.16em] text-dim uppercase">
        Rest
      </div>

      <div className="my-auto py-2">
        <Ring remaining={remaining} total={step.seconds} />

        {isMechanism && (
          <p className="mx-auto mt-4 max-w-[17rem] text-center text-[0.84rem] leading-snug text-[var(--accent)]">
            The 20-second rest IS the mechanism. Don&apos;t stretch it.
          </p>
        )}
      </div>

      {/* Preview and actions sit at the bottom, so the tap target is in the
          same place it is on a set screen and the thumb never travels. */}
      <div className="mt-auto">
        {next?.kind === "set" && (
          <div className="surface mb-3 rounded-[var(--radius-control)] px-4 py-3.5">
            <div className="text-[0.66rem] tracking-[0.16em] text-dim uppercase">
              Up next
            </div>
            <div className="mt-1 text-[1.05rem] font-semibold text-ink">
              {next.exercise}
              {next.sub && (
                <span className="font-normal text-muted"> · {next.sub}</span>
              )}
            </div>
            <div className="tnum mt-0.5 text-[0.86rem] text-dim">
              set {next.n} of {next.of}
              {next.load ? ` · ${next.load} kg` : ""}
            </div>
            {/* The target for what's coming, so you can set your intent during
                the rest instead of reading it cold when the timer fires. */}
            <div className="mt-1.5 text-[0.84rem] text-[var(--accent)]">
              Target · {next.target}
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
