<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Feature Status

This document records implementation and validation status against `PRODUCT_SPEC.md`.

Status meanings: **Implemented** is present in code and covered by the stated validation; **Partial** exists but still has an explicit validation/completion gap; **Planned** is committed future work; **Candidate** is not committed scope.

## Product foundation

| Capability | Status | Notes |
| --- | --- | --- |
| Native SwiftUI iPhone application | Implemented | iOS 17+ core target. |
| SwiftData local persistence | Implemented | Projects, characters, profiles, Guide, history, relationships and visual assets. |
| Story/project library | Implemented | Projects own cast plus genre/premise context. |
| Built-in/custom genres | Implemented | Genre feeds Character Guide selection. |
| Project overview metrics | Implemented | Cast, relationships, history, Guide answers and average development. |
| Legacy orphan-character migration | Implemented | Idempotent migration into one `Imported Characters` project with regression coverage. |
| Startup store-open failure handling | Implemented | 1.0 replaces startup `fatalError` with a non-destructive recovery screen and does not automatically replace the local store. |
| CI test gate | Implemented | Hosted Xcode workflow dynamically prepares a simulator and runs the complete test suite. |
| CI Release-configuration gate | Implemented | 1.0 additionally compiles the optimized Release configuration with signing disabled. |
| Release-quality error surfacing | Implemented | Major story/character/Guide/history/relationship/import/destructive flows surface relevant failures. |

## Character profile and cast workflow

| Capability | Status | Notes |
| --- | --- | --- |
| Core metadata and portrait | Implemented | Name, nickname, age, pronouns, role, summary and portrait. |
| Flexible sections/fields | Implemented | Arbitrary author-defined profile content. |
| Starter profile template | Implemented | Common development areas. |
| Search within story cast | Implemented | Profile content plus linked character names, relationship kinds and notes. |
| Large-cast guidance/result counts | Implemented | Search feedback and searchable relationship cast picker. |
| Completion indicator | Implemented | Heuristic development score. |
| Character deletion impact confirmation | Implemented | Reports linked data before removal. |
| Portrait import failure handling | Implemented | Unreadable/unsupported selected images are reported. |

## Character Guide

| Capability | Status | Notes |
| --- | --- | --- |
| Large stable prompt catalogue | Implemented | More than 120 stable prompt IDs. |
| Genre-specific coverage | Implemented | Expanded sets across built-in genres. |
| Persisted answers / answered suppression | Implemented | Stable prompt IDs preserve saved answer behavior. |
| Development-depth scoring | Implemented | Uses profile, Guide, relationship, role and history signals. |
| Category balancing | Implemented | Suggestions span several dimensions before repetition. |
| Adaptive context | Implemented | Includes trauma/loss, family, life events and contextual follow-ups. |
| Human-readable selection reasons | Implemented | Displayed without becoming character canon. |
| Deep semantic contradiction checking | Planned | Requires a separately designed reasoning layer. |
| Promote Guide answer into profile | Candidate | Must remain explicit and author-controlled if added. |

## Relationships and family

| Capability | Status | Notes |
| --- | --- | --- |
| Real character-to-character links | Implemented | Shared `CharacterRelationship` graph edges. |
| Parent/child and mentor/student inverse semantics | Implemented | Correct meaning from either endpoint. |
| Family grouping and relationship notes | Implemented | People workspace. |
| Add/edit/delete relationship | Implemented | Existing edges are edited in place; deletion is confirmed. |
| Inverse-safe editing | Implemented | Editing from the target endpoint stores the correct inverse. |
| Searchable cast picker | Implemented | Suitable for larger casts. |
| Graphical family tree | Implemented | Derived from relationship data; no second family database. |
| Multi-generation traversal/navigation | Implemented | Tappable members, scroll and zoom. |
| Duplicate/cycle validation | Implemented | Self-links, duplicate family links and ancestry contradictions are rejected. |
| Edit-aware validation | Implemented | The edge under edit is excluded while validating its proposed replacement state. |
| Relationship backup/restore | Implemented | Archive reconstructs direction/endpoints after characters exist. |
| Broader non-family relationship network | Planned | Separate future graph-view candidate. |

