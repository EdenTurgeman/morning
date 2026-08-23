#!/usr/bin/env python3
"""Adds the MorningWidgets app-extension target to the classic .xcodeproj.

Run once. It is idempotent — a second run reports that the target already
exists and changes nothing.

Why this is a script and not a hand edit
----------------------------------------
`ios/Morning.xcodeproj` is a classic project file with no file-system
synchronised groups, so a new target means eleven co-ordinated additions across
nine `isa` sections plus two edits to the host target. Doing that by hand once
is error-prone; doing it again after a merge conflict is worse. The script is
the record of what a widget target actually consists of here.

What it adds
------------
  * a `.appex` product reference, in Products
  * a `MorningWidgets` group holding the extension's source and Info.plist
  * Sources / Frameworks / Resources build phases for it
  * a PBXNativeTarget of type `com.apple.product-type.app-extension`
  * Debug and Release configurations and their list
  * an **Embed Foundation Extensions** copy phase on the app target — the step
    that is easy to forget and whose absence produces an app that builds, runs,
    and simply has no widget
  * a dependency from the app to the extension, so the app never links a stale
    build of it
  * `RestActivity.swift` compiled into BOTH targets, because `ActivityAttributes`
    has to be the same type on each side of the boundary
"""

import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1] / "Morning.xcodeproj" / "project.pbxproj"

# Stable ids, so a re-run against a restored file produces the same result.
IDS = {
    "appex": "E1A00001D0C24B0F9A000001",
    "group": "E1A00002D0C24B0F9A000002",
    "widget_src_ref": "E1A00003D0C24B0F9A000003",
    "widget_plist_ref": "E1A00004D0C24B0F9A000004",
    "widget_src_build": "E1A00005D0C24B0F9A000005",
    "shared_build": "E1A00006D0C24B0F9A000006",
    "sources_phase": "E1A00007D0C24B0F9A000007",
    "frameworks_phase": "E1A00008D0C24B0F9A000008",
    "resources_phase": "E1A00009D0C24B0F9A000009",
    "embed_phase": "E1A0000AD0C24B0F9A00000A",
    "embed_build": "E1A0000BD0C24B0F9A00000B",
    "target": "E1A0000CD0C24B0F9A00000C",
    "config_list": "E1A0000DD0C24B0F9A00000D",
    "config_debug": "E1A0000ED0C24B0F9A00000E",
    "config_release": "E1A0000FD0C24B0F9A00000F",
    "dependency": "E1A00010D0C24B0F9A000010",
    "proxy": "E1A00011D0C24B0F9A000011",
}

APP_TARGET = "920F73BABC436613FF8EC477"
PROJECT_OBJ = "BE1D6E0A13F4D1F82B1854B4"
PRODUCTS_GROUP = "9AA46384ED348E7022351FCC"
ROOT_GROUP = "5450E61315F16E290B57FCB2"
APP_SOURCES_PHASE = "93275FF117AE67866DBB3E3A"


def find_shared_file_ref(text):
    """The file ref for RestActivity.swift, which both targets compile."""
    match = re.search(
        r"([0-9A-F]{24}) /\* RestActivity\.swift \*/ = \{isa = PBXFileReference", text
    )
    if not match:
        sys.exit("RestActivity.swift is not in the project yet — add it first.")
    return match.group(1)


def insert_after(text, anchor, addition):
    index = text.index(anchor) + len(anchor)
    return text[:index] + addition + text[index:]


