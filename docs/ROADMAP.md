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

Goal: make the Guide behave more like an author-development assistant and less like a fixed questionnaire.

Delivered:

- prompt catalogue expanded from the initial small set to well over 100 stable prompts;
- deeper coverage for every existing built-in genre;
- deterministic suggestion scoring based on genre and how developed each category already is;
- category balancing so the visible list spans several dimensions before repeating one;
- development-depth signals derived from profile fields, Guide answers, relationships, role and life history;
- expanded adaptive follow-ups from trauma/loss, family, multiple life events and relationship patterns;
- context triggers for magic, combat/war, secrecy, faith, money, family, romance and revenge;
- human-readable reasons attached to `GuideSuggestion` results;
- 0.5.1 presentation of those reasons directly on Guide cards and inside the answer sheet;
- preservation of stable prompt IDs and answered-prompt suppression;
- unit tests for catalogue uniqueness/size, genre filtering, category diversity, adaptive context and development-depth detection.

The Guide remains deterministic and advisory. It does not silently change character canon. Suggestion explanations are presentation metadata rather than character facts.

True semantic contradiction checking—such as recognising that two independently written facts cannot both be true—is not claimed by 0.5 and remains future work.

## 0.6 — Author workflow and portability

Status: implemented on the 0.6.0 feature branch, subject to exact final-head CI validation and integration.

Goal: make a developed story bible easier to maintain, protect and move.

Delivered scope:

- application-owned project archive format with explicit format version 1;
- system document export for complete story backups;
- system document import for restoring a backup into the Story Library;
- archive coverage for project metadata, characters, flexible fields, Guide answers, life events, relationships and every current visual asset;
- fresh SwiftData object identifiers on restore, with archived IDs used only as temporary graph reconstruction keys;
- ability to restore the same backup multiple times without unique-ID collisions;
- archive validation for unsupported versions and malformed relationship references;
- relationship reconstruction after every character has been created;
- failed-restore cleanup rather than intentionally leaving a partial project;
- round-trip tests that include profile, history, Guide, relationship and binary visual data;
- safer destructive confirmations for story and character deletion with affected-data counts;
- project overview metrics for cast, relationships, history, Guide progress and average character development;
- CI simulator discovery/provisioning so hosted-runner variability does not create a false app failure merely because a particular simulator name is absent.

The archive is deliberately not a raw SwiftData/database dump. Future archive-format changes must increment or explicitly migrate the format rather than depending on accidental decoder compatibility.

## 0.7 — Visual Studio hardening

Status: next major development target after 0.6.0 is integrated, with some validation dependent on access to a supported physical iPhone.

Goal: improve reliability and consistency of the existing focused visual workflow without expanding its scope.

Work to evaluate:

- real-device Image Playground testing;
- clearer handling when Apple Intelligence/Image Playground is unavailable;
- reference-image management improvements;
- stronger consistency between canonical image and turnaround angles;
- better detection and replacement of missing angle frames;
- clearer visual-workspace state when only some turnaround views exist.

This phase does not add scenes, animation or filmmaking.

## 0.8 — Remaining author-release hardening

Status: planned after the parts of 0.7 that can be validated without a physical device.

Likely work:

- richer chronological history presentation;
- editing existing life events rather than delete/recreate only;
- editing existing relationships while preserving graph invariants;
- broader migration regression coverage as the SwiftData model evolves;
- large-cast usability and accessibility passes;
- final destructive-flow and empty-state review;
- release-quality error handling and copy consistency.

This phase may be adjusted after real-device testing exposes concrete usability issues.

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
