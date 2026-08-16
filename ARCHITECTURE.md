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
- Visual generation is optional and availability-gated.
- Provider-specific AI code must not become the owner of core character data.
- Existing story data must survive model evolution through compatible defaults or explicit migrations.

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

Version 0.4 introduces `FamilyGraphSnapshot`, an in-memory projection rooted on the currently selected character. It walks only family relationship kinds and assigns a generation offset relative to the root:

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

### Character Guide

Prompt definitions are application content. `PromptResponse` stores the author's answers.

The local engine mixes universal prompts, genre-specific prompts and adaptive follow-ups triggered by existing profile text, life events and relationships.

Answered prompt IDs are normally suppressed from the unanswered suggestion queue. Prompt selection can be refined without migrating stored answers as long as stable prompt identifiers are preserved.

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

## UI flow

```text
ProjectListView
└── ProjectDetailView
    └── CharacterDetailView
        ├── Profile
        ├── Guide
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
```

A broader non-family relationship network may later build on the same graph concept, but it should remain distinct from the family tree so friends, enemies and professional links do not make genealogy unreadable.

## Compatibility

The core application retains its iOS 17 deployment target. Visual AI is availability-gated so devices without Image Playground can continue using story, profile, Guide, relationship, family-tree and history features.

CI builds and tests the iOS simulator target using Xcode on GitHub Actions. A green CI run is a release requirement.

## Migration strategy

Version 0.4 adds no persistent model entities or fields for the family tree. Existing relationship data is projected at runtime, so no SwiftData migration is required for the graphical family feature itself.

New optional features should prefer optional fields, empty defaults or explicit migration steps that preserve prior story data.

Visual fields are optional. Existing characters do not require reference images or generated visuals. The earlier migration that places pre-project characters into `Imported Characters` remains in place.

Before any future model change that can invalidate stored SwiftData objects, migration behaviour must be designed and tested rather than relying on accidental compatibility.

## Scope boundary

Future work should improve character development, relationship understanding, history, data safety and visual consistency without turning Character Profiler into an unrelated creative suite.

The following remain outside the current architecture: scene generation, video/cinematics, character animation, game-engine systems and automatic story writing.
