<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler

Character Profiler is a native iPhone story-bible and character-development app for authors. It combines flexible character profiles, structured relationships, life history, genre-aware development questions and a focused visual studio for establishing what a character looks like.

## Version 0.6.0

Version 0.6.0 makes Character Profiler much safer to use for serious long-term writing work. A complete story can now be exported as an explicitly versioned Character Profiler backup and later restored through the iOS document picker.

The format begins at **archive version 1** and is owned by Character Profiler rather than being a copy of the SwiftData database. A backup includes story metadata, every character, flexible profile sections and fields, saved Guide answers, life events, relationships, profile/reference/generated images and turnaround frames.

Restore creates fresh local SwiftData identifiers and uses archived character IDs only while rebuilding links inside the imported story. That means the same backup can be restored more than once without colliding with an existing copy. Relationship edges are recreated only after every archived character exists.

0.6 also makes destructive actions more deliberate. Deleting stories or characters now shows an impact summary before anything is removed, and story detail includes quick metrics for cast size, relationships, life events, Guide answers and average character development.

The archive implementation is covered by round-trip tests that encode a developed story, decode it and restore it twice while checking profile, history, Guide, visual and relationship data.

### Product documentation

- `docs/PRODUCT_SPEC.md` — source of truth for what Character Profiler is intended to do.
- `docs/FEATURE_STATUS.md` — implemented vs partial vs planned capability audit.
- `docs/ROADMAP.md` — development order through the first stable author release.
- `ARCHITECTURE.md` — persistent model, archive format, invariants and subsystem boundaries.

## Story projects

- Multiple story projects.
- Fantasy, Science Fiction, Romance, Mystery, Thriller, Horror, Historical Fiction, Contemporary, Adventure, Crime, Young Adult and custom genres.
- Story premise and project-scoped character library.
- Project overview metrics for cast, relationships, history, Guide answers and average development.
- Full project backup/export and restore/import using Character Profiler archive format v1.
- Existing version 0.1.0 characters without a project migrate into `Imported Characters`.

## Character profiles

- Name, nickname, age, pronouns, story role and summary.
- Profile portrait.
- Flexible sections and arbitrary author-defined fields.
- Starter sections for identity, appearance, personality, motivation, background and secrets.
- Search across character data.
- Development-completion indicator.
- Destructive deletion confirmation that reports linked relationship/history/Guide/visual impact before removal.

## Character Guide

Version 0.5 substantially deepened the Character Guide, and 0.5.1 made its reasoning visible to the author.

The Guide combines:

- broad character-development questions;
- expanded genre-specific catalogues;
- deterministic scoring based on how much detail already exists in each category;
- balancing so one category does not dominate the visible list;
- adaptive follow-ups from relationships and life history;
- contextual follow-ups from profile/answer/history text;
- stable prompt IDs and suppression of already answered questions;
- human-readable selection reasons shown directly on suggestion cards and in the answer sheet.

Fantasy prompts include everyday world-building choices that reveal personality: taverns, adventuring, magic, travel, creatures, faith, quests, oaths, status, ruins and life on the road. Other genres use their own appropriate prompt sets rather than simply rewording Fantasy questions.

The Guide remains local, deterministic and advisory. It does not silently rewrite the character record and does not claim full semantic contradiction checking.

## Relationships and family

Relationships link real character records rather than storing names as plain text. Parent/child and mentor/student links automatically read correctly from the opposite character's perspective.

Version 0.4.0 added a graphical family tree that:

- walks the connected family graph rather than showing only direct relatives;
- derives generations from parent/child direction;
- keeps siblings, spouses and partners on the corresponding generation;
- draws relationship connectors behind normal tappable character cards;
- supports scrolling and zoom for larger families;
- prevents duplicate family links and ancestry loops while adding relationships.

The 0.6 archive preserves the relationship graph as links between archived character identifiers and reconstructs those edges after the characters are restored.

A broader visual network for friends, rivals, mentors, colleagues and enemies remains future work rather than being mixed into the family tree.

## Life history

Characters can record trauma, loss, milestones, achievements, relationships, conflict, education, career, adventures, relocation, secrets and custom formative events. Each event can record when it happened and how it changed the character. Life history is included in project backups and also influences adaptive Guide questions.

## Character Visual Studio

The Visual workspace is the fifth area of a character record alongside Profile, Guide, People and History.

It provides:

- up to six visual reference pictures per character;
- author-written appearance notes;
- AI-assisted creation of a canonical full-body character image;
- existing character-profile information included in the visual description;
- multiple references combined into a single reference board;
- ability to use the approved AI image as the profile portrait;
- eight optional turnaround angles at 45-degree intervals;
- a drag-to-rotate image-based 360-degree inspection view;
- independent regeneration for each angle;
- no scene creation, character animation, posing system or movie generation.

Profile pictures, reference images, the accepted canonical visual and turnaround frames are all included in the 0.6 portable project backup.

### AI implementation

Character Visual Studio uses Apple's **Image Playground** framework on supported devices. The system-provided generation interface receives the character description plus selected visual references and returns the image chosen by the author.

This avoids embedding a third-party API secret in the iPhone application. Character Profiler does not contain an OpenAI API key or other private service credential.

On a device where Image Playground is unavailable, the rest of Character Profiler continues to work and the Visual workspace explains that AI generation is unavailable.

## Backup and restore

A story backup is a human-inspectable JSON document with a filename such as:

`Ashes-of-the-Crown.characterprofiler.json`

The file contains a `formatVersion` field. Version 0.6.0 writes and reads archive format 1 and refuses unsupported versions rather than guessing how to interpret them.

Restoring a backup creates another complete story in the local library. It does not overwrite an existing project merely because the archived source identifiers match. This keeps backup/restore behaviour predictable and allows an author to retain multiple restored snapshots.

The backup is an application interchange format, not a raw database dump. Future format evolution must be explicit and migration-aware.

## Requirements

- A current Xcode release with the Image Playground SDK for Visual AI support.
- iOS 17.0 or later for the core application.
- A supported Image Playground device/system for AI visual generation.
- Swift 5 language mode or later.

## Build and run

1. Clone or download the repository.
2. Open `CharacterProfiler.xcodeproj` in Xcode.
3. Select the `CharacterProfiler` scheme.
4. Choose an iPhone simulator or connected iPhone.
5. Under **Signing & Capabilities**, select your Apple Development team for a physical device.
6. Press **Run**.

No personal Apple Team ID is committed to the repository.

GitHub Actions prepares an available iOS simulator dynamically rather than relying on a single hard-coded device name. If a hosted macOS runner has no bootable iPhone simulator, the workflow can download the default iOS runtime before running the tests.

## Data and privacy

Story data, profiles, reference images, generated visuals and turnaround frames are persisted locally with SwiftData. Large image data uses SwiftData external binary storage. The app does not contain advertising or analytics SDKs.

Portable project backups are created only when the author explicitly exports them. Restored files are read only when the author explicitly chooses them through the system document picker.

The system Photos picker is used for user-selected reference pictures. Character Visual Studio delegates image generation to Apple's system Image Playground interface rather than shipping a private AI service key in the app.

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
        └── VisualAngle (8 positions)

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
```

See `ARCHITECTURE.md` for design details.

## Scope boundary

Character Profiler is a character-development tool for authors. Character Visual Studio exists to answer **what does this character look like?** It deliberately does not expand into scene generation, cinematics, animation, game mechanics or story rendering.

## Licence

Copyright © 2026 Shannon Smith.

Character Profiler is free software licensed under the GNU General Public License version 3 or, at your option, any later version. See `LICENSE`.
