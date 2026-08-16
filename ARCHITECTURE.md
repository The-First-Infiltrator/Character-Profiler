<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Architecture

## Purpose and source of truth

Character Profiler is an author-facing story bible. It remembers facts about a cast, helps an author discover missing character detail, links people to one another, records formative history, protects the author's work through portable backups and establishes a consistent visual reference for each character.

Product intent is defined in `docs/PRODUCT_SPEC.md`. Current implementation coverage is tracked in `docs/FEATURE_STATUS.md`, and sequencing is tracked in `docs/ROADMAP.md`.

The application deliberately stops at the character boundary. It is not a scene generator, animation system, filmmaking tool or game engine.

## Architectural principles

- The core data model must remain useful without AI services.
- Author-entered facts are persistent canon; suggestions do not silently overwrite them.
- Flexible profile data is preferred over continually expanding a rigid database schema.
- Relationships link real character records and have meaningful inverse views.
- Visual graph presentations are derived projections of relationship edges, never second relationship databases.
- Character Guide selection remains deterministic and explainable unless a future product decision deliberately introduces another reasoning layer.
- Visual generation is optional and availability-gated.
- The accepted canonical visual is the identity anchor for generated turnaround views.
- Provider-specific AI code must not become the owner of core character data.
- Existing story data must survive model evolution through compatible defaults or explicit migrations.
- Portable backups are application-owned, versioned interchange documents rather than raw persistence-store copies.
- Import must fail safely: unsupported or structurally invalid archives are rejected rather than guessed into the model.

## Persistent model

```text
StoryProject
└── CharacterProfile[]
    ├── ProfileSection[]
    │   └── ProfileField[]
    ├── LifeEvent[]
    ├── PromptResponse[]
    ├── outgoing/incoming CharacterRelationship[]
    │   └── derived FamilyGraphSnapshot / FamilyTreeView
    ├── CharacterReferenceImage[]
    ├── generatedVisualData
    └── CharacterVisualFrame[]
        └── VisualAngle
```

### StoryProject

Stores story title, genre, optional custom genre, premise and cast. Character search and ordinary navigation are scoped to the active project.

### CharacterProfile

Stores frequently used metadata and owns the expandable profile, life history, prompt answers, relationship edges and visual assets.

`visualDescription` stores author-supplied appearance instructions. `generatedVisualData` stores the accepted canonical generated image using SwiftData external binary storage.

A character normally belongs to one project. Earlier pre-project characters are migrated into an `Imported Characters` project.

### Flexible profile

`ProfileSection` and `ProfileField` are intentionally generic. Authors can add arbitrary attributes without a schema change for every genre-specific idea. Default profile sections are convenience content, not storage constraints.

## Relationships and family graph

`CharacterRelationship` is an edge between two real `CharacterProfile` objects. Directional relationships derive inverse meaning automatically, such as parent/child and mentor/student.

Important invariants:

- both endpoints are real character records;
- the same edge is interpretable from either endpoint;
- duplicate equivalent family links are rejected;
- parent/child creation must not introduce an ancestry cycle;
- an ancestor/descendant pair cannot also be recorded as siblings;
- inverse meaning must not be represented by creating a contradictory duplicate edge;
- graphical views are projections of the relationship graph, not separate persistent relationship stores.

### FamilyGraphSnapshot

`FamilyGraphSnapshot` is an in-memory projection rooted on the selected character. It walks family relationship kinds and assigns a generation offset relative to the root:

- parent = -1 generation;
- child = +1 generation;
- sibling, spouse and partner = same generation.

Connected relatives are traversed so grandparents, grandchildren and larger families can appear without additional persistent entities. Relationship edges are deduplicated by relationship ID.

`FamilyTreeView` computes a layout from that snapshot. SwiftUI cards remain interactive views while a `Canvas` draws connectors behind them. The family view supports two-axis scrolling and zoom.

`FamilyRelationshipRules` protects graph structure before a new link is saved. It blocks self-links, duplicate family links and ancestry contradictions without imposing social assumptions on fictional family structures.

## Life history

`LifeEvent` stores formative events and their lasting impact. Trauma and loss can feed additional Character Guide suggestions.