def main():
    text = PROJECT.read_text()

    if "MorningWidgets.appex" in text:
        print("  MorningWidgets target already present; nothing to do")
        return 0

    shared = find_shared_file_ref(text)
    i = IDS

    # --- PBXBuildFile -------------------------------------------------------
    text = insert_after(
        text,
        "/* Begin PBXBuildFile section */\n",
        f"\t\t{i['widget_src_build']} /* RestLiveActivity.swift in Sources */ = "
        f"{{isa = PBXBuildFile; fileRef = {i['widget_src_ref']} /* RestLiveActivity.swift */; }};\n"
        f"\t\t{i['shared_build']} /* RestActivity.swift in Sources */ = "
        f"{{isa = PBXBuildFile; fileRef = {shared} /* RestActivity.swift */; }};\n"
        f"\t\t{i['embed_build']} /* MorningWidgets.appex in Embed Foundation Extensions */ = "
        f"{{isa = PBXBuildFile; fileRef = {i['appex']} /* MorningWidgets.appex */; "
        f"settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};\n",
    )

    # --- PBXFileReference ---------------------------------------------------
    text = insert_after(
        text,
        "/* Begin PBXFileReference section */\n",
        f"\t\t{i['appex']} /* MorningWidgets.appex */ = {{isa = PBXFileReference; "
        f"explicitFileType = \"wrapper.app-extension\"; includeInIndex = 0; "
        f"path = MorningWidgets.appex; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
        f"\t\t{i['widget_src_ref']} /* RestLiveActivity.swift */ = {{isa = PBXFileReference; "
        f"lastKnownFileType = sourcecode.swift; path = RestLiveActivity.swift; sourceTree = \"<group>\"; }};\n"
        f"\t\t{i['widget_plist_ref']} /* Info.plist */ = {{isa = PBXFileReference; "
        f"lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};\n",
    )

    # --- PBXGroup: the extension's own, plus two memberships ----------------
    text = insert_after(
        text,
        "/* Begin PBXGroup section */\n",
        f"\t\t{i['group']} /* MorningWidgets */ = {{\n"
        f"\t\t\tisa = PBXGroup;\n"
        f"\t\t\tchildren = (\n"
        f"\t\t\t\t{i['widget_src_ref']} /* RestLiveActivity.swift */,\n"
        f"\t\t\t\t{i['widget_plist_ref']} /* Info.plist */,\n"
        f"\t\t\t);\n"
        f"\t\t\tpath = MorningWidgets;\n"
        f"\t\t\tsourceTree = \"<group>\";\n"
        f"\t\t}};\n",
    )
    text = text.replace(
        f"\t\t{PRODUCTS_GROUP} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n",
        f"\t\t{PRODUCTS_GROUP} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n"
        f"\t\t\t\t{i['appex']} /* MorningWidgets.appex */,\n",
        1,
    )
    text = text.replace(
        f"\t\t{ROOT_GROUP} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n",
        f"\t\t{ROOT_GROUP} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n"
        f"\t\t\t\t{i['group']} /* MorningWidgets */,\n",
        1,
    )

    # --- Build phases for the extension -------------------------------------
    text = insert_after(
        text,
        "/* Begin PBXSourcesBuildPhase section */\n",
        f"\t\t{i['sources_phase']} /* Sources */ = {{\n"
        f"\t\t\tisa = PBXSourcesBuildPhase;\n"
        f"\t\t\tbuildActionMask = 2147483647;\n"
        f"\t\t\tfiles = (\n"
        f"\t\t\t\t{i['widget_src_build']} /* RestLiveActivity.swift in Sources */,\n"
        f"\t\t\t\t{i['shared_build']} /* RestActivity.swift in Sources */,\n"
        f"\t\t\t);\n"
        f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        f"\t\t}};\n",
    )
    text = insert_after(
        text,
        "/* Begin PBXResourcesBuildPhase section */\n",
        f"\t\t{i['resources_phase']} /* Resources */ = {{\n"
        f"\t\t\tisa = PBXResourcesBuildPhase;\n"
        f"\t\t\tbuildActionMask = 2147483647;\n"
        f"\t\t\tfiles = (\n"
        f"\t\t\t);\n"
        f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        f"\t\t}};\n",
    )

    # Frameworks and the host's embed phase share a section that may not exist.
    frameworks = (
        f"/* Begin PBXFrameworksBuildPhase section */\n"
        f"\t\t{i['frameworks_phase']} /* Frameworks */ = {{\n"
        f"\t\t\tisa = PBXFrameworksBuildPhase;\n"
        f"\t\t\tbuildActionMask = 2147483647;\n"
        f"\t\t\tfiles = (\n"
        f"\t\t\t);\n"
        f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        f"\t\t}};\n"
        f"/* End PBXFrameworksBuildPhase section */\n\n"
    )
    copyfiles = (
        f"/* Begin PBXCopyFilesBuildPhase section */\n"
        f"\t\t{i['embed_phase']} /* Embed Foundation Extensions */ = {{\n"
        f"\t\t\tisa = PBXCopyFilesBuildPhase;\n"
        f"\t\t\tbuildActionMask = 2147483647;\n"
        f"\t\t\tdstPath = \"\";\n"
        f"\t\t\tdstSubfolderSpec = 13;\n"
        f"\t\t\tfiles = (\n"
        f"\t\t\t\t{i['embed_build']} /* MorningWidgets.appex in Embed Foundation Extensions */,\n"
        f"\t\t\t);\n"
        f"\t\t\tname = \"Embed Foundation Extensions\";\n"
        f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        f"\t\t}};\n"
        f"/* End PBXCopyFilesBuildPhase section */\n\n"
    )
    text = text.replace(
        "/* Begin PBXFileReference section */", frameworks + copyfiles + "/* Begin PBXFileReference section */", 1
    )

    # --- The target ---------------------------------------------------------
    text = insert_after(
        text,
        "/* Begin PBXNativeTarget section */\n",
        f"\t\t{i['target']} /* MorningWidgets */ = {{\n"
        f"\t\t\tisa = PBXNativeTarget;\n"
        f"\t\t\tbuildConfigurationList = {i['config_list']} /* Build configuration list for PBXNativeTarget \"MorningWidgets\" */;\n"
        f"\t\t\tbuildPhases = (\n"
        f"\t\t\t\t{i['sources_phase']} /* Sources */,\n"
        f"\t\t\t\t{i['frameworks_phase']} /* Frameworks */,\n"
        f"\t\t\t\t{i['resources_phase']} /* Resources */,\n"
        f"\t\t\t);\n"
        f"\t\t\tbuildRules = (\n"
        f"\t\t\t);\n"
        f"\t\t\tdependencies = (\n"
        f"\t\t\t);\n"
        f"\t\t\tname = MorningWidgets;\n"
        f"\t\t\tpackageProductDependencies = (\n"
        f"\t\t\t);\n"
        f"\t\t\tproductName = MorningWidgets;\n"
        f"\t\t\tproductReference = {i['appex']} /* MorningWidgets.appex */;\n"
        f"\t\t\tproductType = \"com.apple.product-type.app-extension\";\n"
        f"\t\t}};\n",
    )

    # --- Host target: embed phase and dependency ----------------------------
    text = text.replace(
        f"\t\t\t\tB61E33B741FDC6648E209282 /* Resources */,\n\t\t\t);\n"
        f"\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n\t\t\t);\n\t\t\tname = Morning;",
        f"\t\t\t\tB61E33B741FDC6648E209282 /* Resources */,\n"
        f"\t\t\t\t{i['embed_phase']} /* Embed Foundation Extensions */,\n\t\t\t);\n"
        f"\t\t\tbuildRules = (\n\t\t\t);\n"
        f"\t\t\tdependencies = (\n\t\t\t\t{i['dependency']} /* PBXTargetDependency */,\n\t\t\t);\n"
        f"\t\t\tname = Morning;",
        1,
    )

    # --- Dependency and proxy ----------------------------------------------
    text = insert_after(
        text,
        "/* Begin PBXTargetDependency section */\n",
        f"\t\t{i['dependency']} /* PBXTargetDependency */ = {{\n"
        f"\t\t\tisa = PBXTargetDependency;\n"
        f"\t\t\ttarget = {i['target']} /* MorningWidgets */;\n"
        f"\t\t\ttargetProxy = {i['proxy']} /* PBXContainerItemProxy */;\n"
        f"\t\t}};\n",
    )
    text = insert_after(
        text,
        "/* Begin PBXContainerItemProxy section */\n",
        f"\t\t{i['proxy']} /* PBXContainerItemProxy */ = {{\n"
        f"\t\t\tisa = PBXContainerItemProxy;\n"
        f"\t\t\tcontainerPortal = {PROJECT_OBJ} /* Project object */;\n"
        f"\t\t\tproxyType = 1;\n"
        f"\t\t\tremoteGlobalIDString = {i['target']};\n"
        f"\t\t\tremoteInfo = MorningWidgets;\n"
        f"\t\t}};\n",
    )

    # --- Configurations -----------------------------------------------------
    def config(name, extra):
        return (
            f"\t\t{name} /* {extra} */ = {{\n"
            f"\t\t\tisa = XCBuildConfiguration;\n"
            f"\t\t\tbuildSettings = {{\n"
            f"\t\t\t\tCODE_SIGN_STYLE = Automatic;\n"
            f"\t\t\t\tCURRENT_PROJECT_VERSION = 1;\n"
            f"\t\t\t\tGENERATE_INFOPLIST_FILE = NO;\n"
            f"\t\t\t\tINFOPLIST_FILE = MorningWidgets/Info.plist;\n"
            f"\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = Morning;\n"
            f"\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n"
            f"\t\t\t\t\t\"$(inherited)\",\n"
            f"\t\t\t\t\t\"@executable_path/Frameworks\",\n"
            f"\t\t\t\t\t\"@executable_path/../../Frameworks\",\n"
            f"\t\t\t\t);\n"
            f"\t\t\t\tMARKETING_VERSION = 1.0;\n"
            f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.edenturgeman.morning.widgets;\n"
            f"\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";\n"
            f"\t\t\t\tSDKROOT = iphoneos;\n"
            f"\t\t\t\tSKIP_INSTALL = YES;\n"
            f"\t\t\t\tSUPPORTS_MACCATALYST = NO;\n"
            f"\t\t\t\tSUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;\n"
            f"\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;\n"
            f"\t\t\t\tTARGETED_DEVICE_FAMILY = 1;\n"
            f"\t\t\t}};\n"
            f"\t\t\tname = {extra};\n"
            f"\t\t}};\n"
        )

    text = insert_after(
        text,
        "/* Begin XCBuildConfiguration section */\n",
        config(i["config_debug"], "Debug") + config(i["config_release"], "Release"),
    )
    text = insert_after(
        text,
        "/* Begin XCConfigurationList section */\n",
        f"\t\t{i['config_list']} /* Build configuration list for PBXNativeTarget \"MorningWidgets\" */ = {{\n"
        f"\t\t\tisa = XCConfigurationList;\n"
        f"\t\t\tbuildConfigurations = (\n"
        f"\t\t\t\t{i['config_debug']} /* Debug */,\n"
        f"\t\t\t\t{i['config_release']} /* Release */,\n"
        f"\t\t\t);\n"
        f"\t\t\tdefaultConfigurationIsVisible = 0;\n"
        f"\t\t\tdefaultConfigurationName = Release;\n"
        f"\t\t}};\n",
    )

    # --- Register with the project -----------------------------------------
    text = text.replace(
        f"\t\t\t\t\tD4AE504DA7B178600BF662CE = {{\n\t\t\t\t\t\tProvisioningStyle = Automatic;\n\t\t\t\t\t}};\n",
        f"\t\t\t\t\tD4AE504DA7B178600BF662CE = {{\n\t\t\t\t\t\tProvisioningStyle = Automatic;\n\t\t\t\t\t}};\n"
        f"\t\t\t\t\t{i['target']} = {{\n\t\t\t\t\t\tProvisioningStyle = Automatic;\n\t\t\t\t\t}};\n",
        1,
    )
    text = text.replace(
        f"\t\t\t\tD4AE504DA7B178600BF662CE /* MorningTests */,\n\t\t\t);\n\t\t}};\n"
        f"/* End PBXProject section */",
        f"\t\t\t\tD4AE504DA7B178600BF662CE /* MorningTests */,\n"
        f"\t\t\t\t{i['target']} /* MorningWidgets */,\n\t\t\t);\n\t\t}};\n"
        f"/* End PBXProject section */",
        1,
    )

    PROJECT.write_text(text)
    print("  added target MorningWidgets (com.apple.product-type.app-extension)")
    print(f"  wrote {PROJECT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
