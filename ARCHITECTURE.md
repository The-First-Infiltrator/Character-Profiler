<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Architecture

## Purpose

Character Profiler is an author-facing, local-first story bible. Product intent lives in `docs/PRODUCT_SPEC.md`; implementation status and sequencing live in `docs/FEATURE_STATUS.md` and `docs/ROADMAP.md`.

The app deliberately stops at the character boundary. It is not a scene generator, animation/film system, game engine or automatic story writer.

## Core principles

- Author-entered facts are canon; suggestions never silently overwrite them.
- Flexible profile data is preferred to endlessly expanding a rigid schema.
- Relationships are real graph edges between character records.
- Family/relationship diagrams are derived views, never second databases.
- Life history remains author data; the Guide may react to it but does not rewrite it.
- Visual generation is optional and availability-gated.
- The accepted canonical visual is the identity anchor for turnaround generation.
- Portable backups are explicitly versioned application documents, not raw SwiftData stores.
- Persistence changes and archive-format changes are separate compatibility contracts.
- Major author workflows surface persistence/import failures rather than silently swallowing them.

## Persistent model

```text
StoryProject
└── CharacterProfile[]
    ├── ProfileSection[]
    │   └── ProfileField[]
    ├── LifeEvent[]
    ├── PromptResponse[]
    ├── outgoing/incoming CharacterRelationship[]
    ├── CharacterReferenceImage[]
    ├── generatedVisualData
    └── CharacterVisualFrame[]
```

Version 0.8 adds no SwiftData entity or persistent field.

## Story and legacy migration

A `StoryProject` owns story metadata and a cast. A `CharacterProfile` normally belongs to exactly one project.

Older pre-project characters may exist with `project == nil`. `LegacyDataMigration.assignUnassignedCharacters` moves those records into one `Imported Characters` project. The helper is intentionally idempotent: if no orphan records remain, another migration pass performs no work and creates no duplicate imported project.

This is compatibility logic for older local records, not a new 0.8 schema migration.

## Flexible profile

`ProfileSection` and `ProfileField` remain generic. Genre- or story-specific character attributes can be added without a persistent model change.

## Relationship graph

`CharacterRelationship` is one shared edge between two `CharacterProfile` objects. The stored kind is interpreted from `source`; `kind(from:)` returns the correct inverse at the opposite endpoint.

Examples:

- stored parent → source sees parent, target sees child;
- stored mentor → source sees mentor, target sees student.

Structural invariants:

- endpoints must be real, distinct characters;
- inverse meaning is represented by one edge, not duplicate inverse records;
- equivalent duplicate family links are rejected;
- parent/child links may not create ancestry cycles;
- a direct ancestor/descendant pair may not also be siblings;
- graphical family/network views are projections of this graph.

### Editing relationships

Version 0.8 edits the existing edge rather than delete/recreate.

`RelationshipEditingRules.storedKind(displayedKind:for:viewedFrom:)` translates a kind selected from the current character's perspective back into the stored source-oriented value. This preserves inverse semantics even when an edge is edited from its target character.

`FamilyRelationshipRules.validationMessage(... excluding:)` can omit the edge under edit while evaluating the proposed state. Duplicate/family-link checks and ancestor traversal therefore do not mistake the current value for a conflicting second edge, while all structural invariants still apply to the edited result.

Deleting an edge removes the same relationship from both endpoint views and immediately changes any derived family tree.

### Family projection

`FamilyGraphSnapshot` walks family relationship kinds from the selected root and assigns relative generations:

- parent: -1;
- child: +1;
- sibling/spouse/partner: 0.

The snapshot is transient. `FamilyTreeView` computes layout and draws connectors separately from interactive SwiftUI character cards. No family-tree persistence model exists.

## Life history and chronology

`LifeEvent` records title, kind, free-text timing, details, impact and `sortOrder`.

Free-text timing is deliberately not used as a universal parser/sort key. Author chronology may contain “Age 12”, “before the uprising”, invented calendar dates or other story-specific text.

Version 0.8 makes `sortOrder` explicit author-controlled chronology through `LifeEventOrdering`:

- `reorderedIDs` provides deterministic pure ordering behavior;
- `move` updates stored `sortOrder` values;
- `normalize` restores contiguous order values after create/delete/edit flows.

