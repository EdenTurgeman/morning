#!/usr/bin/env bash
# =============================================================================
#  shoot.sh — build, boot, launch and screenshot one surface of the app.
#
#    ./scripts/shoot.sh set                          the Set screen
#    ./scripts/shoot.sh set -session B -step 15      pass anything through
#    ./scripts/shoot.sh set --out set-longest -slot 4.0.0
#    ./scripts/shoot.sh all                          every surface in spec.md §3
#
#  Written for R0 of ios/Docs/redesign-plan.md. Every phase after it depends on
#  being able to look at a screen cheaply, and R3 cannot run at all without it.
#
#  WHY THIS IS A FILE AND NOT A SHELL FUNCTION
#  ------------------------------------------------------------------------
#  It has been re-derived ad hoc in every session that needed it, and it broke
#  once already: zsh does not word-split unquoted parameters, so
#
#      shoot history "-screen history"
#
#  passed ONE argument containing a space, the app matched no flag, and four
#  surfaces silently rendered Home. Nobody noticed until the shots were compared.
#  Here the app's arguments are real argv from "$@" and never a split string.
#
#  SCRIPT FLAGS ARE `--long`, THE APP'S ARE `-short`
#  ------------------------------------------------------------------------
#  Deliberate, so the two can never collide and everything after the target name
#  can be forwarded verbatim without a parser that has to know the app's flags.
#
#      --out NAME     output stem            (default: the target name)
#      --delay SEC    wait before capturing  (default: 4.0, see below)
#      --device NAME  simulator              (default: iPhone 16 Pro)
#      --no-build     skip xcodebuild
#      --keep         leave the app running after the shot
#      --open         open the PNG when done
#
#  THE DELAY IS NOT PADDING
#  ------------------------------------------------------------------------
#  `simctl launch` returns when the process starts, not when a frame is on
#  screen. The Metal pipeline compile alone was once 3.3s. Capture too early and
#  you photograph a launch screen, which looks like a black screen, which looks
#  like a broken surface. 4s is measured slack, not superstition.
#
#  THE SEED IS ALWAYS EXPLICIT
#  ------------------------------------------------------------------------
#  `-seed` WRITES to the store, so the seed from your last launch is still there
#  on the next one and a shot taken without a seed is a shot of whatever you did
#  before. Every launch here names a seed unless you name one yourself. That is
#  the difference between a screenshot and a measurement.
# =============================================================================
set -uo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

DEVICE="iPhone 16 Pro"
BUNDLE="com.edenturgeman.morning"
DD="$ROOT/ios/build/dd"
SHOTS="$ROOT/ios/build/shots"
DELAY="4.0"
BUILD=1
KEEP=0
OPEN=0
OUT=""
DEFAULT_SEED="six-months"

die() { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }
note() { printf '\033[2m%s\033[0m\n' "$*" >&2; }

# --- the surfaces ------------------------------------------------------------
# The eleven of spec.md §3, plus the review-only hosts that are not surfaces but
# are how the parts get looked at. Kept as a function returning an array rather
# than an associative array of strings, because these ARE argument vectors and
# flattening them to strings is the exact bug in the header.
surface_args() {
  case "$1" in
    # 3.1  Home. No `-screen`: MorningApp falls through to AppRoot, which is the
    #      real app, not a review host. Passing `-screen home` happens to work
    #      today only because the string matches nothing; not relied on.
    home)          ARGS=() ;;
    # 3.2  Warm-up. Step 0 of any session. `-step` outranks `startAtFirstSet`.
    warmup)        ARGS=(-screen set -step 0) ;;
    # 3.3  Set.
    set)           ARGS=(-screen set) ;;
    # 3.4  Rest. There is NO `-screen rest` — rest is reached through the set
    #      host at a step that is a rest, which is also how the app reaches it.
    #
    #      Three of them, because they are three different screens and shooting
    #      only the first would have shown the one with the least on it:
    #        rest       A step 2  · 60s, no card (Deck: never the first long rest)
    #        rest-card  A step 6  · 60s, carries a card
    #        rest-myo   B step 17 · 20s, the myo rest — no card, ever
    rest)          ARGS=(-screen set -session A -step 2) ;;
    rest-card)     ARGS=(-screen set -session A -step 6) ;;
    rest-myo)      ARGS=(-screen set -session B -step 17) ;;
    # 3.5  The completion moment, playing over the summary.
    daybreak)      ARGS=(-screen summary) ;;
    # 3.6  Summary, with the choreography skipped so the screen itself is what
    #      lands in the PNG.
    summary)       ARGS=(-screen summary -skip-daybreak) ;;
    # 3.7 – 3.10  The reading surfaces, by their HomeDestination raw value.
    history)       ARGS=(-screen history) ;;
    ledger)        ARGS=(-screen ledger) ;;
    guide)         ARGS=(-screen guide) ;;
    backup)        ARGS=(-screen backup) ;;
    # 3.11  The Live Activity's Lock Screen presentation, hosted inside the app
    #       because a Widget cannot be shown from one and this machine has no
    #       Lock Screen to reach.
    live-activity) ARGS=(-screen live-activity) ;;
    # Review hosts. Not surfaces — instruments.
    figures)       ARGS=(-screen figures) ;;
    sky)           ARGS=(-screen sky) ;;
    lab)           ARGS=(-screen lab) ;;
    *)             ARGS=(-screen "$1") ;;
  esac
}

