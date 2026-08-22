#!/usr/bin/env python3
"""Add Swift source files to Morning.xcodeproj.

    ios/Tools/add-source-file.py Morning/Design/Tokens.swift [...]

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
TARGET_GROUP = "Morning"


def oid(*parts: str) -> str:
    """A stable 24-hex-character object id, derived from the path."""
    return hashlib.sha1("::".join(parts).encode()).hexdigest()[:24].upper()


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


def add(text: str, rel: str) -> str:
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

    # 2. PBXFileReference. `path` stays relative to the owning group.
    anchor = "/* Begin PBXFileReference section */\n"
    group_relative = path.name if path.parent.name in ("", TARGET_GROUP) else str(path).split("/", 1)[-1]
    entry = (
        f"\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; "
        f"lastKnownFileType = sourcecode.swift; path = {group_relative}; sourceTree = \"<group>\"; }};\n"
    )
    text = text.replace(anchor, anchor + entry, 1)

    # 3. Group membership.
    start, _ = find_group_block(text, path.parent.name or TARGET_GROUP)
    text = text[:start] + f"\t\t\t\t{file_id} /* {name} */,\n" + text[start:]

    # 4. Sources build phase.
    match = re.search(r"isa = PBXSourcesBuildPhase;.*?files = \(\n", text, re.S)
    if not match:
        raise SystemExit("could not find the Sources build phase")
    text = text[: match.end()] + f"\t\t\t\t{build_id} /* {name} in Sources */,\n" + text[match.end() :]

    print(f"  added: {rel}")
    return text


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    text = PBXPROJ.read_text()
    for rel in sys.argv[1:]:
        if not (ROOT / rel).exists():
            raise SystemExit(f"no such file on disk: ios/{rel}")
        text = add(text, rel)
    PBXPROJ.write_text(text)
    print(f"wrote {PBXPROJ.relative_to(ROOT.parent)}")


if __name__ == "__main__":
    main()
