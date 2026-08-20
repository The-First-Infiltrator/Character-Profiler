<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

## What changed

Describe the user-visible and architectural change.

## Compatibility

- [ ] No SwiftData schema change
- [ ] No archive-format change
- [ ] Any compatibility change is explicitly documented and migrated

## Validation

- [ ] Unit tests added/updated where behaviour changed
- [ ] UI/integration coverage added where a user workflow changed
- [ ] Simulator test suite passes
- [ ] Optimized simulator Release builds
- [ ] Optimized unsigned iPhoneOS Release builds
- [ ] Physical-device validation recorded when required

## Safety review

- [ ] Persistence failures cannot leave unintended mutations pending
- [ ] Import/export boundaries remain bounded and validated
- [ ] No credentials, signing-team IDs, private story data or generated build products are committed

## Remaining limitations

List anything CI cannot prove, especially physical-device Image Playground behaviour.
