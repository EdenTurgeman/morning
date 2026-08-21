#!/usr/bin/env bash
# =============================================================================
#  One-shot environment setup for the Morning iOS port.
#
#  Idempotent — run it as often as you like. Run it first, every time you pick
#  this repo up on a new machine or in a new agent session.
#
#    ./scripts/bootstrap.sh            install what's missing and report
#    ./scripts/bootstrap.sh --check    report only, install nothing
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

FAILED=0

head_ "Platform"
if [[ "$(uname -s)" != "Darwin" ]]; then
  bad "Not macOS. The iOS port cannot be built anywhere else."
  bad "The web app still works here: npm install && npm run dev"
  exit 1
fi
ok "macOS $(sw_vers -productVersion) on $(uname -m)"

head_ "Xcode"
if ! xcode-select -p >/dev/null 2>&1; then
  bad "No developer directory. Install Xcode from the App Store, then:"
  bad "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  FAILED=1
elif [[ "$(xcode-select -p)" == *CommandLineTools* ]]; then
  bad "Only the Command Line Tools are selected — that cannot build an iOS app."
  bad "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  FAILED=1
else
  ok "$(xcodebuild -version | head -1) at $(xcode-select -p)"
  if xcrun simctl list devicetypes 2>/dev/null | grep -q "iPhone 16 Pro"; then
    ok "iPhone 16 Pro simulator available"
  else
    warn "No iPhone 16 Pro simulator. Xcode -> Settings -> Components."
  fi
fi

head_ "Tools"
brew_install() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    ok "$tool ($($tool --version 2>&1 | head -1))"
    return
  fi
  if $CHECK_ONLY; then bad "$tool missing — brew install $tool"; FAILED=1; return; fi
  if ! command -v brew >/dev/null 2>&1; then
    bad "$tool missing and Homebrew is not installed. See https://brew.sh"
    FAILED=1
    return
  fi
  echo "  installing $tool..."
  brew install "$tool" >/dev/null && ok "$tool installed"
}
brew_install swiftlint
brew_install swiftformat

if command -v node >/dev/null 2>&1; then
  ok "node $(node -v)"
else
  bad "node missing. The web app is the behaviour spec and you need to run it."
  FAILED=1
fi

head_ "Signing"
if grep -qE 'DEVELOPMENT_TEAM = [A-Z0-9]+' ios/Morning.xcodeproj/project.pbxproj 2>/dev/null; then
  ok "signing team set in the project"
else
  warn "No development team set. Fine for the simulator; to install on the phone,"
  warn "open the project -> Morning target -> Signing & Capabilities -> Team."
fi

head_ "Xcode project"
if [[ -f ios/Morning.xcodeproj/project.pbxproj ]]; then
  ok "ios/Morning.xcodeproj present (committed — open it directly)"
else
  bad "ios/Morning.xcodeproj is missing from the repo"
  FAILED=1
fi

head_ "Web app (the behaviour specification)"
if $CHECK_ONLY; then
  [[ -d node_modules ]] && ok "node_modules present" || warn "run npm install"
elif [[ -d node_modules ]]; then
  ok "node_modules present"
else
  echo "  npm install..."
  npm install --silent && ok "npm install done"
fi

head_ "Git hooks"
if $CHECK_ONLY; then
  [[ "$(git config core.hooksPath || true)" == ".githooks" ]] && ok "hooks active" || warn "not active"
else
  git config core.hooksPath .githooks
  chmod +x .githooks/* 2>/dev/null || true
  ok "core.hooksPath = .githooks (format + lint on commit)"
fi

head_ "MCP"
warn "ios-port/02-design-brief.md §4 requires the screensdesign MCP"
warn "(https://screensdesign.com) for the research pass. It is not in the"
warn "public connector registry — connect it in your client before starting"
warn "workstream W1, or that workstream cannot be done as specified."

head_ "Next"
cat <<'TXT'
  1. Read CLAUDE.md, then ios/Agents/00-handoff-log.md
  2. npm run dev  — then do a full session of A and a full session of B.
     You cannot design the replacement for something you have not used.
  3. open ios/Morning.xcodeproj  (⌘U runs 53 acceptance tests, all skipped)
  4. Pick up the first unclaimed workstream in ios/Agents/
TXT

if [[ $FAILED -eq 0 ]]; then
  printf '\n\033[32mEnvironment ready.\033[0m\n'
else
  printf '\n\033[31mEnvironment incomplete — see ✗ above.\033[0m\n'
  exit 1
fi
