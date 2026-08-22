#!/usr/bin/env python3
"""Add Swift source files to Morning.xcodeproj.

    ios/Tools/add-source-file.py Morning/Design/Tokens.swift [...]
    ios/Tools/add-source-file.py --test MorningTests/FooTests.swift

`Morning.xcodeproj` is a plain committed project using classic file references
rather than synchronized folder groups, so a file on disk is invisible to the
build until four entries exist for it: a PBXBuildFile, a PBXFileReference, a
child of its group, and a member of the target's Sources phase.

Doing that by hand is how a project file gets corrupted, so it lives here
instead. Paths are given relative to `ios/`, and groups are created as needed.
Re-adding a file already in the project is a no-op, so this is safe to re-run.
"""
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBXPROJ = ROOT / "Morning.xcodeproj" / "project.pbxproj"
APP_GROUP = "Morning"
TEST_GROUP = "MorningTests"


def oid(*parts: str) -> str:
    """A stable 24-hex-character object id, derived from the path."""
    return hashlib.sha1("::".join(parts).encode()).hexdigest()[:24].upper()


def sources_phase_index(text: str, test_target: bool) -> int:
    """Where to insert into the Sources build phase.

    There are two: the app target's, then the test target's. Picking the wrong
    one compiles a test into the app, or an app file into the tests.
    """
    phases = [
        m.end()
        for m in re.finditer(r"isa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = \d+;\n\t\t\tfiles = \(\n", text)
    ]
    if len(phases) < 2:
        raise SystemExit(f"expected two Sources build phases, found {len(phases)}")
    return phases[1] if test_target else phases[0]


def find_group_block(text: str, name: str) -> tuple[int, int]:
    """Return the (start, end) span of a PBXGroup's `children = ( ... );`."""
    for match in re.finditer(r"([0-9A-F]{24}) /\* (\S+) \*/ = \{\n\t\t\tisa = PBXGroup;", text):
        block_start = match.end()
        block_end = text.index("\t\t};", block_start)
        block = text[block_start:block_end]
        if re.search(rf"path = {re.escape(name)};", block):
            children = re.search(r"children = \(\n", block)
            if children:
                return block_start + children.end(), block_start + block.index("\t\t\t);")
    raise SystemExit(f"could not find PBXGroup with path = {name};")


def ensure_group(text: str, name: str, parent: str = APP_GROUP) -> str:
    """Create a PBXGroup for `name` under `parent` if it does not exist yet.

    A new directory on disk is invisible to Xcode until a group declares it,
    which is a separate step from declaring the files inside it.
    """
    if re.search(rf"path = {re.escape(name)};", text):
        return text

    group_id = oid("group", name)
    entry = (
        f"\t\t{group_id} /* {name} */ = {{\n"
        f"\t\t\tisa = PBXGroup;\n"
        f"\t\t\tchildren = (\n"
        f"\t\t\t);\n"
        f"\t\t\tpath = {name};\n"
        f"\t\t\tsourceTree = \"<group>\";\n"
        f"\t\t}};\n"
    )
    anchor = "/* Begin PBXGroup section */\n"
    text = text.replace(anchor, anchor + entry, 1)

    # And list it as a child of its parent, or Xcode shows an empty project.
    start, _ = find_group_block(text, parent)
    text = text[:start] + f"\t\t\t\t{group_id} /* {name} */,\n" + text[start:]
    print(f"  created group: {name}")
    return text


def add(text: str, rel: str, test_target: bool = False) -> str:
    path = Path(rel)
    if path.name in text and f"path = {path.name};" in text:
        print(f"  already present: {rel}")
        return text

    file_id = oid("file", rel)
    build_id = oid("build", rel)
    name = path.name

    # 1. PBXBuildFile
    anchor = "/* Begin PBXBuildFile section */\n"
    entry = f"\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};\n"
    text = text.replace(anchor, anchor + entry, 1)

    # 2. PBXFileReference. `path` is relative to the OWNING GROUP, and the group
    #    is looked up by the file's parent directory below — so the group already
    #    carries the directory and the reference must carry only the filename.
    #    Writing "Model/Steps.swift" here resolves to Morning/Model/Model/Steps.swift.
    anchor = "/* Begin PBXFileReference section */\n"
    entry = (
        f"\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; "
        f"lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};\n"
    )
    text = text.replace(anchor, anchor + entry, 1)

    # 3. Group membership.
    default_group = TEST_GROUP if test_target else APP_GROUP
    start, _ = find_group_block(text, path.parent.name or default_group)
    text = text[:start] + f"\t\t\t\t{file_id} /* {name} */,\n" + text[start:]

    # 4. Sources build phase — the right one of the two.
    insert = sources_phase_index(text, test_target)
    text = text[:insert] + f"\t\t\t\t{build_id} /* {name} in Sources */,\n" + text[insert:]

    print(f"  added: {rel}")
    return text


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "--test"]
    test_target = "--test" in sys.argv
    if not args:
        raise SystemExit(__doc__)
    text = PBXPROJ.read_text()
    for rel in args:
        if not (ROOT / rel).exists():
            raise SystemExit(f"no such file on disk: ios/{rel}")
        default_group = TEST_GROUP if test_target else APP_GROUP
        parent = Path(rel).parent.name
        if parent and parent != default_group:
            text = ensure_group(text, parent, default_group)
        text = add(text, rel, test_target)
    PBXPROJ.write_text(text)
    print(f"wrote {PBXPROJ.relative_to(ROOT.parent)}")


if __name__ == "__main__":
    main()
