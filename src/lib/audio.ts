/* iOS refuses to make a sound until the page has had a user gesture, and a
 * suspended AudioContext stays suspended forever if you don't resume it inside
 * one. So: create + resume on the first touch, then synthesise every beep with
 * an oscillator. No audio files, nothing to load, works offline. */

let ctx: AudioContext | null = null;

type WebkitWindow = Window & { webkitAudioContext?: typeof AudioContext };

export function unlockAudio(): void {
  try {
    if (!ctx) {
      const Ctor =
        window.AudioContext ?? (window as WebkitWindow).webkitAudioContext;
      if (!Ctor) return;
      ctx = new Ctor();
      // A one-sample silent buffer is the canonical way to convince WebKit the
      // context is genuinely gesture-initiated.
      const buffer = ctx.createBuffer(1, 1, 22050);
      const source = ctx.createBufferSource();
      source.buffer = buffer;
      source.connect(ctx.destination);
      source.start(0);
    }
    if (ctx.state === "suspended") void ctx.resume();
  } catch {
    /* no audio — the countdown still advances visually */
  }
}

/** Rising two- or three-note chime. The last note is pitched higher so "go"
 *  is distinguishable from "counting" without looking at the screen. */
export function beep(notes = 3): void {
  if (!ctx || ctx.state !== "running") return;
  try {
    for (let i = 0; i < notes; i++) {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      const at = ctx.currentTime + i * 0.19;

      osc.type = "sine";
      osc.frequency.value = i === notes - 1 ? 1180 : 840;

      // Exponential ramps rather than a hard start/stop, so it reads as a
      // chime instead of a click.
      gain.gain.setValueAtTime(0.0001, at);
      gain.gain.exponentialRampToValueAtTime(0.35, at + 0.012);
      gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.16);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(at);
      osc.stop(at + 0.18);
    }
  } catch {
    /* ignore */
  }
}

/** The session-complete flourish: a rising major arpeggio with a soft pad
 *  under it. Only ever plays once a session, on the Daybreak screen — which is
 *  what lets it be four times longer than the rest beep without wearing out. */
export function chime(): void {
  if (!ctx || ctx.state !== "running") return;
  try {
    const now = ctx.currentTime;
    // A4 · C#5 · E5 · A5 — a plain A major triad resolving up the octave.
    const notes = [440, 554.37, 659.25, 880];

    notes.forEach((freq, i) => {
      const at = now + i * 0.15;
      const osc = ctx!.createOscillator();
      const gain = ctx!.createGain();
      osc.type = "triangle";
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.0001, at);
      gain.gain.exponentialRampToValueAtTime(0.22, at + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.85);
      osc.connect(gain);
      gain.connect(ctx!.destination);
      osc.start(at);
      osc.stop(at + 0.9);
    });

    // Low sine underneath, so the arpeggio has a floor to sit on.
    const pad = ctx.createOscillator();
    const padGain = ctx.createGain();
    pad.type = "sine";
    pad.frequency.value = 220;
    padGain.gain.setValueAtTime(0.0001, now);
    padGain.gain.exponentialRampToValueAtTime(0.1, now + 0.25);
    padGain.gain.exponentialRampToValueAtTime(0.0001, now + 1.6);
    pad.connect(padGain);
    padGain.connect(ctx.destination);
    pad.start(now);
    pad.stop(now + 1.7);
  } catch {
    /* ignore */
  }
}

/** Short, dry confirmation that a set went into the log. Deliberately quiet
 *  and low — it's an acknowledgement, not an event. */
export function confirmTone(): void {
  if (!ctx || ctx.state !== "running") return;
  try {
    const at = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = "sine";
    osc.frequency.setValueAtTime(520, at);
    osc.frequency.exponentialRampToValueAtTime(660, at + 0.07);
    gain.gain.setValueAtTime(0.0001, at);
    gain.gain.exponentialRampToValueAtTime(0.16, at + 0.01);
    gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.14);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(at);
    osc.stop(at + 0.16);
  } catch {
    /* ignore */
  }
}

/** Fires the instant the rep counter passes what you did last time. This is
 *  the moment the whole program is built around, and it happens while you're
 *  still holding the weight — so it gets its own sound rather than being
 *  discovered later on the summary screen. */
export function beatIt(): void {
  if (!ctx || ctx.state !== "running") return;
  try {
    const at = ctx.currentTime;
    [784, 1046.5].forEach((freq, i) => {
      const t = at + i * 0.075;
      const osc = ctx!.createOscillator();
      const gain = ctx!.createGain();
      osc.type = "triangle";
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.0001, t);
      gain.gain.exponentialRampToValueAtTime(0.2, t + 0.012);
      gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.28);
      osc.connect(gain);
      gain.connect(ctx!.destination);
      osc.start(t);
      osc.stop(t + 0.3);
    });
  } catch {
    /* ignore */
  }
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

/** Soft single tick, used for the last three seconds of a rest. */
export function tick(): void {
  if (!ctx || ctx.state !== "running") return;
  try {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    const at = ctx.currentTime;
    osc.type = "sine";
    osc.frequency.value = 620;
    gain.gain.setValueAtTime(0.0001, at);
    gain.gain.exponentialRampToValueAtTime(0.12, at + 0.008);
    gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.09);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(at);
    osc.stop(at + 0.1);
  } catch {
    /* ignore */
  }
}
