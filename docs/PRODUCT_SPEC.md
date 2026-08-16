<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# Character Profiler Product Specification

**Document status:** Source of truth for product intent  
**Product:** Character Profiler  
**Target platform:** iPhone / iOS  
**Primary audience:** Authors and writers building fictional characters and casts

## 1. Product definition

Character Profiler is a native iPhone story-bible and character-development application for authors. It helps an author define, remember and deepen fictional characters while keeping those characters connected to the story they belong to.

The application combines structured character records with flexible author-defined information, linked relationships, formative history, genre-aware development prompts and a focused visual reference workspace.

The product is centred on a simple question: **who is this character, how are they connected to the rest of the cast, what shaped them, and what do they look like?**

Character Profiler is not intended to write the novel for the author. Its AI-assisted features should help the author think, organise and visualise while leaving character facts and creative decisions under the author's control.

## 2. Core product principles

1. **Author control is primary.** Suggestions are prompts, not imposed canon. The application must not silently overwrite character facts or invent permanent facts without the author's acceptance.
2. **Characters are living records.** A character is more than a fixed form. The record must be expandable as the author discovers new information.
3. **Story context matters.** Character development questions should reflect the selected genre and information already known about the character.
4. **Relationships are data, not notes.** Family and other relationships must link actual character records so the cast can be understood as a network.
5. **History has consequences.** Trauma, loss, achievements and other formative events should be recordable and may influence later development prompts.
6. **Visualisation stays focused.** Visual AI exists to establish and inspect a character's appearance. It must not grow into scene generation, animation, filmmaking or a game engine.
7. **The core app remains useful without AI.** Profiles, relationships, history and the Character Guide must remain usable when visual AI is unavailable.
8. **Local-first is the default.** Character and story data should remain available on the device without requiring a permanent online account or service dependency.

## 3. Story projects

An author creates one or more story projects. Each project groups the cast and provides context for character development.

A project must support:

- title;
- genre;
- optional custom genre text;
- story premise or short description;
- a project-scoped cast of characters;
- searching and navigating characters within that project.

Built-in genres currently include Fantasy, Science Fiction, Romance, Mystery, Thriller, Horror, Historical Fiction, Contemporary, Adventure, Crime and Young Adult, plus a custom genre option.

Genre selection is not merely a label. It is input to the Character Guide so that questions are appropriate to the world and type of story being written.

## 4. Character record

A character belongs to a story project and has a persistent record.

Frequently used character metadata includes:

- name;
- nickname;
- age or age text;
- pronouns;
- role in the story;
- summary;
- profile portrait.

The character record must remain extensible. The author can add arbitrary profile sections and fields rather than being limited to fields compiled into the application.

Default starter areas should cover common author needs such as identity, appearance, personality, motivation, background, fears and flaws, beliefs and values, habits and mannerisms, and secrets. These are starting points, not a closed schema.

## 5. Character Guide

The Character Guide helps an author develop a character by asking useful questions.

The Guide should draw from three sources:

1. general character-development prompts useful in most fiction;
2. genre-specific prompts;
3. adaptive follow-up prompts based on facts already recorded.

Examples for Fantasy include questions about taverns, adventuring, magic, creatures, travel, faith, quests and life outside safe settlements. Other genres must use their own appropriate prompt sets rather than simply rewording Fantasy prompts.

The Guide should consider, where available, the selected story genre, existing profile fields, previous Guide answers, relationships, and life events—especially trauma and loss.

Guide answers are saved as part of the character record. Once a question has been meaningfully answered it should normally stop appearing as an unanswered suggestion.

The Guide may ask follow-up questions but must not autonomously rewrite the character profile. A later feature may offer explicit, author-approved promotion of Guide answers into profile facts, but that is not implicit behaviour.

## 6. Relationships and family

Relationships must link two real character records.

Supported relationship concepts include family relationships and broader social/story relationships such as parent/child, sibling, partner, friend, rival or enemy, mentor/student, colleague or ally, and custom relationship types where appropriate.

Directional relationships must be understandable from either character's point of view. For example, if Character A is recorded as the parent of Character B, Character B must read Character A as a parent while Character A reads Character B as a child.

