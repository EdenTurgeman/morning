/* ---------------------------------------------------------------------------
 * SOUND
 *
 * Everything is synthesised with oscillators — no audio files, nothing to
 * load, works offline.
 *
 * ── the rule this file is built around ────────────────────────────────────
 * This app makes six short noises in twenty minutes. It has no business
 * taking your music away for the other nineteen. So it never claims the audio
 * session for longer than a cue actually lasts:
 *
 *   1. The context is created on your first tap and then handed straight back.
 *      A running AudioContext holds an active audio session on iOS whether or
 *      not it is making a sound, and an active session is what silences Music.
 *   2. Every cue resumes it, plays, and releases it again. Overlapping cues
 *      extend one shared hold rather than fighting over it — so the five
 *      countdown ticks and the "go" beep are a single continuous hold, not six.
 *   3. The session type is "transient", the platform's word for a short sound
 *      that should DUCK other audio rather than interrupt it. Your music dips
 *      under the count-in and comes back up after it, the way a navigation
 *      prompt behaves.
 *
 * The previous version asked for "playback" — the category meant for a music
 * app — and additionally held a looping silent <audio> element open for the
 * life of the page. Together those told iOS this was the thing you were
 * listening to, so Music stopped and stayed stopped.
 *
 * ── the one thing that can't be fixed ─────────────────────────────────────
 * "transient" follows the ring/silent switch. That is the trade: a category
 * that ignores the switch is by definition one that takes the session away
 * from whatever else is playing. If music is playing at all then the switch
 * isn't the problem; a silent phone with nothing playing is the case where
 * you'll hear nothing, and the countdown still runs visually.
 * ------------------------------------------------------------------------- */

let ctx: AudioContext | null = null;

type WebkitWindow = Window & { webkitAudioContext?: typeof AudioContext };
interface AudioSessionNav {
  audioSession?: { type: string };
}

/* --- the session hold ------------------------------------------------------
 * `releaseAt` is the wall-clock moment the app has no further use for the
 * audio session. Cues push it forward; one timer chases it and suspends once
 * it stops moving. That is what makes a countdown duck your music once rather
 * than pumping it six times. */

let releaseAt = 0;
let releaseTimer: ReturnType<typeof setTimeout> | null = null;

function setSessionType(type: "transient" | "auto"): void {
  try {
    const session = (navigator as unknown as AudioSessionNav).audioSession;
    if (session) session.type = type;
  } catch {
    /* Safari-only, and still an editor's draft */
  }
}

function scheduleRelease(): void {
  if (releaseTimer) clearTimeout(releaseTimer);
  releaseTimer = setTimeout(
    () => {
      releaseTimer = null;
      // A cue landed while we were waiting — chase the new deadline instead.
      if (Date.now() < releaseAt - 15) {
        scheduleRelease();
        return;
      }
      void ctx?.suspend().catch(() => {});
      setSessionType("auto");
    },
    Math.max(0, releaseAt - Date.now()) + 30,
  );
}

/** Keep the audio session for at least `ms` more, then give it back. */
function hold(ms: number): void {
  releaseAt = Math.max(releaseAt, Date.now() + ms);
  scheduleRelease();
}

/**
 * Play one cue.
 *
 * `holdMs` is how long the sound needs the session for, tail included. It is
 * deliberately longer than the sound itself: releasing on the exact sample the
 * last oscillator stops clips the release, and re-ducking 200ms later for the
 * next tick would be audible.
 */
function cue(holdMs: number, play: (ac: AudioContext, at: number) => void): void {
  const ac = ctx;
  if (!ac) return;

  hold(holdMs);
  setSessionType("transient");

  const go = () => {
    try {
      play(ac, ac.currentTime);
    } catch {
      /* ignore */
    }
  };

  // resume() is async. An earlier version called it and then checked the state
  // synchronously — which is never "running" yet — so every cue after a
  // suspension was silently dropped. Scheduling inside the promise costs a few
  // milliseconds and never loses the sound.
  if (ac.state === "running") go();
  else void ac.resume().then(go).catch(() => {});
}

/** Called from the first touch anywhere, and again when a session starts. */
export function unlockAudio(): void {
  try {
    if (!ctx) {
      const Ctor =
        window.AudioContext ?? (window as WebkitWindow).webkitAudioContext;
      if (!Ctor) return;
      ctx = new Ctor();
      // A one-sample silent buffer is the canonical way to convince WebKit the
      // context is genuinely gesture-initiated. Everything after this is then
      // allowed to resume without a gesture of its own.
      const buffer = ctx.createBuffer(1, 1, 22050);
      const source = ctx.createBufferSource();
      source.buffer = buffer;
      source.connect(ctx.destination);
      source.start(0);
    }
    // Unlocked, then released: being armed must not cost you your music for
    // the rest of the session.
    hold(120);
  } catch {
    /* no audio — the countdown still advances visually */
  }
}

/** Zero. The note the count-in has been climbing toward — C6, an octave above
 *  where the run started, with C5 underneath for body. Longer and louder than
 *  any tick, so "go" is unmistakable even if you missed the count. */
export function beep(_notes = 3): void {
  void _notes;
  cue(1100, (ac, at) => {
    (
      [
        { hz: 1046.5, gain: 0.34, len: 0.5, type: "triangle" as OscillatorType },
        { hz: 523.25, gain: 0.16, len: 0.55, type: "sine" as OscillatorType },
      ] as const
    ).forEach(({ hz, gain: g, len, type }) => {
      const osc = ac.createOscillator();
      const gain = ac.createGain();
      osc.type = type;
      osc.frequency.value = hz;
      gain.gain.setValueAtTime(0.0001, at);
      gain.gain.exponentialRampToValueAtTime(g, at + 0.012);
      gain.gain.exponentialRampToValueAtTime(0.0001, at + len);
      osc.connect(gain);
      gain.connect(ac.destination);
      osc.start(at);
      osc.stop(at + len + 0.03);
    });
  });
}

