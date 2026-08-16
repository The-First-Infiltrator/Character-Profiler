<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Feature Status

This document compares the intended product in `PRODUCT_SPEC.md` with the current implementation. It is deliberately separate from the changelog: the changelog records what changed, while this file records what is complete, partial or still planned.

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
| Project overview metrics | Implemented | 0.6 shows cast, relationship, life-event, Guide-answer and average-development counts. |
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
| Character deletion impact confirmation | Implemented | 0.6 reports linked relationships, history, Guide answers and visual assets before permanent deletion. |

## Character Guide

| Capability | Status | Notes |
| --- | --- | --- |
| Large general development catalogue | Implemented | 0.5 expands the catalogue to well over 100 stable prompts. |
| Genre-specific prompt sets | Implemented | Fantasy, SF, Romance, Mystery/Thriller, Horror, Historical, Contemporary, Adventure/Crime and YA all have expanded coverage. |
| Fantasy tavern/adventure/world questions | Implemented | Directly reflects the original product concept. |
| Persisted Guide answers | Implemented | Answers are stored per character. |
| Stable prompt identifiers | Implemented | Catalogue growth does not invalidate saved answers. |
| Hide answered prompts from normal suggestions | Implemented | Answered prompt IDs are suppressed. |
| Development-depth scoring | Implemented | Existing profile fields, answers, relationships, role and history contribute to category depth. |
| Underdeveloped-area prioritisation | Implemented | Lightly developed categories receive a higher suggestion score. |
| Category balancing | Implemented | Visible suggestions deliberately span several categories before repeating a theme. |
| Adaptive prompts from relationships/history/profile text | Implemented | Expanded in 0.5 with family, multiple life events, role and keyword-triggered follow-ups. |
| Adaptive combat/magic/secrecy/faith/money/relationship/revenge follow-ups | Implemented | Rule-based context can trigger more specific questions. |
| Human-readable suggestion reason | Implemented | `GuideSuggestion` records why a prompt was selected. |
| Explicit reason presentation in the Guide UI | Implemented | 0.5.1 shows the reason on suggestion cards and in the answer sheet without altering canonical prompt data. |
| Deep semantic consistency/contradiction checking | Planned | Requires a deliberately designed reasoning layer beyond the current deterministic rule engine. |
| Explicit promotion of Guide answer into profile field | Candidate | Must remain author-controlled if added. |

## Relationships and family

| Capability | Status | Notes |
| --- | --- | --- |
| Real links between character records | Implemented | Relationship edges link two `CharacterProfile` objects. |
| Parent/child inverse meaning | Implemented | Direction is interpreted from each character's point of view. |
| Mentor/student inverse meaning | Implemented | Same directional model. |
| Family grouping in character People view | Implemented | Family relationships are separated from other relationships. |
| Notes on relationships | Implemented | Stored on each relationship edge. |
| Graphical family tree | Implemented | Root-centred graph derived from existing family relationship edges. |
| Multi-generation traversal | Implemented | Connected grandparents, grandchildren and further generations are included without extra stored tree data. |
| Tappable family members | Implemented | Tree cards navigate to the existing character record. |
| Large-family navigation | Implemented | Two-axis scrolling, pinch zoom and explicit zoom controls. |
| Duplicate family-link prevention | Implemented | Equivalent family links are blocked while adding relationships. |
| Ancestry-cycle prevention | Implemented | Parent/child cycles and ancestor/descendant sibling contradictions are rejected. |
| Relationship preservation in project backups | Implemented | 0.6 archives endpoint IDs and reconstructs edges only after all characters exist. |
| Broader non-family relationship network | Planned | Friends, rivals, enemies, mentors and colleagues remain separate future work. |

## History and trauma

| Capability | Status | Notes |
| --- | --- | --- |
| Structured life events | Implemented | Title, kind, timing, details and impact. |
| Trauma and loss event types | Implemented | Used by adaptive Guide questions. |
| General formative event categories | Implemented | Milestones and other life events supported. |
| Life-history backup/restore | Implemented | 0.6 project archives include every stored life event. |
| Chronological visual timeline | Partial | Events are displayed as history entries; richer timeline presentation can improve later. |

## Character Visual Studio

| Capability | Status | Notes |
| --- | --- | --- |
| Dedicated Visual workspace | Implemented | Fifth character area. |
| Up to six reference images | Implemented | Selected with Photos picker. |
| Written appearance instructions | Implemented | Stored per character. |
| Character/profile facts included in generation concept | Implemented | Current generation description includes known data. |
| AI-assisted canonical character image | Partial | Implemented using Image Playground; requires real-device validation for consistency and availability behaviour. |
| Use generated image as profile portrait | Implemented | Canonical visual can become the portrait. |
| Eight angle definitions | Implemented | 45-degree turnaround positions. |
| Independent angle generation | Implemented | Each angle can be generated/regenerated. |
| Drag-to-rotate turnaround viewer | Implemented | Steps through available angle frames. |
| Visual asset backup/restore | Implemented | 0.6 archives profile images, references, canonical generated visual and turnaround frames. |
| True continuous 3D mesh | Not planned | Explicitly outside current product design. |
| Scene generation | Not planned | Explicitly outside product scope. |
| Animation/cinematics | Not planned | Explicitly outside product scope. |

## Data portability and safety

| Capability | Status | Notes |
| --- | --- | --- |
| Local persistent data | Implemented | Current primary storage model. |
| Versioned project backup/export | Implemented | 0.6 writes Character Profiler JSON archive format v1. |
| Project restore/import | Implemented | 0.6 validates and rebuilds the complete local project graph. |
| Restore without identifier collision | Implemented | Restored SwiftData objects receive fresh IDs; archived IDs are reconstruction keys only. |
| Archive format validation | Implemented | Unsupported versions and malformed relationship references are rejected. |
| Whole-story round-trip test | Implemented | Test includes flexible profile data, Guide answers, history, visual assets and relationships and restores the same backup twice. |
| Project deletion impact confirmation | Implemented | 0.6 reports project/cast/relationship impact and recommends backing up first. |
| iCloud sync | Candidate | Requires a deliberate design and migration strategy. |

## 0.6.0 completion criteria

0.6.0 is considered complete when:

1. project export produces an explicitly versioned portable archive rather than a raw SwiftData store copy;
2. the archive includes project metadata, characters, arbitrary profile data, Guide answers, life events, relationships and all current visual assets;
3. restore validates archive format/version and reconstructs a new usable project;
4. restoring the same archive more than once does not collide with existing SwiftData identifiers;
5. relationship links survive a complete encode/decode/restore round trip;
6. story and character deletion require a destructive confirmation that describes affected linked data;
7. story detail exposes useful project/cast development metrics;
8. round-trip and unsupported-version tests pass in Xcode CI;
9. CI reliably prepares an iOS simulator instead of depending on one hard-coded simulator name;
10. version/build metadata is 0.6.0 / build 8;
11. product spec, feature status, roadmap, changelog, README and architecture describe the implemented behaviour accurately.

After 0.6.0 is integrated, Visual Studio hardening and other remaining 1.0 reliability work become the next major focus.
