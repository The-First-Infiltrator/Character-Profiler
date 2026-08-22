<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler

[![iOS Build](https://github.com/The-First-Infiltrator/Character-Profiler/actions/workflows/ios-build.yml/badge.svg)](https://github.com/The-First-Infiltrator/Character-Profiler/actions/workflows/ios-build.yml)

Character Profiler is a native iPhone story-bible and character-development app for authors. It combines flexible character profiles, linked relationships and family, structured life history, genre-aware development questions, portable project backup/restore and a focused character-appearance workspace.

## Version 1.1.0

**Character Profiler 1.1.0 build 16** is the first major interface and workflow refinement after the stable 1.0 line. It keeps the existing local data model and archive format while making the app substantially easier to navigate and use on an iPhone.

The 1.1 experience centres on three clearer levels:

- **Story Library** — a cleaner story home with richer story rows, cast/development context and an explicit restore action;
- **Story workspace** — a story summary card, development metrics and a more deliberate cast-building flow;
- **Character workspace** — a dashboard instead of a cramped five-way segmented control, with full-screen destinations for Profile, Character Guide, People & Relationships, History and Visual Studio.

Editing is also less overwhelming. Character identity, story role, portrait and detailed profile sections are separated into clearer groups, while long profile sections collapse until the author chooses to work on them.

The 1.0.2 deletion fixes and 1.0.3 app-icon integrity repair remain included. CI still validates the actual compiled iPhone icon against the canonical source image before release packaging.

Character Profiler remains local-first. Version 1.1.0 adds no new SwiftData entity or persistent field and does not change **Character Profiler archive format v1**.

## Product boundaries

Character Profiler is a character-development tool. It does not silently turn suggestions into canon and does not attempt to write the novel for the author.

The Visual Studio exists to answer **what does this character look like?** It now has two deliberately separate visual paths: Image Playground produces authored 2D canonical/turnaround reference images, while RealityKit photogrammetry can reconstruct three or more photographs into an actual rotatable USDZ model on supported hardware. The 3D path is for appearance inspection only; it is not a scene generator, animation/filmmaking system, game engine, posing studio or rigged character system. The USDZ reconstruction is currently generated as a temporary on-device result and is separate from archive format v1, which continues to preserve the existing 2D visual assets.

## Visual Studio validation boundary

The Visual Studio integration, deterministic eight-slot 2D state and real-device compilation are covered by hosted CI. The 3D reconstruction path is compiled as part of the real-device target and explicitly fails when RealityKit cannot reconstruct the supplied photographs reliably. Hosted CI still cannot prove physical-device Image Playground output quality or the quality of a particular photogrammetry reconstruction.

A supported physical iPhone is therefore required to validate actual Image Playground generation, canonical/turnaround consistency and practical RealityKit reconstruction from real photographs. Source photographs for 3D reconstruction should show the same person from overlapping angles; three can be attempted, while a broader set generally provides a stronger reconstruction.

This limitation does not affect the local profile, Guide, relationship, history or backup workflows; those remain available when Image Playground or 3D reconstruction is unavailable.

## Backup and restore

A project backup is a human-inspectable JSON document such as `Ashes-of-the-Crown.characterprofiler.json`.

Archive format v1 contains project metadata, every character, flexible profile sections/fields, Guide answers, life events, relationships, profile/reference/generated images and turnaround frames. Restore validates the document before creating a destination story, creates fresh local SwiftData identifiers and then rebuilds relationship edges from archived reconstruction keys. The same backup can therefore be restored repeatedly without colliding with the original or another restore.

The archive is an application-owned interchange format, not a raw SwiftData database copy. SwiftData schema compatibility and archive-format compatibility are maintained as separate contracts.

Backup processing is deliberately bounded. The current archive implementation accepts encoded archives up to 128 MiB, at most 1,000 characters and 25,000 relationships per story, no more than six reference images and eight turnaround frames per character, and applies additional generous limits to nested profile/history/Guide collections, text fields and visual payloads.

## Requirements and build

- iOS 17.0 or later for the core application.
- Xcode with the Image Playground SDK for Visual AI compilation.
- A supported Apple device/system environment for actual Image Playground generation and RealityKit photogrammetry.
- Swift 5 language mode or later.

Open `CharacterProfiler.xcodeproj`, select the `CharacterProfiler` scheme and choose an iPhone simulator or connected iPhone. A physical-device build requires an Apple Development team under Signing & Capabilities. No personal Team ID is committed to the repository.

GitHub Actions uses pinned Xcode 16.4 on the `macos-15` runner, dynamically prepares an iPhone simulator, runs the complete unit/UI-test suite with complete Swift concurrency diagnostics, compiles an optimized simulator Release and separately compiles an unsigned optimized real-device iOS Release. The device build is packaged into `CharacterProfiler-<version>-unsigned.ipa` and retained as a CI artifact.

Published GitHub Releases include the unsigned IPA and its SHA-256 checksum. The IPA is intentionally unsigned: AltStore/AltServer, Sideloadly or another sideloading tool applies the user's development signature during installation.

## Data and privacy

Character and story data is local-first through SwiftData. Large image payloads use external binary storage in the local store. Character Profiler contains no advertising or analytics SDKs. Backups and restores are explicit author actions through the system document UI, and image selection uses the system Photos picker.

If the local story store cannot be opened, the app does not silently create a replacement store as a recovery shortcut.

## Documentation

- `docs/PRODUCT_SPEC.md` — product intent and boundaries.
- `docs/FEATURE_STATUS.md` — implementation/validation audit.
- `docs/ROADMAP.md` — completed milestones and future candidates.
- `docs/RELEASE_CHECKLIST.md` — stable-release and physical-device validation gates.
- `ARCHITECTURE.md` — model, graph, archive, migration and subsystem design.
- `CHANGELOG.md` — release history.
- `SECURITY.md` — responsible vulnerability reporting and supported-version policy.
- `CONTRIBUTING.md` — contribution, testing and pull-request expectations.

## Licence

Copyright © 2026 Shannon Smith and Olivia Jezewski.

Character Profiler is free software licensed under the GNU General Public License version 3 or, at your option, any later version (`GPL-3.0-or-later`). The complete GPLv3 text is included in `LICENSE`.
