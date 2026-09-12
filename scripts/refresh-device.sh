#!/usr/bin/env bash
# =============================================================================
#  refresh-device.sh — build Morning and install it on Eden's iPhone.
#
#    ./scripts/refresh-device.sh                 build + install, talk about it
#    ./scripts/refresh-device.sh --quiet-absent  say nothing if no phone is here
#    ./scripts/refresh-device.sh --debug         Debug instead of Release
#    ./scripts/refresh-device.sh --device NAME   pick a specific device
#
#  WHY THIS EXISTS
#  ---------------------------------------------------------------------------
#  Signed with a FREE Apple ID, an iOS app's provisioning profile lasts **seven
#  days**. On day eight the app stops launching — it does not lose data, it just
#  refuses to open until it is re-signed. Re-signing is a rebuild, so this is a
#  rebuild on a timer.
#
#  `-allowProvisioningUpdates` is the whole trick: it lets `xcodebuild` renew
#  the profile without anybody opening Xcode, which is what makes a launchd job
#  possible. See `scripts/refresh-device.plist`.
#
#  RELEASE, NOT DEBUG, BY DEFAULT
#  ---------------------------------------------------------------------------
#  ⌘R from Xcode builds Debug and that is right for debugging. This is the build
#  Eden actually trains on, and `02-design-brief.md` asks for 120Hz with no
#  dropped frames during a timer — a Debug build is the wrong thing to measure
#  that on, let alone to use at 6:10am.
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CONFIG="Release"
QUIET_ABSENT=0
WANT_DEVICE=""
DD="$ROOT/ios/build/device"
LOG="$ROOT/ios/build/refresh.log"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug)        CONFIG="Debug"; shift ;;
    --quiet-absent) QUIET_ABSENT=1; shift ;;
    --device)       WANT_DEVICE="$2"; shift 2 ;;
    -h|--help)      sed -n '2,12p' "$0"; exit 0 ;;
    *)              echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$(dirname "$LOG")"
say() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"; }
die() { say "FAILED: $*"; exit 1; }

# --- is a real phone here? ---------------------------------------------------
# `reality` separates a physical device from a simulator; simulators are always
# "here" and installing into one is not what this script is for.
DEVJSON="$(mktemp)"
trap 'rm -f "$DEVJSON"' EXIT
xcrun devicectl list devices --json-output "$DEVJSON" --quiet >/dev/null 2>&1 || true

# Prints "<udid> <ddi>" for the first matching physical iPhone.
#
# `ddi` is whether the Developer Disk Image is mounted. Without it the device
# reads "connected (no DDI)" and `xcodebuild` sits there until it times out
# with "Connecting to iPhone. Xcode will continue when the operation
# completes" — which says nothing about what is actually wrong.
FOUND="$(python3 - "$DEVJSON" "$WANT_DEVICE" <<'PYEOF'
import json, sys
path, want = sys.argv[1], sys.argv[2]
try:
    devices = json.load(open(path)).get("result", {}).get("devices", [])
except Exception:
    devices = []
for device in devices:
    hardware = device.get("hardwareProperties", {})
    if hardware.get("reality") != "physical" or hardware.get("platform") != "iOS":
        continue
    properties = device.get("deviceProperties", {})
    name = properties.get("name", "")
    udid = hardware.get("udid", "")
    if want and want not in (name, udid):
        continue
    print(udid, "ddi" if properties.get("ddiServicesAvailable") else "no-ddi")
    break
PYEOF
)"
UDID="${FOUND%% *}"
DDI="${FOUND##* }"

if [[ -n "$UDID" && "$DDI" == "no-ddi" ]]; then
  # The phone is there but not prepared. Normal on a first connection or after
  # a restart, and it resolves once the device is UNLOCKED — the image will not
  # mount on a locked phone. A launchd run should shrug and retry later.
  [[ $QUIET_ABSENT -eq 1 ]] && exit 0
  die "the phone is connected but not prepared for development (no DDI). Unlock it and leave it unlocked, open Xcode > Window > Devices and Simulators, wait for 'Preparing iPhone for development' to finish, then run this again."
fi

if [[ -z "$UDID" ]]; then
  # A launchd job runs whether or not the phone is on the network. Absence is
  # the normal case, not a failure, and logging it every hour would bury the
  # one line that matters on the day something actually breaks.
  [[ $QUIET_ABSENT -eq 1 ]] && exit 0
  die "no physical iOS device is paired. Plug the phone in, or enable Xcode > Window > Devices and Simulators > Connect via Network."
fi

# --- is it signable? ---------------------------------------------------------
if ! grep -qE 'DEVELOPMENT_TEAM = [A-Z0-9]+' ios/Morning.xcodeproj/project.pbxproj; then
  die "no DEVELOPMENT_TEAM in the project. Open ios/Morning.xcodeproj and set Team on BOTH the Morning and MorningWidgets targets — the widget is the one people miss."
fi

say "building $CONFIG for $UDID"
if ! xcodebuild build \
      -project ios/Morning.xcodeproj \
      -scheme Morning \
      -configuration "$CONFIG" \
      -destination "id=$UDID" \
      -derivedDataPath "$DD" \
      -allowProvisioningUpdates \
      -destination-timeout 600 \
      >>"$LOG" 2>&1; then
  grep -E 'error:' "$LOG" | tail -5 >&2 || true
  die "build failed — full output in ${LOG#"$ROOT"/}"
fi

APP="$DD/Build/Products/$CONFIG-iphoneos/Morning.app"
[[ -d "$APP" ]] || die "built, but no app at ${APP#"$ROOT"/}"

say "installing"
if ! xcrun devicectl device install app --device "$UDID" "$APP" >>"$LOG" 2>&1; then
  tail -5 "$LOG" >&2
  die "install failed — full output in ${LOG#"$ROOT"/}"
fi

say "done. Morning is re-signed for another seven days."
