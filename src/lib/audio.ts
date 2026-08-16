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