History is character data, not AI-generated narrative. The Guide may react to it but does not rewrite it.

## Character Guide

Guide logic lives in `CharacterGuide.swift`. Prompt definitions are application content; `PromptResponse` stores author answers.

Two selection APIs are maintained:

- `PromptEngine.suggestions(...)` provides the original simple `[CharacterPrompt]` compatibility API;
- `PromptEngine.detailedSuggestions(...)` returns `GuideSuggestion` values containing the prompt, human-readable reason and relevance score.

Prompt IDs are stable storage keys. Existing IDs should not be casually renamed because saved responses use them to suppress answered questions.

### Development depth and balance

`developmentDepths(for:)` builds a lightweight heuristic score for each `PromptCategory` from profile fields, answered Guide prompts, metadata, relationships, story role and life events.

Applicable prompts are scored using genre relevance and category depth. Adaptive suggestions receive higher scores when recorded facts create strong follow-up opportunities. Selection then aims for category diversity before filling remaining slots by score with a soft cap on repetition.

The deterministic adaptive layer can react to subjects including trauma/loss, family, multiple life events, role, magic, taverns/drinking-place behaviour, war/combat, secrecy, faith, money, romance and revenge.

Each rich suggestion carries a reason. The UI exposes that reason without persisting it as character canon.

Character Profiler does **not** currently claim arbitrary semantic contradiction detection across prose facts.

## Portable project archive

`ProjectArchive.swift` is a non-SwiftData support layer for explicit project backup and restore.

A raw SwiftData store is an implementation detail, not a stable interchange contract. Archive format 1 serialises the author-visible project graph into a `Codable` structure containing:

- project metadata and timestamps;
- all characters and common metadata;
- arbitrary profile sections and fields;
- life events;
- Guide responses;
- relationship edges;
- profile images;
- author reference images;
- canonical generated visual data;
- turnaround frames and `VisualAngle` values.

### Archive identifiers versus local identifiers

Archived UUIDs exist so relationships can refer to character records inside the document. Restore does **not** replay those UUIDs as new SwiftData object IDs.

Restore creates a new project and new local model objects. A temporary archived-character-ID to new-character map reconstructs relationships only after all characters exist. This allows the same backup to be restored multiple times without unique-ID collisions.

### Validation and failure handling

Archive validation rejects unsupported format versions, required blank identity, duplicate archived IDs, self-referential relationship endpoints and relationship endpoints that do not exist in the archived cast.

Restore validates before insertion and removes a partially created destination project if a later reconstruction step throws.

`ProjectArchiveDocument` conforms to SwiftUI `FileDocument`. Export uses the system file exporter; restore uses the system file importer.

## Character Visual Studio

Version 0.7 moves the visual workflow into the dedicated `CharacterVisualWorkspaceView.swift` source. The persistent model remains the same; the new state helpers are derived projections over existing visual records.

### Runtime availability

Visual AI uses Apple's Image Playground integration when supported. The workspace reads SwiftUI's Image Playground support environment value before enabling generation controls.

If generation is unavailable, existing reference pictures, appearance notes, canonical images and turnaround frames remain visible/manageable. The rest of Character Profiler never depends on visual generation being available.

### Reference images

`CharacterReferenceImage` stores up to six selected pictures. Images are normalised before storage. Existing `label` and `sortOrder` fields are used for explicit reference naming and ordering; 0.7 requires no new persistent fields.

`VisualReferenceOrdering` contains deterministic ordering logic. Reordering changes `sortOrder`; it does not duplicate image records.

### Canonical character image

The canonical generation concept combines character name/story context, role, summary, appearance notes, populated profile fields and a reference board assembled from selected reference images.

The accepted result becomes `generatedVisualData` and may also be copied to the profile portrait.

The canonical image is the identity anchor for turnaround generation. Once an angle is being generated, the source image is the accepted canonical visual rather than the original reference board or profile portrait.

When a canonical image is replaced while angle frames exist, the UI makes the stale-turnaround risk explicit. The author may keep existing views or request a turnaround reset. Crucially, that reset occurs only after a replacement image is successfully accepted; opening and cancelling generation does not destroy existing frames.

