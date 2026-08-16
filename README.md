<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler

Character Profiler is a native iPhone story-bible and character-development app for authors. It combines flexible character profiles, structured relationships, life history, genre-aware development questions, portable project backup and a focused visual studio for establishing what a character looks like.

## Version 0.7.0

Version 0.7.0 hardens **Character Visual Studio** without expanding it into scene generation, animation or a 3D/game system.

The visual workflow is now organised around one accepted **canonical character image**. Turnaround views use that canonical image as their identity source, and replacing the canonical visual makes the relationship between the old turnaround and the new identity explicit. The author can replace the canonical image while keeping existing views, or choose to reset those views only after a replacement is successfully accepted.

The eight-view turnaround is now a fixed set of named angle slots rather than a list that silently skips missing frames. Visual Studio reports completion progress, identifies missing views, lets the author jump through all eight positions, generate the next missing view, regenerate or delete an individual frame, and reset the whole turnaround while preserving the canonical image, references and appearance notes.

Reference pictures are also easier to manage: up to six can be labelled, reordered and deleted through an explicit editor. Image-import and save failures are surfaced instead of being silently ignored.

Image Playground availability is checked at runtime. A device/system environment that cannot generate images can still view and manage existing reference pictures, canonical visuals and turnaround frames, while the rest of Character Profiler remains available normally.

The app version is **0.7.0 build 9**. Simulator CI covers Visual Studio state, eight-slot navigation, duplicate-frame detection and reference ordering. Actual Image Playground output quality and identity consistency still require validation on a supported physical device.

### Product documentation

- `docs/PRODUCT_SPEC.md` — source of truth for product intent and boundaries.
- `docs/FEATURE_STATUS.md` — implemented, partial, planned and candidate capability audit.
- `docs/ROADMAP.md` — development sequence toward the first stable author release.
- `ARCHITECTURE.md` — persistent model, archive format, invariants and subsystem boundaries.

## Story projects

- Multiple story projects.
- Fantasy, Science Fiction, Romance, Mystery, Thriller, Horror, Historical Fiction, Contemporary, Adventure, Crime, Young Adult and custom genres.
- Story premise and project-scoped character library.
- Project overview metrics for cast, relationships, history, Guide answers and average development.
- Full project backup/export and restore/import using Character Profiler archive format v1.
- Existing pre-project characters migrate into `Imported Characters`.

## Character profiles

- Name, nickname, age, pronouns, story role and summary.
- Profile portrait.
- Flexible sections and arbitrary author-defined fields.
- Starter sections for identity, appearance, personality, motivation, background and secrets.
- Search across character data.
- Development-completion indicator.
- Destructive deletion confirmation that reports linked relationship/history/Guide/visual impact before removal.

## Character Guide

The Character Guide combines broad character-development questions, expanded genre-specific catalogues, deterministic scoring, category balancing and adaptive follow-ups from recorded profile facts, relationships and life history.

It maintains stable prompt IDs, suppresses already answered prompts, and shows a human-readable **why this question?** explanation without copying that explanation into character canon.

Fantasy prompts include taverns, adventuring, magic, travel, creatures, faith, quests, oaths, status, ruins and life on the road. Other genres use their own appropriate prompt sets rather than simply rewording Fantasy questions.

The Guide remains local, deterministic and advisory. It does not silently rewrite character facts and does not claim full semantic contradiction checking.

## Relationships and family

Relationships link real character records rather than storing names as plain text. Directional links such as parent/child and mentor/student read correctly from either character's perspective.

The graphical family tree:

- walks the connected family graph rather than only direct relatives;
- derives generations from parent/child direction;
- keeps siblings, spouses and partners on the corresponding generation;
- uses tappable character cards over a separately drawn connector layer;
- supports scrolling and zoom for larger families;
- prevents duplicate family links and ancestry loops while adding relationships.

Project archives preserve relationship endpoints and direction so the graph can be reconstructed after restore. A broader non-family relationship network remains future work.

## Life history

Characters can record trauma, loss, milestones, achievements, relationships, conflict, education, career, adventures, relocation, secrets and custom formative events. Each event can record when it happened and how it changed the character. Life history is included in project backups and can influence adaptive Guide questions.

## Character Visual Studio

The Visual workspace is the fifth area of a character record alongside Profile, Guide, People and History.

It provides:

