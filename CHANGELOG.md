<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Changelog

## [0.3.0] - 2026-08-16

### Added

- Character Visual Studio as a fifth character workspace.
- Up to six visual reference pictures per character using the system Photos picker.
- Author-written appearance notes.
- AI-assisted canonical character creation using Apple's Image Playground on supported devices.
- Character profile and reference-image context supplied to visual generation.
- Ability to use the approved AI character image as the normal profile portrait.
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
