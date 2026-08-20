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

### 0.8 — Author-release hardening

Status: complete and integrated.

Delivered editable/reorderable life history, in-place inverse-safe relationship editing, edit-aware graph validation, confirmed relationship/life-event deletion, searchable large-cast relationship selection, relationship-aware cast search, migration regression coverage, improved accessibility/empty states and release-quality failure surfacing.

### 1.0.0 — First stable author release

Status: released.

Established the first stable feature baseline, non-destructive startup store failure handling, hostile archive regression coverage, optimized Release CI, complete GPLv3 licensing and explicit physical-device Visual Studio validation boundaries.

### 1.0.1 — Audit hardening

Status: released.

This release is a focused corrective pass over the complete codebase. It addresses issues found in a line-by-line functionality/code/commenting audit:

- transactional SwiftData save/rollback semantics;
- editable/deletable saved Character Guide answers;
- stable profile section/field identifiers and explicit blank-label validation;
- Story Library activity timestamps for character-scoped work;
- Visual Studio persistence debounce and stronger identity-reference handling;
- stricter archive validation and cleanup behavior;
- removal of the old arbitrary family-tree traversal cap plus explicit detection of conflicting generation paths;
- source decomposition and invariant comments around the Guide, relationship and history subsystems;
- real application asset/AppIcon wiring;
- simulator tests plus optimized simulator and `iphoneos` device Release builds;
- release-publisher syntax checking and exact-main/exact-CI target verification;
- repository documentation synchronized to the actual released/hardened state.

Version 1.0.1 remains archive format v1 and introduces no new SwiftData entity or persistent field.

### 1.0.2 — Device deletion and icon correction

Status: released.

Delivered explicit confirmed character/story deletion paths, end-to-end deletion coverage and the first corrected physical-device icon package. Version 1.0.2 remains archive format v1 and introduces no SwiftData entity or persistent field.

### 1.0.3 — Compiled app-icon integrity

Status: released.

Delivered the deterministic canonical icon and a permanent CI gate that verifies the pixels of the icon compiled into the iPhoneOS application before release. Version 1.0.3 remains archive format v1 and introduces no SwiftData entity or persistent field.

### 1.1.0 — iPhone workflow refinement

Status: release candidate.

Delivers the redesigned Story Library and story workspace hierarchy, a full-screen Character workspace dashboard, clearer story and character editing, collapsible profile details and end-to-end coverage for the revised navigation and deletion flows.

Version 1.1.0 remains archive format v1 and introduces no SwiftData entity or persistent field. The release candidate must pass the complete simulator test suite plus optimized simulator and unsigned iPhoneOS Release builds before its IPA is published for physical-device testing.

## Outstanding physical-device checks

Hosted CI cannot establish Image Playground output quality. A supported physical iPhone is still required to validate:

- actual Image Playground generation on-device;
- device-specific availability/user-flow behavior;
- canonical and turnaround consistency of face, body proportions, clothing, colours and equipment.

## Post-1.0 candidates, not commitments

The following require a deliberate product decision before entering a numbered release:

- semantic contradiction/consistency analysis across character facts;
- broader visual relationship network for non-family links;
- iCloud synchronization;
- additional visual-AI provider abstraction;
- richer archive history/comparison;
- package-based archive assets if JSON backups become too large for practical projects;
- iPad-specific layouts;
- Mac companion application;
- true 3D character mesh.

## Explicitly outside the roadmap

Unless the product specification is deliberately changed, Character Profiler does not include scene/video generation, character animation, a game engine, RPG mechanics, automatic chapter/story writing or a large posing studio.
