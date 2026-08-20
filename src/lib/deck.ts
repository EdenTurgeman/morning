import { CARDS, type Card, type Subject } from "@/lib/cards";
import type { Step } from "@/lib/steps";

/* ---------------------------------------------------------------------------
 * Rotation, and how often a card is allowed to interrupt you.
 *
 * Draws without replacement: nothing repeats until the whole deck has been
 * seen, then it starts over. Random-with-replacement would show the same card
 * twice in a session often enough to be irritating, and a fixed order would
 * make the first cards familiar and the last ones perpetually unseen.
 *
 * Progress lives under its own localStorage key rather than in AppData. It is
 * genuinely disposable — losing it just restarts the cycle — and keeping it
 * out of AppData keeps the backup file about training, which is the thing that
 * actually matters if it is ever lost.
 * ------------------------------------------------------------------------- */

const SEEN_KEY = "mub_cards_seen_v1";

/** Rests shorter than this don't get a card. The 20s myo rest is the mechanism
 *  of the technique — anything inviting you to linger there breaks it. */
export const MIN_REST_FOR_CARD = 45;

/* Short-term memory, in module scope on purpose: it exists only to stop the
 * same card turning up twice in one sitting, and a reload ends the sitting.
 * Callers don't have to thread ids through the component tree to get that. */
const RECENT_LIMIT = 8;
const recent: string[] = [];

function remember(id: string): void {
  recent.push(id);
  if (recent.length > RECENT_LIMIT) recent.shift();
}

function readSeen(): Set<string> {
  try {
    const raw = localStorage.getItem(SEEN_KEY);
    if (!raw) return new Set();
    const ids: unknown = JSON.parse(raw);
    return Array.isArray(ids) ? new Set(ids.filter((i) => typeof i === "string")) : new Set();
  } catch {
    return new Set();
  }
}

function writeSeen(seen: Set<string>): void {
  try {
    localStorage.setItem(SEEN_KEY, JSON.stringify([...seen]));
  } catch {
    /* rotation is disposable — never let it break a workout */
  }
}

/** Cards not yet drawn this cycle. Ids that no longer exist in the deck are
 *  ignored, so removing a card can never strand the rotation. */
function remaining(seen: Set<string>, subjects?: readonly Subject[]): Card[] {
  const pool = subjects?.length
    ? CARDS.filter((c) => subjects.includes(c.subject))
    : [...CARDS];
  return pool.filter((c) => !seen.has(c.id));
}

/**
 * Draw one card and mark it seen.
 *
 * Recently drawn cards are held back automatically, so a session that shows
 * three cards never shows the same one twice — even across a cycle boundary.
 */
export function drawCard(): Card | null {
  if (CARDS.length === 0) return null;

  const seen = readSeen();
  let pool = remaining(seen).filter((c) => !recent.includes(c.id));

  // Cycle exhausted: reshuffle, still holding back what you just saw.
  if (pool.length === 0) {
    seen.clear();
    pool = CARDS.filter((c) => !recent.includes(c.id));
    if (pool.length === 0) pool = [...CARDS];
  }

  const card = pool[Math.floor(Math.random() * pool.length)];
  seen.add(card.id);
  writeSeen(seen);
  remember(card.id);
  return card;
}

/**
 * Which rest steps carry a card.
 *
 * Two per session — not one per long rest. Session A has seven rests of 45s or
 * more; eight cards in twenty minutes turns a workout into homework, and each
 * one lands less than the one before. Two land properly and leave the rest of
 * the session about lifting.
 *
 * They're taken from roughly the first and third quarter of the long rests so
 * they're spread across the session, and never from the very first one — that
 * rest is spent getting your breath back after the opening set, not reading.
 */
export function cardRestIndices(steps: readonly Step[]): readonly number[] {
  const long: number[] = [];
  steps.forEach((s, i) => {
    if (s.kind === "rest" && s.seconds >= MIN_REST_FOR_CARD) long.push(i);
  });
  if (long.length <= 1) return long;

  const at = (fraction: number) =>
    long[Math.min(long.length - 1, Math.max(1, Math.round(long.length * fraction)))];
  return [...new Set([at(0.25), at(0.72)])];
}

/**
 * How long to think before the answer appears by itself.
 *
 * Scaled to the rest, then clamped: never so fast that a 45s rest gives you no
 * chance to work it out, never so slow that a 90s rest runs out before you've
 * read the answer.
 */
export function revealDelayFor(restSeconds: number): number {
  return Math.round(Math.min(11000, Math.max(6500, restSeconds * 160)));
}

/** How far through the current cycle you are — for the deck screen, later. */
export function deckProgress(): { seen: number; total: number } {
  const seen = readSeen();
  const valid = CARDS.filter((c) => seen.has(c.id)).length;
  return { seen: valid, total: CARDS.length };
}

export function resetDeck(): void {
  try {
    localStorage.removeItem(SEEN_KEY);
  } catch {
    /* ignore */
  }
  recent.length = 0;
}
