<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Feature Status

This document compares the intended product in `PRODUCT_SPEC.md` with the current implementation. The changelog records what changed; this file records what is complete, partial, planned or only a candidate.

Status meanings:

- **Implemented** — present in the current codebase.
- **Partial** — present but still needs validation, UX completion or deeper behaviour.
- **Planned** — part of the intended product but not yet implemented.
- **Candidate** — useful idea, but not committed product scope.

## Product foundation

| Capability | Status | Notes |
| --- | --- | --- |
| Native SwiftUI iPhone application | Implemented | SwiftUI application with an Xcode project. |
| SwiftData local persistence | Implemented | Core entities and visual assets persist locally. |
| Story/project library | Implemented | Projects own a cast and store genre/premise. |
| Built-in genres plus custom genre | Implemented | Used by the Character Guide. |
| Project overview metrics | Implemented | Cast, relationship, life-event, Guide-answer and average-development counts. |
| Migration of pre-project characters | Implemented | Earlier characters can be placed into Imported Characters. |
| CI build and unit-test workflow | Implemented | Xcode simulator build and unit tests are the release gate. |
| Resilient hosted-runner simulator preparation | Implemented | CI discovers an available iPhone simulator and can download the default iOS runtime when needed. |

## Character profile

| Capability | Status | Notes |
| --- | --- | --- |
| Name, nickname, age, pronouns, role, summary | Implemented | Stored on `CharacterProfile`. |
| Profile portrait | Implemented | Uses selected/generated image data. |
| Flexible sections and arbitrary fields | Implemented | Not limited to a fixed compiled form. |
| Starter author-oriented profile template | Implemented | Identity, appearance, personality, motivation, background and secrets. |
| Search within a story cast | Implemented | Searches character data in the active project. |
| Character development completion indicator | Implemented | Current heuristic only; may be refined later. |
| Character deletion impact confirmation | Implemented | Reports linked relationships, history, Guide answers and visual assets before permanent deletion. |

## Character Guide

| Capability | Status | Notes |
| --- | --- | --- |
| Large general development catalogue | Implemented | Well over 100 stable prompts. |
| Genre-specific prompt sets | Implemented | Fantasy, SF, Romance, Mystery/Thriller, Horror, Historical, Contemporary, Adventure/Crime and YA have expanded coverage. |
| Persisted Guide answers | Implemented | Answers are stored per character. |
| Stable prompt identifiers | Implemented | Catalogue growth does not invalidate saved answers. |
| Hide answered prompts | Implemented | Answered prompt IDs are suppressed from normal suggestions. |
| Development-depth scoring | Implemented | Profile fields, answers, relationships, role and history contribute to category depth. |
| Underdeveloped-area prioritisation | Implemented | Lightly developed categories receive a higher suggestion score. |
| Category balancing | Implemented | Visible suggestions span several categories before repeating a theme. |
| Adaptive prompts from relationships/history/profile text | Implemented | Includes family, trauma/loss, multiple life events, role and contextual follow-ups. |
| Human-readable suggestion reason | Implemented | `GuideSuggestion` records why a prompt was selected. |
| Explicit reason presentation | Implemented | Shown on suggestion cards and in the answer sheet without altering canonical prompt data. |
| Deep semantic consistency/contradiction checking | Planned | Requires a deliberately designed reasoning layer beyond the deterministic rule engine. |
| Explicit promotion of Guide answer into profile field | Candidate | Must remain author-controlled if added. |

## Relationships and family

| Capability | Status | Notes |
| --- | --- | --- |
| Real links between character records | Implemented | Relationship edges link two `CharacterProfile` objects. |
| Parent/child and mentor/student inverse meaning | Implemented | Direction is interpreted from each character's point of view. |
| Family grouping in People view | Implemented | Family relationships are separated from other relationships. |
| Relationship notes | Implemented | Stored on each relationship edge. |
| Graphical family tree | Implemented | Root-centred graph derived from existing family edges. |
| Multi-generation traversal | Implemented | Connected grandparents, grandchildren and further generations are included without extra stored tree data. |
| Tappable family members | Implemented | Tree cards navigate to existing character records. |
| Large-family navigation | Implemented | Two-axis scrolling, pinch zoom and explicit zoom controls. |
| Duplicate family-link prevention | Implemented | Equivalent family links are blocked. |
| Ancestry-cycle prevention | Implemented | Parent/child cycles and ancestor/descendant sibling contradictions are rejected. |
| Relationship preservation in project backups | Implemented | Archive endpoint IDs are reconstructed after all restored characters exist. |
| Broader non-family relationship network | Planned | Friends, rivals, enemies, mentors and colleagues remain separate future work. |

## History and trauma

