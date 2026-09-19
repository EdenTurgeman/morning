#!/usr/bin/env python3
"""
WORKOUT.md must not drift from the program.

The doc explains the training; `ios/Morning/Program.swift` IS it. A document
that quietly stops matching the code is worse than no document, because it is
believed. So every exercise name, rep target and cue the program compiles to has
to appear in the doc verbatim, and this fails the build when one does not.

Reads the golden fixture rather than parsing Swift: the fixture is already
asserted against the compiler by the acceptance suite, so if it is right, it is
right about this too.

    python3 scripts/verify-workout-doc.py
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
doc = (ROOT / "WORKOUT.md").read_text(encoding="utf-8")
fixture = json.loads((ROOT / "ios/MorningTests/Fixtures/compiled-steps.json").read_text(encoding="utf-8"))

missing = []
for key, steps in fixture["steps"].items():
    for step in steps:
        if step["kind"] == "timer":
            for cue in step["cues"]:
                if cue not in doc:
                    missing.append(f"{key} warm-up cue: {cue}")
        elif step["kind"] == "set":
            if step["exercise"] not in doc:
                missing.append(f"{key} {step['slot']} exercise: {step['exercise']}")
            # "8–15 reps" may be written as "8–15 reps" or just "8–15".
            if step["target"].replace(" reps", "") not in doc:
                missing.append(f"{key} {step['slot']} target: {step['target']}")
            for cue in step["cues"]:
                if cue not in doc:
                    missing.append(f"{key} {step['slot']} cue: {cue}")

if missing:
    print("WORKOUT.md has drifted from the program. Not found in the doc:", file=sys.stderr)
    for item in dict.fromkeys(missing):
        print(f"  - {item}", file=sys.stderr)
    sys.exit(1)

sets = sum(1 for steps in fixture["steps"].values() for s in steps if s["kind"] == "set")
print(f"WORKOUT.md matches the program: {sets} sets across {len(fixture['steps'])} sessions")
