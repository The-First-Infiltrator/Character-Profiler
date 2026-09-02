<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler 1.1.2 Release Checklist

This checklist records the stable-line release gates without duplicating implementation detail from `ARCHITECTURE.md` or feature history from `CHANGELOG.md`.

**Current stable metadata:** 1.1.2 build 18, iOS 17+, SwiftData schema unchanged from the 1.0/1.1 line, archive format v1.

## Automated release gates

- [x] Exact release SHA passed the complete iOS simulator unit/UI test suite.
- [x] Exact release SHA compiled as an optimized simulator Release with signing disabled.
- [x] Exact release SHA compiled as an optimized generic `iphoneos` Release with signing disabled.
- [x] Strict Swift concurrency diagnostics were enabled.
- [x] AppIcon source/manifest/dimensions/alpha were validated before packaging.
- [x] Third-party GitHub Actions are pinned to immutable commit SHAs.
- [x] CI dynamically discovers or provisions an available iPhone simulator.
- [x] Green CI packages the unsigned device application as an IPA and emits SHA-256.
- [x] Publication accepts only a successful push-triggered `iOS Build` for exact current `main` whose subject begins `Release <version>`.
- [x] Publication validates Xcode marketing/build metadata and independently rebuilds the optimized unsigned device payload on that same tested SHA.
- [x] Publication does not falsely claim to rerun simulator tests; those belong to the triggering `iOS Build` proof.
- [x] Existing version tags/releases are hard failures and are never moved, edited, deleted or replaced.
- [x] Published asset set is exactly the versioned unsigned IPA plus checksum.

## Persistence and archive safety

- [x] Save failure rolls the SwiftData context back to its last committed state.
- [x] Whole-project archive round trip covers profile, Guide, history, relationships and supported visual assets.
- [x] Repeated restore creates fresh local SwiftData identifiers.
- [x] Unsupported archive versions, missing identity, duplicate identifiers and invalid relationship endpoints are rejected.
- [x] Family ancestry cycles/conflicting generations are rejected before restore.
- [x] Resource limits bound encoded archive size, collection counts, text and visual payloads.
- [x] Store-open failure presents a non-destructive retry state rather than erasing/replacing data.
- [x] Story/character/relationship/history destructive actions require deliberate confirmation.

## Author workflow

- [x] Story and character creation/editing are implemented.
- [x] Major editors protect unsaved work from accidental dismissal.
- [x] Character-scoped work updates story activity ordering.
- [x] Flexible profile row identifiers survive normal edits.
- [x] Blank profile labels block save instead of silently losing data.
- [x] Relationship direction/inverse semantics and structural family validation are covered.
- [x] Life events are editable and explicitly orderable.
- [x] Saved Guide answers are reviewable, editable and deliberately deletable.

## Visual Studio

- [x] Author reference images are labelled/reorderable and appearance-note persistence is debounced.
- [x] 2D turnaround generation uses the accepted canonical image as its identity anchor.
- [x] Existing visual assets remain manageable when Image Playground is unavailable.
- [x] 3D reconstruction requires a bounded minimum source set, can be cancelled and surfaces failure explicitly.
- [x] Temporary USDZ output is not misrepresented as persistent/archive-backed character data.

## Documentation and packaging

- [x] README, architecture, feature status, roadmap and changelog agree on version 1.1.1/build 17 and archive-v1 compatibility.
- [x] Repository carries the complete GPLv3 licence plus `GPL-3.0-or-later` SPDX notices.
- [x] Release v1.1.1 exists with the unsigned IPA and checksum.

## Physical-device validation boundary

These remain real-device quality checks rather than hosted-CI claims:

- [ ] Image Playground generation completes in the supported physical-device environment.
- [ ] Canonical output is acceptably consistent with the author's identity/appearance inputs.
- [ ] Eight generated 2D turnaround views preserve identity and clothing/equipment well enough to function as one reference set.
- [ ] RealityKit photogrammetry produces useful geometry from representative real multi-angle photograph sets.

These open quality checks do not invalidate the local-first profile, Guide, relationship, history or backup workflows.
