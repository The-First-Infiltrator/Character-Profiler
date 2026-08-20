<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Architecture

## Purpose

Character Profiler is an author-facing, local-first story bible. Product intent lives in `docs/PRODUCT_SPEC.md`; implementation status and sequencing live in `docs/FEATURE_STATUS.md` and `docs/ROADMAP.md`.

The application stops at the character boundary. It is not a scene generator, animation/film system, game engine or automatic story writer.

## Core principles

- Author-entered facts are canon; suggestions never silently overwrite them.
- Flexible profile data is preferred to endlessly expanding a rigid schema.
- Relationships are real graph edges between character records.
- Family/relationship diagrams are derived views, never second databases.
- Life history remains author data; the Guide may react to it but does not rewrite it.
- Visual generation is optional and availability-gated.
- The accepted canonical visual is the identity anchor for turnaround generation.
- Portable backups are explicitly versioned application documents, not raw SwiftData stores.
- SwiftData-schema evolution and archive-format evolution are separate compatibility contracts.
- A failed user-visible save must roll the current SwiftData unit of work back instead of leaving dirty mutations for a later save.
- Character-scoped author work updates both the character and owning story activity timestamps.
- Recovery behavior must prefer preserving potentially recoverable author data over silently replacing it.

## Persistent model

```text
StoryProject
└── CharacterProfile[]
    ├── ProfileSection[]
    │   └── ProfileField[]
    ├── LifeEvent[]
    ├── PromptResponse[]
    ├── outgoing/incoming CharacterRelationship[]
    ├── CharacterReferenceImage[]
    ├── generatedVisualData
    └── CharacterVisualFrame[]
```

Versions 0.8, 1.0.0 and 1.0.1 add no SwiftData entity or persistent field. The 1.0.1 app continues to use the model already proven by the 0.8/1.0 line.

## Persistence transaction rule

`PersistenceSafety.swift` defines two cross-cutting invariants.

`ModelContext.saveOrRollback()` saves the current unit of work and calls `rollback()` before rethrowing if persistence fails. This matters because SwiftUI editors mutate the main SwiftData context directly. Without rollback, a failed delete or edit could remain pending and be persisted accidentally by a later unrelated save.

`CharacterProfile.markModified()` updates `CharacterProfile.updatedAt` and the owning `StoryProject.updatedAt`. Story Library sorting uses the project timestamp, so Guide/history/relationship/visual work must count as project activity even when project metadata itself did not change.

## Store creation and startup failure

`CharacterProfilerApp` builds one `ModelContainer` containing the full persistent schema. Container construction is represented as a `Result<ModelContainer, Error>`:

- success injects the real container into `ProjectListView`;
- failure presents `DataStoreUnavailableView`;
- Character Profiler does **not** automatically delete, reset or replace the store;
- the underlying error description is visible/selectable for diagnosis.

This is deliberately conservative. A future guided repair/restore workflow may improve recovery, but silent destructive “fixes” are outside the current design.

## Story and legacy migration

A `StoryProject` owns story metadata and a cast. A `CharacterProfile` normally belongs to exactly one project.

Older pre-project characters may exist with `project == nil`. `LegacyDataMigration.assignUnassignedCharacters` moves those records into one migration bucket named `Imported Characters`, identified by the full metadata tuple used by the migration rather than title alone. This prevents an ordinary author-created story with the same title from being hijacked.

## Flexible profile

`ProfileSection` and `ProfileField` remain generic. Genre- or story-specific character attributes can be added without a persistent-model change.

`ProfileDraft` carries the stable UUID of every existing section and field. Save reconciles draft rows against existing SwiftData rows by UUID, updates surviving rows in place, inserts only genuinely new rows and deletes only rows the author removed. Blank section titles or field labels are rejected before save so authored values are never silently discarded as a side effect of validation.

## Relationship graph

`CharacterRelationship` is one shared edge between two `CharacterProfile` objects. The stored kind is interpreted from `source`; inverse meaning is derived at the opposite endpoint.

Examples:

- stored parent → source sees parent, target sees child;
- stored mentor → source sees mentor, target sees student.

Structural invariants:

- endpoints must be real, distinct characters;
- inverse meaning is represented by one edge, not duplicate inverse records;
- equivalent duplicate family links are rejected;
- parent/child links may not create ancestry cycles;
- a direct ancestor/descendant pair may not also be siblings;
- graphical views are projections of this graph.

`RelationshipEditingRules.storedKind(displayedKind:for:viewedFrom:)` translates a kind selected from the current character's perspective back into the stored source-oriented value. `FamilyRelationshipRules.validationMessage(... excluding:)` omits the edge under edit while evaluating the proposed replacement.

### Family projection

`FamilyGraphSnapshot` walks family relationship kinds from the selected root and assigns relative generations: parent `-1`, child `+1`, sibling/spouse/partner `0`.

The graph uses a safety cap for pathological or extremely large connected families. 1.0.1 records whether traversal hit that cap so the UI can disclose truncation instead of presenting an incomplete projection as complete.

The snapshot is transient. No second family-tree persistence model exists.

## Life history and chronology

`LifeEvent` records title, kind, free-text timing, details, impact and `sortOrder`.

