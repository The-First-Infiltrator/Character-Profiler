<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Architecture

Character Profiler is an author-facing story bible. It remembers facts about a cast, helps an author discover missing character detail, links people to one another, records formative history and establishes a consistent visual reference for each character. The application deliberately stops at the character boundary: it is not a scene generator, animation system or game engine.

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

`StoryProject` stores title, genre and premise and owns the cast. `CharacterProfile` stores core metadata and owns expandable profile sections, formative history, guide answers, relationship edges and visual assets. `ProfileSection` and `ProfileField` stay generic so authors can add attributes without requiring a schema change for every genre-specific idea.

Relationships are real links between character records. Directional links derive the inverse view automatically—for example parent/child and mentor/student. Life events record trauma, loss, milestones, conflict and other formative events. The Character Guide keeps prompt definitions as application content and persists only the author's `PromptResponse` answers.

## Character Visual Studio

Version 0.3.0 adds a focused visual layer. Each character may store up to six author-selected reference pictures plus written appearance notes. On supported systems, Apple's Image Playground receives the character description and a reference-board image and returns an author-approved canonical character visual.

The app deliberately does not attempt to construct a complex 3D mesh. Instead, `VisualAngle` defines eight standard views at 45-degree intervals. Each accepted `CharacterVisualFrame` uses the canonical visual as its source reference, and the turntable viewer maps horizontal dragging across available angle frames. This provides a useful 360-degree inspection workflow without turning the app into an animation or scene-production tool.

## UI flow

```text
ProjectListView
└── ProjectDetailView
    └── CharacterDetailView
        ├── Profile
        ├── Guide
        ├── People
        ├── History
        └── Visual
            ├── Reference Pictures
            ├── Appearance Notes
            ├── AI Character
            └── 360° Turn-Around
```

## Compatibility

The core application targets iOS 17. Visual AI is availability-gated for systems that provide Image Playground, so unsupported devices continue to use the story, profile, guide, relationship and history features.

## Privacy and provider boundary

Character Profiler uses Apple's system Photos picker for author-selected images and does not embed a private third-party AI service key. If another visual provider is ever added, it should sit behind a replaceable generation boundary and must not require a secret to be hard-coded into the distributed iPhone application.
