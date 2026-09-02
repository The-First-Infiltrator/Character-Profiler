<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Feature Status

This document records the current implementation and validation state against `PRODUCT_SPEC.md`. Historical release detail belongs in `CHANGELOG.md`; this file deliberately describes the current product rather than repeating release history.

Status meanings: **Implemented** is present in code and covered by the stated validation; **Partial** exists but retains an explicit validation/completion gap; **Planned** is committed future work; **Candidate** requires a separate product decision.

## Product foundation

| Capability | Status | Notes |
| --- | --- | --- |
| Native SwiftUI iPhone application | Implemented | iOS 17+ target, current version 1.1.2 build 18. |
| SwiftData local persistence | Implemented | Projects, characters, profiles, Guide, history, relationships and visual assets. |
| Transactional save failure handling | Implemented | User-visible save failure rolls back the current SwiftData unit of work. |
| Story/project library | Implemented | Projects own cast, genre, premise and activity context. |
| Startup store-open recovery | Implemented | Non-destructive error/retry state; no automatic store deletion or replacement. |
| Portable project archive | Implemented | Application-owned JSON archive format v1, independent of SwiftData schema versioning. |
| Resource-bounded archive handling | Implemented | Encoded size, collection, text and visual payload limits are validated before restore. |

## Character profile and author workflow

| Capability | Status | Notes |
| --- | --- | --- |
| Core identity and portrait | Implemented | Name, nickname, age, pronouns, role, summary and replace/remove portrait flow. |
| Flexible sections/fields | Implemented | Arbitrary author-defined profile content with stable row UUIDs. |
| Blank-label safety | Implemented | Invalid blank section/field labels block save instead of silently discarding authored content. |
| Completion indicator | Implemented | Deterministic development heuristic. |
| Story/cast search | Implemented | Identity, flexible profile content and relationship context. |
| Destructive character/story actions | Implemented | Confirmed with linked-data impact before removal. |
| Unsaved-change protection | Implemented | Major editors prevent accidental dismissal of pending author work. |

## Character Guide

| Capability | Status | Notes |
| --- | --- | --- |
| Stable prompt catalogue | Implemented | More than 120 stable prompt IDs. |
| Genre/development-aware selection | Implemented | Deterministic scoring, underdeveloped-area weighting and category balancing. |
| Adaptive recorded context | Implemented | Uses role, profile, relationship and life-history signals. |
| Persisted answers | Implemented | Stable prompt IDs preserve saved answers; answers can be reviewed, edited and deliberately deleted. |
| Human-readable selection reasons | Implemented | Advisory UI metadata only; never silently becomes character canon. |
| Deep semantic contradiction checking | Planned | Requires a separately designed reasoning layer. |

## Relationships and family

| Capability | Status | Notes |
| --- | --- | --- |
| Character-to-character graph edges | Implemented | One shared relationship edge with endpoint-relative inverse meaning. |
| Add/edit/delete relationship | Implemented | Existing edges are edited in place; deletion is deliberate. |
| Searchable cast picker | Implemented | Suitable for larger projects. |
| Family tree | Implemented | Derived projection; no second family database. |
| Structural validation | Implemented | Rejects self-links, equivalent duplicates, ancestry cycles and conflicting family generations. |
| Multi-generation navigation | Implemented | Root-centred graph with zoom/recenter behaviour. |
| Broader non-family network view | Planned | Separate future graph-view candidate. |

## History

| Capability | Status | Notes |
| --- | --- | --- |
| Structured life events | Implemented | Title, category, free-text timing, details, impact and deterministic ordering. |
| Edit/reorder/delete | Implemented | Existing events remain stable records and deletion is confirmed. |
| Guide integration | Implemented | Relevant history contributes to adaptive Guide context. |
| Archive round trip | Implemented | Events and ordering are preserved by archive v1. |

## Character Visual Studio

| Capability | Status | Notes |
| --- | --- | --- |
| Dedicated Visual workspace | Implemented | Separate 2D Appearance and 3D Reconstruction modes. |
| Labelled/reorderable references | Implemented | Up to six author-controlled reference images. |
| Appearance notes | Implemented | Debounced persistence with final-save failure surfacing. |
| Image Playground availability handling | Implemented | Core non-visual workflows remain independent. |
| AI-assisted canonical image | Partial | SDK/build path is verified; real output quality still requires supported-device validation. |
| Eight-view 2D turnaround | Implemented | Fixed 45-degree slots with missing/duplicate/progress/recovery handling. |
| RealityKit photogrammetry reconstruction | Implemented | Three or more photographs can produce a temporary rotatable USDZ when supported. Practical reconstruction quality remains a physical-device concern. |
| Persistent/archive-backed 3D model | Candidate | Current USDZ output is temporary presentation state and not archive-v1 data. |
| Scenes/animation/cinematics | Not planned | Outside product scope. |

## Data portability and safety

| Capability | Status | Notes |
| --- | --- | --- |
| Repeated restore with fresh local IDs | Implemented | Archived UUIDs are reconstruction keys, not reused SwiftData identifiers. |
| Structural archive validation | Implemented | Required identity, duplicate IDs, relationship endpoints, family cycles/conflicts and visual payload invariants. |
| Whole-story round trip | Implemented | Profile, Guide, history, relationships and supported visual assets. |
| Failed restore rollback | Implemented | Partial reconstruction is not deliberately left pending. |
| Package-based external archive assets | Candidate | Consider only if real image-heavy projects make JSON impractical. |
| iCloud synchronization | Candidate | Requires explicit migration/conflict design. |

## Automated validation

For current `main`, `iOS Build` provides the release-eligibility proof:

1. complete simulator unit/UI tests;
2. optimized simulator Release compilation;
3. optimized unsigned generic `iphoneos` Release compilation;
4. application-resource/AppIcon validation; and
5. strict Swift concurrency diagnostics.

A release publisher runs only after a successful push-triggered `iOS Build` on a `Release <version>` commit. It verifies that SHA is still exact current `main`, validates version/build metadata, rebuilds the optimized device payload on that SHA and creates a new immutable tag/release. It does **not** claim to rerun simulator tests during publication.

Physical-device Image Playground output quality and RealityKit reconstruction quality remain explicitly outside hosted-CI proof.
