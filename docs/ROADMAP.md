<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Roadmap

The roadmap follows the product specification rather than adding features simply because they are technically possible.

## 0.3.1 — Stabilisation and definition

Status: complete.

Established the first build-clean baseline, product specification, feature-status audit, architecture boundaries and development roadmap.

## 0.4 — Family tree

Status: complete and integrated.

Delivered a graphical family tree projected from the existing relationship graph, multi-generation traversal, navigation, zoom/scroll and structural validation for duplicate links and ancestry contradictions.

## 0.5 / 0.5.1 — Character Guide depth

Status: complete and integrated.

Delivered more than 120 stable prompts, broad genre coverage, deterministic development-depth scoring, category balancing, adaptive context, stable answered-prompt suppression and visible human-readable reasons for suggestions.

The Guide remains advisory and does not silently change canon. Full semantic contradiction detection remains a future candidate.

## 0.6 — Author workflow and portability

Status: complete and integrated.

Delivered Character Profiler archive format v1, complete project backup/export and restore/import, fresh local IDs on restore, graph reconstruction, archive validation, round-trip tests, project metrics, safer story/character deletion and resilient hosted-runner simulator preparation.

## 0.7 — Visual Studio hardening

Status: complete and integrated for everything simulator CI can validate. Physical-device Image Playground output-quality validation remains outstanding.

Delivered runtime Image Playground availability handling, labelled/reorderable reference images, canonical-image lifecycle controls, canonical identity anchoring for turnaround generation, fixed eight-slot navigation, missing/duplicate angle reporting, progress, per-angle recovery/reset controls and deterministic visual-state tests.

Still requiring a supported physical device:

- real Image Playground generation testing;
- judgement of canonical/turnaround face, proportions, clothing and equipment consistency;
- device-specific Image Playground availability/user-flow validation.

## 0.8 — Author-release hardening

Status: implemented on the 0.8.0 feature branch; final exact-head Xcode validation and integration are the release gates.

Goal: remove the remaining everyday author-workflow rough edges before 1.0.

Delivered in 0.8.0:

- editable existing life events without delete/recreate;
- a richer chronological History presentation with explicit author-controlled ordering;
- move-earlier/move-later controls for free-text ages/dates that cannot be safely machine-sorted;
- destructive confirmation and surfaced save errors for life-event removal/changes;
- editing existing relationship type and notes on the existing shared graph edge;
- inverse-safe relationship editing from either character's perspective;
- family-graph validation that evaluates edits while excluding the edge currently being changed;
- destructive confirmation for relationship removal, including family-tree impact;
- searchable cast selection when adding relationships;
- project cast search expanded to relationship names, kinds and notes;
- large-cast result counts and search guidance;
- improved empty states and accessibility labels/hints across author workflows;
- surfaced SwiftData save failures in story, character, Guide, relationship, history and destructive-action flows;
- explicit portrait-import failure handling;
- idempotent legacy orphan-character migration extracted into a testable helper;
- regression tests for ordering, inverse relationship edits, edit-aware family validation, migration idempotency and relationship-aware search;
- app version 0.8.0 build 10.

Version 0.8 adds no new SwiftData entity or persistent field and does not change portable archive format v1.

## 1.0 — First stable author release

Status: **next major development target after 0.8 integration**.

Goal: a dependable character-development application an author can use for a real writing project without treating it as a prototype.

The 1.0 pass should concentrate on release readiness rather than broad new feature scope:

- exact-head build/test stability;
- migration and archive compatibility review;
- final data-loss-path audit;
- final accessibility and large-cast usability review;
- copy/error consistency;
- packaging/release documentation;
- resolution of any concrete issues found during supported physical-device Visual Studio testing.

## Future candidates, not commitments

These require a deliberate product decision before entering a numbered release:

- semantic contradiction/consistency analysis across character facts;
- broader non-family relationship network;
- iCloud synchronisation;
- provider abstraction for additional visual AI services;
- richer archive history/comparison;
- iPad-specific layouts;
- Mac companion app;
- true 3D character mesh.

## Explicitly outside the roadmap

Unless the product specification is deliberately changed, the roadmap does not include scene/video generation, character animation, a game engine, RPG mechanics, automatic chapter/story writing or a large posing studio.
