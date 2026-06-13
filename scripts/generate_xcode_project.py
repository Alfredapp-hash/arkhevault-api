#!/usr/bin/env python3
"""Generate ArkheVault.xcodeproj/project.pbxproj with all source files."""

import hashlib
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJECT_NAME = "ArkheVault"
BUNDLE_ID = "com.arkheholdings.vault"

EXCLUDE_DIRS = {".git", "scripts", "ArkheVault.xcodeproj"}
EXCLUDE_FILES = {"generate_xcode_project.py"}


def uid(seed: str) -> str:
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()


def collect_sources() -> list[Path]:
    sources = []
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT)
        if any(part in EXCLUDE_DIRS for part in rel.parts):
            continue
        if path.name in EXCLUDE_FILES:
            continue
        if rel.suffix == ".swift":
            sources.append(rel)
    return sources


def is_test(path: Path) -> bool:
  return path.parts[0] == "Tests"


def is_ui_test(path: Path) -> bool:
    return path.parts[:2] == ("Tests", "ArkheVaultUITests")


def is_unit_test(path: Path) -> bool:
    return path.parts[:2] == ("Tests", "ArkheVaultTests")


def main() -> None:
    sources = collect_sources()
    app_sources = [p for p in sources if not is_test(p)]
    unit_tests = [p for p in sources if is_unit_test(p)]
    ui_tests = [p for p in sources if is_ui_test(p)]

    model_path = Path("Core/Data/ArkheVaultDataModel.xcdatamodeld")

    ids = {
        "project": uid("project"),
        "main_group": uid("main_group"),
        "products_group": uid("products_group"),
        "app_target": uid("app_target"),
        "unit_target": uid("unit_target"),
        "ui_target": uid("ui_target"),
        "app_product": uid("app_product"),
        "unit_product": uid("unit_product"),
        "ui_product": uid("ui_product"),
        "app_sources_phase": uid("app_sources_phase"),
        "unit_sources_phase": uid("unit_sources_phase"),
        "ui_sources_phase": uid("ui_sources_phase"),
        "frameworks_phase": uid("frameworks_phase"),
        "unit_frameworks_phase": uid("unit_frameworks_phase"),
        "ui_frameworks_phase": uid("ui_frameworks_phase"),
        "resources_phase": uid("resources_phase"),
        "model_ref": uid("model_ref"),
        "model_build": uid("model_build"),
        "project_config_debug": uid("project_config_debug"),
        "project_config_release": uid("project_config_release"),
        "app_config_debug": uid("app_config_debug"),
        "app_config_release": uid("app_config_release"),
        "unit_config_debug": uid("unit_config_debug"),
        "unit_config_release": uid("unit_config_release"),
        "ui_config_debug": uid("ui_config_debug"),
        "ui_config_release": uid("ui_config_release"),
        "app_target_dep": uid("app_target_dep"),
        "unit_target_dep": uid("unit_target_dep"),
    }

    file_refs: dict[str, str] = {}
    build_files: dict[str, str] = {}

    def add_file(rel: Path, target: str) -> tuple[str, str | None]:
        key = str(rel)
        if key not in file_refs:
            file_refs[key] = uid(f"ref:{key}")
        ref = file_refs[key]
        if target == "none":
            return ref, None
        build_key = f"{target}:{key}"
        if build_key not in build_files:
            build_files[build_key] = uid(f"build:{build_key}")
        return ref, build_files[build_key]

    for rel in app_sources:
        add_file(rel, "app")
    for rel in unit_tests:
        add_file(rel, "unit")
    for rel in ui_tests:
        add_file(rel, "ui")
    add_file(model_path, "app")

    lines: list[str] = []
    lines.append("// !$*UTF8*$!")
    lines.append("{")
    lines.append("\tarchiveVersion = 1;")
    lines.append("\tclasses = {")
    lines.append("\t};")
    lines.append("\tobjectVersion = 56;")
    lines.append("\tobjects = {")

  # PBXBuildFile
    lines.append("\n/* Begin PBXBuildFile section */")
    for rel in app_sources:
        _, build_id = add_file(rel, "app")
        lines.append(f"\t\t{build_id} /* {rel.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[str(rel)]} /* {rel.name} */; }};")
    for rel in unit_tests:
        _, build_id = add_file(rel, "unit")
        lines.append(f"\t\t{build_id} /* {rel.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[str(rel)]} /* {rel.name} */; }};")
    for rel in ui_tests:
        _, build_id = add_file(rel, "ui")
        lines.append(f"\t\t{build_id} /* {rel.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[str(rel)]} /* {rel.name} */; }};")
    lines.append(f"\t\t{ids['model_build']} /* ArkheVaultDataModel.xcdatamodeld in Sources */ = {{isa = PBXBuildFile; fileRef = {ids['model_ref']} /* ArkheVaultDataModel.xcdatamodeld */; }};")
    lines.append("/* End PBXBuildFile section */\n")

    # PBXFileReference
    lines.append("/* Begin PBXFileReference section */")
    lines.append(f"\t\t{ids['app_product']} /* {PROJECT_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {PROJECT_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    lines.append(f"\t\t{ids['unit_product']} /* {PROJECT_NAME}Tests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = {PROJECT_NAME}Tests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
    lines.append(f"\t\t{ids['ui_product']} /* {PROJECT_NAME}UITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = {PROJECT_NAME}UITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
    for rel in sources:
        lines.append(f"\t\t{file_refs[str(rel)]} /* {rel.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {rel.name}; sourceTree = \"<group>\"; }};")
    lines.append(f"\t\t{ids['model_ref']} /* ArkheVaultDataModel.xcdatamodeld */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.xcdatamodel; path = ArkheVaultDataModel.xcdatamodeld; sourceTree = \"<group>\"; }};")
    lines.append("/* End PBXFileReference section */\n")

    # PBXFrameworksBuildPhase
    for phase_id, name in [
        (ids["frameworks_phase"], "app"),
        (ids["unit_frameworks_phase"], "unit"),
        (ids["ui_frameworks_phase"], "ui"),
    ]:
        lines.append("/* Begin PBXFrameworksBuildPhase section */" if name == "app" else "")
        if name == "app":
            pass
    lines.append(f"\t\t{ids['frameworks_phase']} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append(f"\t\t{ids['unit_frameworks_phase']} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append(f"\t\t{ids['ui_frameworks_phase']} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXFrameworksBuildPhase section */\n")

    # Groups
    def group_children(folder: Path) -> list[str]:
        children = []
        subdirs = sorted([p for p in folder.iterdir() if p.is_dir() and p.name not in EXCLUDE_DIRS and p.name != "ArkheVault.xcodeproj"], key=lambda p: p.name)
        files = sorted([p for p in folder.iterdir() if p.is_file() and p.suffix == ".swift"], key=lambda p: p.name)
        for f in files:
            rel = f.relative_to(ROOT)
            children.append(file_refs[str(rel)])
        for d in subdirs:
            children.append(uid(f"group:{d.relative_to(ROOT)}"))
        if folder == ROOT / "Core" / "Data":
            children.append(ids["model_ref"])
        return children

    group_ids: dict[str, str] = {str(ROOT): ids["main_group"]}

    def ensure_groups(path: Path) -> None:
        rel = path.relative_to(ROOT)
        key = str(rel)
        if key not in group_ids:
            group_ids[key] = uid(f"group:{key}")

    for rel in sources:
        for parent in [rel.parent] + list(rel.parents):
            if parent == Path("."):
                continue
            if str(parent) == ".":
                continue
            ensure_groups(ROOT / parent)
    ensure_groups(ROOT / "Core" / "Data")

    lines.append("/* Begin PBXGroup section */")
    lines.append(f"\t\t{ids['products_group']} /* Products */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{ids['app_product']} /* {PROJECT_NAME}.app */,")
    lines.append(f"\t\t\t\t{ids['unit_product']} /* {PROJECT_NAME}Tests.xctest */,")
    lines.append(f"\t\t\t\t{ids['ui_product']} /* {PROJECT_NAME}UITests.xctest */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tname = Products;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    all_group_paths = sorted(group_ids.keys(), key=lambda x: (x.count("/"), x))
    for gpath in all_group_paths:
        if gpath == str(ROOT):
            folder = ROOT
        else:
            folder = ROOT / gpath
        gid = group_ids[gpath]
        children = group_children(folder) if folder.is_dir() else []
        lines.append(f"\t\t{gid} /* {folder.name if gpath != str(ROOT) else PROJECT_NAME} */ = {{")
        lines.append("\t\t\tisa = PBXGroup;")
        lines.append("\t\t\tchildren = (")
        for child in children:
            if child in group_ids.values():
                # find name
                child_name = [k for k, v in group_ids.items() if v == child][0]
                display = Path(child_name).name if child_name != str(ROOT) else PROJECT_NAME
                lines.append(f"\t\t\t\t{child} /* {display} */,")
            else:
                # file ref - find path
                ref_path = [k for k, v in file_refs.items() if v == child]
                if ref_path:
                    lines.append(f"\t\t\t\t{child} /* {Path(ref_path[0]).name} */,")
                elif child == ids["model_ref"]:
                    lines.append(f"\t\t\t\t{child} /* ArkheVaultDataModel.xcdatamodeld */,")
        if gpath == str(ROOT):
            lines.append(f"\t\t\t\t{ids['products_group']} /* Products */,")
        lines.append("\t\t\t);")
        if gpath == str(ROOT):
            lines.append(f"\t\t\tpath = .;")
        else:
            lines.append(f"\t\t\tpath = {folder.name};")
        lines.append("\t\t\tsourceTree = \"<group>\";")
        lines.append("\t\t};")

    lines.append("/* End PBXGroup section */\n")

    # PBXNativeTarget
    def target_block(target_id, name, product_id, sources_phase, frameworks_phase, product_type, bundle_id_suffix):
        lines.append(f"\t\t{target_id} /* {name} */ = {{")
        lines.append("\t\t\tisa = PBXNativeTarget;")
        lines.append(f"\t\t\tbuildConfigurationList = {uid(name + ':configs')} /* Build configuration list for PBXNativeTarget \"{name}\" */;")
        lines.append("\t\t\tbuildPhases = (")
        lines.append(f"\t\t\t\t{sources_phase} /* Sources */,")
        if name == PROJECT_NAME:
            lines.append(f"\t\t\t\t{ids['resources_phase']} /* Resources */,")
        lines.append(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
        lines.append("\t\t\t);")
        lines.append("\t\t\tbuildRules = (")
        lines.append("\t\t\t);")
        lines.append("\t\t\tdependencies = (")
        if name.endswith("Tests"):
            lines.append(f"\t\t\t\t{ids['app_target_dep']} /* PBXTargetDependency */,")
        lines.append("\t\t\t);")
        lines.append(f"\t\t\tname = {name};")
        lines.append(f"\t\t\tproductName = {name};")
        lines.append(f"\t\t\tproductReference = {product_id} /* {name}{'.app' if name == PROJECT_NAME else '.xctest'} */;")
        lines.append(f"\t\t\tproductType = \"{product_type}\";")
        lines.append("\t\t};")

    lines.append("/* Begin PBXNativeTarget section */")
    target_block(ids["app_target"], PROJECT_NAME, ids["app_product"], ids["app_sources_phase"], ids["frameworks_phase"], "com.apple.product-type.application", "")
    target_block(ids["unit_target"], f"{PROJECT_NAME}Tests", ids["unit_product"], ids["unit_sources_phase"], ids["unit_frameworks_phase"], "com.apple.product-type.bundle.unit-test", "tests")
    target_block(ids["ui_target"], f"{PROJECT_NAME}UITests", ids["ui_product"], ids["ui_sources_phase"], ids["ui_frameworks_phase"], "com.apple.product-type.bundle.ui-testing", "uitests")
    lines.append("/* End PBXNativeTarget section */\n")

    # PBXProject
    lines.append("/* Begin PBXProject section */")
    lines.append(f"\t\t{ids['project']} /* Project object */ = {{")
    lines.append("\t\t\tisa = PBXProject;")
    lines.append("\t\t\tattributes = {")
    lines.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    lines.append("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    lines.append("\t\t\t\tLastUpgradeCheck = 1500;")
    lines.append("\t\t\t\tTargetAttributes = {")
    lines.append(f"\t\t\t\t\t{ids['app_target']} = {{")
    lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    lines.append("\t\t\t\t\t};")
    lines.append(f"\t\t\t\t\t{ids['unit_target']} = {{")
    lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    lines.append(f"\t\t\t\t\t\tTestTargetID = {ids['app_target']};")
    lines.append("\t\t\t\t\t};")
    lines.append(f"\t\t\t\t\t{ids['ui_target']} = {{")
    lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    lines.append(f"\t\t\t\t\t\tTestTargetID = {ids['app_target']};")
    lines.append("\t\t\t\t\t};")
    lines.append("\t\t\t\t};")
    lines.append("\t\t\t};")
    lines.append(f"\t\t\tbuildConfigurationList = {uid('project:configs')} /* Build configuration list for PBXProject \"{PROJECT_NAME}\" */;")
    lines.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    lines.append("\t\t\tdevelopmentRegion = en;")
    lines.append("\t\t\thasScannedForEncodings = 0;")
    lines.append("\t\t\tknownRegions = (")
    lines.append("\t\t\t\ten,")
    lines.append("\t\t\t\tBase,")
    lines.append("\t\t\t);")
    lines.append(f"\t\t\tmainGroup = {ids['main_group']};")
    lines.append(f"\t\t\tproductRefGroup = {ids['products_group']} /* Products */;")
    lines.append("\t\t\tprojectDirPath = \"\";")
    lines.append("\t\t\tprojectRoot = \"\";")
    lines.append("\t\t\ttargets = (")
    lines.append(f"\t\t\t\t{ids['app_target']} /* {PROJECT_NAME} */,")
    lines.append(f"\t\t\t\t{ids['unit_target']} /* {PROJECT_NAME}Tests */,")
    lines.append(f"\t\t\t\t{ids['ui_target']} /* {PROJECT_NAME}UITests */,")
    lines.append("\t\t\t);")
    lines.append("\t\t};")
    lines.append("/* End PBXProject section */\n")

    # Resources
    lines.append("/* Begin PBXResourcesBuildPhase section */")
    lines.append(f"\t\t{ids['resources_phase']} /* Resources */ = {{")
    lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXResourcesBuildPhase section */\n")

    # Sources phases
    def sources_phase(phase_id, rels, include_model=False):
        lines.append(f"\t\t{phase_id} /* Sources */ = {{")
        lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
        lines.append("\t\t\tbuildActionMask = 2147483647;")
        lines.append("\t\t\tfiles = (")
        for rel in rels:
            build_id = build_files[[k for k in build_files if k.endswith(f":{rel}")][0]]
            lines.append(f"\t\t\t\t{build_id} /* {rel.name} in Sources */,")
        if include_model:
            lines.append(f"\t\t\t\t{ids['model_build']} /* ArkheVaultDataModel.xcdatamodeld in Sources */,")
        lines.append("\t\t\t);")
        lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        lines.append("\t\t};")

    lines.append("/* Begin PBXSourcesBuildPhase section */")
    sources_phase(ids["app_sources_phase"], app_sources, include_model=True)
    sources_phase(ids["unit_sources_phase"], unit_tests)
    sources_phase(ids["ui_sources_phase"], ui_tests)
    lines.append("/* End PBXSourcesBuildPhase section */\n")

    # Target dependency
    lines.append("/* Begin PBXContainerItemProxy section */")
    lines.append(f"\t\t{uid('proxy')} /* PBXContainerItemProxy */ = {{")
    lines.append("\t\t\tisa = PBXContainerItemProxy;")
    lines.append(f"\t\t\tcontainerPortal = {ids['project']} /* Project object */;")
    lines.append("\t\t\tproxyType = 1;")
    lines.append(f"\t\t\tremoteGlobalIDString = {ids['app_target']};")
    lines.append(f"\t\t\tremoteInfo = {PROJECT_NAME};")
    lines.append("\t\t};")
    lines.append("/* End PBXContainerItemProxy section */\n")

    lines.append("/* Begin PBXTargetDependency section */")
    lines.append(f"\t\t{ids['app_target_dep']} /* PBXTargetDependency */ = {{")
    lines.append("\t\t\tisa = PBXTargetDependency;")
    lines.append(f"\t\t\ttarget = {ids['app_target']} /* {PROJECT_NAME} */;")
    lines.append(f"\t\t\ttargetProxy = {uid('proxy')} /* PBXContainerItemProxy */;")
    lines.append("\t\t};")
    lines.append("/* End PBXTargetDependency section */\n")

    # XCBuildConfiguration
    def build_settings(target_name: str, is_test: bool = False) -> str:
        bundle = BUNDLE_ID if not is_test else f"{BUNDLE_ID}.{target_name.split('Tests')[1].lower() or 'tests'}"
        if target_name.endswith("Tests"):
            bundle = f"{BUNDLE_ID}.tests" if target_name == f"{PROJECT_NAME}Tests" else f"{BUNDLE_ID}.uitests"
        settings = [
            f"PRODUCT_BUNDLE_IDENTIFIER = {bundle};",
            f"PRODUCT_NAME = $(TARGET_NAME);",
            "SWIFT_VERSION = 5.0;",
            "MACOSX_DEPLOYMENT_TARGET = 13.0;",
            "CODE_SIGN_STYLE = Automatic;",
            "CURRENT_PROJECT_VERSION = 1;",
            "MARKETING_VERSION = 1.0;",
        ]
        if target_name == PROJECT_NAME:
            settings.extend([
                "GENERATE_INFOPLIST_FILE = YES;",
                'INFOPLIST_KEY_CFBundleDisplayName = "Arkhe Vault";',
                "INFOPLIST_KEY_LSApplicationCategoryType = public.app-category.business;",
                "INFOPLIST_KEY_NSHumanReadableCopyright = \"Copyright © 2026 Arkhe Holdings. All rights reserved.\";",
                "ENABLE_HARDENED_RUNTIME = YES;",
            ])
        if is_test:
            settings.append("BUNDLE_LOADER = $(TEST_HOST);")
            settings.append(f'TEST_HOST = "$(BUILT_PRODUCTS_DIR)/{PROJECT_NAME}.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/{PROJECT_NAME}";')
        if target_name == f"{PROJECT_NAME}UITests":
            settings = [s for s in settings if not s.startswith("BUNDLE_LOADER") and not s.startswith("TEST_HOST")]
        return "\n\t\t\t\t".join(settings)

    def config_list(list_id, name, debug_id, release_id):
        lines.append(f"\t\t{list_id} /* Build configuration list for {name} */ = {{")
        lines.append("\t\t\tisa = XCConfigurationList;")
        lines.append("\t\t\tbuildConfigurations = (")
        lines.append(f"\t\t\t\t{debug_id} /* Debug */,")
        lines.append(f"\t\t\t\t{release_id} /* Release */,")
        lines.append("\t\t\t);")
        lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
        lines.append("\t\t\tdefaultConfigurationName = Release;")
        lines.append("\t\t};")

    lines.append("/* Begin XCBuildConfiguration section */")
    for cfg_id, name, settings in [
        (ids["project_config_debug"], "Debug", "DEBUG=1"),
        (ids["project_config_release"], "Release", ""),
        (ids["app_config_debug"], f"{PROJECT_NAME} Debug", build_settings(PROJECT_NAME)),
        (ids["app_config_release"], f"{PROJECT_NAME} Release", build_settings(PROJECT_NAME)),
        (ids["unit_config_debug"], f"{PROJECT_NAME}Tests Debug", build_settings(f"{PROJECT_NAME}Tests", True)),
        (ids["unit_config_release"], f"{PROJECT_NAME}Tests Release", build_settings(f"{PROJECT_NAME}Tests", True)),
        (ids["ui_config_debug"], f"{PROJECT_NAME}UITests Debug", build_settings(f"{PROJECT_NAME}UITests", True)),
        (ids["ui_config_release"], f"{PROJECT_NAME}UITests Release", build_settings(f"{PROJECT_NAME}UITests", True)),
    ]:
        lines.append(f"\t\t{cfg_id} /* {name.split()[-1]} */ = {{")
        lines.append("\t\t\tisa = XCBuildConfiguration;")
        lines.append("\t\t\tbuildSettings = {")
        if "PROJECT_NAME" not in name and "Tests" not in name:
            lines.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
            lines.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
            lines.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
            lines.append("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
            lines.append("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
            lines.append("\t\t\t\tSDKROOT = macosx;")
            lines.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = \"$(inherited)\";")
            if settings:
                lines.append(f"\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = \"$(inherited) {settings}\";")
        else:
            lines.append(f"\t\t\t\t{settings}")
        lines.append("\t\t\t};")
        lines.append(f"\t\t\tname = {name.split()[-1]};")
        lines.append("\t\t};")

    lines.append("/* End XCBuildConfiguration section */\n")

    lines.append("/* Begin XCConfigurationList section */")
    config_list(uid("project:configs"), f'PBXProject "{PROJECT_NAME}"', ids["project_config_debug"], ids["project_config_release"])
    config_list(uid(f"{PROJECT_NAME}:configs"), f'PBXNativeTarget "{PROJECT_NAME}"', ids["app_config_debug"], ids["app_config_release"])
    config_list(uid(f"{PROJECT_NAME}Tests:configs"), f'PBXNativeTarget "{PROJECT_NAME}Tests"', ids["unit_config_debug"], ids["unit_config_release"])
    config_list(uid(f"{PROJECT_NAME}UITests:configs"), f'PBXNativeTarget "{PROJECT_NAME}UITests"', ids["ui_config_debug"], ids["ui_config_release"])
    lines.append("/* End XCConfigurationList section */")

    lines.append("\t};")
    lines.append(f"\trootObject = {ids['project']} /* Project object */;")
    lines.append("}")

    out = ROOT / "ArkheVault.xcodeproj" / "project.pbxproj"
    out.write_text("\n".join(lines) + "\n")
    print(f"Wrote {out} ({len(app_sources)} app sources, {len(unit_tests)} unit tests, {len(ui_tests)} ui tests)")


if __name__ == "__main__":
    main()
