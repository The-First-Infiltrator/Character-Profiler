<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Security Policy

Character Profiler is a local-first iPhone application. Security reports are especially important when they involve backup parsing, local data integrity, file handling, unexpected disclosure of story/character data, or a path that could cause destructive persistence behaviour.

## Supported versions

Security fixes are applied to the current supported release line. Older development snapshots and superseded prerelease builds are not maintained separately.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting/security-advisory flow for this repository when it is available. Include the affected version or commit, the minimum steps needed to reproduce the problem, the expected and actual behaviour, and any relevant crash/error output.

If private vulnerability reporting is unavailable, open a repository issue that requests a private contact path but does **not** include exploit details, private story data, credentials, tokens or other sensitive material.

Please do not publish a working exploit or sensitive reproduction data before a fix has had a reasonable opportunity to be prepared and released.

## Scope notes

Character Profiler does not operate a hosted account service or application backend. Reports about third-party Apple platform services should identify the Character Profiler-specific boundary or misuse involved. Physical-device Image Playground output quality or normal generative variation is a product-quality concern rather than a security vulnerability unless it exposes data or crosses an application security boundary.
