<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Changelog

## [1.0.1] - 2026-08-18

### Fixed

- SwiftData save failures now roll the current unit of work back instead of leaving failed edits, inserts or deletions pending for a later unrelated save.
- Character-scoped Guide, relationship, history and Visual Studio work now updates the owning story activity timestamp so Story Library recency remains accurate.
- Profile editing preserves existing section/field UUIDs instead of deleting and recreating every row on each save.
- Blank profile section titles and field labels are now reported as validation errors rather than causing authored rows to be silently omitted.
- Saved Character Guide answers can be viewed in full, edited and deliberately deleted; answered-prompt suppression no longer makes persisted answers effectively read-only.
- Character portraits can be explicitly removed from the editor.
- Visual Studio appearance notes are debounced instead of saving synchronously on every keystroke.
- Canonical visual generation now keeps the profile portrait as an identity cue even when separate reference images are present.
- Restore failure handling uses rollback-safe persistence rather than intentionally suppressing cleanup-save errors.
- Archive validation now rejects duplicate nested identifiers, duplicate prompt IDs/turnaround angles, blank required nested labels/titles, empty required visual payloads, ancestry cycles and conflicting family-generation paths before restore.
- Relationship perspective lookup no longer treats an unrelated character as the target endpoint.
- Large family-tree traversal reports structural generation conflicts instead of silently presenting an arbitrary traversal result.
- Legacy migration no longer identifies the imported bucket by title alone.
- The non-destructive local-store recovery screen now offers an explicit retry without erasing or replacing the author's store.
- Backup JSON validation/encoding is prepared away from the interactive SwiftUI path before the system file exporter writes the document.

### Code quality and packaging

- Split Guide, relationship/family and history implementations out of the oversized character-detail source.
- Added focused comments for persistence, relationship direction, archive reconstruction and other non-obvious invariants rather than commenting trivial syntax.
- Added a real opaque 1024×1024 application AppIcon, not just an asset-catalogue manifest entry.
- CI now preflights the icon file, catalogue manifest, dimensions and alpha state so missing packaging assets cannot hide behind a successful Xcode exit code.
- Added an XCUITest target with a smoke flow that launches the Story Library and opens the New Story editor.
- Added deterministic regression coverage for the rollback failure path, unrelated relationship endpoints and conflicting archived family-generation paths.
- App version remains 1.0.1 build 12.
- No SwiftData entity/field was added and portable archive format remains version 1.

### CI and release safety

- GitHub Actions runs the complete simulator unit/UI tests, an optimized simulator Release build and an optimized unsigned generic `iphoneos` Release build.
- Stale runs for the same pull request or branch are cancelled through workflow concurrency grouping.
- Third-party workflow actions are pinned to immutable commit SHAs.
- Release-publisher JavaScript is stored in a normal source file and syntax-checked before execution.
- A release request is rejected unless its exact target SHA is an ancestor of `main` and that exact SHA has a successful `iOS Build` workflow run.
- README, architecture, feature-status, roadmap and release-checklist documentation are synchronized with the released 1.0.0 baseline and 1.0.1 hardening work.

### Validation boundary

- Hosted CI can compile the real-device target but still cannot prove Image Playground output quality or cross-angle visual identity consistency on a physical supported iPhone.
- Archive format v1 intentionally remains a single portable JSON document for compatibility. A future archive-format revision can move large binary visual assets into a package layout if real projects demonstrate that scale requires it.

## [1.0.0] - 2026-08-17

### Stable-release readiness

- App version advanced to 1.0.0 build 11 without changing the SwiftData schema or Character Profiler archive format v1.
- Failure to open the local SwiftData story store now presents a non-destructive recovery screen instead of terminating through `fatalError`; Character Profiler does not automatically erase or replace the store.
- Archive regression coverage now rejects missing story/character identity, duplicate character IDs, duplicate relationship IDs, self-relationships and relationship endpoints missing from the archived cast.
- Invalid-archive restore tests verify validation occurs before a destination story is inserted.
- Portable backup filename sanitisation is covered by regression tests.
- GitHub Actions now runs the full simulator test suite and separately compiles the optimized Release configuration on release candidates.
- Added `docs/RELEASE_CHECKLIST.md` to make automated, packaging and physical-device validation gates explicit.
- Replaced the abbreviated repository license notice with the complete GNU General Public License version 3 text while retaining the project's `GPL-3.0-or-later` grant in SPDX/source notices.

