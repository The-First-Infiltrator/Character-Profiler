<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Roadmap

The roadmap follows the product specification rather than adding features simply because they are technically possible.

## 0.3.1 — Stabilisation and definition

Status: complete.

Delivered the first build-clean baseline, formal product specification, feature-status audit, architecture boundaries and development roadmap.

## 0.4 — Family tree

Status: complete and integrated.

Delivered:

- graphical family tree generated from existing family relationships;
- generation placement from parent/child direction;
- connected-family traversal across multiple generations;
- tappable character cards;
- distinct ancestry/partner/sibling connectors;
- scrolling and zoom for larger families;
- duplicate-link and ancestry-cycle validation;
- Xcode unit coverage for graph generation and structural validation.

The family tree remains a projection of `CharacterRelationship` data rather than a second family database.

## 0.5 — Character Guide depth

Status: complete and integrated through 0.5.1.

Delivered:

- prompt catalogue expanded to well over 100 stable prompts;
- deeper coverage for every built-in genre;
- deterministic suggestion scoring based on genre and existing character development;
- category balancing;
- development-depth signals from profile fields, Guide answers, relationships, role and history;
- adaptive follow-ups from trauma/loss, family, multiple life events and contextual text;
- human-readable suggestion reasons;
- 0.5.1 presentation of those reasons in Guide cards and the answer sheet;
- preservation of stable prompt IDs and answered-prompt suppression;
- unit tests for catalogue uniqueness/size, genre filtering, category diversity, adaptive context and development-depth detection.

The Guide remains deterministic and advisory. True semantic contradiction checking is a separate future feature candidate.

## 0.6 — Author workflow and portability

Status: complete and integrated.

Delivered:

- Character Profiler archive format v1;
- system document export for complete story backups;
- Story Library restore/import;
- archive coverage for project metadata, characters, flexible fields, Guide answers, life events, relationships and all current visual assets;
- fresh local SwiftData identifiers on restore;
- ability to restore the same backup multiple times without identifier collisions;
- archive validation and safe failed-restore cleanup;
- relationship reconstruction after all restored characters exist;
- whole-project round-trip tests;
- safer story and character deletion confirmations with affected-data counts;
- project overview metrics;
- resilient CI simulator discovery/provisioning.

The archive is an application-owned interchange format, not a raw SwiftData/database dump.

## 0.7 — Visual Studio hardening

Status: simulator-testable scope implemented and Xcode-green on the 0.7.0 feature branch; physical-device output-quality validation remains outstanding.

Goal: improve reliability and consistency of the focused character-appearance workflow without expanding its product scope.

Delivered in 0.7.0:

- dedicated Visual Studio view implementation separated from the general character-detail screen;
- runtime Image Playground availability handling using the system support environment value;
- labelled/reorderable/deletable reference-image management;
- explicit canonical-image replacement and clearing lifecycle;
- canonical replacement can reset stale turnaround frames only after a replacement is successfully accepted;
- canonical visual enforced as the source identity image for turnaround generation;
- fixed eight-slot turnaround navigation instead of silently skipping missing positions;
- completion progress and named missing-angle reporting;
- next-missing generation action;
- independent regeneration/deletion of angle frames;
- whole-turnaround reset that preserves canonical/reference source material;
- duplicate-angle detection;
- surfaced image-import/save errors;
- deterministic Xcode tests for visual completeness, duplicate detection, angle wraparound and reference ordering;
- app version 0.7.0 build 9.

Still requiring a supported physical device:

- real Image Playground generation testing;
- judgement of whether canonical identity, proportions, clothing and equipment remain acceptably consistent across generated angles;
- confirmation of device-specific Image Playground availability/user-flow behaviour that simulator CI cannot reproduce.

This phase does not add scenes, animation, posing, filmmaking or a true 3D mesh.

## 0.8 — Remaining author-release hardening

Status: **next major development target**.

Goal: remove the remaining everyday author-workflow rough edges before the 1.0 stability pass.

Planned work:

- richer chronological history presentation;
- editing existing life events rather than delete/recreate only;
- editing existing relationships while preserving graph invariants;
- broader migration regression coverage as the SwiftData model evolves;
- large-cast usability and accessibility passes;
- final destructive-flow and empty-state review;
- release-quality error handling and copy consistency;
- review of any non-device-dependent issues discovered while auditing Visual Studio 0.7.

Physical-device findings from 0.7 may add targeted visual fixes here without expanding Visual Studio beyond character appearance/inspection.

## 1.0 — First stable author release

Goal: a dependable character-development application an author can use for a real writing project without treating it as a prototype.

Release criteria are defined in `PRODUCT_SPEC.md` and include build/test stability, robust persistence, portable backup/restore, safe destructive actions, a usable family/relationship view, useful genre-aware development guidance, dependable history/relationship handling and a clearly bounded visual workflow.

## Future candidates, not commitments

The following ideas may be useful but require an explicit product decision before they enter a numbered release:

- semantic contradiction/consistency analysis across character facts;
- broader non-family relationship network;
- iCloud synchronisation;
- provider abstraction for additional visual AI services;
- richer archive management such as backup history/comparison;
- iPad-specific multi-column layouts;
- Mac companion application.

A true 3D character mesh is also a separate future decision. The current eight-view turnaround should not be described as a true 3D model.

## Explicitly outside the roadmap

Unless the product specification is deliberately changed, the roadmap does not include:

- scene generation;
- video or cinematic generation;
- character animation;
- a game engine;
- RPG mechanics;
- automatic chapter/story writing;
- a large posing studio.
