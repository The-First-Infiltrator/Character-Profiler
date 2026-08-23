<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler 1.1 Release Checklist

This checklist records the release-quality gates for the current stable line. It separates automated proof from physical-device Image Playground validation.

## Automated release gates

Version 1.1.0 build 16 is the current release-candidate line. A candidate is publishable only when the exact current `main` commit passes the complete simulator tests, optimized simulator Release build and optimized unsigned generic `iphoneos` Release build, and that same commit is deliberately named `Release <version>`. Project/icon packaging changes also run the compiled app-icon pixel-integrity gate.

- [ ] Exact final 1.1.0 candidate passes the complete iOS simulator unit and UI-test suite.
- [ ] Exact final 1.1.0 candidate compiles successfully as an optimized simulator Release with code signing disabled.
- [ ] Exact final 1.1.0 candidate compiles successfully as an optimized generic `iphoneos` Release with code signing disabled.
- [ ] Exact final 1.1.0 candidate passes compiled app-icon integrity validation.
- [ ] The exact `Release <version>` commit on `main` passes the complete publication build/test gate.
- [x] Hosted CI dynamically discovers or provisions an iPhone simulator rather than assuming one fixed device exists.
- [x] XCUITest end-to-end coverage launches the Story Library, creates a story, opens it, creates a character, and verifies the saved character appears.
- [x] CI preflights the AppIcon file, manifest entry, 1024×1024 dimensions and opaque alpha state before Xcode builds.
- [x] Third-party GitHub Actions are pinned to immutable commit SHAs.
- [x] Stale CI for the same `main` ref is cancelled by concurrency grouping.
- [x] Green CI builds package the optimized unsigned device app into an IPA artifact and emit a SHA-256 checksum.
- [x] Release publication accepts only the exact tested current `main` commit whose subject begins `Release <version>`.
- [x] Release publication independently reruns the complete simulator tests plus optimized simulator and iPhoneOS Release builds before creating a new immutable GitHub Release.
- [x] Existing version tags and GitHub Releases are hard failures and are never moved, edited, deleted or replaced.
- [x] Stable versions publish as normal releases; versions with a `-suffix` such as `1.1.0-rc.1` publish as prereleases automatically.
- [x] Published releases attach `CharacterProfiler-<version>-unsigned.ipa` and its SHA-256 checksum as the exact asset set.

## Persistence and data safety

- [x] Save failures roll the SwiftData context back to the last committed state.
- [x] Rollback behavior has a forced-failure regression test rather than relying only on successful persistence tests.
- [x] Whole-project archive round trip preserves project metadata, character profiles, arbitrary sections/fields, Guide answers, history, relationships and visual assets.
- [x] The same archive can be restored more than once with fresh local SwiftData identifiers.
- [x] Unsupported future archive format versions are rejected.
- [x] Missing story/character identity is rejected before restore.
- [x] Duplicate identifiers and invalid relationship endpoints are rejected before restore.
- [x] Semantic duplicate relationships and multiple family links for the same character pair are rejected before restore.
- [x] Corrupt archives with ancestry cycles or conflicting family-generation paths are rejected before restore.
- [x] Restore cleanup does not intentionally swallow a second SwiftData save failure.
- [x] Legacy orphan-character migration remains idempotent under regression tests.
- [x] Story, character, relationship and life-event destructive actions require deliberate confirmation.
- [x] Major author-facing persistence/import failures are surfaced rather than silently swallowed.
- [x] Failure to open the local SwiftData store produces a non-destructive recovery state with a retry action rather than `fatalError`.
- [x] Portable archive format remains explicitly versioned and separate from the SwiftData schema.

## Character and author workflow

- [x] Story and character creation/editing are implemented.
- [x] Character edits update the owning story's recency timestamp.
- [x] Flexible profile sections and arbitrary fields remain supported.
- [x] Existing section/field identifiers are preserved across normal profile edits.
- [x] Blank section/field labels block save instead of causing silent data loss.
- [x] Portraits can be selected, replaced and removed.
- [x] Cast search covers profile information plus relationship names, kinds and notes.
- [x] Large-cast relationship selection is searchable.
- [x] Relationship direction and inverse parent/child plus mentor/student semantics are preserved.
- [x] Relationship perspective helpers reject unrelated characters instead of silently treating them as the target endpoint.
- [x] Family graph validation prevents self/duplicate/ancestry contradictions, removes the old arbitrary traversal cap and detects conflicting generation paths.
- [x] Existing life events are editable and explicitly orderable.
- [x] Genre-aware Character Guide suggestions preserve stable prompt IDs.
- [x] Saved Guide answers can be viewed, edited and deliberately deleted.
- [x] Guide reasons remain advisory metadata rather than being silently copied into canon.

## Visual Studio

- [x] Reference images remain author-controlled and reorderable.
- [x] Appearance-note persistence is debounced rather than writing on every keystroke.
- [x] A failed final Appearance Notes flush is surfaced through an ancestor that remains visible after leaving Visual Studio.
- [x] Canonical generation can use the character's existing portrait together with reference imagery.
- [x] Turnaround generation continues to use the accepted canonical image as its identity anchor.
- [x] Existing visual assets remain manageable when Image Playground is unavailable.

## Packaging and documentation

- [x] Source/project documentation identifies `GPL-3.0-or-later` through SPDX headers/notices.
- [x] Repository includes the complete GNU General Public License version 3 text.
- [x] App metadata is 1.1.0 build 16 in Debug and Release configurations.
- [x] Application asset catalogue includes a real opaque 1024×1024 AppIcon and is part of the app target resources.
- [x] README, architecture, feature-status audit and roadmap describe the 1.1.0 interface scope and unchanged data/archive contracts.
- [x] Changelog records 1.0.2, 1.0.3 and 1.1.0 plus the remaining physical-device validation boundary.
- [ ] A GitHub `v1.1.0-rc.1` release and its IPA/checksum exist only after the exact publication gate above succeeds.

## Physical-device Visual Studio validation

The following cannot be proven by hosted simulator/device compilation and remain explicit until tested on a supported physical iPhone:

- [ ] Image Playground generation launches and completes in the real device environment.
- [ ] Device-specific Image Playground availability/user flow behaves as expected.
- [ ] The canonical generated character is acceptably consistent with the author's inputs.
- [ ] Eight generated turnaround angles preserve face, body proportions, clothing, colours and equipment well enough to be useful as one character reference set.

These items do not invalidate the local-first profile, Guide, relationship, history or backup workflows. They prevent the project from claiming that generated-image quality has been physically validated when it has not.
