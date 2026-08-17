<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler

Character Profiler is a native iPhone story-bible and character-development app for authors. It combines flexible profiles, structured relationships and family, life history, genre-aware development questions, portable project backup and a focused visual workspace.

## Version 0.8.0

Version **0.8.0 build 10** is the author-workflow hardening release before the 1.0 stability pass.

The History workspace is now a real editable timeline rather than an add/delete list. Existing events can be opened and changed in place, moved earlier or later in author-controlled chronological order, and deleted only after a destructive confirmation. Explicit ordering is intentional: `whenText` may contain values such as “Age 12”, “three winters before the war” or a calendar date, so Character Profiler does not pretend every author's chronology can be safely parsed by a machine.

Relationships are now editable without deleting and recreating their graph edge. The author can change relationship type and notes from either character's record; directional inverse semantics such as parent/child and mentor/student remain correct. Family validation evaluates the proposed replacement state while excluding the edge's old value, so legitimate edits are possible without weakening ancestry/duplicate protection.

Large casts are easier to work with. Adding a relationship uses a searchable cast picker, project search also finds relationship names/kinds/notes, and larger projects show result counts and search guidance.

0.8 also removes a class of silent failures. Story/character editors, Guide answers, history, relationships, destructive actions, legacy migration and portrait import now surface relevant errors instead of relying on `try?` or quietly ignoring failed image loads.

No new SwiftData entity or persistent field is introduced by 0.8. Portable backup remains **Character Profiler archive format v1**.

### Product documentation

- `docs/PRODUCT_SPEC.md` — source of truth for product intent and boundaries.
- `docs/FEATURE_STATUS.md` — implemented/partial/planned/candidate capability audit.
- `docs/ROADMAP.md` — development sequence toward the first stable release.
- `ARCHITECTURE.md` — data invariants, persistence/archive design and subsystem boundaries.

## Story projects and cast

- Multiple story projects with built-in or custom genres and premise.
- Project-scoped cast library and search.
- Project overview metrics for cast, relationships, history, Guide answers and development.
- Search across character metadata/profile content plus linked character names, relationship kinds and relationship notes.
- Search result counts/guidance for larger casts.
- Complete project backup/export and restore/import using archive format v1.
- Idempotent migration of older pre-project characters into `Imported Characters`.
- Destructive story/character deletion confirmations with affected-data counts.

## Character profiles

- Name, nickname, age, pronouns, story role, summary and portrait.
- Flexible sections and arbitrary author-defined fields.
- Starter sections for identity, appearance, personality, motivation, background and secrets.
- Development-completion indicator.
- Explicit save and portrait-import error feedback.

## Character Guide

The Guide contains more than 120 stable prompts, broad genre-specific sets, deterministic development-depth scoring, category balancing and adaptive follow-ups from profile facts, relationships and life history.

Answered prompt IDs remain stable and suppressed from normal unanswered suggestions. Each rich suggestion explains **why this question?** without copying the explanation into character canon.

The Guide remains local, deterministic and advisory. It does not silently rewrite character facts and does not claim arbitrary semantic contradiction detection.

## Relationships and family

Relationships link real `CharacterProfile` records rather than storing names as notes. Parent/child and mentor/student links read correctly from both endpoints.

0.8 allows an existing relationship's type and notes to be edited on the same persisted edge. Editing from the opposite endpoint translates the displayed relationship back to the correct stored inverse. Family edits keep the same self-link, duplicate-link, ancestry-cycle and ancestor/sibling safeguards used during creation.

Adding a relationship uses a searchable cast picker. Removing a relationship requires confirmation and explains that one shared link disappears from both character records; family-tree impact is made explicit.

The graphical family tree is a derived projection of the same relationship graph. It supports multi-generation traversal, tappable members, scrolling and zoom without creating a second family database.

## Life history

Characters can record trauma, loss, milestones, achievements, relationships, conflict, education, career, adventures, relocation, secrets and other formative events.

Each event records a title, kind, free-text time/age, details and lasting impact. Events can now be edited in place and explicitly reordered. History is included in project backups and may influence adaptive Guide questions.

## Character Visual Studio

Visual Studio remains focused on answering **what does this character look like?** It supports:

- up to six labelled/reorderable reference images;
- author-written appearance notes;
- an accepted canonical Image Playground character image on supported devices;
- canonical image reuse as the profile portrait;
- explicit canonical replacement/reset lifecycle;
- eight fixed turnaround positions at 45° intervals;
- missing/duplicate angle detection and completion progress;
- drag/arrow navigation across all eight slots;
- independent angle generation/regeneration/deletion and whole-turnaround reset;
- runtime Image Playground availability handling.

The canonical image is the identity source for turnaround generation. Simulator CI validates the SDK/state logic, but actual cross-angle face/body/clothing consistency still requires a supported physical iPhone.

Scenes, animation, filmmaking, a game engine and a true 3D mesh are outside current product scope.

## Backup and restore

A story backup is a human-inspectable JSON document such as:

`Ashes-of-the-Crown.characterprofiler.json`

Archive format v1 includes project metadata, characters, flexible profile data, Guide answers, life events, relationships and current visual assets. Restore validates the archive, creates fresh local SwiftData identifiers, and reconstructs relationship endpoints after characters exist. The same backup can therefore be restored more than once without ID collision.

The archive is an application-owned interchange format, not a raw SwiftData store copy.

## Requirements and build

- iOS 17.0 or later for the core app.
- Current Xcode with the Image Playground SDK for Visual AI support.
- Supported device/system environment for Image Playground generation.
- Swift 5 language mode or later.

Open `CharacterProfiler.xcodeproj`, select the `CharacterProfiler` scheme and choose an iPhone simulator or connected iPhone. A physical-device run requires an Apple Development team under Signing & Capabilities. No personal Team ID is committed.

GitHub Actions dynamically prepares an available iOS simulator and runs the complete test suite as the release gate.

## Data and privacy

Story/profile/relationship/history/Guide/visual data is local-first through SwiftData. Large images use external binary storage. Character Profiler contains no advertising or analytics SDK. Backups are created/restored only through explicit author actions, and selected photos come through the system Photos picker.

## Architecture summary

```text
StoryProject
└── CharacterProfile[]
    ├── ProfileSection[] -> ProfileField[]
    ├── LifeEvent[] -> LifeEventOrdering
    ├── PromptResponse[] -> Character Guide
    ├── CharacterRelationship[] -> FamilyGraphSnapshot / FamilyTreeView
    ├── CharacterReferenceImage[]
    ├── generatedVisualData
    └── CharacterVisualFrame[] -> VisualAngle (8 slots)

ProjectArchive format v1
└── complete portable project graph with fresh-ID restore
```

See `ARCHITECTURE.md` for design details.

## Licence

Copyright © 2026 Shannon Smith.

Character Profiler is free software licensed under GNU GPL version 3 or, at your option, any later version. See `LICENSE`.
