<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Contributing

Character Profiler is intentionally focused: it is an author-facing character-development/story-bible application, not a general scene generator, game engine or 3D character modeller. Contributions should preserve that boundary and the local-first data model.

## Before changing code

- Read `docs/PRODUCT_SPEC.md`, `ARCHITECTURE.md` and `docs/FEATURE_STATUS.md`.
- Keep application-specific SwiftUI, SwiftData, archive and character-domain semantics in this repository.
- Do not add a shared-library dependency unless it replaces real duplicated portable behaviour and reduces overall complexity.
- Treat the SwiftData schema and the portable archive format as separate compatibility contracts. A schema change does not automatically justify an archive-format change, and vice versa.
- Do not introduce destructive persistence recovery or silently replace an unreadable local store.

## Development requirements

The project uses Swift 5 language mode and targets iOS 17 or later. CI pins Xcode 16.4, runs complete Swift concurrency diagnostics, executes the simulator test suite, builds an optimized simulator Release and separately compiles an unsigned optimized `iphoneos` Release.

Before proposing a change, run the `CharacterProfiler` scheme tests and a Release build with the same toolchain where practical. Changes to archive parsing, relationships/family invariants, persistence safety, Guide ranking or Visual Studio state should include focused regression tests.

## Pull requests

Keep each pull request scoped to one coherent change. Explain the user-visible effect, persistence/archive compatibility impact, tests added or changed, and any limitation that still requires physical-device validation.

Do not commit personal signing-team identifiers, credentials, generated build products or private story/character data.

## Licence

By contributing, you agree that your contribution is provided under the repository's `GPL-3.0-or-later` licence.