### Compatibility and scope

- No new persistent entity or field is introduced by 1.0; local schema compatibility remains the same as 0.8.
- Portable project backup remains archive format v1 and continues to preserve profile, Guide, history, relationship and visual data.
- 1.0 is a stability/release pass over the feature set built through 0.8, not a broad new feature family.
- Physical-device Image Playground output-quality and cross-angle identity consistency remain explicitly unvalidated by simulator CI.
- A GitHub 1.0 tag/release is a separate action from merging this code and requires explicit release authorization.

## [0.8.0] - 2026-08-17

### Added

- Editable existing life events through a shared add/edit history editor.
- Author-controlled chronological life-event ordering with move-earlier and move-later actions.
- Richer timeline-style History presentation with explicit sequence position and lasting-impact treatment.
- Editable existing relationship type and notes while preserving the original shared graph edge.
- Inverse-safe relationship editing from either endpoint using `RelationshipEditingRules`.
- Edit-aware family validation that excludes the edge under edit while checking the proposed relationship state.
- Searchable cast picker for adding relationships in larger projects.
- Relationship-aware project cast search covering linked character names, relationship kinds and notes.
- Idempotent `LegacyDataMigration` helper for older unassigned character records.
- Regression tests for history ordering, inverse relationship editing, edit-aware family validation, migration idempotency and relationship-aware search.

### Safety and usability

- Life-event and relationship deletion now require destructive confirmation and explain linked/derived effects.
- Major story/character/Guide/relationship/history/migration/destructive save paths surface SwiftData failures instead of silently swallowing them.
- Character portrait import reports unreadable/failed image conversion rather than failing silently.
- Large-cast search shows useful result counts/guidance and no-results states.
- Profile, Guide and unavailable-project empty states are clearer.
- Accessibility labels/hints were strengthened across cast rows, project metrics, history, relationship actions and family-tree controls.

### Compatibility

- App version is now 0.8.0 build 10.
- Version 0.8 adds no new SwiftData entity or persistent field.
- Character Profiler archive format remains version 1; existing 0.6/0.7 project archives remain structurally compatible.
- Physical-device Image Playground output-quality validation from 0.7 remains outstanding and is not falsely claimed by simulator CI.

## [0.7.0] - 2026-08-16

### Added

- Dedicated `CharacterVisualWorkspaceView.swift` for the Visual Studio workflow instead of embedding the implementation in `CharacterDetailView`.
- `VisualWorkspaceSnapshot` derived state for canonical-image presence, reference count, unique available angles, missing angles, duplicate stored angles and turnaround completion.
- Runtime Image Playground support detection using the system availability environment value.
- Reference-image editor with labels, deterministic ordering and explicit deletion.
- Canonical visual replacement choices that make stale-turnaround risk explicit.
- Eight fixed turnaround slots with completion progress and named missing-angle reporting.
- Arrow and drag navigation through all eight positions, including positions that have not yet been generated.
- Generate-next-missing, per-angle regeneration/deletion and whole-turnaround reset controls.
- Duplicate stored-angle detection in the Visual Studio UI.
- Unit tests for visual-state completeness, duplicate-angle handling, eight-angle wraparound navigation and reference ordering.

### Reliability and consistency

- Turnaround generation uses the accepted canonical image as the identity source rather than falling back to unrelated source references.
- Replacing a canonical image can reset existing turnaround frames only after a replacement is successfully accepted, so cancelling generation does not destroy the current turnaround.
- Resetting the turnaround preserves the canonical image, reference pictures and written appearance notes.
- Clearing the visual set preserves author reference pictures and appearance notes.
- Existing visual assets remain viewable/manageable when image generation is unavailable.
- Reference import and visual-save failures are surfaced rather than silently ignored.
- App version is now 0.7.0 build 9.

### Validation boundary

- Simulator CI validates the SwiftUI/Image Playground SDK integration and deterministic Visual Studio state logic.
- Actual generated-image quality and character-identity consistency across canonical and turnaround views still require validation on a supported physical device.
- Version 0.7 adds no new SwiftData entity or persistent field; the existing archive v1 visual payload remains structurally sufficient.

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
