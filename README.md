<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler

[![iOS Build](https://github.com/The-First-Infiltrator/Character-Profiler/actions/workflows/ios-build.yml/badge.svg)](https://github.com/The-First-Infiltrator/Character-Profiler/actions/workflows/ios-build.yml)

Character Profiler is a native iPhone story-bible and character-development app for authors. It combines flexible character profiles, linked relationships and family, structured life history, genre-aware development questions, portable project backup/restore and a focused character-appearance workspace.

## Version 1.0.1

**Character Profiler 1.0.1 build 12** is the audit-hardening update to the first stable release. It focuses on data-integrity guarantees, author workflow completeness, device-build validation, release safety and repository maintainability rather than adding a new feature family.

Key hardening in 1.0.1 includes:

- SwiftData save failures now roll back the current unit of work so a failed delete/edit cannot be committed accidentally by a later unrelated save;
- character-scoped changes also update the owning story activity timestamp, keeping Story Library recency accurate;
- profile editing preserves existing section/field UUIDs and blocks blank labels instead of silently dropping authored data;
- saved Character Guide answers now have a complete view/edit/delete workflow;
- Visual Studio appearance notes are debounced rather than saved on every keystroke, and canonical generation can incorporate the existing portrait together with author references;
- archive validation is stricter, restore cleanup no longer intentionally suppresses persistence failures, and backup import/export now enforces bounded resource budgets before expensive graph processing;
- family-tree projection no longer has the old arbitrary 120-character traversal cap and now surfaces conflicting generation paths instead of depending silently on traversal order;
- the Xcode target now contains a real asset catalogue/AppIcon definition;
- CI pins Xcode 16.4, enables complete Swift concurrency diagnostics in Swift 5 language mode, tests the simulator, builds an optimized simulator Release and separately compiles an unsigned optimized `iphoneos` Release;
- the UI suite now crosses from story/character creation into history creation and destructive deletion, while deterministic Guide-ranking fixtures lock editorial-priority behaviour;
- release publishing syntax-checks its script and refuses to tag a commit unless the exact SHA is on `main` and has a successful exact-SHA `iOS Build` run.

The core application remains local-first and the portable backup format remains **Character Profiler archive format v1**. Version 1.0.1 does not introduce a new SwiftData entity/field or change the archive format number.

## Product boundaries

Character Profiler is a character-development tool. It does not silently turn suggestions into canon and does not attempt to write the novel for the author.

The Visual Studio exists to answer **what does this character look like?** It is not a scene generator, animation/filmmaking system, game engine, posing studio or true 3D character modeller. The eight-view turnaround is a set of generated reference images, not a textured 3D mesh.

## Visual Studio validation boundary

The Visual Studio integration, availability handling and deterministic eight-slot state are covered by simulator CI, and 1.0.1 also compiles the real-device iOS target. Actual Image Playground output quality still cannot be proven by hosted CI.

A supported physical iPhone is still required to validate that real generation launches correctly and that the canonical image plus all eight turnaround views preserve face, body proportions, clothing, colours and equipment well enough to be useful as one consistent character reference set.

This limitation does not affect the local profile, Guide, relationship, history or backup workflows; those remain available when Image Playground is unavailable.

## Backup and restore

A project backup is a human-inspectable JSON document such as `Ashes-of-the-Crown.characterprofiler.json`.

Archive format v1 contains project metadata, every character, flexible profile sections/fields, Guide answers, life events, relationships, profile/reference/generated images and turnaround frames. Restore validates the document before creating a destination story, creates fresh local SwiftData identifiers and then rebuilds relationship edges from archived reconstruction keys. The same backup can therefore be restored repeatedly without colliding with the original or another restore.

The archive is an application-owned interchange format, not a raw SwiftData database copy. SwiftData schema compatibility and archive-format compatibility are maintained as separate contracts.

Backup processing is deliberately bounded. Version 1.0.1 accepts encoded archives up to 128 MiB, at most 1,000 characters and 25,000 relationships per story, no more than six reference images and eight turnaround frames per character, and applies additional generous limits to nested profile/history/Guide collections, text fields and visual payloads. Import preflights the selected file before mapping/decoding it, checked arithmetic protects cumulative image accounting, and export uses the same policy so the app does not create a backup it would reject on restore.

## Requirements and build

- iOS 17.0 or later for the core application.
- Xcode with the Image Playground SDK for Visual AI compilation.
- A supported Apple device/system environment for actual Image Playground generation.
- Swift 5 language mode or later.

Open `CharacterProfiler.xcodeproj`, select the `CharacterProfiler` scheme and choose an iPhone simulator or connected iPhone. A physical-device build requires an Apple Development team under Signing & Capabilities. No personal Team ID is committed to the repository.

GitHub Actions uses the pinned Xcode 16.4 toolchain on the `macos-15` runner, dynamically prepares an iPhone simulator, runs the complete unit/UI-test suite with complete Swift concurrency diagnostics, compiles an optimized simulator Release and separately compiles an unsigned optimized real-device iOS Release.

## Data and privacy

Character and story data is local-first through SwiftData. Large image payloads use external binary storage in the local store. Character Profiler contains no advertising or analytics SDKs. Backups and restores are explicit author actions through the system document UI, and image selection uses the system Photos picker.

If the local story store cannot be opened, the app does not silently create a replacement store as a recovery shortcut.

## Documentation

- `docs/PRODUCT_SPEC.md` — product intent and boundaries.
- `docs/FEATURE_STATUS.md` — implementation/validation audit.
- `docs/ROADMAP.md` — completed milestones and post-1.0 candidates.
- `docs/RELEASE_CHECKLIST.md` — stable-release and physical-device validation gates.
- `ARCHITECTURE.md` — model, graph, archive, migration and subsystem design.
- `CHANGELOG.md` — release history.
- `SECURITY.md` — responsible vulnerability reporting and supported-version policy.
- `CONTRIBUTING.md` — contribution, testing and pull-request expectations.

## Licence

Copyright © 2026 Shannon Smith.

Character Profiler is free software licensed under the GNU General Public License version 3 or, at your option, any later version (`GPL-3.0-or-later`). The complete GPLv3 text is included in `LICENSE`.
