<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Changelog

## [0.6.0] - 2026-08-16

### Added

- Versioned Character Profiler project archive format, beginning with format version 1.
- Story-level **Export Backup** through the system document exporter.
- Story Library **Restore Backup** through the system document importer.
- Full backup coverage for story metadata, characters, flexible profile sections and fields, life events, Guide answers, relationships, profile/reference/generated images and turnaround frames.
- Archive validation for unsupported versions, duplicate identifiers, missing relationship endpoints and structurally invalid self-relationships.
- Project overview metrics for cast size, relationships, life events, Guide answers and average development.
- Round-trip tests that encode a developed story, decode it, restore it twice and verify profile, history, Guide, visual and relationship data.

### Data safety

- Restores create fresh SwiftData model identifiers; archived IDs are used only as internal reconstruction keys, so restoring the same backup more than once does not collide with existing local data.
- Relationship edges are reconstructed only after every archived character has been restored.
- Story and character swipe deletion now stages a destructive confirmation with counts describing linked data that will be removed.
- Story deletion explicitly reminds the author to export a backup first when the work may be needed again.
- Failed archive restores remove the partially created project rather than intentionally leaving an incomplete restored story.

### Changed

- Story detail now includes an at-a-glance project-development overview.
- App version is now 0.6.0 build 8.
- GitHub Actions no longer assumes a hard-coded `iPhone 16` simulator exists. CI initialises CoreSimulator, selects an available iPhone simulator by identifier, and can download the default iOS runtime when a hosted runner has no bootable iPhone simulator.

### Scope

- The portable archive is an application-owned, explicitly versioned interchange format rather than a raw SwiftData/database copy.
- Version 0.6 adds no new SwiftData entities or persistent fields and does not introduce cloud synchronisation.

## [0.5.1] - 2026-08-16

### Changed

- Character Guide suggestion cards now show the human-readable reason produced by `GuideSuggestion`.
- Opening a Guide question shows a dedicated **Why this question** section before the answer field.
- Guide introductory copy now makes the adaptive explanation behaviour explicit.
- Suggestion reasons are also exposed as accessibility hints on the question buttons.
- App version is now 0.5.1 build 7.

### Data integrity

- Selection reasons remain presentation metadata only.
- Saving a Guide answer continues to persist the stable prompt ID, canonical question and author-written answer; the explanation is not copied into character canon.

## [0.5.0] - 2026-08-16

### Added

- Dedicated `CharacterGuide.swift` support source for Guide selection and catalogue content.
- Prompt catalogue expanded to well over 100 stable prompts across the existing built-in genres.
- Development-depth scoring from profile fields, saved Guide answers, relationships, story role and life history.
- Underdeveloped-area prioritisation so sparse character dimensions receive more attention.
- Category balancing so the visible Guide spans multiple dimensions before repeating the same category.
- Expanded adaptive follow-ups for trauma/loss, family relationships, multiple life events and recorded story role.
- Context-sensitive follow-ups for magic, drinking-place behaviour, war/combat, secrecy, faith, money, family, romance and revenge.
- `GuideSuggestion` metadata with a human-readable explanation of why a question was selected.
- Unit tests for catalogue size and unique IDs, genre filtering, category diversity, adaptive trauma/combat context and profile development-depth recognition.

### Changed

- Guide selection is now scored and deterministic rather than simply taking the first matching questions from a fixed list.
- Existing `PromptEngine.suggestions` remains available for compatibility while richer selection is exposed through `detailedSuggestions`.
- Stable prompt IDs and answered-prompt suppression are preserved so existing saved answers remain valid.
- App version is now 0.5.0 build 6.

### Scope

- 0.5 remains a local deterministic character-development engine. It does not silently create canon or claim deep semantic contradiction checking.
- Semantic consistency analysis remains future work.

## [0.4.0] - 2026-08-16

### Added

- Graphical family tree launched from a character's People workspace.
- Root-centred generation layout derived from existing parent/child relationship direction.
- Siblings, spouses and partners placed on the same generation as appropriate.
- Scrollable family canvas for larger connected families.
- Pinch zoom plus explicit zoom-out, reset and zoom-in controls.
- Tappable family-tree character cards that navigate directly to the linked character record.
- Distinct connector treatment for ancestry, partners and siblings without duplicating relationship data for the diagram.
- Family graph traversal across connected relatives rather than only direct relationships.
- Duplicate relationship validation when adding a relationship.
- Ancestry-cycle protection for parent/child links and ancestor/descendant sibling contradictions.
- Unit tests covering multi-generation placement, duplicate detection and ancestry-loop rejection.

### Changed

- Relationship rows now open the related character while retaining direct delete control.
- Adding a relationship shows an explanatory validation message when the proposed link would be structurally invalid.

### Scope

- The family tree is generated entirely from `CharacterRelationship` records; it does not create a second family-tree database.
- Version 0.4.0 focuses on family relationships. A broader friends/rivals/mentors relationship-network view remains future work.

## [0.3.1] - 2026-08-16

### Fixed

- Removed a `UIGraphicsImageRendererContext.fill(_:)` compatibility extension that collided with UIKit and caused the first real Xcode CI build to fail during Swift module emission.
- Restored image normalisation to use the renderer API directly without shadowing UIKit methods.

### Documentation

- Added a formal product specification describing the author-focused story-bible goal and explicit product boundaries.
- Added a feature-status audit separating implemented, partial, planned and candidate capabilities.
- Added a staged roadmap beginning with the graphical family/relationship view after stabilisation.
- Strengthened architecture documentation, data invariants, migration expectations and the distinction between the eight-view turnaround and a true 3D model.

### Scope

- 0.3.1 is a stabilisation release and deliberately adds no unrelated feature scope.

## [0.3.0] - 2026-08-16

### Added

- Character Visual Studio as a fifth character workspace.
- Up to six visual reference pictures per character using the system Photos picker.
- Author-written appearance notes.
- AI-assisted canonical character creation using Apple's Image Playground on supported devices.
- Character profile and reference-image context supplied to visual generation.
- Ability to use the approved AI image as the normal profile portrait.
- Eight standard turn-around angles at 45-degree intervals.
- Independent generation/regeneration for each angle using the canonical character as source reference.
- Drag-to-rotate turntable viewer across available angle frames.
- SwiftData models for reference images and turn-around frames using external binary storage.
- Unit test covering the eight-angle turn-around definition.

### Scope

- Visual Studio is deliberately limited to character appearance and inspection.
- No scene generation, posing system, story animation, cinematics or game-engine functionality was added.

## [0.2.0] - 2026-08-16

### Added

- Story projects with genre and premise.
- Character portraits and expanded author-oriented profile sections.
- Local genre-aware Character Guide with adaptive follow-up questions.
- Persisted guide answers.
- Real character-to-character relationships with inverse parent/child and mentor/student handling.
- Family-oriented relationship display.
- Character life-history timeline with trauma, loss and other event types.
- Character development completion indicator.
- Automatic migration of pre-project characters into an Imported Characters project.

## [0.1.0] - 2026-08-16

### Added

- Initial native iPhone application foundation.
- SwiftUI character list, detail and editing interfaces.
- SwiftData persistence.
- Flexible sections and arbitrary profile fields.
- Search across character data.
- Starter character profile template.
- Unit-test target and GitHub Actions build workflow.
