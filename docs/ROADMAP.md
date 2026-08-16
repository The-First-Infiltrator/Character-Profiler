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

Status: implemented on the 0.5.0 feature branch, subject to final Xcode CI validation and integration.

Goal: make the Guide behave more like an author-development assistant and less like a fixed questionnaire.

Delivered scope:

- prompt catalogue expanded from the initial small set to well over 100 stable prompts;
- deeper coverage for every existing built-in genre;
- deterministic suggestion scoring based on genre and how developed each category already is;
- category balancing so the visible list spans several dimensions before repeating one;
- development-depth signals derived from profile fields, Guide answers, relationships, role and life history;
- expanded adaptive follow-ups from trauma/loss, family, multiple life events and relationship patterns;
- context triggers for magic, combat/war, secrecy, faith, money, family, romance and revenge;
- human-readable reasons attached to `GuideSuggestion` results;
- preservation of stable prompt IDs and answered-prompt suppression;
- unit tests for catalogue uniqueness/size, genre filtering, category diversity, adaptive context and development-depth detection.

The Guide remains deterministic and advisory. It does not silently change character canon.

True semantic contradiction checking—such as recognising that two independently written facts cannot both be true—is not claimed by 0.5 and remains future work.

## 0.6 — Author workflow and portability

Status: next major development target after 0.5.0 is integrated.

Goal: make a developed story bible easier to maintain, protect and move.

Planned work to design and implement:

- project-level backup/export and restore/import;
- a versioned portable project format rather than an undocumented database dump;
- safer deletion flows for heavily linked characters;
- project summaries and cast overview improvements;
- migration tests as the SwiftData model evolves;
- clear handling of visual assets during backup and restore.

Export/import format and sync behaviour should be designed before implementation so story data is not trapped in a brittle format.

## 0.7 — Visual Studio hardening

Goal: improve reliability and consistency of the existing focused visual workflow without expanding its scope.

Work to evaluate:

- real-device Image Playground testing;
- clearer handling when Apple Intelligence/Image Playground is unavailable;
- reference-image management improvements;
- stronger consistency between canonical image and turnaround angles;
- better detection and replacement of missing angle frames.

This phase does not add scenes, animation or filmmaking.

## 1.0 — First stable author release

Goal: a dependable character-development application an author can use for a real writing project without treating it as a prototype.

Release criteria are defined in `PRODUCT_SPEC.md` and include build/test stability, robust persistence, a usable family/relationship view, useful genre-aware development guidance, dependable history/relationship handling and a clearly bounded visual workflow.

## Future candidates, not commitments

The following ideas may be useful but require an explicit product decision before they enter a numbered release:

- semantic contradiction/consistency analysis across character facts;
- broader non-family relationship network;
- iCloud synchronisation;
- provider abstraction for additional visual AI services;
- project-level JSON or archive formats beyond basic backup needs;
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
