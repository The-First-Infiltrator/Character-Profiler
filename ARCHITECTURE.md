<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Architecture

## Purpose and source of truth

Character Profiler is an author-facing story bible. It remembers facts about a cast, helps an author discover missing character detail, links people to one another, records formative history and establishes a consistent visual reference for each character.

Product intent is defined in `docs/PRODUCT_SPEC.md`. Current implementation coverage is tracked in `docs/FEATURE_STATUS.md`, and planned sequencing is in `docs/ROADMAP.md`.

The application deliberately stops at the character boundary. It is not a scene generator, animation system, filmmaking tool or game engine.

## Architectural principles

- The core data model must remain useful without AI services.
- Author-entered facts are persistent canon; suggestions do not silently overwrite them.
- Flexible profile data is preferred over continually expanding a rigid database schema.
- Relationships link real character records and have meaningful inverse views.
- Visual family/network presentations are derived projections of relationship edges, never a second relationship database.
- Character Guide selection remains deterministic and explainable unless a future product decision deliberately introduces another reasoning layer.
- Visual generation is optional and availability-gated.
- Provider-specific AI code must not become the owner of core character data.
- Existing story data must survive model evolution through compatible defaults or explicit migrations.
- Portable backups are application-owned, versioned interchange documents rather than raw persistence-store copies.
- Import must fail safely: unsupported or structurally invalid archives must be rejected rather than partially guessed into the data model.

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
```

### StoryProject

Stores story title, genre, optional custom genre, premise and the cast. Character search and ordinary navigation are scoped to the active project.

### CharacterProfile

Stores frequently used metadata and owns the expandable profile, life history, prompt answers, relationship edges and visual assets.

`visualDescription` stores author-supplied appearance instructions. `generatedVisualData` stores the approved canonical AI character image using SwiftData external binary storage.

A character normally belongs to one project. Earlier pre-project characters are migrated into an `Imported Characters` project.

### Flexible profile

`ProfileSection` and `ProfileField` remain intentionally generic. Authors can add arbitrary attributes without requiring a database schema change for every genre-specific idea.

Default profile sections are convenience content, not storage constraints.

### Relationships

`CharacterRelationship` is an edge between two `CharacterProfile` objects. Directional relationships derive the inverse view automatically, such as parent/child and mentor/student.

Important invariants:

- both endpoints refer to real character records;
- the same edge must be interpretable from either endpoint;
- duplicate equivalent links should be rejected at creation time;
- parent/child creation must not introduce an ancestry cycle;
- an ancestor/descendant pair cannot also be recorded as siblings;
- deleting or editing relationships must not create a second contradictory copy merely to express the inverse label;
- graphical family/network views are projections of this graph, not a second relationship database.

### Family graph projection

Version 0.4 introduced `FamilyGraphSnapshot`, an in-memory projection rooted on the currently selected character. It walks only family relationship kinds and assigns a generation offset relative to the root:

- parent = -1 generation;
- child = +1 generation;
- sibling, spouse and partner = same generation.

The projection follows connected relatives so grandparents, grandchildren and more distant generations can appear without additional stored family-tree entities. Relationship edges are deduplicated by relationship ID during graph construction.

`FamilyTreeView` computes a layout from that snapshot. SwiftUI character cards remain ordinary interactive views, while a `Canvas` draws connectors behind them. This separation keeps navigation and accessibility on normal controls while avoiding a duplicate visual-data model.

The family view supports two-axis scrolling and zoom. The selected root is visually distinguished, and tapping another family member opens that character's existing record.

`FamilyRelationshipRules` performs structural validation before a new relationship is saved. Its purpose is data integrity, not social or moral judgement: it blocks self-links, duplicate family links and ancestry contradictions while otherwise leaving fictional family structures to the author.

### Life history

`LifeEvent` records formative events and their lasting impact. Trauma and loss can feed additional Character Guide suggestions.

History is character data, not AI-generated narrative. The Guide can react to it but does not rewrite it.

## Character Guide

Version 0.5 moves Guide logic into `CharacterGuide.swift`. Prompt definitions remain application content, while `PromptResponse` stores the author's accepted answers.

The Guide has two public selection layers:

- `PromptEngine.suggestions(...)` preserves the original simple `[CharacterPrompt]` API for compatibility;
- `PromptEngine.detailedSuggestions(...)` returns richer `GuideSuggestion` values containing the prompt, a human-readable reason and an internal relevance score.

### Prompt catalogue

The catalogue contains universal prompts plus expanded built-in genre sets. Prompt IDs are stable storage keys. Changing wording or ranking must not casually rename an existing ID because saved `PromptResponse` records use that identifier to suppress already answered questions.

### Development depth

`developmentDepths(for:)` builds a lightweight score for each `PromptCategory`. Signals include:

- answered Guide prompts;
- common profile sections and field labels;
- nickname, age and pronouns for identity;
- story role;
- summary content;
- linked relationships;
- life events, including extra weight for trauma/loss.

The score is deliberately heuristic rather than pretending to be semantic understanding. Its job is to notice obviously sparse areas and give them more opportunity to appear.

### Candidate scoring and balance

For every applicable catalogue prompt, the engine combines genre relevance with the current depth of that category. Genre-specific prompts receive a relevance advantage, while categories with little recorded detail receive an underdevelopment bonus.

Adaptive suggestions use higher explicit scores when an existing fact creates a strong follow-up opportunity.

After duplicate IDs and answered prompts are removed, `balancedSelection` first aims for category diversity and then fills remaining slots by score with a soft cap on repeated categories. This prevents a character with one strong theme—such as trauma or relationships—from receiving a whole screen of nearly identical questions.

### Adaptive context rules

The deterministic adaptive layer can react to:

- trauma or loss;
- existing relationships and family links;
- multiple life events;
- recorded story role;
- fantasy magic terminology;
- taverns/drinking-place behaviour;
- war, battle, soldiers, combat or mercenary history;
- secrecy/deception;
- faith/religion;
- money/wealth/poverty/debt;
- family terminology;
- romance/partnership language;
- revenge/vengeance.

The searchable corpus is assembled from summary, role, visual description, profile fields, saved Guide answers, life-event text and relationship notes. These rules generate questions only; they do not alter the character record.

### Explanation and limits

Each rich suggestion carries a reason such as genre relevance, an underdeveloped category or a specific recorded context trigger. Version 0.5.1 exposes that explanation directly in the Guide UI while keeping it separate from persisted canonical prompt/answer data.

Version 0.5 does **not** claim deep semantic contradiction detection. Recognising that two arbitrary prose facts cannot both be true would require a separately designed reasoning layer and remains future work.

Answered prompt IDs remain suppressed from the unanswered suggestion queue. Prompt selection can evolve without a SwiftData migration as long as stable prompt identifiers are preserved.

## Portable project archive

Version 0.6 introduces `ProjectArchive.swift`, a non-SwiftData support layer for explicit project backup and restore.

### Why an application archive exists

A raw SwiftData store is an implementation detail and is not a stable interchange contract. The portable archive instead serialises the author-visible project graph into an application-owned `Codable` structure.

Archive format version 1 contains:

- project metadata and timestamps;
- all characters and commonly used metadata;
- arbitrary profile sections and fields;
- life events;
- saved Guide prompt responses;
- relationship edges between characters in the project;
- profile images;
- author reference images;
- canonical generated visual data;
- turnaround frames and their `VisualAngle` values.

`JSONEncoder` produces a deterministic, human-inspectable document with sorted keys and millisecond timestamps. Binary `Data` values are represented by Codable's JSON data encoding and remain part of the single project document.

### Archive identifiers versus local identifiers

Every archived record carries its source UUID so relationships can refer to character records inside that archive. Those UUIDs are **not** replayed as the new SwiftData object IDs during restore.

Restore creates a new `StoryProject` and new local model objects. A temporary map from archived character UUID to newly created `CharacterProfile` is used to rebuild relationship edges after every character exists.

This design has two important properties:

1. importing the same backup multiple times does not violate the model's unique-ID constraints;
2. archive identity remains a reconstruction mechanism rather than making a portable document dependent on one local SwiftData store.

### Validation and failure handling

`ProjectArchive.validate()` rejects:

- unsupported archive format versions;
- missing/blank project or character identity where required;
- duplicate archived character IDs;
- duplicate archived relationship IDs;
- self-referential relationship endpoints;
- relationship endpoints that do not exist in the archived cast.

Restore validates before inserting data. Characters and their owned content are created first, relationships second. If restore throws after creating the destination project, the implementation deletes that partially created project and attempts to save the cleanup before propagating the error.

Unsupported future archive formats are rejected explicitly. A future format change should either add compatible optional/defaulted fields or introduce a deliberate version migration path; it must not rely on accidentally decoding a structurally different document.

### Document UI boundary

`ProjectArchiveDocument` conforms to SwiftUI `FileDocument`. Export uses the system file exporter and restore uses the system file importer. The author chooses where a backup is written and explicitly chooses which backup to restore.

The Story Library owns restore because restoring creates a new story. `ProjectDetailView` owns export because a backup is scoped to the currently open story.

## Character Visual Studio

Version 0.3 introduced a focused visual layer.

### Reference images

`CharacterReferenceImage` stores up to six author-selected pictures. The system Photos picker supplies only the images the author explicitly chooses. Imported images are normalised before storage.

### Canonical character image

The Visual workspace constructs a generation concept from character name and story genre, story role and summary, author visual notes, populated profile fields and a reference board composed from selected reference images.

The current implementation uses Apple's Image Playground system interface on supported devices. The author chooses the accepted result; that result becomes `generatedVisualData`.

The core model does not depend on Image Playground. If an additional provider is ever introduced, it should be placed behind a visual-generation boundary and must not require a secret to be hard-coded into the distributed iPhone application.

### 360-degree turnaround

Character Profiler does not currently construct a true 3D mesh.

`VisualAngle` defines eight standard views at 45-degree intervals. `CharacterVisualFrame` stores an accepted image for each angle. Angle generation uses the canonical character image as a source reference and asks for the same identity, proportions, clothing and equipment from the requested direction.

The turnaround viewer maps horizontal drag input across available frames. With all eight views present, the author can inspect a complete image-based turnaround.

This is deliberately an inspection tool, not an animation or posing system.

## Destructive-action safety

Version 0.6 changes list deletion from immediate model deletion to a staged destructive confirmation.

Project deletion calculates the selected project's character and relationship impact and reminds the author that profile, history, Guide and visual content is contained within that story. Character deletion reports linked relationship, history, Guide-answer and visual-asset counts.

These summaries are safeguards, not an undo system. Once the author confirms deletion, the SwiftData cascade rules remain responsible for owned records. Portable backup exists as the durable recovery mechanism.

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
        │   ├── Family / other relationship rows
        │   ├── AddRelationshipView
        │   │   └── FamilyRelationshipRules validation
        │   └── FamilyTreeView
        │       └── FamilyGraphSnapshot
        ├── History
        └── Visual
            ├── Reference Pictures
            ├── Appearance Notes
            ├── AI Character
            └── 360° Turnaround

ProjectArchiveDocument
└── ProjectArchive format v1
    ├── encode / validate / decode
    └── fresh-ID project graph reconstruction
```

