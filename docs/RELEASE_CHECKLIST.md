<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler 1.0 Release Checklist

This checklist is the release-readiness gate for the first stable Character Profiler source release. It does not turn untested assumptions into release claims.

## Automated release gates

- [ ] Exact final 1.0 candidate passes the complete iOS simulator unit-test suite.
- [ ] Exact final 1.0 candidate compiles successfully in the Xcode Release configuration with code signing disabled.
- [ ] After integration, the exact `main` merge commit passes the same GitHub Actions workflow.
- [x] Hosted CI dynamically discovers or provisions an iPhone simulator rather than assuming one fixed device exists.

## Persistence and data safety

- [x] Whole-project archive round trip preserves project metadata, character profiles, arbitrary sections/fields, Guide answers, history, relationships and visual assets.
- [x] The same archive can be restored more than once with fresh local SwiftData identifiers.
- [x] Unsupported future archive format versions are rejected.
- [x] Missing story/character identity is rejected before restore.
- [x] Duplicate archived character identifiers are rejected.
- [x] Duplicate archived relationship identifiers are rejected.
- [x] Self-referential relationship endpoints are rejected.
- [x] Relationship endpoints missing from the archived cast are rejected.
- [x] Invalid archives are rejected before a destination project is inserted.
- [x] Legacy orphan-character migration is idempotent under regression tests.
- [x] Story, character, relationship and life-event destructive actions require deliberate confirmation.
- [x] Major author-facing persistence/import failures are surfaced instead of silently swallowed.
- [x] Failure to open the local SwiftData store no longer terminates through `fatalError`; the app presents a non-destructive recovery screen and does not automatically replace the store.
- [x] Portable archive format remains explicitly versioned and separate from the SwiftData schema.

## Character and author workflow

- [x] Story and character creation/editing are implemented.
- [x] Flexible profile sections and arbitrary fields remain supported.
- [x] Cast search covers profile information plus relationship names, kinds and notes.
- [x] Large-cast relationship selection is searchable.
- [x] Relationship direction and parent/child plus mentor/student inverse semantics are regression-tested.
- [x] Family graph duplicate/cycle invariants are regression-tested, including relationship editing.
- [x] Existing life events are editable and explicitly orderable.
- [x] Genre-aware Character Guide suggestions preserve stable prompt IDs and saved answers.
- [x] Guide reasons remain advisory metadata rather than being silently copied into canon.

## Accessibility and failure-state review

- [x] Major cast, relationship, history, project metrics and family-tree controls have explicit accessibility labels/hints where icon-only or contextual controls would otherwise be ambiguous.
- [x] Empty story, cast, search, Guide, relationship, history and Visual states provide explanatory copy rather than blank screens.
- [x] Unsupported Image Playground environments retain the non-AI core application.
- [x] Store-open failure produces a readable recovery state instead of a startup crash.

## Packaging and documentation

- [x] Source files and project documentation identify `GPL-3.0-or-later` through SPDX headers/notices.
- [x] Repository includes the complete GNU General Public License version 3 text.
- [x] App metadata is 1.0.0 build 11.
- [x] README, changelog, architecture, feature-status audit and roadmap describe the final 1.0 state accurately.
- [x] 1.0 release notes identify known validation boundaries rather than claiming unsupported behavior.
- [ ] A GitHub tag/release is created only after explicit release authorization and after the final `main` gate is green.

## Physical-device Visual Studio validation

The following cannot be proven by simulator CI and must remain explicitly visible until tested on a supported physical iPhone:

- [ ] Image Playground generation launches and completes in the real device environment.
- [ ] Device-specific Image Playground availability/user flow behaves as expected.
- [ ] The canonical generated character is acceptably consistent with the author's inputs.
- [ ] Eight generated turnaround angles preserve face, body proportions, clothing, colours and equipment well enough to be useful as one character reference set.

These physical-device items do not invalidate the local-first profile, Guide, relationship, history or backup workflows. They do prevent the project from claiming that generated-image quality has been physically validated when it has not.

## Release discipline

A 1.0 merge and a 1.0 GitHub release are separate actions. Passing this checklist can make the branch ready to integrate; publishing a tag/release still requires explicit authorization.
