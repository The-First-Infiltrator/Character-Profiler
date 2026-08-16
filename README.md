<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler

Character Profiler is a native iPhone story-bible and character-development app for authors. It combines flexible character profiles, structured relationships, life history, genre-aware development questions and a focused visual studio for establishing what a character looks like.

## Version 0.4.0

Version 0.4.0 turns the existing relationship data into an author-facing graphical family tree.

The People workspace now opens a root-centred family map generated from the same `CharacterRelationship` records already used elsewhere in the app. Parents and earlier generations appear above the selected character, children and later generations below, while siblings, spouses and partners share the appropriate generation. Family members remain tappable character records rather than duplicate diagram-only objects.

The tree supports scrolling, pinch zoom and explicit zoom controls for larger families. Version 0.4.0 also adds validation against duplicate family links and ancestry cycles when relationships are created.

### Product documentation

- `docs/PRODUCT_SPEC.md` — source of truth for what Character Profiler is intended to do.
- `docs/FEATURE_STATUS.md` — implemented vs partial vs planned capability audit.
- `docs/ROADMAP.md` — development order through the first stable author release.
- `ARCHITECTURE.md` — persistent model, invariants and subsystem boundaries.

## Character Visual Studio

Version 0.3 introduced **Character Visual Studio** without turning the app into a scene generator or animation package.

The Visual workspace is the fifth area of a character record alongside Profile, Guide, People and History.

It provides:

- Up to six visual reference pictures per character.
- Author-written appearance notes for details that reference pictures do not show.
- AI-assisted creation of a canonical full-body character image.
- The existing written character profile is automatically included in the visual description.
- Multiple reference pictures are combined into a single reference board before generation, giving Image Playground one visual source while preserving face, hair, body, clothing and other appearance cues.
- The approved AI image can become the character's normal profile portrait.
- Eight optional turn-around angles: front, front-right, right, back-right, back, back-left, left and front-left.
- A drag-to-rotate viewer that steps through the available angle images to give the author a simple 360-degree inspection view.
- Each angle can be regenerated independently.
- No scene creation, character animation, posing system or movie generation.

### AI implementation

Character Visual Studio uses Apple's **Image Playground** framework on supported devices. The system-provided generation interface receives the character description plus the selected visual references and returns the image chosen by the author.

This keeps the visual feature focused and avoids embedding a third-party API secret in the iPhone application. Character Profiler does not contain an OpenAI API key or other private service credential.

On a device where Image Playground is unavailable, the rest of Character Profiler continues to work and the Visual workspace explains that AI generation is unavailable.

### Story projects

- Multiple story projects.
- Fantasy, Science Fiction, Romance, Mystery, Thriller, Horror, Historical Fiction, Contemporary, Adventure, Crime, Young Adult and custom genres.
- Story premise and project-scoped character library.
- Existing version 0.1.0 characters without a project migrate into `Imported Characters`.

### Character profiles

- Name, nickname, age, pronouns, story role and summary.
- Profile portrait.
- Flexible sections and arbitrary author-defined fields.
- Starter sections for identity, appearance, personality, motivation, background and secrets.
- Search across character data.
- Development-completion indicator.

### Character Guide

The local Character Guide includes broad and genre-specific development prompts. It adapts suggestions based on saved answers, relationships and formative life events.

Fantasy prompts include the sort of everyday world-building choices that reveal personality: taverns, adventuring, magic, travel, creatures, faith and quests.

### Relationships and family

Relationships link real character records rather than storing names as plain text. Parent/child and mentor/student links automatically read correctly from the opposite character's perspective.

Version 0.4.0 adds a graphical family tree that:

- walks the connected family graph rather than showing only direct relatives;
- derives generations from parent/child direction;
- keeps siblings, spouses and partners on the corresponding generation;
- draws relationship connectors behind normal tappable character cards;
- supports scrolling and zoom for larger families;
- prevents duplicate family links and ancestry loops while adding relationships.

A broader visual network for friends, rivals, mentors, colleagues and enemies remains future work rather than being mixed into the family tree.

### Life history

Characters can record trauma, loss, milestones, achievements, relationships, conflict, education, career, adventures, relocation, secrets and custom formative events. Each event can record when it happened and how it changed the character.

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

## Data and privacy

Story data, profiles, reference images, generated visuals and turn-around frames are persisted with SwiftData. Large image data uses SwiftData external binary storage. The app does not contain advertising or analytics SDKs.

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
```

See `ARCHITECTURE.md` for design details.

## Scope boundary

Character Profiler is a character-development tool for authors. Character Visual Studio exists to answer **what does this character look like?** It deliberately does not expand into scene generation, cinematics, animation, game mechanics or story rendering.

## Licence

Copyright © 2026 Shannon Smith.

Character Profiler is free software licensed under the GNU General Public License version 3 or, at your option, any later version. See `LICENSE`.
