<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler

Character Profiler is a native iPhone story-bible and character-development app for authors. It combines flexible character profiles, linked relationships and family, structured life history, genre-aware development questions, portable project backup/restore and a focused character-appearance workspace.

## Version 1.0.0

**Character Profiler 1.0.0 build 11** is the first stable-release candidate. The 1.0 pass deliberately concentrates on reliability, data safety, compatibility, packaging and release verification rather than adding a new feature family.

The application now has a non-destructive startup failure state: if the local SwiftData story store cannot be opened, Character Profiler shows a recovery message instead of terminating with `fatalError`, and it does not automatically erase or replace the author's store.

Portable backup remains **Character Profiler archive format v1**. In addition to the full round-trip/restore-twice coverage added in 0.6, the 1.0 suite exercises malformed archives: missing story or character identity, duplicate character IDs, duplicate relationship IDs, self-relationships and endpoints that do not exist in the archived cast are rejected before restore inserts a destination story.

The GitHub Actions release gate now proves two builds on the exact candidate SHA: the complete simulator test suite and a separate optimized **Release configuration** compile with signing disabled. Hosted CI still discovers or provisions an available iPhone simulator dynamically.

The repository includes the complete GNU GPL version 3 license text and a dedicated `docs/RELEASE_CHECKLIST.md` that separates automated proof from the physical-device Image Playground checks that simulator CI cannot establish.

### What 1.0 contains

Character Profiler 1.0 includes the work delivered through the 0.x milestones:

- multiple story projects with built-in/custom genres, premise, project metrics and cast search;
- flexible character profiles with arbitrary sections/fields, portraits and development progress;
- a local deterministic Character Guide with more than 120 stable prompts, genre-aware scoring, adaptive follow-ups and visible “why this question?” reasons;
- real character-to-character relationship edges, inverse parent/child and mentor/student semantics, safe relationship editing and a graphical multi-generation family tree;
- editable, explicitly ordered life-history events covering trauma, loss, milestones, conflict, relationships, education, career, adventure and other formative events;
- searchable relationship selection and relationship-aware search for larger casts;
- complete versioned project backup/export and restore/import, including relationships, Guide answers, history and visual assets;
- deliberate destructive confirmations and surfaced persistence/import failures throughout the major author workflows;
- Character Visual Studio with labelled reference images, canonical appearance management and eight fixed 45° turnaround slots on supported Image Playground devices.

## Product boundaries

Character Profiler is a character-development tool. It does not silently turn suggestions into canon and does not attempt to write the novel for the author.

The Visual Studio exists to answer **what does this character look like?** It is not a scene generator, animation/filmmaking system, game engine, posing studio or true 3D character modeller. The eight-view turnaround is a set of generated reference images, not a textured 3D mesh.

## Visual Studio validation boundary

The Visual Studio integration, availability handling and deterministic eight-slot state are covered by simulator CI. Actual Image Playground output quality cannot be proven there.

A supported physical iPhone is still required to validate that real generation launches correctly and that the canonical image plus all eight turnaround views preserve face, body proportions, clothing, colours and equipment well enough to be useful as one consistent character reference set. Character Profiler does not claim that physical output-quality validation has happened yet.

This limitation does not affect the local profile, Guide, relationship, history or backup workflows; those remain available when Image Playground is unavailable.

## Backup and restore

A project backup is a human-inspectable JSON document such as:

`Ashes-of-the-Crown.characterprofiler.json`

Archive format v1 contains project metadata, every character, flexible profile sections/fields, Guide answers, life events, relationships, profile/reference/generated images and turnaround frames.

Restore validates the document before creating a destination story, creates fresh local SwiftData identifiers and then rebuilds relationship edges from archived reconstruction keys. The same backup can therefore be restored repeatedly without colliding with the original or another restore.

The archive is an application-owned interchange format, not a raw SwiftData database copy. SwiftData schema compatibility and archive-format compatibility are maintained as separate contracts.

## Requirements and build

- iOS 17.0 or later for the core application.
- Xcode with the Image Playground SDK for Visual AI compilation.
- A supported Apple device/system environment for actual Image Playground generation.
- Swift 5 language mode or later.

Open `CharacterProfiler.xcodeproj`, select the `CharacterProfiler` scheme and choose an iPhone simulator or connected iPhone. A physical-device build requires an Apple Development team under Signing & Capabilities. No personal Team ID is committed to the repository.

GitHub Actions dynamically prepares an iPhone simulator, runs the complete test suite and separately compiles the Release configuration.

## Data and privacy

Character and story data is local-first through SwiftData. Large image payloads use external binary storage. Character Profiler contains no advertising or analytics SDKs. Backups and restores are explicit author actions through the system document UI, and image selection uses the system Photos picker.

If the local story store cannot be opened, the app does not silently create a replacement store as a recovery shortcut.

## Documentation

- `docs/PRODUCT_SPEC.md` — product intent and boundaries.
- `docs/FEATURE_STATUS.md` — implementation/validation audit.
- `docs/ROADMAP.md` — completed milestones and post-1.0 candidates.
- `docs/RELEASE_CHECKLIST.md` — 1.0 stability and release gates.
- `ARCHITECTURE.md` — model, graph, archive, migration and subsystem design.
- `CHANGELOG.md` — release history.

## Licence

Copyright © 2026 Shannon Smith.

Character Profiler is free software licensed under the GNU General Public License version 3 or, at your option, any later version (`GPL-3.0-or-later`). The complete GPLv3 text is included in `LICENSE`.