# The step indices above ARE hardcoded, and they are the one thing in this file
# that can rot without saying so: they come from Program.swift's block list and
# Deck.cardRestIndices, and editing the program moves them. They were worked out
# by hand and then checked against a render, which is the only check that counts.
#
#   A: 0 warm-up · 1,3,5 push-up sets · 2,4,6 rests(60) · 7-15 superset+rests(45)
#      · 16-20 superset, trailing rest dropped                       = 21 steps
#   B: as A to step 15, then 16-21 the myo block, 3 sets w/ rests(20)
#      · 22-24 floor fly, trailing rest dropped                      = 25 steps
#
# `MorningTests/Acceptance` already asserts both compiled lengths, so a program
# change fails there first. If it ever fails HERE instead, the symptom is a shot
# of a set screen in a file named rest.png — look at the PNG, not at the name.
ALL=(home warmup set rest rest-card rest-myo daybreak summary history ledger guide backup live-activity)

# --- arguments ---------------------------------------------------------------
[[ $# -ge 1 ]] || die "usage: shoot.sh <target|all> [--out NAME] [--delay SEC] [app args...]
targets: ${ALL[*]} figures sky lab"

TARGET="$1"; shift

APP_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)    OUT="$2"; shift 2 ;;
    --delay)  DELAY="$2"; shift 2 ;;
    --device) DEVICE="$2"; shift 2 ;;
    --no-build) BUILD=0; shift ;;
    --keep)   KEEP=1; shift ;;
    --open)   OPEN=1; shift ;;
    --help|-h) sed -n '2,48p' "$0"; exit 0 ;;
    *) APP_ARGS+=("$1"); shift ;;
  esac
done

# --- build -------------------------------------------------------------------
APP="$DD/Build/Products/Debug-iphonesimulator/Morning.app"
if [[ $BUILD -eq 1 ]]; then
  note "building…"
  if ! xcodebuild build \
      -project ios/Morning.xcodeproj -scheme Morning \
      -destination "platform=iOS Simulator,name=$DEVICE" \
      -derivedDataPath "$DD" CODE_SIGNING_ALLOWED=NO \
      >"$ROOT/ios/build/shoot-build.log" 2>&1; then
    grep -E 'error:' "$ROOT/ios/build/shoot-build.log" | sort -u | head -20 >&2
    die "build failed — full output in ios/build/shoot-build.log"
  fi
fi
[[ -d "$APP" ]] || die "no app at $APP (run without --no-build)"

# --- device ------------------------------------------------------------------
UDID="$(xcrun simctl list devices available \
        | grep -F "$DEVICE (" | head -1 \
        | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
[[ -n "$UDID" ]] || die "no available simulator named '$DEVICE'"

if ! xcrun simctl list devices | grep -F "$UDID" | grep -q Booted; then
  note "booting $DEVICE…"
  xcrun simctl boot "$UDID" || die "boot failed"
  xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
fi

xcrun simctl install "$UDID" "$APP" >/dev/null || die "install failed"

# --- one shot ----------------------------------------------------------------
mkdir -p "$SHOTS"

shoot_one() {
  local target="$1"; shift
  local stem="${OUT:-$target}"
  local png="$SHOTS/$stem.png"

  surface_args "$target"
  local launch=(${ARGS[@]+"${ARGS[@]}"} ${APP_ARGS[@]+"${APP_ARGS[@]}"})

  # Determinism: name a seed unless the caller already did. See the header.
  local has_seed=0
  for a in ${launch[@]+"${launch[@]}"}; do [[ "$a" == "-seed" ]] && has_seed=1; done
  [[ $has_seed -eq 1 ]] || launch+=(-seed "$DEFAULT_SEED")

  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1
  if ! xcrun simctl launch "$UDID" "$BUNDLE" "${launch[@]}" >/dev/null 2>&1; then
    die "launch failed: ${launch[*]}"
  fi

  # `sleep` here is not laziness — there is no "first frame drawn" signal
  # simctl will give you. The alternative is polling screenshots, which costs
  # more time than it saves.
  sleep "$DELAY"
  xcrun simctl io "$UDID" screenshot --type=png "$png" >/dev/null 2>&1 \
    || die "screenshot failed for $target"

  [[ $KEEP -eq 1 ]] || xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1

  local size
  size="$(sips -g pixelWidth -g pixelHeight "$png" 2>/dev/null \
          | awk '/pixel/ {printf "%s ", $2}' | sed 's/ $//' | tr ' ' 'x')"
  printf '%-16s %s  (%s)\n' "$target" "${png#"$ROOT"/}" "$size"
}

if [[ "$TARGET" == "all" ]]; then
  for s in "${ALL[@]}"; do
    OUT="" shoot_one "$s"
  done
else
  shoot_one "$TARGET"
fi

[[ $OPEN -eq 1 ]] && open "$SHOTS/${OUT:-$TARGET}.png"
exit 0