Editing changes the existing `LifeEvent` object in place. Deleting history is confirmed because it can also alter adaptive Guide context.

## Character Guide

`CharacterGuide.swift` owns stable prompt content and deterministic selection. `PromptResponse` stores author answers.

`PromptEngine.detailedSuggestions` combines genre relevance, development-depth heuristics, category balancing and adaptive recorded context. `GuideSuggestion.reason` explains selection in the UI but is not persisted as character canon.

Stable prompt IDs are part of compatibility: existing response IDs must not be casually renamed.

Full arbitrary semantic contradiction detection is not currently claimed.

## Cast search and large projects

`CharacterSearch.matches` centralises project cast search. It covers:

- name/nickname/role/summary;
- profile section/field labels and values;
- linked character display names;
- relationship kind labels;
- relationship notes.

Adding a relationship uses a searchable character picker rather than a large flat picker, so selection remains usable as cast size grows.

## Portable project archive

`ProjectArchive.swift` defines Character Profiler archive format v1 as a `Codable` projection of the author-visible project graph.

Format v1 includes project metadata, characters, profile sections/fields, life events (including ordering), Guide responses, relationship edges, profile/reference images, canonical generated visual and turnaround frames.

Archived UUIDs are reconstruction keys only. Restore creates fresh SwiftData identifiers, maps archived character IDs to new local records, then rebuilds relationships after all characters exist. This lets one backup be restored repeatedly without unique-ID collision.

Validation rejects unsupported versions and malformed graph structure before a restore is accepted. Failed restore attempts clean up partial destination data.

Version 0.8 does not change archive format v1 because it introduces no new persisted information.

## Character Visual Studio

`CharacterVisualWorkspaceView.swift` owns the visual workflow. Existing persistent fields remain sufficient:

- `CharacterReferenceImage` with label/order/image data;
- `generatedVisualData` as the accepted canonical visual;
- `CharacterVisualFrame` keyed by `VisualAngle`.

Image Playground availability is read at runtime. Core character/profile/Guide/relationship/history/archive features do not depend on visual AI.

The canonical visual is the source identity image for angle generation. `VisualWorkspaceSnapshot` derives available/missing/duplicate angle state and completion across eight fixed 45° positions.

The turnaround is an image-based inspection sequence, not a true 3D mesh.

Simulator CI can validate APIs and deterministic state, but physical-device testing is still required to judge whether generated face/body/clothing/equipment identity remains acceptably consistent.

## Destructive-action and error safety

Story/character deletion reports affected linked data. Version 0.8 adds confirmed deletion for relationships and life events.

Major author save paths use explicit `do/catch` feedback instead of treating `try?` as acceptable release behavior. Portrait import also distinguishes unreadable/failed conversion from a successful selection.

Confirmations are not an undo system; portable backup remains the durable recovery mechanism.

## UI flow

```text
ProjectListView
├── Restore Backup
├── LegacyDataMigration
└── ProjectDetailView
    ├── Project overview
    ├── searchable cast / CharacterSearch
    ├── Export Backup
    └── CharacterDetailView
        ├── Profile
        ├── Guide
        ├── People
        │   ├── RelationshipEditorView
        │   ├── RelationshipCharacterPicker
        │   └── FamilyTreeView / FamilyGraphSnapshot
        ├── History
        │   ├── LifeEventEditorView
        │   └── LifeEventOrdering
        └── Visual
            └── CharacterVisualWorkspaceView

ProjectArchiveDocument
└── ProjectArchive format v1
```

## Compatibility and release gate

The core deployment target remains iOS 17. Image Playground-specific functionality is separately availability-gated.

GitHub Actions dynamically prepares an iPhone simulator and runs the complete Xcode test suite. A green run on the exact final feature/release head is required before integration.

Migration strategy by release:

- 0.4: family tree is derived; no persistent change.
- 0.5: Guide scoring/reasons are derived; no persistent change.
- 0.6: portable archive v1 added outside SwiftData schema.
- 0.7: visual hardening uses existing visual records/order metadata.
- 0.8: author-workflow hardening edits/orders existing records and tests legacy migration; no persistent change and archive stays v1.

Any future schema change capable of invalidating stored records requires a deliberate migration design and regression tests before release.
