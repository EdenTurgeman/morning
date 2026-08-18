/* ---------------------------------------------------------------------------
 * SOUND
 *
 * Everything is synthesised with oscillators — no audio files, nothing to
 * load, works offline. Getting it to actually come out of an iPhone takes
 * three separate things, and missing any one of them means silence:
 *
 * 1. A user gesture. iOS won't start an AudioContext without one.
 *
 * 2. The right audio session. Web Audio defaults to the "ambient" category on
 *    iOS, which the ring/silent switch mutes — HTML5 <audio> is exempt, Web
 *    Audio is not. iOS 16.4+ exposes navigator.audioSession, so we can ask for
 *    "playback" and be heard with the switch on. Older versions get the
 *    long-standing workaround: a looping near-silent <audio> element, which
 *    holds a non-ambient session for the page.
 *
 * 3. Resuming after suspension. iOS suspends the context every time the page
 *    is hidden. An earlier version of this file simply returned when the
 *    context wasn't running, so the first screen lock or app switch killed
 *    every sound for the rest of the session. Now every cue resumes first, and
 *    we also resume on visibilitychange.
 *
 * Even with all of that, a phone in Silent mode on iOS below 16.4 cannot be
 * made to beep from a web app. isAudioBlocked() reports that so the UI can say
 * so rather than leaving you wondering.
 * ------------------------------------------------------------------------- */

let ctx: AudioContext | null = null;
let keepAlive: HTMLAudioElement | null = null;

type WebkitWindow = Window & { webkitAudioContext?: typeof AudioContext };
interface AudioSessionNav {
  audioSession?: { type: string };
}

/** Ask iOS to treat this page as playback rather than ambient, so the ring
 *  switch doesn't mute it. Safari-only and still an editor's draft, hence the
 *  feature test. */
function claimPlaybackSession(): void {
  try {
    const session = (navigator as unknown as AudioSessionNav).audioSession;
    if (session) session.type = "playback";
  } catch {
    /* not supported */
  }
}

/** A near-silent looping element. On iOS versions without the AudioSession
 *  API this is the only lever available: media elements aren't governed by the
 *  ambient category, so holding one open keeps the page's session out of it.
 *  Volume is 0.001 rather than 0 — a genuinely silent stream gets optimised
 *  away and the trick stops working. */
function startKeepAlive(): void {
  if (keepAlive) return;
  try {
    const sampleRate = 8000;
    const samples = sampleRate / 2;
    const buf = new ArrayBuffer(44 + samples);
    const view = new DataView(buf);
    const ascii = (off: number, text: string) => {
      for (let i = 0; i < text.length; i++) view.setUint8(off + i, text.charCodeAt(i));
    };
    ascii(0, "RIFF");
    view.setUint32(4, 36 + samples, true);
    ascii(8, "WAVEfmt ");
    view.setUint32(16, 16, true);
    view.setUint16(20, 1, true); // PCM
    view.setUint16(22, 1, true); // mono
    view.setUint32(24, sampleRate, true);
    view.setUint32(28, sampleRate, true);
    view.setUint16(32, 1, true);
    view.setUint16(34, 8, true); // 8-bit
    ascii(36, "data");
    view.setUint32(40, samples, true);
    for (let i = 0; i < samples; i++) view.setUint8(44 + i, 128); // 8-bit silence

    const el = document.createElement("audio");
    el.setAttribute("playsinline", "");
    el.loop = true;
    el.volume = 0.001;
    el.src = URL.createObjectURL(new Blob([buf], { type: "audio/wav" }));
    void el.play().catch(() => {});
    keepAlive = el;
  } catch {
    /* best effort */
  }
}

export function unlockAudio(): void {
  try {
    claimPlaybackSession();
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
    startKeepAlive();
    if (ctx.state === "suspended") void ctx.resume();
  } catch {
    /* no audio — the countdown still advances visually */
  }
}

/** Called before every cue. Returns the context only if it can make sound,
 *  and kicks off a resume when it can't — which is what makes sound survive a
 *  screen lock mid-session. */
function live(): AudioContext | null {
  const ac = ctx;
  if (!ac) return null;
  if (ac.state !== "running") {
    // resume() is async, so this cue is likely lost — but it restores sound
    // for every cue after it, which is the difference between "silent after
    // the first screen lock" and "silent for one beep".
    void ac.resume().catch(() => {});
    claimPlaybackSession();
    return (ac.state as AudioContextState) === "running" ? ac : null;
  }
  return ac;
}

/** True when we have a context but iOS is refusing to run it — almost always
 *  the ring/silent switch on a version without the AudioSession API. */
export function isAudioBlocked(): boolean {
  return ctx !== null && ctx.state !== "running";
}

export function audioReady(): boolean {
  return ctx !== null && ctx.state === "running";
}

/** True when the browser can opt out of the silent switch at all. */
export function supportsPlaybackSession(): boolean {
  return Boolean((navigator as unknown as AudioSessionNav).audioSession);
}

if (typeof document !== "undefined") {
  // iOS suspends the context whenever the page hides. Resume on the way back,
  // or every cue after the first backgrounding is silent.
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible" && ctx && ctx.state !== "running") {
      void ctx.resume().catch(() => {});
      claimPlaybackSession();
      void keepAlive?.play().catch(() => {});
    }
  });
}

/** Rising two- or three-note chime. The last note is pitched higher so "go"
 *  is distinguishable from "counting" without looking at the screen. */
export function beep(notes = 3): void {
  const ac = live();
  if (!ac) return;
  try {
    for (let i = 0; i < notes; i++) {
      const osc = ac.createOscillator();
      const gain = ac.createGain();
      const at = ac.currentTime + i * 0.19;

      osc.type = "sine";
      osc.frequency.value = i === notes - 1 ? 1180 : 840;

      // Exponential ramps rather than a hard start/stop, so it reads as a
      // chime instead of a click.
      gain.gain.setValueAtTime(0.0001, at);
      gain.gain.exponentialRampToValueAtTime(0.35, at + 0.012);
      gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.16);

      osc.connect(gain);
      gain.connect(ac.destination);
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
  const ac = live();
  if (!ac) return;
  try {
    const now = ac.currentTime;
    // A4 · C#5 · E5 · A5 — a plain A major triad resolving up the octave.
    const notes = [440, 554.37, 659.25, 880];

    notes.forEach((freq, i) => {
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
  } catch {
    /* ignore */
  }
}

/** Short, dry confirmation that a set went into the log. Deliberately quiet
 *  and low — it's an acknowledgement, not an event. */
export function confirmTone(): void {
  const ac = live();
  if (!ac) return;
  try {
    const at = ac.currentTime;
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
  } catch {
    /* ignore */
  }
}

/** Fires the instant the rep counter passes what you did last time. This is
 *  the moment the whole program is built around, and it happens while you're
 *  still holding the weight — so it gets its own sound rather than being
 *  discovered later on the summary screen. */
export function beatIt(): void {
  const ac = live();
  if (!ac) return;
  try {
    const at = ac.currentTime;
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
  const ac = live();
  if (!ac) return;
  try {
    const osc = ac.createOscillator();
    const gain = ac.createGain();
    const at = ac.currentTime;
    osc.type = "sine";
    osc.frequency.value = 620;
    gain.gain.setValueAtTime(0.0001, at);
    gain.gain.exponentialRampToValueAtTime(0.12, at + 0.008);
    gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.09);
    osc.connect(gain);
    gain.connect(ac.destination);
    osc.start(at);
    osc.stop(at + 0.1);
  } catch {
    /* ignore */
  }
}
