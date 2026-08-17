<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Architecture

## Purpose

Character Profiler is an author-facing, local-first story bible. Product intent lives in `docs/PRODUCT_SPEC.md`; implementation status and sequencing live in `docs/FEATURE_STATUS.md` and `docs/ROADMAP.md`.

The application stops at the character boundary. It is not a scene generator, animation/film system, game engine or automatic story writer.

## Core principles

- Author-entered facts are canon; suggestions never silently overwrite them.
- Flexible profile data is preferred to endlessly expanding a rigid schema.
- Relationships are real graph edges between character records.
- Family/relationship diagrams are derived views, never second databases.
- Life history remains author data; the Guide may react to it but does not rewrite it.
- Visual generation is optional and availability-gated.
- The accepted canonical visual is the identity anchor for turnaround generation.
- Portable backups are explicitly versioned application documents, not raw SwiftData stores.
- SwiftData-schema evolution and archive-format evolution are separate compatibility contracts.
- Major author workflows surface persistence/import failures rather than silently swallowing them.
- Recovery behavior must prefer preserving potentially recoverable author data over silently replacing it.

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

Versions 0.8 and 1.0 add no SwiftData entity or persistent field. The 1.0 app continues to use the model already proven by the 0.8 release line.

## Store creation and startup failure

`CharacterProfilerApp` builds one `ModelContainer` containing the full persistent schema.

Before 1.0, a container-construction error terminated the application through `fatalError`. That is not an acceptable stable-release recovery policy because a migration, storage or filesystem problem could make the author see only a crash.

In 1.0, container construction is represented as a `Result<ModelContainer, Error>`:

- success injects the real container into `ProjectListView`;
- failure presents `DataStoreUnavailableView`;
- the failure view explains that the local story database could not be opened;
- Character Profiler does **not** automatically delete, reset or replace the store;
- the underlying error description is visible/selectable for diagnosis.

This is deliberately conservative. A future guided repair/restore workflow may improve recovery, but silent destructive “fixes” are outside the current design.

## Story and legacy migration

A `StoryProject` owns story metadata and a cast. A `CharacterProfile` normally belongs to exactly one project.

Older pre-project characters may exist with `project == nil`. `LegacyDataMigration.assignUnassignedCharacters` moves those records into one `Imported Characters` project. The helper is idempotent: if no orphan records remain, another migration pass performs no work and creates no duplicate imported project.

This is compatibility behavior for older records, not a new 1.0 schema migration.

## Flexible profile

`ProfileSection` and `ProfileField` remain generic. Genre- or story-specific character attributes can be added without a persistent-model change.

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
- graphical views are projections of this graph.

### Editing relationships

`RelationshipEditingRules.storedKind(displayedKind:for:viewedFrom:)` translates a kind selected from the current character's perspective back into the stored source-oriented value. The existing graph edge is changed rather than deleted/recreated.

`FamilyRelationshipRules.validationMessage(... excluding:)` omits the edge under edit while evaluating the proposed state. This permits legitimate changes without weakening duplicate/ancestry protection.

Deleting an edge removes the same relationship from both endpoint views and immediately changes derived family projections.

### Family projection

`FamilyGraphSnapshot` walks family relationship kinds from the selected root and assigns relative generations:

- parent: -1;
- child: +1;
- sibling/spouse/partner: 0.

The snapshot is transient. `FamilyTreeView` computes layout and draws connectors separately from interactive SwiftUI character cards. No family-tree persistence model exists.

## Life history and chronology

`LifeEvent` records title, kind, free-text timing, details, impact and `sortOrder`.

Free-text timing is intentionally not treated as a universal machine-sortable date. Authors may use “Age 12”, “three winters before the war”, fictional calendars or ordinary dates.

`LifeEventOrdering` makes chronology explicitly author-controlled:

- `reorderedIDs` provides deterministic pure ordering behavior;
- `move` changes stored sequence;
- `normalize` restores contiguous `sortOrder` values after edit/create/delete flows.

Editing changes the existing event in place. Deleting history is confirmed because history also feeds adaptive Guide context.

## Character Guide

`CharacterGuide.swift` owns stable prompt content and deterministic selection. `PromptResponse` stores author answers.

`PromptEngine.detailedSuggestions` combines genre relevance, development-depth heuristics, category balancing and adaptive recorded context. `GuideSuggestion.reason` explains selection in the UI but is not persisted as character canon.

Stable prompt IDs are compatibility keys and should not be casually renamed. Full arbitrary semantic contradiction detection is not currently claimed.

## Cast search and large projects