Free-text timing is intentionally not treated as a universal machine-sortable date. Authors may use “Age 12”, “three winters before the war”, fictional calendars or ordinary dates. `LifeEventOrdering` therefore makes chronology explicitly author-controlled through deterministic earlier/later movement and contiguous normalization.

## Character Guide

`CharacterGuide.swift` owns stable prompt content and deterministic selection. `PromptResponse` stores author answers.

`PromptEngine.detailedSuggestions` combines genre relevance, development-depth heuristics, category balancing and adaptive recorded context. `GuideSuggestion.reason` explains selection in the UI but is not persisted as character canon.

Answered prompts are intentionally suppressed from the unanswered suggestion feed. `CharacterGuideView.swift` therefore owns a separate Saved Answers workflow that exposes all persisted answers for editing or deliberate deletion; otherwise suppression would make saved canon effectively read-only.

Stable prompt IDs are compatibility keys and should not be casually renamed. Full arbitrary semantic contradiction detection is not currently claimed.

## Cast search and large projects

`CharacterSearch.matches` centralizes cast search across character identity/role/summary, flexible profile fields, linked character names, relationship kind labels and relationship notes. Adding a relationship uses a searchable cast picker rather than an unbounded flat picker.

## Portable project archive

`ProjectArchive.swift` defines Character Profiler archive format v1 as a `Codable` projection of the author-visible project graph.

Format v1 includes project metadata, characters, flexible sections/fields, life events and ordering, Guide responses, relationship edges, profile/reference images, canonical generated visual and turnaround frames. Archived UUIDs are reconstruction keys only; restore creates fresh local identifiers and uses archived IDs only to rebuild links.

### Validation boundary

Validation runs before restore inserts the destination project. Format v1 rejects unsupported versions, blank required identity data, duplicate IDs across archived entity collections, duplicate Guide prompt IDs per character, duplicate turnaround angles, empty required image payloads, invalid relationship endpoints and ancestry cycles.

Restore is one SwiftData unit of work. Reconstruction calls `saveOrRollback()` and a thrown restore path explicitly rolls the context back so partially rebuilt objects are not deliberately left pending.

Archive v1 currently stores images as `Data` in one human-inspectable JSON document. That is acceptable for the current format contract, but package-based external asset storage remains a future option if image-heavy projects make the JSON representation impractical. Such a change would require explicit archive-format evolution rather than silently changing v1.

## Character Visual Studio

`CharacterVisualWorkspaceView.swift` owns the visual workflow. Persistent data consists of labelled/ordered `CharacterReferenceImage` records, `visualDescription`, `generatedVisualData` for the accepted canonical image and `CharacterVisualFrame` records keyed by `VisualAngle`.

Appearance-note editing is debounced and flushed when necessary instead of synchronously saving on every keystroke. Canonical generation builds its identity/reference board from the existing profile portrait plus author reference images; turnaround generation continues to use the accepted canonical visual as the single identity anchor.

Image Playground support is availability-gated. Core profile, Guide, relationship, history and archive functionality does not depend on visual generation. The turnaround is an image-based inspection sequence, not a true 3D mesh.

Hosted CI can prove SDK integration and compile both simulator and real-device targets. It cannot prove that physical Image Playground output preserves face, proportions, clothing, colours and equipment acceptably across eight generated angles.

## Source organization

`CharacterDetailView.swift` is intentionally kept as the character-workspace shell. Subsystem-heavy implementations are split into:

- `CharacterGuideView.swift`;
- `CharacterRelationshipsView.swift`;
- `CharacterHistoryView.swift`;
- `CharacterVisualWorkspaceView.swift`.

Comments should explain invariants, compatibility decisions and non-obvious safety constraints rather than restating obvious Swift syntax.

## Destructive-action and error safety

Story and character deletion report affected linked data. Relationship, Guide-answer, reference-image and life-event removal are deliberate actions. Major author save/import paths surface relevant failures and use rollback-safe persistence.

Confirmations are not an undo system; portable project backup remains the durable user-controlled recovery mechanism.

## Compatibility and release gate

The core deployment target remains iOS 17. Image Playground functionality is separately availability-gated.

For 1.0.1, GitHub Actions proves three build gates on the exact candidate SHA:

1. complete simulator test suite;
2. optimized simulator Release compilation;
3. optimized generic `iphoneos` Release compilation with signing disabled.

Release publication is separately hardened. `.github/scripts/publish-release.js` is syntax-checked before execution and rejects a requested release target unless the exact SHA is an ancestor of `main` and has a successful exact-SHA `iOS Build` workflow run.

Migration/compatibility history:

- 0.4: family tree derived from existing relationships; no persistent change.
- 0.5: Guide scoring/reasons derived from existing records; no persistent change.
- 0.6: portable archive format v1 added separately from SwiftData schema.
- 0.7: visual hardening reused existing visual records/order metadata.
- 0.8: author-workflow hardening edited/ordered existing records and tested legacy migration; no persistent change.
- 1.0.0: startup/data/archive/release hardening; no persistent change and archive remains v1.
- 1.0.1: audit hardening, transactional rollback, profile ID preservation, workflow completion and release verification; no persistent change and archive remains v1.

Any future schema change capable of invalidating stored records requires deliberate migration design and regression coverage before release. Archive-format evolution requires an independent version/upgrade decision.