/** The session-complete flourish: a rising major arpeggio with a soft pad
 *  under it. Only ever plays once a session, on the Daybreak screen — which is
 *  what lets it be four times longer than the rest beep without wearing out. */
export function chime(): void {
  cue(2300, (ac, now) => {
    // A4 · C#5 · E5 · A5 — a plain A major triad resolving up the octave.
    [440, 554.37, 659.25, 880].forEach((freq, i) => {
      const at = now + i * 0.15;
      const osc = ac.createOscillator();
      const gain = ac.createGain();
      osc.type = "triangle";
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.0001, at);
      gain.gain.exponentialRampToValueAtTime(0.22, at + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.85);
      osc.connect(gain);
      gain.connect(ac.destination);
      osc.start(at);
      osc.stop(at + 0.9);
    });

    // Low sine underneath, so the arpeggio has a floor to sit on.
    const pad = ac.createOscillator();
    const padGain = ac.createGain();
    pad.type = "sine";
    pad.frequency.value = 220;
    padGain.gain.setValueAtTime(0.0001, now);
    padGain.gain.exponentialRampToValueAtTime(0.1, now + 0.25);
    padGain.gain.exponentialRampToValueAtTime(0.0001, now + 1.6);
    pad.connect(padGain);
    padGain.connect(ac.destination);
    pad.start(now);
    pad.stop(now + 1.7);
  });
}

/** Short, dry confirmation that a set went into the log. Deliberately quiet
 *  and low — it's an acknowledgement, not an event. */
export function confirmTone(): void {
  cue(500, (ac, at) => {
    const osc = ac.createOscillator();
    const gain = ac.createGain();
    osc.type = "sine";
    osc.frequency.setValueAtTime(520, at);
    osc.frequency.exponentialRampToValueAtTime(660, at + 0.07);
    gain.gain.setValueAtTime(0.0001, at);
    gain.gain.exponentialRampToValueAtTime(0.16, at + 0.01);
    gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.14);
    osc.connect(gain);
    gain.connect(ac.destination);
    osc.start(at);
    osc.stop(at + 0.16);
  });
}

/** Fires the instant the rep counter passes what you did last time. This is
 *  the moment the whole program is built around, and it happens while you're
 *  still holding the weight — so it gets its own sound rather than being
 *  discovered later on the summary screen. */
export function beatIt(): void {
  cue(800, (ac, at) => {
    [784, 1046.5].forEach((freq, i) => {
      const t = at + i * 0.075;
      const osc = ac.createOscillator();
      const gain = ac.createGain();
      osc.type = "triangle";
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.0001, t);
      gain.gain.exponentialRampToValueAtTime(0.2, t + 0.012);
      gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.28);
      osc.connect(gain);
      gain.connect(ac.destination);
      osc.start(t);
      osc.stop(t + 0.3);
    });
  });
}

/** Best-effort haptic. iOS Safari still has no Vibration API, so this only
 *  does anything on Android and desktop Chrome — it's a bonus where it exists,
 *  never something the feedback depends on. */
export function buzz(pattern: number | number[] = 12): void {
  try {
    (navigator as unknown as { vibrate?: (p: number | number[]) => boolean })
      .vibrate?.(pattern);
  } catch {
    /* ignore */
  }
}

/* --- the countdown -------------------------------------------------------
 * The last five seconds of every timer climb a C-major pentatonic run and
 * resolve an octave up at zero:
 *
 *     5s  C5    4s  D5    3s  E5    2s  G5    1s  A5   →  0s  C6
 *
 * Ascending on purpose. A rising line reads as tension building toward "go";
 * a falling one reads as winding down, which is the opposite of what you want
 * in the two seconds before a set. Each step is also a little louder and a
 * little longer than the last, so you can tell where you are in the count
 * without listening for the pitch — useful when the phone is on the floor and
 * you're face-down over it.
 *
 * Each tick holds the session for 1.4s, comfortably past the next tick, so the
 * whole count-in and the "go" beep are one unbroken hold: your music dips once
 * at five and comes back once after zero.
 * ----------------------------------------------------------------------- */

const COUNTDOWN: Record<number, { hz: number; gain: number; len: number }> = {
  5: { hz: 523.25, gain: 0.1, len: 0.1 },
  4: { hz: 587.33, gain: 0.12, len: 0.11 },
  3: { hz: 659.25, gain: 0.15, len: 0.12 },
  2: { hz: 783.99, gain: 0.19, len: 0.13 },
  1: { hz: 880.0, gain: 0.24, len: 0.15 },
};

/** One step of the count-in. `secondsLeft` is 5 down to 1. */
export function countdownTick(secondsLeft: number): void {
  const note = COUNTDOWN[secondsLeft];
  if (!note) return;
  cue(1400, (ac, at) => {
    const osc = ac.createOscillator();
    const gain = ac.createGain();
    osc.type = "triangle";
    osc.frequency.value = note.hz;
    gain.gain.setValueAtTime(0.0001, at);
    gain.gain.exponentialRampToValueAtTime(note.gain, at + 0.008);
    gain.gain.exponentialRampToValueAtTime(0.0001, at + note.len);
    osc.connect(gain);
    gain.connect(ac.destination);
    osc.start(at);
    osc.stop(at + note.len + 0.02);
  });
}