The current structured relationship model is the foundation for a future graphical family/relationship view. The graphical tree is a planned interface feature; the underlying relationship data already exists.

## 7. Character history

Authors must be able to record formative life events. A life event is more structured than a free-form note and can include an event title, type, when it occurred or the character's age, what happened, and how it affected the character.

Event types may include trauma, loss, milestones, achievements, relationships, conflict, education, career changes, adventures, relocation, secrets and custom events.

The application should treat history as part of character development. For example, a recorded trauma or major loss may cause the Guide to ask how reminders affect the character or which other characters notice the lasting impact.

## 8. Character Visual Studio

The Visual workspace exists to answer **what does this character look like?**

The author can supply a written visual description, facts already stored in the character profile, a profile picture, and multiple selected visual reference images.

The AI-assisted visual workflow should use those inputs to help establish a consistent canonical appearance. The author chooses whether to accept a generated result.

### 8.1 Reference images

The current design supports up to six author-selected reference images. They may represent the face, body shape, hairstyle, clothing, equipment or other appearance cues.

Reference images remain stored with the character so the author can regenerate or refine the visual later.

### 8.2 Canonical appearance

The accepted generated image is the character's canonical visual reference. It may also be used as the profile portrait.

The AI generation request should emphasise a single character, full-body reference presentation and a neutral/unobtrusive background. It should not create a story scene.

### 8.3 360-degree inspection

The current 360-degree design is intentionally simple. It uses eight standard views at 45-degree intervals: front, front-right, right, back-right, back, back-left, left and front-left.

Dragging across the turntable viewer moves through available views to provide a practical character turnaround.

This is **not a true textured 3D mesh** and is not represented as one. A true 3D model would be a separate future decision and must not be introduced merely as feature creep.

## 9. Explicit non-goals

Character Profiler must not drift into the following without a deliberate change to this specification:

- generating scenes from the novel;
- animating characters;
- filmmaking, cinematics or video generation;
- game-engine systems;
- combat mechanics or RPG gameplay;
- large posing or animation studios;
- automatically writing story chapters;
- replacing the author's decisions with AI-generated canon.

The Visual Studio remains a character appearance tool, not a scene creator.

## 10. Persistence and privacy

The current implementation uses SwiftData for local persistence.

The model stores story projects, characters, flexible profile fields, Guide answers, relationships, life events and visual assets. Large image payloads use external binary storage where appropriate.

The system Photos picker should be used for selecting images so the author deliberately supplies the files the app needs.

No private AI service API key should be embedded in the distributed app binary. The current Visual Studio uses Apple's system Image Playground on supported devices. If another provider is added later, credentials and provider access must be designed safely and separately from the core data model.

## 11. Compatibility

The core application currently targets iOS 17 or later.

Visual AI is availability-gated because Image Playground support depends on newer Apple software and compatible hardware. A device that cannot use Visual AI must still be able to use the rest of Character Profiler.

## 12. UX structure

The primary navigation is:

```text
Story Library
└── Story Project
    └── Character
        ├── Profile
        ├── Guide
        ├── People
        ├── History
        └── Visual
```

This structure should remain understandable as features grow. New functionality should normally fit one of these concepts rather than adding unrelated top-level modes.

## 13. Definition of a strong first public release

A release suitable to call 1.0 should, at minimum:

- build and test cleanly in supported Xcode CI;
- reliably create, edit, search and delete story projects and characters;
- preserve flexible profile data across launches;
- correctly maintain relationship direction and inverse meaning;
- provide a usable graphical family/relationship view;
- record and display life history;
- provide useful genre-aware Character Guide questions;
- keep answered prompts and character facts persistent;
- support reference images and focused character visual generation on compatible devices;
- make the limitations of the eight-view turnaround clear;
- preserve core functionality on devices without Visual AI;
- have documented migration behaviour and no known destructive data-loss path.

## 14. Change control

This file is the product-intent source of truth. A future feature that materially changes the product boundary should update this specification before or alongside implementation.

Implementation status belongs in `FEATURE_STATUS.md`. Planned sequencing belongs in `ROADMAP.md`. Technical structure belongs in the root `ARCHITECTURE.md`.