`CharacterSearch.matches` centralizes cast search across character identity/role/summary, flexible profile fields, linked character names, relationship kind labels and relationship notes.

Adding a relationship uses a searchable cast picker rather than an unbounded flat picker.

## Portable project archive

`ProjectArchive.swift` defines Character Profiler archive format v1 as a `Codable` projection of the author-visible project graph.

Format v1 includes project metadata, characters, flexible sections/fields, life events and ordering, Guide responses, relationship edges, profile/reference images, canonical generated visual and turnaround frames.

Archived UUIDs are reconstruction keys only. Restore creates fresh SwiftData identifiers, maps archived character IDs to the new local records and rebuilds relationships only after all characters exist. One backup can therefore be restored repeatedly without identifier collision.

### Validation boundary

Validation occurs before restore inserts the destination project. Format v1 rejects:

- unsupported archive versions;
- blank story title;
- blank character names;
- duplicate archived character identifiers;
- duplicate archived relationship identifiers;
- self-referential relationship endpoints;
- relationship endpoints not present in the archived cast.

The 1.0 test suite includes hostile/malformed archive cases and asserts that self/missing-endpoint failures leave no destination `StoryProject` inserted in the test container.

The established whole-story test also encodes/decodes/restores a developed project twice and checks profile content, Guide answers, history, visual assets and relationship direction.

1.0 retains archive format v1 because no new persisted author information requires a format change.

## Character Visual Studio

`CharacterVisualWorkspaceView.swift` owns the visual workflow. Persistent data consists of labelled/ordered `CharacterReferenceImage` records, `generatedVisualData` for the accepted canonical image and `CharacterVisualFrame` records keyed by `VisualAngle`.

Image Playground support is availability-gated. Core profile, Guide, relationship, history and archive functionality does not depend on visual generation.

The canonical visual is the source identity image for turnaround generation. `VisualWorkspaceSnapshot` derives available/missing/duplicate state and completion across eight fixed 45° slots.

The turnaround is an image-based inspection sequence, not a true 3D mesh.

Simulator CI can prove SDK integration and deterministic state. It cannot prove that physical Image Playground output preserves face, proportions, clothing, colours and equipment acceptably across eight generated angles. That remains an explicit physical-device validation item.

## Destructive-action and error safety

Story and character deletion report affected linked data. Relationship and life-event removal are also confirmed before deletion.

Major author save/import paths use explicit `do/catch` feedback. Portrait import distinguishes unreadable/failed conversion from a valid image. Startup store-open failure has a dedicated non-destructive state.

Confirmations are not an undo system; portable project backup remains the durable user-controlled recovery mechanism.

## UI flow

```text
CharacterProfilerApp
├── successful ModelContainer
│   └── ProjectListView
│       ├── Restore Backup
│       ├── LegacyDataMigration
│       └── ProjectDetailView
│           ├── Project overview
│           ├── searchable cast / CharacterSearch
│           ├── Export Backup
│           └── CharacterDetailView
│               ├── Profile
│               ├── Guide
│               ├── People
│               │   ├── RelationshipEditorView
│               │   ├── RelationshipCharacterPicker
│               │   └── FamilyTreeView / FamilyGraphSnapshot
│               ├── History
│               │   ├── LifeEventEditorView
│               │   └── LifeEventOrdering
│               └── Visual
│                   └── CharacterVisualWorkspaceView
└── failed ModelContainer
    └── DataStoreUnavailableView

ProjectArchiveDocument
└── ProjectArchive format v1
```

## Compatibility and release gate

The core deployment target remains iOS 17. Image Playground functionality is separately availability-gated.

For 1.0, GitHub Actions has two build gates on the exact candidate SHA:

1. dynamically prepare/discover an iPhone simulator and run the complete `xcodebuild test` suite;
2. independently compile the `Release` configuration with signing disabled.

After merge, the exact `main` commit must pass the same workflow. A tag/GitHub Release is a separate publication action.

Migration/compatibility history:

- 0.4: family tree derived from existing relationships; no persistent change.
- 0.5: Guide scoring/reasons derived from existing records; no persistent change.
- 0.6: portable archive format v1 added separately from SwiftData schema.
- 0.7: visual hardening reused existing visual records/order metadata.
- 0.8: author-workflow hardening edited/ordered existing records and tested legacy migration; no persistent change.
- 1.0: startup/data/archive/release hardening; no persistent change and archive remains v1.

Any future schema change capable of invalidating stored records requires deliberate migration design and regression coverage before release. Archive-format evolution requires an independent version/upgrade decision.