## History and trauma

| Capability | Status | Notes |
| --- | --- | --- |
| Structured life events | Implemented | Title, kind, free-text timing, details and impact. |
| Trauma/loss and formative categories | Implemented | Feed adaptive Guide suggestions. |
| Timeline presentation | Implemented | Connected ordered History view. |
| Edit existing life event | Implemented | Persisted event is edited in place. |
| Author-controlled ordering | Implemented | Earlier/later controls avoid unsafe parsing of arbitrary time text. |
| Life-event deletion confirmation | Implemented | Effect on history/Guide context is explained. |
| Life-history backup/restore | Implemented | Archive v1 preserves events and ordering. |

## Character Visual Studio

| Capability | Status | Notes |
| --- | --- | --- |
| Dedicated Visual workspace | Implemented | `CharacterVisualWorkspaceView.swift`. |
| Up to six labelled/reorderable references | Implemented | Photos picker, labels, ordering and deletion. |
| Written appearance instructions | Implemented | Stored per character. |
| Runtime Image Playground availability handling | Implemented | Unsupported environments retain core/non-generation functionality. |
| AI-assisted canonical character image | Partial | Workflow compiles and state is tested; real output quality/identity consistency still needs supported physical-device validation. |
| Canonical replacement/portrait lifecycle | Implemented | Accepted canonical image is explicit and can become the portrait. |
| Eight fixed turnaround angles | Implemented | 45° slots. |
| Canonical identity source for angles | Implemented | Turnaround generation uses accepted canonical visual. |
| Missing/duplicate/progress state | Implemented | Fixed slots remain visible even when missing. |
| Per-angle recovery and whole reset | Implemented | Source references/notes can be retained. |
| Visual asset backup/restore | Implemented | Archive v1 includes current visual data. |
| True 3D mesh | Not planned | Separate future product decision. |
| Scenes/animation/cinematics | Not planned | Explicitly outside scope. |

## Data portability and safety

| Capability | Status | Notes |
| --- | --- | --- |
| Versioned project archive/export | Implemented | JSON archive format v1. |
| Project restore/import | Implemented | Validates and reconstructs complete project graph. |
| Fresh local IDs on restore | Implemented | Same backup can be restored repeatedly without identifier collision. |
| Whole-story round-trip test | Implemented | Profile, Guide, history, relationships and visual assets; restores twice. |
| Future archive-version rejection | Implemented | Unsupported format versions fail explicitly. |
| Missing project/character identity rejection | Implemented | 1.0 negative validation coverage. |
| Duplicate archived character-ID rejection | Implemented | 1.0 negative validation coverage. |
| Duplicate archived relationship-ID rejection | Implemented | 1.0 negative validation coverage. |
| Self/missing relationship endpoint rejection | Implemented | 1.0 tests also verify invalid restore inserts no destination story. |
| Story/character destructive confirmations | Implemented | Impact summaries before deletion. |
| SwiftData schema change in 1.0 | None | 1.0 reuses the 0.8 model. |
| Archive-format change in 1.0 | None | Format remains v1. |
| iCloud sync | Candidate | Requires deliberate migration/conflict design. |

## 1.0 release-readiness status

The 1.0 candidate is considered ready to integrate when:

1. the exact final candidate passes the complete simulator test suite;
2. the same exact candidate compiles the Release configuration;
3. local-store startup failure is non-destructive rather than a fatal crash;
4. archive round-trip and hostile/malformed archive cases are regression-tested;
5. migration behavior remains documented/tested and 1.0 adds no accidental persistence-format change;
6. major destructive actions and author-facing save/import failures are deliberate and visible;
7. the repository includes complete licensing and release documentation;
8. app metadata is 1.0.0 build 11;
9. README, changelog, architecture, roadmap and release checklist match the implementation;
10. the physical-device Visual Studio validation gap remains explicitly disclosed rather than being inferred from simulator success.

After merge, the exact `main` commit must pass the same CI workflow before a stable GitHub release should be considered. Tagging/publishing is a separate explicitly authorized action.