| Capability | Status | Notes |
| --- | --- | --- |
| Structured life events | Implemented | Title, kind, timing, details and impact. |
| Trauma and loss event types | Implemented | Used by adaptive Guide questions. |
| General formative event categories | Implemented | Milestones and other life events supported. |
| Life-history backup/restore | Implemented | Project archives include every stored life event. |
| Chronological visual timeline | Partial | Events are structured and ordered, but 0.8 is expected to improve timeline presentation/editing. |
| Edit existing life event | Planned | 0.8 target; current workflow still emphasises add/delete. |

## Character Visual Studio

| Capability | Status | Notes |
| --- | --- | --- |
| Dedicated Visual workspace | Implemented | Fifth character area; 0.7 moves implementation into `CharacterVisualWorkspaceView.swift`. |
| Up to six reference images | Implemented | Selected with the system Photos picker. |
| Reference labels and ordering | Implemented | 0.7 adds explicit rename/reorder management using existing `sortOrder`. |
| Reference deletion | Implemented | Explicit editor and destructive confirmation. |
| Written appearance instructions | Implemented | Stored per character. |
| Character/profile facts included in generation concept | Implemented | Known data contributes to canonical generation. |
| Runtime Image Playground availability handling | Implemented | Generation controls respect the system `supportsImagePlayground` environment value; existing assets remain usable when unavailable. |
| AI-assisted canonical character image | Partial | Workflow is implemented; actual generated-image quality/identity consistency still needs supported physical-device validation. |
| Canonical visual replacement lifecycle | Implemented | Replacement can keep or reset the turnaround; destructive reset is deferred until a replacement is accepted. |
| Use generated image as profile portrait | Implemented | Canonical visual can become the portrait. |
| Eight fixed angle definitions | Implemented | Front through front-left at 45-degree intervals. |
| Canonical image as angle-generation identity source | Implemented | Angle generation uses the accepted canonical visual rather than falling back to unrelated references. |
| Independent angle generation/regeneration | Implemented | Each slot can be generated or regenerated. |
| Per-angle deletion | Implemented | Existing frames can be removed independently. |
| Missing-angle visibility | Implemented | Missing views remain explicit fixed slots instead of being silently skipped. |
| Turnaround completion progress | Implemented | Reports completed views, percentage and missing named angles. |
| Generate next missing angle | Implemented | Direct recovery action for incomplete turnarounds. |
| Whole-turnaround reset | Implemented | Removes angle frames while preserving canonical image, references and notes. |
| Duplicate stored-angle detection | Implemented | Derived snapshot reports duplicate angle records and UI warns about them. |
| Drag/arrow eight-slot navigation | Implemented | Navigation moves through every standard angle, including missing positions. |
| Visual asset backup/restore | Implemented | Archive v1 includes profile images, references, canonical generated visual and turnaround frames. |
| True continuous 3D mesh | Not planned | Explicitly outside current product design. |
| Scene generation | Not planned | Explicitly outside product scope. |
| Animation/cinematics | Not planned | Explicitly outside product scope. |

## Data portability and safety

| Capability | Status | Notes |
| --- | --- | --- |
| Local persistent data | Implemented | Primary storage model. |
| Versioned project backup/export | Implemented | Character Profiler JSON archive format v1. |
| Project restore/import | Implemented | Validates and rebuilds the complete local project graph. |
| Restore without identifier collision | Implemented | Restored SwiftData objects receive fresh IDs; archived IDs are reconstruction keys only. |
| Archive format validation | Implemented | Unsupported versions and malformed relationship references are rejected. |
| Whole-story round-trip test | Implemented | Includes flexible profile data, Guide answers, history, visual assets and relationships; restores the same backup twice. |
| Project deletion impact confirmation | Implemented | Reports project/cast/relationship impact and recommends backing up first. |
| iCloud sync | Candidate | Requires a deliberate design and migration strategy. |

## 0.7.0 completion criteria

The simulator-testable part of 0.7.0 is considered complete when:

1. Visual Studio uses actual Image Playground availability rather than assuming every iOS 18.1+ environment can generate images;
2. reference images can be labelled, reordered and deleted without changing the persistent schema;
3. the accepted canonical image is the identity source for angle generation;
4. replacing the canonical image makes stale-turnaround risk explicit and does not delete existing frames merely because generation was opened and cancelled;
5. all eight standard angle slots remain visible even when some frames are missing;
6. turnaround completion, missing views and duplicate stored angles are inspectable;
7. individual angle frames can be regenerated/deleted and the whole turnaround can be reset without deleting source references or appearance notes;
8. deterministic visual-state/navigation/reference-ordering tests pass in Xcode CI;
9. app version/build metadata is 0.7.0 / build 9;
10. README, changelog, feature status and roadmap describe the implemented behaviour accurately.

Physical-device Image Playground output quality and identity consistency remain an explicit validation item rather than being falsely marked complete by simulator CI.

With the non-device-dependent 0.7 hardening complete, **0.8 — remaining author-release hardening** becomes the next major implementation target.
