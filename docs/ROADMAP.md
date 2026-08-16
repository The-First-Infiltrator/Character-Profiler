<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Roadmap

The roadmap follows the product specification rather than adding features simply because they are technically possible.

## 0.3.1 — Stabilisation and definition

Goal: make the current application build-clean and make the repository the source of truth for what Character Profiler is intended to become.

Work:

- fix the UIKit renderer compile regression exposed by the first real Xcode CI run;
- run the complete GitHub Actions Xcode build and unit tests;
- formalise `PRODUCT_SPEC.md`;
- maintain `FEATURE_STATUS.md` as an implementation audit;
- strengthen architecture documentation and product boundaries;
- document the development sequence in this roadmap;
- avoid adding unrelated functionality during stabilisation.

Exit criterion: CI is green and the documentation accurately describes both the intended product and the implementation that exists.

## 0.4 — Family and relationship map

Goal: turn the existing relationship graph into a useful author-facing visual tool.

Priority behaviour:

- graphical family tree from existing parent/child/sibling/partner links;
- tap a person to open their character record;
- visually distinguish family from non-family relationships;
- support larger families without making the view unreadable;
- preserve the underlying relationship data model rather than duplicating relationship information solely for the diagram.

A broader relationship-network view may follow the family tree, but the first objective is a clear and dependable family view.

## 0.5 — Character Guide depth

Goal: improve how well the app helps an author discover missing dimensions of a character.

Planned work:

- increase prompt coverage within existing genres;
- improve distribution so the Guide does not over-focus on one category;
- add better follow-ups from life events and relationship patterns;
- identify obviously underdeveloped profile areas;
- improve explanation of why a prompt is being suggested where useful.

The Guide remains advisory. It should not silently turn AI or prompt output into character canon.

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
