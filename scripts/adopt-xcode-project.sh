#!/usr/bin/env bash
# =============================================================================
#  One-time migration: XcodeGen spec  ->  a plain committed Morning.xcodeproj.
#
#    ./scripts/adopt-xcode-project.sh
#
#  Generates the project once, commits it, and removes every trace of the
#  generator — the spec, the xcodegen steps in bootstrap and CI, and finally
#  this script. Afterwards the repo has an ordinary Xcode project and no
#  project-generation tooling at all.
#
#  Why this rather than Xcode's New Project wizard: the wizard produces a
#  nested ios/Morning/Morning/ layout, which would mean moving every source
#  file and rewriting every path in the docs. This lands the project exactly
#  where everything already points.
#
#  Run once. It refuses to run twice.
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

ok()  { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad() { printf '  \033[31m✗\033[0m %s\n' "$1"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  bad "macOS only."
  exit 1
fi
if [[ ! -f ios/project.yml ]]; then
  bad "ios/project.yml is gone — this migration has already run."
  exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  bad "Working tree is dirty. Commit or stash first — this script commits for you."
  git status --short
  exit 1
fi

printf '\n\033[1m1. Generate the project\033[0m\n'
if ! command -v xcodegen >/dev/null 2>&1; then
  command -v brew >/dev/null 2>&1 || { bad "Homebrew needed to install xcodegen once. See https://brew.sh"; exit 1; }
  echo "  installing xcodegen (temporarily — you can uninstall it at the end)..."
  brew install xcodegen >/dev/null
fi
(cd ios && xcodegen generate)
[[ -f ios/Morning.xcodeproj/project.pbxproj ]] || { bad "generate produced no project.pbxproj"; exit 1; }
ok "ios/Morning.xcodeproj created ($(wc -l <ios/Morning.xcodeproj/project.pbxproj | tr -d ' ') lines of pbxproj)"

printf '\n\033[1m2. Track it instead of ignoring it\033[0m\n'
node - <<'JS'
const fs = require("fs");

// .gitignore: stop ignoring the project, keep ignoring per-user state inside it
let gi = fs.readFileSync(".gitignore", "utf8");
gi = gi.replace(
  `# The Xcode project is generated from ios/project.yml by XcodeGen. It is not
# checked in on purpose: a .pbxproj cannot be reviewed or merged.
ios/Morning.xcodeproj/
`,
  `# The Xcode project is a normal committed .xcodeproj. Only per-user state
# inside it is ignored.
ios/Morning.xcodeproj/project.xcworkspace/
`
);
fs.writeFileSync(".gitignore", gi);

// bootstrap.sh: no generator to install, no project to generate
let bs = fs.readFileSync("scripts/bootstrap.sh", "utf8");
bs = bs.replace("brew_install xcodegen\n", "");
bs = bs.replace(
  /head_ "Signing"[\s\S]*?head_ "Xcode project"[\s\S]*?\nfi\n/,
  `head_ "Signing"
if grep -q 'DEVELOPMENT_TEAM = ""' ios/Morning.xcodeproj/project.pbxproj 2>/dev/null; then
  warn "No development team set. Fine for the simulator; to install on the phone,"
  warn "open the project -> Morning target -> Signing & Capabilities -> Team."
else
  ok "signing team set in the project"
fi

head_ "Xcode project"
if [[ -f ios/Morning.xcodeproj/project.pbxproj ]]; then
  ok "ios/Morning.xcodeproj present (committed — open it directly)"
else
  bad "ios/Morning.xcodeproj is missing from the repo"
  FAILED=1
fi
`
);
fs.writeFileSync("scripts/bootstrap.sh", bs);

// verify-ios.sh: drop the generate phase
let v = fs.readFileSync("scripts/verify-ios.sh", "utf8");
v = v.replace(/run "xcodegen".*\n/, "");
v = v.replace("Runs bootstrap, generates the project, builds, tests, lints and format-checks,",
              "Runs bootstrap, builds, tests, lints and format-checks,");
v = v.replace("  say \"xcodegen        $(xcodegen --version 2>&1 | head -1)\"\n", "");
fs.writeFileSync("scripts/verify-ios.sh", v);

// CI: no xcodegen, no generate step, no xcconfig stub
let ci = fs.readFileSync(".github/workflows/ios.yml", "utf8");
ci = ci.replace("run: brew install xcodegen swiftlint swiftformat",
                "run: brew install swiftlint swiftformat");
ci = ci.replace(
  `      - name: Signing stub
        # CI builds for the simulator, which needs no team and no certificate.
        run: cp ios/Local.xcconfig.example ios/Local.xcconfig

      - name: Generate project
        run: cd ios && xcodegen generate

`,
  ""
);
fs.writeFileSync(".github/workflows/ios.yml", ci);

console.log("  patched .gitignore, scripts/bootstrap.sh, scripts/verify-ios.sh, .github/workflows/ios.yml");
JS
ok "generator removed from bootstrap, CI and the verify script"

printf '\n\033[1m3. Delete the generator\033[0m\n'
rm -f ios/project.yml ios/Local.xcconfig.example ios/Local.xcconfig
ok "removed ios/project.yml and the Local.xcconfig pair"

printf '\n\033[1m4. Commit\033[0m\n'
git add -A
git add -f ios/Morning.xcodeproj/project.pbxproj
git commit -q -m "$(cat <<'MSG'
Replace the XcodeGen spec with a plain committed Morning.xcodeproj

XcodeGen's justification here was pbxproj merge conflicts, which Xcode 16
buildable folders largely solve, and which barely apply to one developer
running agents sequentially. The other reason it was chosen — that the
scaffolding agent could not produce a valid .xcodeproj from Linux — is not
a property of this project.

So: generated the project once, committed it, and removed the generator
from the spec, bootstrap, CI and the verify script. Signing now lives in
the project's Signing & Capabilities tab rather than a gitignored xcconfig.

No project-generation tooling remains. Open ios/Morning.xcodeproj.
MSG
)"
ok "committed"

printf '\n\033[1mDone. Two things to do in Xcode, both optional:\033[0m\n'
cat <<'TXT'
  1. Select the Morning and MorningTests groups in the navigator, right-click ->
     "Convert to Folder". That turns them into buildable folders, so adding a
     file on disk no longer touches the project file at all. 30 seconds, and it
     is the one thing XcodeGen was buying us.
  2. Morning target -> Signing & Capabilities -> Team, if you want to install on
     the phone. Simulator builds need nothing.

  You can now `brew uninstall xcodegen` if you like — nothing uses it.
  Next: ./scripts/verify-ios.sh
TXT

rm -- "$0"
