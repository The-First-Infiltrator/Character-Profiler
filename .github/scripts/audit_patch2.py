#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later

from pathlib import Path
ROOT = Path('.')

def read(path): return (ROOT / path).read_text()
def write(path, content): (ROOT / path).write_text(content)
def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1: raise RuntimeError(f'{label}: expected exactly one match, found {count}')
    return text.replace(old, new, 1)

# Add one genuine end-to-end XCUITest smoke flow.
ui_test_path = ROOT / "CharacterProfilerUITests/CharacterProfilerUITests.swift"
ui_test_path.parent.mkdir(parents=True, exist_ok=True)
ui_test_path.write_text('''// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest

final class CharacterProfilerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesLibraryAndOpensNewStoryEditor() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Character Profiler"].waitForExistence(timeout: 8))
        let newStory = app.buttons["New Story"]
        XCTAssertTrue(newStory.waitForExistence(timeout: 4))
        newStory.tap()
        XCTAssertTrue(app.navigationBars["New Story"].waitForExistence(timeout: 4))
    }
}
''')

# Wire the UI-test target into the existing hand-authored Xcode project.
path = "CharacterProfiler.xcodeproj/project.pbxproj"
s = read(path)

def insert_before(marker, addition, label):
    global s
    s = replace_once(s, marker, addition + marker, label)

insert_before("/* End PBXBuildFile section */",
'''\t\tA60000000000000000000001 /* CharacterProfilerUITests.swift in Sources */ = {isa = PBXBuildFile; fileRef = B60000000000000000000001 /* CharacterProfilerUITests.swift */; };
\t\tA60000000000000000000002 /* XCTest.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = B1000000000000000000000B /* XCTest.framework */; };
''', "UI build files")

insert_before("/* End PBXContainerItemProxy section */",
'''\t\tC60000000000000000000001 /* PBXContainerItemProxy */ = {
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = D10000000000000000000001 /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = D10000000000000000000002;
\t\t\tremoteInfo = CharacterProfiler;
\t\t};
''', "UI container proxy")

insert_before("/* End PBXFileReference section */",
'''\t\tB60000000000000000000001 /* CharacterProfilerUITests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CharacterProfilerUITests.swift; sourceTree = "<group>"; };
\t\tB60000000000000000000002 /* CharacterProfilerUITests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = CharacterProfilerUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
''', "UI file refs")

insert_before("/* End PBXFrameworksBuildPhase section */",
'''\t\tE60000000000000000000001 /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\tA60000000000000000000002 /* XCTest.framework in Frameworks */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
''', "UI frameworks")

s = replace_once(
    s,
    '''\t\t\t\tF10000000000000000000007 /* CharacterProfilerTests */,
\t\t\t\tF10000000000000000000008 /* Frameworks */,
''',
    '''\t\t\t\tF10000000000000000000007 /* CharacterProfilerTests */,
\t\t\t\tF60000000000000000000001 /* CharacterProfilerUITests */,
\t\t\t\tF10000000000000000000008 /* Frameworks */,
''',
    "UI root group"
)
insert_before('\t\tF10000000000000000000008 /* Frameworks */ = {',
'''\t\tF60000000000000000000001 /* CharacterProfilerUITests */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\tB60000000000000000000001 /* CharacterProfilerUITests.swift */,
\t\t\t);
\t\t\tpath = CharacterProfilerUITests;
\t\t\tsourceTree = "<group>";
\t\t};
''', "UI group")
s = replace_once(
    s,
    '''\t\t\t\tB1000000000000000000000D /* CharacterProfilerTests.xctest */,
''',
    '''\t\t\t\tB1000000000000000000000D /* CharacterProfilerTests.xctest */,
\t\t\t\tB60000000000000000000002 /* CharacterProfilerUITests.xctest */,
''',
    "UI product group"
)

insert_before("/* End PBXNativeTarget section */",
'''\t\tD60000000000000000000002 /* CharacterProfilerUITests */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = D60000000000000000000010 /* Build configuration list for PBXNativeTarget "CharacterProfilerUITests" */;
\t\t\tbuildPhases = (
\t\t\t\tE60000000000000000000003 /* Sources */,
\t\t\t\tE60000000000000000000001 /* Frameworks */,
\t\t\t\tE60000000000000000000005 /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\tC60000000000000000000002 /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = CharacterProfilerUITests;
\t\t\tproductName = CharacterProfilerUITests;
\t\t\tproductReference = B60000000000000000000002 /* CharacterProfilerUITests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.ui-testing";
\t\t};
''', "UI native target")

