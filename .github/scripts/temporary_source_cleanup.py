#!/usr/bin/env python3
"""One-shot repository cleanup; removes itself after producing the source patch."""

from pathlib import Path


def insert_once(text: str, marker: str, addition: str) -> str:
    count = text.count(marker)
    if count != 1:
        raise SystemExit(f"Expected exactly one marker, found {count}: {marker!r}")
    return text.replace(marker, marker + addition, 1)


# Move the optional RealityKit/Quick Look implementation out of the character shell.
detail_path = Path("CharacterProfiler/Views/CharacterDetailView.swift")
detail = detail_path.read_text()
imports = "import SwiftUI\nimport SwiftData\nimport RealityKit\nimport QuickLook\n"
if imports not in detail:
    raise SystemExit("CharacterDetailView import boundary changed unexpectedly")
detail = detail.replace(imports, "import SwiftUI\nimport SwiftData\n", 1)

start_marker = "private struct Character3DHeadWorkspaceView: View {"
end_marker = "private struct CharacterProfilePanel: View {"
start = detail.find(start_marker)
end = detail.find(end_marker, start)
if start < 0 or end < 0 or end <= start:
    raise SystemExit("Could not isolate the 3D reconstruction subsystem")

block = detail[start:end].rstrip() + "\n"
block = block.replace(start_marker, "struct Character3DHeadWorkspaceView: View {", 1)
three_d = """// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftUI
import RealityKit
import QuickLook

/// Optional RealityKit photogrammetry workspace.
///
/// Reconstruction is deliberately temporary presentation state: it reads existing
/// portrait/reference images, writes only to an isolated temporary directory and
/// never mutates SwiftData or archive-v1 data. Device capability, minimum input and
/// cancellation remain explicit user-visible boundaries.
""" + block
Path("CharacterProfiler/Views/Character3DHeadWorkspaceView.swift").write_text(three_d)
detail_path.write_text(detail[:start] + detail[end:])

# Register the new source in the hand-maintained Xcode project.
project_path = Path("CharacterProfiler.xcodeproj/project.pbxproj")
project = project_path.read_text()
project = insert_once(
    project,
    "\t\tA40000000000000000000001 /* CharacterVisualWorkspaceView.swift in Sources */ = {isa = PBXBuildFile; fileRef = B40000000000000000000001 /* CharacterVisualWorkspaceView.swift */; };\n",
    "\t\tA70000000000000000000001 /* Character3DHeadWorkspaceView.swift in Sources */ = {isa = PBXBuildFile; fileRef = B70000000000000000000001 /* Character3DHeadWorkspaceView.swift */; };\n",
)
project = insert_once(
    project,
    "\t\tB40000000000000000000001 /* CharacterVisualWorkspaceView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CharacterVisualWorkspaceView.swift; sourceTree = \"<group>\"; };\n",
    "\t\tB70000000000000000000001 /* Character3DHeadWorkspaceView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Character3DHeadWorkspaceView.swift; sourceTree = \"<group>\"; };\n",
)
project = insert_once(
    project,
    "\t\t\t\tB40000000000000000000001 /* CharacterVisualWorkspaceView.swift */,\n",
    "\t\t\t\tB70000000000000000000001 /* Character3DHeadWorkspaceView.swift */,\n",
)
project = insert_once(
    project,
    "\t\t\t\tA40000000000000000000001 /* CharacterVisualWorkspaceView.swift in Sources */,\n",
    "\t\t\t\tA70000000000000000000001 /* Character3DHeadWorkspaceView.swift in Sources */,\n",
)
project_path.write_text(project)

# Keep architecture documentation synchronized with source ownership.
architecture_path = Path("ARCHITECTURE.md")
architecture = architecture_path.read_text()
section_start = architecture.find("## Source organization")
section_end = architecture.find("## Destructive-action and error safety", section_start)
if section_start < 0 or section_end < 0:
    raise SystemExit("Architecture source-organization section not found")
source_section = """## Source organization

`CharacterDetailView.swift` is the character-workspace shell and navigation boundary. Subsystem-heavy implementations are kept separate so presentation state does not turn the shell into a second application layer:

- `CharacterGuideView.swift` — Guide workflow;
- `CharacterRelationshipsView.swift` — relationships and family projection;
- `CharacterHistoryView.swift` — life history;
- `CharacterVisualWorkspaceView.swift` — persistent 2D appearance workflow; and
- `Character3DHeadWorkspaceView.swift` — temporary RealityKit reconstruction and Quick Look presentation.

The 3D subsystem remains separate even though its USDZ is not persisted. If persistence/export/editing is added later, that change requires an explicit storage/archive contract rather than expanding the workspace shell or silently adding model state.

Comments should explain invariants, compatibility decisions and non-obvious safety constraints rather than restating obvious Swift syntax.

"""
architecture_path.write_text(architecture[:section_start] + source_section + architecture[section_end:])

# Put the important SwiftData invariants next to the model declarations.
model_path = Path("CharacterProfiler/Models/CharacterProfile.swift")
model = model_path.read_text()
model = model.replace(
    "@Model\nfinal class StoryProject {",
    "/// Persistent story root. Character-scoped author work must also advance `updatedAt`\n"
    "/// so Story Library recency reflects work performed below the project record.\n"
    "@Model\nfinal class StoryProject {",
    1,
)
model = model.replace(
    "@Model\nfinal class CharacterProfile {",
    "/// Persistent character aggregate. Flexible sections and visual/history/Guide records\n"
    "/// are owned children; relationship edges are shared graph records whose direction has\n"
    "/// semantic meaning. Raw enum strings are compatibility storage and must remain stable.\n"
    "@Model\nfinal class CharacterProfile {",
    1,
)
relationship_marker = (
    "    @Relationship(deleteRule: .cascade, inverse: \\CharacterRelationship.source)\n"
    "    var outgoingRelationships: [CharacterRelationship] = []\n"
)
if relationship_marker not in model:
    raise SystemExit("Character relationship ownership marker changed unexpectedly")
model = model.replace(
    relationship_marker,
    "    // A relationship is stored once. Do not create a second inverse edge;\n"
    "    // endpoint-relative meaning is derived by CharacterRelationship.kind(from:).\n"
    + relationship_marker,
    1,
)
model = model.replace(
    "@Model\nfinal class CharacterRelationship {",
    "/// One directed graph edge shared by two characters. `kindRaw` is interpreted from\n"
    "/// `source`; callers viewing from `target` receive the defined inverse meaning.\n"
    "@Model\nfinal class CharacterRelationship {",
    1,
)
model_path.write_text(model)

# Self-remove all one-shot implementation machinery from the final tree.
Path(".github/workflows/temporary-source-cleanup.yml").unlink()
Path(".github/scripts/temporary_source_cleanup.py").unlink()
