#!/usr/bin/env bash
# =============================================================================
#  Full verification of the iOS environment. macOS only.
#
#    ./scripts/verify-ios.sh
#
#  Runs bootstrap, builds, tests, lints and format-checks,
#  then writes everything an agent needs to fix it to:
#
#    ios/build/verify-report.txt
#
#  Never aborts early — a failing phase is recorded and the next one still runs,
#  because the point is to collect ALL the errors in one pass, not the first one.
# =============================================================================
set -uo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
REPORT="$ROOT/ios/build/verify-report.txt"
RAW="$ROOT/ios/build/verify-raw.log"
mkdir -p "$ROOT/ios/build"
: >"$REPORT"
: >"$RAW"

DEST="${IOS_DEST:-platform=iOS Simulator,name=iPhone 16 Pro}"
PHASES=()

say()  { printf '%s\n' "$*" | tee -a "$REPORT"; }
rule() { say ""; say "=== $* ==============================================="; }
run()  { # run <phase name> <cmd...>
  local name="$1"; shift
  rule "$name"
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  printf '\n##### %s (exit %s)\n%s\n' "$name" "$rc" "$out" >>"$RAW"
  if [[ $rc -eq 0 ]]; then
    PHASES+=("PASS  $name")
    say "PASS (exit 0)"
    printf '%s\n' "$out" | tail -15 | sed 's/^/  | /' | tee -a "$REPORT" >/dev/null
  else
    PHASES+=("FAIL  $name (exit $rc)")
    say "FAIL (exit $rc)"
    say "--- errors ---"
    # Xcode, SwiftLint and SwiftFormat error formats, plus anything shouty
    printf '%s\n' "$out" \
      | grep -Ei '(error|warning):|^error|fatal|cannot find|no such module|has no member|Undefined symbol|xcodebuild: error|Command .* failed' \
      | sed 's/^/  /' | sort -u | head -80 | tee -a "$REPORT" >/dev/null
    say "--- last 40 lines of output ---"
    printf '%s\n' "$out" | tail -40 | sed 's/^/  | /' | tee -a "$REPORT" >/dev/null
  fi
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Not macOS. Nothing here can be verified." >&2
  exit 1
fi

rule "Environment"
{
  say "date            $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  say "macOS           $(sw_vers -productVersion) ($(uname -m))"
  say "xcode-select    $(xcode-select -p 2>&1)"
  say "xcodebuild      $(xcodebuild -version 2>&1 | tr '\n' ' ')"
  say "swift           $(swift --version 2>&1 | head -1)"
  say "swiftlint       $(swiftlint --version 2>&1 | head -1)"
  say "swiftformat     $(swiftformat --version 2>&1 | head -1)"
  say "node            $(node -v 2>&1)"
  say "destination     $DEST"
  say "git             $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)"
} 2>/dev/null

run "bootstrap"        ./scripts/bootstrap.sh
run "build"            xcodebuild build -project ios/Morning.xcodeproj -scheme Morning -destination "$DEST" -derivedDataPath ios/build/DerivedData CODE_SIGNING_ALLOWED=NO
run "test"             xcodebuild test  -project ios/Morning.xcodeproj -scheme Morning -destination "$DEST" -derivedDataPath ios/build/DerivedData CODE_SIGNING_ALLOWED=NO
run "swiftlint"        bash -c 'cd ios && swiftlint lint --config .swiftlint.yml'
run "swiftformat"      bash -c 'cd ios && swiftformat --lint --config .swiftformat .'
run "generators"       bash -c 'node ios/Tools/gen-seeds.mjs 2026-08-21 >/dev/null && git diff --quiet -- ios/Morning/Resources/Seeds && echo "seed generator is reproducible"'

rule "Acceptance suite"
say "assertions:       $(grep -rho 'func test[A-Z]' ios/MorningTests/Acceptance/ | wc -l | tr -d ' ')"
say "still skipped:    $(grep -rho '^        throw XCTSkip' ios/MorningTests/Acceptance/ | wc -l | tr -d ' ')"

rule "Summary"
for p in "${PHASES[@]}"; do say "$p"; done
FAILED=$(printf '%s\n' "${PHASES[@]}" | grep -c '^FAIL' || true)
say ""
say "phases failed: $FAILED"
say "full output:   ios/build/verify-raw.log"

printf '\n\033[1mReport written to ios/build/verify-report.txt\033[0m\n'
if [[ "$FAILED" -gt 0 ]]; then
  printf '\033[31m%s phase(s) failed.\033[0m Hand the report to the agent — it has every error in it.\n' "$FAILED"
  exit 1
fi
printf '\033[32mEnvironment verified.\033[0m\n'