- up to six labelled visual reference pictures per character;
- reference-image reordering and deletion;
- author-written appearance notes;
- AI-assisted creation of one canonical full-body character image;
- character/profile facts included in the generation concept;
- selected references combined into a reference board for canonical generation;
- ability to use the accepted canonical image as the profile portrait;
- explicit canonical-image replacement and clearing workflows;
- eight fixed turnaround positions at 45-degree intervals;
- completion progress and a clear list of missing angle views;
- drag and arrow navigation through all eight slots, including missing ones;
- independent generation/regeneration and deletion for each angle;
- generation of the next missing angle;
- whole-turnaround reset while preserving the canonical visual and source references;
- duplicate stored-angle detection;
- runtime Image Playground availability handling;
- no scene creation, character animation, posing system or movie generation.

Profile pictures, reference images, the accepted canonical visual and turnaround frames are included in the portable project backup.

### AI implementation

Character Visual Studio uses Apple's **Image Playground** framework when the current device/system environment supports it. The author chooses whether to accept a generated result.

Character Profiler does not embed an OpenAI API key or another private visual-service credential. The core model does not depend on image generation being available.

Simulator CI can validate the app logic and SDK integration, but it cannot establish whether generated output on a physical device preserves a character's face, clothing and proportions well enough across all eight angles. That remains a real-device validation item.

## Backup and restore

A story backup is a human-inspectable JSON document with a filename such as:

`Ashes-of-the-Crown.characterprofiler.json`

The document includes a `formatVersion`. Character Profiler currently writes and reads archive format 1 and rejects unsupported versions rather than guessing how to interpret them.

A backup includes project metadata, every character, flexible profile data, Guide answers, life events, relationships and all current visual assets. Restore creates fresh local SwiftData identifiers and uses archived identifiers only to reconstruct links inside the imported project, so the same backup can be restored more than once.

The backup is an application interchange format, not a raw SwiftData database copy.

## Requirements

- iOS 17.0 or later for the core application.
- A current Xcode release with the Image Playground SDK for Visual AI support.
- A supported device/system environment for Image Playground generation.
- Swift 5 language mode or later.

## Build and run

1. Clone or download the repository.
2. Open `CharacterProfiler.xcodeproj` in Xcode.
3. Select the `CharacterProfiler` scheme.
4. Choose an iPhone simulator or connected iPhone.
5. Under **Signing & Capabilities**, select your Apple Development team for a physical device.
6. Press **Run**.

No personal Apple Team ID is committed to the repository.

GitHub Actions dynamically prepares an available iOS simulator rather than relying on one hard-coded device name. If a hosted runner has no usable iPhone runtime, the workflow can download the default iOS runtime before running tests.

## Data and privacy

Story data, profiles, reference images, generated visuals and turnaround frames are persisted locally with SwiftData. Large image data uses SwiftData external binary storage. The app does not contain advertising or analytics SDKs.

Portable project backups are created only when the author explicitly exports them. Restored files are read only when the author explicitly chooses them through the system document picker. The system Photos picker is used for user-selected reference images.

## Architecture

```text
StoryProject
└── CharacterProfile[]
    ├── ProfileSection[]
    │   └── ProfileField[]
    ├── LifeEvent[]
    ├── PromptResponse[]
    ├── CharacterRelationship[] -> CharacterProfile
    │   └── derived FamilyGraphSnapshot / FamilyTreeView
    ├── CharacterReferenceImage[]
    ├── generatedVisualData
    └── CharacterVisualFrame[]
        └── VisualAngle (8 fixed positions)

CharacterGuide.swift
├── CharacterPrompt catalogue
├── GuideSuggestion + reason
├── development-depth scoring
├── category balancing
└── adaptive context rules

ProjectArchive.swift
├── formatVersion
├── complete project snapshot
├── JSON encode/decode + validation
└── fresh-ID SwiftData reconstruction

CharacterVisualWorkspaceView.swift
├── runtime Image Playground availability
├── reference management
├── canonical visual lifecycle
└── VisualWorkspaceSnapshot
    ├── available/missing angles
    ├── duplicate-angle detection
    └── turnaround completion
```

See `ARCHITECTURE.md` for design details.

## Scope boundary

Character Profiler is a character-development tool for authors. Character Visual Studio exists to answer **what does this character look like?** It deliberately does not expand into scene generation, cinematics, animation, game mechanics or story rendering.

## Licence

Copyright © 2026 Shannon Smith.

Character Profiler is free software licensed under the GNU General Public License version 3 or, at your option, any later version. See `LICENSE`.
