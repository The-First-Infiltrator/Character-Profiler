<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Feature Status

This document records implementation status against `PRODUCT_SPEC.md`.

Status meanings: **Implemented** is present in code; **Partial** needs validation or completion; **Planned** is committed future work; **Candidate** is not yet committed scope.

## Product foundation

| Capability | Status | Notes |
| --- | --- | --- |
| Native SwiftUI iPhone application | Implemented | Xcode project targeting iPhone. |
| SwiftData local persistence | Implemented | Core entities and visual assets persist locally. |
| Story/project library | Implemented | Projects own a cast and genre/premise context. |
| Built-in/custom genres | Implemented | Genre feeds Character Guide selection. |
| Project overview metrics | Implemented | Cast, relationships, history, Guide answers and average development. |
| Legacy orphan-character migration | Implemented | Older unassigned characters move into one `Imported Characters` project; 0.8 adds idempotency regression coverage. |
| CI build/unit-test gate | Implemented | Hosted Xcode simulator workflow dynamically prepares an available iPhone runtime. |
| Release-quality save/error surfacing | Implemented | 0.8 removes silent save failure from major story, character, Guide, relationship, history and destructive workflows. |

## Character profile and cast workflow

| Capability | Status | Notes |
| --- | --- | --- |
| Core metadata and portrait | Implemented | Name, nickname, age, pronouns, role, summary and portrait. |
| Flexible sections/fields | Implemented | Author-defined profile content. |
| Starter profile template | Implemented | Common character-development areas. |
| Search within story cast | Implemented | Searches profile content; 0.8 also searches linked character names, relationship kinds and notes. |
| Large-cast search guidance/result counts | Implemented | 0.8 improves feedback for larger projects. |
| Completion indicator | Implemented | Heuristic development score. |
| Character deletion impact confirmation | Implemented | Reports linked data and reminds the author about backups. |
| Portrait import failure handling | Implemented | 0.8 surfaces unreadable/unsupported selected images. |

## Character Guide

| Capability | Status | Notes |
| --- | --- | --- |
| Large prompt catalogue | Implemented | More than 120 stable prompts. |
| Genre-specific coverage | Implemented | Expanded sets across built-in genres. |
| Persisted answers/stable prompt IDs | Implemented | Answered prompts remain suppressible across catalogue evolution. |
| Development-depth scoring | Implemented | Uses profile/Guide/relationship/role/history signals. |
| Category balancing | Implemented | Visible suggestions span multiple dimensions. |
| Adaptive context | Implemented | Includes trauma/loss, family, life events and contextual follow-ups. |
| Human-readable selection reasons | Implemented | Shown in the Guide UI without becoming canon. |
| Guide save failure handling | Implemented | 0.8 surfaces persistence errors. |
| Deep semantic contradiction checking | Planned | Requires a separately designed reasoning layer. |
| Promote Guide answer into profile | Candidate | Must remain explicit and author-controlled if added. |

## Relationships and family

| Capability | Status | Notes |
| --- | --- | --- |
| Real character-to-character links | Implemented | Relationships are shared graph edges. |
| Parent/child and mentor/student inverse semantics | Implemented | Correct meaning from either endpoint. |
| Family grouping and notes | Implemented | People view separates family/other links. |
| Edit existing relationship | Implemented | 0.8 edits kind/notes on the existing edge instead of delete/recreate. |
| Inverse-safe relationship editing | Implemented | Editing from the target character stores the correct inverse kind. |
| Searchable relationship cast picker | Implemented | 0.8 supports large casts when adding a link. |
| Relationship deletion confirmation | Implemented | Shared-link/family-tree effect is explained before removal. |
| Graphical family tree | Implemented | Derived root-centred graph; no second family database. |
| Multi-generation traversal/navigation | Implemented | Connected relatives, tappable cards, scroll and zoom. |
| Duplicate/cycle structural validation | Implemented | Duplicate links and ancestry contradictions rejected. |
| Edit-aware family validation | Implemented | 0.8 excludes the edge being edited while validating the proposed replacement state. |
| Relationship backup/restore | Implemented | Archive reconstructs endpoints after characters exist. |
| Broader non-family relationship network | Planned | Separate future graph view candidate. |

