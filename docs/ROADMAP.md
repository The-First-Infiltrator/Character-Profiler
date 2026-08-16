<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Roadmap

The roadmap follows the product specification rather than adding features simply because they are technically possible.

## 0.3.1 — Stabilisation and definition

Status: complete.

Goal: make the application build-clean and make the repository the source of truth for what Character Profiler is intended to become.

Delivered:

- fixed the UIKit renderer compile regression exposed by the first real Xcode CI run;
- completed the GitHub Actions Xcode build and unit tests;
- formalised `PRODUCT_SPEC.md`;
- established `FEATURE_STATUS.md` as an implementation audit;
- strengthened architecture documentation and product boundaries;
- documented the development sequence in this roadmap.

## 0.4 — Family tree

Status: implemented on the 0.4.0 feature branch, subject to final CI validation and release integration.

Goal: turn the existing relationship graph into a useful author-facing visual family tool without creating a second family database.

Delivered scope:

- graphical family tree generated from existing parent/child/sibling/spouse/partner links;
- generation placement derived from parent/child direction;
- connected-family traversal so grandparents, grandchildren and larger family structures can appear;
- tappable family members that open their existing character records;
- distinct visual connector treatment for ancestry, partners and siblings;
- two-axis scrolling for large layouts;
- pinch zoom plus explicit zoom controls;
- duplicate-link validation;
- ancestry-cycle protection for parent/child links;
- protection against recording a direct ancestor/descendant pair as siblings;
- unit coverage for family-graph generation and structural validation.

The family tree remains a projection of `CharacterRelationship` data. It does not persist a parallel tree model.

A broader non-family relationship network for friends, rivals, enemies, mentors and colleagues remains future work. It should be designed separately so genealogy does not become visually unreadable.

## 0.5 — Character Guide depth

Status: next major development target after 0.4.0 is integrated.

Goal: improve how well the app helps an author discover missing dimensions of a character rather than merely presenting a questionnaire.

Planned work:

- substantially increase prompt coverage within existing genres;
- improve category distribution so suggestions do not over-focus on one dimension;
- add deeper follow-ups from life events and relationship patterns;
- connect multiple known facts when suggesting a question;
- identify obviously underdeveloped profile areas;
- improve explanation of why a prompt is being suggested where useful;
- preserve stable prompt IDs so existing answers remain valid as the catalogue grows.

The Guide remains advisory. It should not silently turn generated suggestions or prompt output into character canon.

## 0.6 — Author workflow and portability

Goal: make a developed story bible easier to maintain and protect.

Likely work to evaluate:

- project-level backup/export and restore/import;
- safer deletion flows for heavily linked characters;
- project summaries and cast overview improvements;
- migration tests as the SwiftData model evolves.

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
