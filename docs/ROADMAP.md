<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Roadmap

The roadmap follows the product specification rather than adding features simply because they are technically possible.

## Completed foundation

### 0.3.1 — Stabilisation and definition

Status: complete and integrated.

Established the first build-clean baseline, product specification, feature-status audit, architecture boundaries and development roadmap.

### 0.4 — Family tree

Status: complete and integrated.

Delivered the graphical family tree projected from real relationship edges, multi-generation traversal, navigation, zoom/scroll and structural validation for duplicate links and ancestry contradictions.

### 0.5 / 0.5.1 — Character Guide depth

Status: complete and integrated.

Delivered more than 120 stable prompts, broad genre coverage, deterministic development-depth scoring, category balancing, adaptive context, stable answered-prompt suppression and visible human-readable reasons.

### 0.6 — Author workflow and portability

Status: complete and integrated.

Delivered Character Profiler archive format v1, complete project backup/export and restore/import, fresh local IDs, graph reconstruction, validation, round-trip tests, project metrics, safer story/character deletion and resilient hosted-runner simulator preparation.

### 0.7 — Visual Studio hardening

Status: complete and integrated for simulator-testable behavior. Physical-device Image Playground output-quality validation remains outstanding.

Delivered runtime Image Playground availability handling, labelled/reorderable references, canonical-image lifecycle, canonical identity anchoring for turnaround generation, eight fixed angle slots, missing/duplicate reporting, progress, per-angle recovery/reset and deterministic visual-state tests.

Outstanding physical-device checks:

- actual Image Playground generation on a supported iPhone;
- device-specific availability/user-flow behavior;
- canonical and turnaround consistency of face, body proportions, clothing, colours and equipment.

### 0.8 — Author-release hardening

Status: complete and integrated.

Delivered editable/reorderable life history, in-place inverse-safe relationship editing, edit-aware graph validation, confirmed relationship/life-event deletion, searchable large-cast relationship selection, relationship-aware cast search, migration regression coverage, improved accessibility/empty states and release-quality failure surfacing.

Version 0.8 added no SwiftData entity/field and retained archive format v1.

## 1.0 — First stable author release

Status: **current release-readiness candidate**.

Goal: make the existing product dependable enough to call stable without using a major version number as an excuse for unrelated feature growth.

The 1.0 pass delivers/validates:

- non-destructive startup behavior when the local SwiftData store cannot open;
- hostile/malformed archive regression coverage in addition to the existing whole-story round trip;
- explicit proof that invalid archives are rejected before a destination story is inserted;
- a CI gate containing both the complete simulator test suite and a separate Release-configuration compile;
- complete GNU GPLv3 license text in the source distribution;
- a release checklist tying stability claims to concrete validation;
- version 1.0.0 build 11;
- final README/changelog/architecture/feature-status alignment;
- continued archive format v1 and no 1.0 SwiftData schema change;
- explicit disclosure of the still-unperformed physical-device Visual Studio quality checks.

Release sequence:

1. exact final 1.0 feature head passes tests and Release build;
2. PR is marked ready;
3. integration into `main` requires explicit merge authorization;
4. exact merged `main` commit passes the same workflow;
5. a `v1.0.0` tag/GitHub Release is a separate action requiring explicit release authorization.

## Post-1.0 candidates, not commitments

The following require a deliberate product decision before entering a numbered release:

- semantic contradiction/consistency analysis across character facts;
- broader visual relationship network for non-family links;
- iCloud synchronization;
- additional visual-AI provider abstraction;
- richer archive history/comparison;
- iPad-specific layouts;
- Mac companion application;
- true 3D character mesh.

## Explicitly outside the roadmap

Unless the product specification is deliberately changed, Character Profiler does not include scene/video generation, character animation, a game engine, RPG mechanics, automatic chapter/story writing or a large posing studio.
