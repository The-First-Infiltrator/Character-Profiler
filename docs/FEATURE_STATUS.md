<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Feature Status

This document records implementation and validation status against `PRODUCT_SPEC.md`.

Status meanings: **Implemented** is present in code and covered by the stated validation; **Partial** exists but still has an explicit validation/completion gap; **Planned** is committed future work; **Candidate** is not committed scope.

## Product foundation

| Capability | Status | Notes |
| --- | --- | --- |
| Native SwiftUI iPhone application | Implemented | iOS 17+ core target with application asset catalogue/AppIcon definition. |
| SwiftData local persistence | Implemented | Projects, characters, profiles, Guide, history, relationships and visual assets. |
| Transactional save failure handling | Implemented | 1.0.1 uses save-or-rollback semantics so failed edits/deletes do not remain pending for later accidental persistence. |
| Story/project library | Implemented | Projects own cast plus genre/premise context. |
| Project activity ordering | Implemented | Character-scoped work propagates `updatedAt` to the owning story. |
| Built-in/custom genres | Implemented | Genre feeds Character Guide selection. |
| Project overview metrics | Implemented | Cast, relationships, history, Guide answers and average development. |
| Legacy orphan-character migration | Implemented | Idempotent migration into one `Imported Characters` project with regression coverage. |
| Startup store-open failure handling | Implemented | Non-destructive recovery screen; the local store is not automatically erased/replaced. |
| CI simulator test gate | Implemented | Hosted Xcode workflow dynamically prepares a simulator and runs the complete unit-test suite. |
| CI optimized simulator Release gate | Implemented | Release configuration compiles with signing disabled. |
| CI optimized iPhoneOS Release gate | Implemented | 1.0.1 separately compiles a generic real-device iOS target with signing disabled. |
| Release target verification | Implemented | Publisher requires exact target SHA on `main` plus a successful exact-SHA `iOS Build`. |

## Character profile and cast workflow

| Capability | Status | Notes |
| --- | --- | --- |
| Core metadata and portrait | Implemented | Name, nickname, age, pronouns, role, summary; portrait can be chosen, replaced or removed. |
| Flexible sections/fields | Implemented | Arbitrary author-defined profile content. |
| Stable profile row identifiers | Implemented | 1.0.1 reconciles edits by section/field UUID instead of recreating every row. |
| Blank profile-label safety | Implemented | Blank section/field labels block save with an author-fixable validation message instead of silently discarding data. |
| Starter profile template | Implemented | Common development areas. |
| Search within story cast | Implemented | Profile content plus linked character names, relationship kinds and notes. |
| Completion indicator | Implemented | Heuristic development score. |
| Character deletion impact confirmation | Implemented | Reports linked data before removal. |
| Portrait import failure handling | Implemented | Unreadable/unsupported selected images are reported. |

## Character Guide

| Capability | Status | Notes |
| --- | --- | --- |
| Large stable prompt catalogue | Implemented | More than 120 stable prompt IDs. |
| Genre-specific coverage | Implemented | Expanded sets across built-in genres. |
| Persisted answers / answered suppression | Implemented | Stable prompt IDs preserve saved answer behavior. |
| Saved answer management | Implemented | 1.0.1 adds view-all, edit and deliberate delete flows for persisted answers. |
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
| Add/edit/delete relationship | Implemented | Existing edges are edited in place; deletion is confirmed. |
| Inverse-safe editing | Implemented | Editing from the target endpoint stores the correct inverse. |
| Searchable cast picker | Implemented | Suitable for larger casts. |
| Graphical family tree | Implemented | Derived from relationship data; no second family database. |
| Multi-generation traversal/navigation | Implemented | Tappable members, scroll and zoom. |
| Large-family traversal limit disclosure | Implemented | 1.0.1 reports when the safety cap truncates a graph instead of silently presenting an incomplete tree as complete. |
| Duplicate/cycle validation | Implemented | Self-links, duplicate family links and ancestry contradictions are rejected. |
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
| Written appearance instructions | Implemented | Stored per character; 1.0.1 debounces persistence instead of saving on every keystroke. |
| Runtime Image Playground availability handling | Implemented | Unsupported environments retain core/non-generation functionality. |
| AI-assisted canonical character image | Partial | Workflow compiles for simulator/device targets; real output quality/identity consistency still needs supported physical-device validation. |
| Canonical identity inputs | Implemented | Canonical generation can use the existing portrait together with author reference imagery; angles use the accepted canonical image. |
| Canonical replacement/portrait lifecycle | Implemented | Accepted canonical image is explicit and can become the portrait. |
| Eight fixed turnaround angles | Implemented | 45° slots. |
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
| Required/duplicate identifier validation | Implemented | 1.0.1 extends structural checks beyond top-level character/relationship IDs into nested archived records. |
| Relationship endpoint validation | Implemented | Self/missing endpoints are rejected before restore. |
| Restore cleanup failure handling | Implemented | Cleanup is no longer intentionally swallowed with `try?`; rollback protects the context if cleanup persistence also fails. |
| Story/character destructive confirmations | Implemented | Impact summaries before deletion. |
| SwiftData schema change in 1.0.1 | None | 1.0.1 reuses the 0.8/1.0 model. |
| Archive-format change in 1.0.1 | None | Format remains v1. |
| Package-based external archive assets | Candidate | Consider if large image-heavy JSON archives become a practical memory/performance problem. |
| iCloud sync | Candidate | Requires deliberate migration/conflict design. |

## 1.0.1 validation status

The 1.0.1 audit branch is ready to integrate only when the exact final head passes:

1. complete simulator unit tests;
2. optimized simulator Release compilation;
3. optimized unsigned `iphoneos` Release compilation;
4. documentation/source-scope audit showing no accidental SwiftData/archive-format change;
5. PR review with the exact head SHA fixed for merge approval.

After merge, the exact `main` commit must pass the same workflow before a stable 1.0.1 tag/release is requested. Physical-device Image Playground quality remains a separately disclosed validation boundary.
