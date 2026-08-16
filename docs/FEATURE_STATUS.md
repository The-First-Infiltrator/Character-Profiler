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
| Migration of pre-project characters | Implemented | Earlier characters can be placed into Imported Characters. |
| CI build and unit-test workflow | Implemented | 0.3.1 passed the full Xcode simulator build and unit-test workflow; 0.4 continues to use the same release gate. |

## Character profile

| Capability | Status | Notes |
| --- | --- | --- |
| Name, nickname, age, pronouns, role, summary | Implemented | Stored on `CharacterProfile`. |
| Profile portrait | Implemented | Uses selected/generated image data. |
| Flexible sections and arbitrary fields | Implemented | Not limited to a fixed compiled form. |
| Starter author-oriented profile template | Implemented | Identity, appearance, personality, motivation, background and secrets. |
| Search within a story cast | Implemented | Searches character data in the active project. |
| Character development completion indicator | Implemented | Current heuristic only; may be refined later. |

## Character Guide

| Capability | Status | Notes |
| --- | --- | --- |
| General development prompts | Implemented | Foundation prompt catalogue. |
| Genre-specific prompt sets | Implemented | Includes Fantasy, SF, Romance, Mystery/Thriller, Horror, Historical, Contemporary, Adventure/Crime and YA. |
| Fantasy tavern/adventure/world questions | Implemented | Directly reflects the original product concept. |
| Persisted Guide answers | Implemented | Answers are stored per character. |
| Hide answered prompts from normal suggestions | Implemented | Answered prompt IDs are suppressed. |
| Adaptive prompts from relationships/history/profile text | Implemented | Initial rule-based version. |
| Deep semantic consistency checking | Planned | Future Guide work. |
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
| Broader non-family relationship network | Planned | Friends, rivals, enemies, mentors and colleagues remain separate future work. |

## History and trauma

| Capability | Status | Notes |
| --- | --- | --- |
| Structured life events | Implemented | Title, kind, timing, details and impact. |
| Trauma and loss event types | Implemented | Used by adaptive Guide questions. |
| General formative event categories | Implemented | Milestones and other life events supported. |
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
| True continuous 3D mesh | Not planned | Explicitly outside current product design. |
| Scene generation | Not planned | Explicitly outside product scope. |
| Animation/cinematics | Not planned | Explicitly outside product scope. |

## Data portability and sync

| Capability | Status | Notes |
| --- | --- | --- |
| Local persistent data | Implemented | Current primary storage model. |
| JSON/project export and import | Candidate | Useful for backup/portability but not yet committed to a release. |
| iCloud sync | Candidate | Requires a deliberate design and migration strategy. |

## 0.4.0 completion criteria

0.4.0 is considered complete when:

1. the graphical family tree is generated only from existing relationship data;
2. parent/child generation placement and same-generation family links behave correctly;
3. large families can be navigated through scrolling and zoom;
4. family cards open the existing linked character records;
5. invalid duplicate/cyclic family links are blocked;
6. the new relationship tests pass in Xcode CI;
7. version/build metadata is 0.4.0 / build 5;
8. product specification, architecture, README, changelog and roadmap reflect the implemented behaviour.
