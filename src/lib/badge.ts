/* ---------------------------------------------------------------------------
 * Home-screen icon badge.
 *
 * iOS 16.4+ gives installed web apps the Badging API, so the icon can carry a
 * number the way a native app's does. This app puts the sessions you still owe
 * this week there — so the home screen answers "am I behind?" without you
 * opening anything. The badge clears itself the moment the week is complete.
 *
 * Only works from the installed home-screen app, never from a Safari tab, and
 * the first call may prompt for notification permission on some versions —
 * so this is strictly best-effort and never blocks or throws.
 * ------------------------------------------------------------------------- */

interface BadgeNavigator {
  setAppBadge?: (count?: number) => Promise<void>;
  clearAppBadge?: () => Promise<void>;
}

const nav = () => navigator as unknown as BadgeNavigator;

export function supportsBadge(): boolean {
  return typeof nav().setAppBadge === "function";
}

export function setWeekBadge(remaining: number): void {
  const n = nav();
  try {
    if (remaining > 0) void n.setAppBadge?.(remaining)?.catch(() => {});
    else void n.clearAppBadge?.()?.catch(() => {});
  } catch {
    /* not supported, or not installed to the home screen */
  }
}