A broader non-family relationship network may later build on the same graph concept, but it should remain distinct from the family tree so friends, enemies and professional links do not make genealogy unreadable.

## Compatibility and CI

The core application retains its iOS 17 deployment target. Visual AI is availability-gated so devices without Image Playground can continue using story, profile, Guide, relationship, family-tree, history and backup features.

CI builds and tests the iOS simulator target using Xcode on GitHub Actions. A green CI run is a release requirement.

Hosted macOS runner images do not always expose the same named simulator at job start, so version 0.6 no longer hard-codes `iPhone 16`. The workflow initialises CoreSimulator, selects an available iPhone simulator UUID, and if necessary downloads the default iOS runtime for the selected Xcode before running tests.

## Migration strategy

Version 0.4 added no persistent model entities or fields for the family tree. Existing relationship data is projected at runtime.

Version 0.5 also added no new persistent model fields for Guide scoring. It derives depth and adaptive context from existing character data and preserves `PromptResponse` storage.

Version 0.6 likewise adds no new SwiftData model entity or field. `ProjectArchive` is a separate Codable projection of the existing model, so backup/restore does not require a SwiftData schema migration.

The archive itself now has an independent format version. SwiftData schema evolution and archive-format evolution are related but separate compatibility concerns: a future app must be able to migrate local data safely and must also decide how older portable archive versions are decoded or upgraded.

New optional persistent features should prefer optional fields, empty defaults or explicit migration steps that preserve prior story data.

Visual fields are optional. Existing characters do not require reference images or generated visuals. The earlier migration that places pre-project characters into `Imported Characters` remains in place.

Before any future model change that can invalidate stored SwiftData objects, migration behaviour must be designed and tested rather than relying on accidental compatibility.

## Scope boundary

Future work should improve character development, relationship understanding, history, data safety and visual consistency without turning Character Profiler into an unrelated creative suite.

The following remain outside the current architecture: scene generation, video/cinematics, character animation, game-engine systems and automatic story writing.