## History and trauma

| Capability | Status | Notes |
| --- | --- | --- |
| Structured life events | Implemented | Title, kind, timing, details and impact. |
| Trauma/loss and formative categories | Implemented | Used by adaptive Guide questions. |
| Chronological timeline presentation | Implemented | 0.8 provides a connected ordered timeline-style history view. |
| Edit existing life event | Implemented | 0.8 edits the persisted event in place. |
| Author-controlled event ordering | Implemented | Earlier/later controls handle free-text ages/dates without unsafe parsing assumptions. |
| Life-event deletion confirmation | Implemented | Explains history/Guide effect before removal. |
| Life-history backup/restore | Implemented | Archive v1 includes all life events and ordering. |

## Character Visual Studio

| Capability | Status | Notes |
| --- | --- | --- |
| Dedicated Visual workspace | Implemented | `CharacterVisualWorkspaceView.swift`. |
| Up to six labelled/reorderable references | Implemented | Photos picker, labels, ordering and deletion. |
| Written appearance instructions | Implemented | Stored per character. |
| Runtime Image Playground availability handling | Implemented | Unsupported environments retain non-generation functionality. |
| AI-assisted canonical character image | Partial | Workflow exists; output quality/identity consistency still needs supported physical-device validation. |
| Canonical replacement/portrait lifecycle | Implemented | Accepted canonical visual is explicit. |
| Eight fixed turnaround angles | Implemented | 45-degree slots. |
| Canonical identity source for angles | Implemented | Turnaround generation uses accepted canonical visual. |
| Missing/duplicate/progress state | Implemented | 0.7 hardening. |
| Per-angle recovery and whole reset | Implemented | Existing source material can be retained. |
| Visual asset backup/restore | Implemented | Archive v1 includes all visual data. |
| True 3D mesh | Not planned | Separate future product decision. |
| Scenes/animation/cinematics | Not planned | Outside product scope. |

## Data portability and safety

| Capability | Status | Notes |
| --- | --- | --- |
| Versioned project archive/export | Implemented | JSON archive format v1. |
| Project restore/import | Implemented | Validates/reconstructs complete graph. |
| Fresh local IDs on restore | Implemented | Same backup can be restored more than once. |
| Archive structural validation | Implemented | Unsupported/malformed data rejected. |
| Whole-story round-trip test | Implemented | Profile, Guide, history, relationships and visual assets. |
| Story/character destructive confirmations | Implemented | Impact summaries before deletion. |
| 0.8 persistent-schema change | None | 0.8 reuses existing fields/entities; archive format remains v1. |
| iCloud sync | Candidate | Requires deliberate migration/conflict design. |

## 0.8.0 completion criteria

0.8.0 is complete when:

1. existing life events can be edited and explicitly reordered without delete/recreate;
2. existing relationships can be edited on the same graph edge from either character perspective without corrupting inverse meaning;
3. family structural validation remains active during edits while ignoring the edge's old value;
4. relationship and life-event deletion are deliberate confirmed actions;
5. adding relationships remains usable in large casts through searchable character selection;
6. cast search includes relationship context and gives useful no-result/count feedback;
7. legacy orphan-character migration is deterministic/idempotent under tests;
8. major author save/import interactions surface meaningful failures instead of silently swallowing them;
9. accessibility labels/hints cover the hardened history, relationship, family-tree and cast workflows;
10. regression tests and the complete existing suite pass in Xcode CI;
11. app version/build metadata is 0.8.0 / build 10;
12. README, changelog, architecture, feature status and roadmap match implemented behavior.

After 0.8 integration, the next major target is the **1.0 release-readiness pass**. Physical-device Image Playground quality validation remains a separate outstanding validation item.