Clearing the visual set removes canonical/turnaround generated data while retaining source reference pictures and appearance notes.

### Fixed eight-slot turnaround

Character Profiler does not construct a true 3D mesh.

`VisualAngle` defines eight standard slots at 45-degree intervals:

1. front (0°)
2. front-right (45°)
3. right (90°)
4. back-right (135°)
5. back (180°)
6. back-left (225°)
7. left (270°)
8. front-left (315°)

`CharacterVisualFrame` stores accepted image data for an angle. Missing views are represented by the absence of a frame for that `VisualAngle`; no placeholder object is persisted.

`VisualWorkspaceSnapshot` derives:

- whether a canonical visual exists;
- current reference count;
- unique available angles;
- missing angles;
- duplicate stored angles;
- completed angle count and progress.

The viewer navigates the fixed `VisualAngle` sequence rather than a filtered list of existing frames. This means missing positions remain visible and understandable. The author can generate a missing slot, regenerate/delete an existing slot, generate the next missing slot, or reset all angle frames while keeping the canonical/reference material.

Duplicate stored angle records are treated as a data-integrity warning. The derived snapshot counts the angle once for completion and reports the duplicate condition instead of falsely claiming more than eight views.

### Validation boundary

Simulator CI can prove the SwiftUI/Image Playground SDK integration compiles and can test deterministic state/navigation/reference-ordering logic.

Simulator CI cannot judge the visual quality of Image Playground output or guarantee that a physical device will preserve face, proportions, clothing and equipment consistently across all generated angles. That remains a real-device validation requirement.

## Destructive-action safety

Story and character deletion use staged confirmations rather than immediate model deletion. Project deletion reports cast/relationship impact and reminds the author about backups. Character deletion reports linked relationship, history, Guide-answer and visual-asset counts.

These confirmations are safeguards, not an undo system. Portable backup is the durable recovery mechanism.

## UI flow

```text
ProjectListView
├── Restore Backup
└── ProjectDetailView
    ├── Project overview metrics
    ├── Export Backup
    └── CharacterDetailView
        ├── Profile
        ├── Guide
        │   └── PromptEngine / GuideSuggestion
        ├── People
        │   ├── relationship rows
        │   ├── AddRelationshipView
        │   │   └── FamilyRelationshipRules
        │   └── FamilyTreeView
        │       └── FamilyGraphSnapshot
        ├── History
        └── Visual
            └── CharacterVisualWorkspaceView
                ├── reference management
                ├── appearance notes
                ├── canonical visual lifecycle
                └── VisualWorkspaceSnapshot / 8 angle slots

ProjectArchiveDocument
└── ProjectArchive format v1
    ├── encode / validate / decode
    └── fresh-ID project graph reconstruction
```

## Compatibility and CI

The core application retains its iOS 17 deployment target. Image Playground-specific UI is availability-gated.

GitHub Actions builds/tests the iOS simulator target using Xcode. The workflow initialises CoreSimulator, discovers an available iPhone simulator UUID and can download the default iOS runtime if a hosted runner exposes no usable iPhone simulator.

A green exact-head CI run is a release requirement.

## Migration strategy

- Version 0.4 added no persistent entities/fields for the family tree; it is derived from relationship data.
- Version 0.5 added no persistent fields for Guide scoring; it derives state from existing character records.
- Version 0.6 added no SwiftData entity/field; archive format v1 is a separate `Codable` projection.
- Version 0.7 adds no SwiftData entity/field; Visual Studio hardening derives state from existing reference/canonical/frame records and existing ordering metadata.

The archive format and SwiftData schema are separate compatibility contracts. A future app must migrate local persistence safely and also deliberately decide how older portable archive versions are decoded/upgraded.

Before any model change that can invalidate stored SwiftData objects, migration behaviour must be designed and tested rather than relying on accidental compatibility.

## Scope boundary

Future work should improve character development, relationship understanding, history, data safety and visual consistency without turning Character Profiler into an unrelated creative suite.

The following remain outside the current architecture: scene generation, video/cinematics, character animation, game-engine systems, a large posing studio and automatic story writing.
