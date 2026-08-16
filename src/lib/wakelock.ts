/* The screen must not sleep between sets. iOS drops the wake lock whenever the
 * page is hidden, so it has to be re-acquired on the way back — hence the
 * `desired` flag rather than just holding the sentinel. */

let sentinel: WakeLockSentinel | null = null;
let desired = false;

export async function setWakeLock(on: boolean): Promise<void> {
  desired = on;
  try {
    if (on) {
      if ("wakeLock" in navigator && !sentinel) {
        sentinel = await navigator.wakeLock.request("screen");
        sentinel.addEventListener("release", () => {
          sentinel = null;
        });
      }
    } else if (sentinel) {
      await sentinel.release();
      sentinel = null;
    }
  } catch {
    /* Safari refuses when the page isn't visible; the visibilitychange
       listener below retries. */
  }
}

if (typeof document !== "undefined") {
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible" && desired && !sentinel) {
      void setWakeLock(true);
    }
  });
}
