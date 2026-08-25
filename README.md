<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler

[![iOS Build](https://github.com/The-First-Infiltrator/Character-Profiler/actions/workflows/ios-build.yml/badge.svg)](https://github.com/The-First-Infiltrator/Character-Profiler/actions/workflows/ios-build.yml)

Character Profiler is a native iPhone story-bible and character-development app for authors. It combines flexible character profiles, relationships and family, structured life history, genre-aware development questions, portable backup/restore and a focused appearance workspace.

**Current version:** 1.1.1 build 17  
**Platform:** iOS 17 or later  
**Licence:** GPL-3.0-or-later

## Capabilities

The application is organised around three levels:

- **Story Library** — story overview, cast/development context and restore entry point.
- **Story workspace** — story summary, development metrics and cast-building workflow.
- **Character workspace** — Profile, Character Guide, People & Relationships, History and Visual Studio.

Character Profiler remains local-first. Version 1.1.1 keeps the existing SwiftData model and **Character Profiler archive format v1**.

Visual Studio has two deliberately separate paths: Image Playground produces authored 2D reference imagery, while RealityKit photogrammetry can reconstruct three or more photographs into a rotatable USDZ model on supported hardware. The 3D path is for appearance inspection, not scene generation, animation, rigging or filmmaking.

## Architecture

SwiftData owns the local story/character store. Large image payloads use external binary storage. Backup files are application-owned JSON interchange documents rather than raw SwiftData database copies, which keeps archive compatibility separate from SwiftData schema compatibility.

Restore validates the archive, creates fresh local identifiers and then rebuilds relationships from archived reconstruction keys. The same backup can therefore be restored repeatedly without identifier collisions.

Backup processing is bounded: archives are limited to 128 MiB encoded size, 1,000 characters and 25,000 relationships per story, with additional limits on nested collections, text and visual payloads.

The optional RealityKit/Quick Look reconstruction implementation is isolated in `Character3DHeadWorkspaceView.swift`; `CharacterDetailView.swift` remains the character-workspace/navigation shell rather than owning the 3D subsystem.

The app contains no advertising or analytics SDKs. Photos are selected through the system picker, and backup/restore is explicit through the system document UI.

## Build and test

Open `CharacterProfiler.xcodeproj`, select the `CharacterProfiler` scheme and build for an iPhone simulator or connected iPhone. A physical-device build requires an Apple Development team under Signing & Capabilities; no personal Team ID is committed to the repository.

GitHub Actions uses pinned Xcode 16.4 on `macos-15`, prepares an iPhone simulator dynamically, runs the complete test suite with strict Swift concurrency diagnostics, builds an optimized simulator Release and separately compiles an unsigned optimized iPhoneOS Release.

Hosted CI validates the compiled application icon against the canonical source image. Physical-device Image Playground output quality and the quality of a particular photogrammetry reconstruction still require real-device testing.

## Release assets

A numbered release publishes:

| File | Purpose |
| --- | --- |
| `CharacterProfiler-<version>-unsigned.ipa` | Unsigned physical-device iOS application package. |
| `CharacterProfiler-<version>-unsigned.ipa.sha256` | SHA-256 checksum for the IPA. |

The IPA is intentionally unsigned. AltStore/AltServer, Sideloadly or another compatible sideloading tool applies the user's development signature during installation.

## Repository and release policy

This repository uses `main` as its working branch. Development changes are made directly on `main`; the normal project workflow does not depend on PR, feature or release branches.

Every push to `main` runs the iOS build/test workflow. Ordinary commits do not publish. A commit is release-eligible only when its subject begins `Release <version>` and the complete `iOS Build` workflow succeeds.

The publisher checks out that exact tested commit, verifies it is still current `main`, validates project/release metadata and independently builds the optimized unsigned iPhoneOS release payload on the same SHA. It then creates a new immutable version tag and GitHub Release containing the unsigned IPA plus checksum. A version containing a prerelease suffix such as `-rc.1` is published as a prerelease automatically. Existing version tags, releases and release assets are never moved, patched, deleted or replaced in place.

The simulator test and optimized simulator/device compile gates belong to the triggering `iOS Build` run. Publication consumes that successful exact-SHA result rather than pretending to rerun tests it does not rerun.

## Documentation

- `docs/PRODUCT_SPEC.md` — product intent and boundaries.
- `docs/FEATURE_STATUS.md` — current implementation and validation status.
- `docs/ROADMAP.md` — completed milestones and future candidates.
- `docs/RELEASE_CHECKLIST.md` — stable-release and physical-device validation gates.
- `ARCHITECTURE.md` — model, graph, archive, migration and subsystem design.
- `CHANGELOG.md` — release history.
- `SECURITY.md` — vulnerability reporting and supported-version policy.

## Limits

Character Profiler is a character-development tool. It does not silently turn suggestions into canon and does not attempt to write the novel for the author. Visual Studio is an appearance workspace, not a general-purpose image/video production system.

If Image Playground or RealityKit reconstruction is unavailable, the local profile, Guide, relationship, history and backup workflows remain usable.

## Licence

Copyright © 2026 Shannon Smith and Olivia Jezewski.

Character Profiler is free software licensed under the GNU General Public License version 3 or, at your option, any later version (`GPL-3.0-or-later`). The complete licence text is included in `LICENSE`.