s = replace_once(
    s,
    '''\t\t\t\t\tD10000000000000000000003 = {
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t\tTestTargetID = D10000000000000000000002;
\t\t\t\t\t};
''',
    '''\t\t\t\t\tD10000000000000000000003 = {
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t\tTestTargetID = D10000000000000000000002;
\t\t\t\t\t};
\t\t\t\t\tD60000000000000000000002 = {
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t\tTestTargetID = D10000000000000000000002;
\t\t\t\t\t};
''',
    "UI target attributes"
)
s = replace_once(
    s,
    '''\t\t\t\tD10000000000000000000003 /* CharacterProfilerTests */,
''',
    '''\t\t\t\tD10000000000000000000003 /* CharacterProfilerTests */,
\t\t\t\tD60000000000000000000002 /* CharacterProfilerUITests */,
''',
    "UI project targets"
)

insert_before("/* End PBXResourcesBuildPhase section */",
'''\t\tE60000000000000000000005 /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
''', "UI resources")

insert_before("/* End PBXSourcesBuildPhase section */",
'''\t\tE60000000000000000000003 /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\tA60000000000000000000001 /* CharacterProfilerUITests.swift in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
''', "UI sources")

insert_before("/* End PBXTargetDependency section */",
'''\t\tC60000000000000000000002 /* PBXTargetDependency */ = {
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = D10000000000000000000002 /* CharacterProfiler */;
\t\t\ttargetProxy = C60000000000000000000001 /* PBXContainerItemProxy */;
\t\t};
''', "UI target dependency")

insert_before("/* End XCBuildConfiguration section */",
'''\t\tD60000000000000000000020 /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.firstinfiltrator.CharacterProfilerUITests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t\tTEST_TARGET_NAME = CharacterProfiler;
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\tD60000000000000000000021 /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.firstinfiltrator.CharacterProfilerUITests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t\tTEST_TARGET_NAME = CharacterProfiler;
\t\t\t};
\t\t\tname = Release;
\t\t};
''', "UI build configs")

insert_before("/* End XCConfigurationList section */",
'''\t\tD60000000000000000000010 /* Build configuration list for PBXNativeTarget "CharacterProfilerUITests" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\tD60000000000000000000020 /* Debug */,
\t\t\t\tD60000000000000000000021 /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
''', "UI config list")
write(path, s)

# Shared scheme runs the UI smoke test with the ordinary unit suite.
path = "CharacterProfiler.xcodeproj/xcshareddata/xcschemes/CharacterProfiler.xcscheme"
s = read(path)
s = replace_once(
    s,
    '''         <TestableReference skipped = "NO" parallelizable = "YES">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "D10000000000000000000003" BuildableName = "CharacterProfilerTests.xctest" BlueprintName = "CharacterProfilerTests" ReferencedContainer = "container:CharacterProfiler.xcodeproj"></BuildableReference>
         </TestableReference>
''',
    '''         <TestableReference skipped = "NO" parallelizable = "YES">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "D10000000000000000000003" BuildableName = "CharacterProfilerTests.xctest" BlueprintName = "CharacterProfilerTests" ReferencedContainer = "container:CharacterProfiler.xcodeproj"></BuildableReference>
         </TestableReference>
         <TestableReference skipped = "NO" parallelizable = "NO">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "D60000000000000000000002" BuildableName = "CharacterProfilerUITests.xctest" BlueprintName = "CharacterProfilerUITests" ReferencedContainer = "container:CharacterProfiler.xcodeproj"></BuildableReference>
         </TestableReference>
''',
    "UI scheme"
)
write(path, s)

# Documentation truth pass.
path = "docs/RELEASE_CHECKLIST.md"
s = read(path)
s = s.replace(
    "- [x] Application asset catalogue and AppIcon set are part of the app target resources.",
    "- [x] Application asset catalogue includes a real opaque 1024×1024 AppIcon, and CI preflights its existence/dimensions/alpha before Xcode builds."
)
anchor = "- [x] Simulator tests pass on the exact release candidate commit.\n"
if anchor in s and "XCUITest smoke coverage" not in s:
    s = s.replace(anchor, anchor + "- [x] XCUITest smoke coverage launches the Story Library and opens the New Story editor.\n", 1)
marker = "- [x] Optimized generic iPhoneOS Release compilation passes on the exact release candidate commit.\n"
if marker in s and "immutable commit SHAs" not in s:
    s = s.replace(marker, marker + "- [x] Third-party GitHub Actions are pinned to immutable commit SHAs, and stale PR CI is cancelled by concurrency grouping.\n", 1)
write(path, s)

path = "CHANGELOG.md"
s = read(path)
needle = "## 1.0.1"
idx = s.find(needle)
if idx != -1 and "real 1024×1024 AppIcon asset" not in s[idx:idx+5000]:
    insert_at = s.find("\n", idx) + 1
    extra = "\n- Added a real 1024×1024 AppIcon asset plus CI resource preflight so missing/broken icon assets cannot hide behind a green Xcode exit code.\n- Added XCUITest smoke coverage, persistence rollback failure-path regression coverage, archive family-generation conflict validation, startup retry, off-main backup JSON encoding, CI concurrency cancellation and immutable GitHub Action pins.\n"
    s = s[:insert_at] + extra + s[insert_at:]
write(path, s)

print("Applied final audit fixes.")
