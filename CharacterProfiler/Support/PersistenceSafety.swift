// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftData
import SwiftUI

enum PersistenceSafety {
    /// Executes a persistence commit and guarantees rollback before the error escapes.
    ///
    /// Keeping the transaction primitive injectable lets tests force the failure path without
    /// depending on a particular SQLite/SwiftData failure mode.
    static func commit(save: () throws -> Void, rollback: () -> Void) throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}

/// Hard limits for the portable JSON backup boundary.
///
/// These are intentionally generous for normal author work while still placing a deterministic
/// ceiling on allocations, collection traversal and embedded image payloads from hand-edited or
/// hostile archives. The policy is native Swift: it follows Infiltratr Common's bounded/checked
/// design philosophy without introducing a C dependency into the iOS application.
enum ArchiveResourcePolicy {
    static let maximumEncodedArchiveBytes = 128 * 1024 * 1024
    static let maximumCharacters = 1_000
    static let maximumRelationships = 25_000
    static let maximumSectionsPerCharacter = 128
    static let maximumFieldsPerSection = 256
    static let maximumLifeEventsPerCharacter = 5_000
    static let maximumPromptResponsesPerCharacter = 5_000
    static let maximumReferenceImagesPerCharacter = 6
    static let maximumVisualFramesPerCharacter = 8
    static let maximumTextBytes = 1 * 1024 * 1024
    static let maximumImageBytes = 48 * 1024 * 1024
    static let maximumTotalImageBytes = 96 * 1024 * 1024

    static func validateEncodedByteCount(_ byteCount: Int) throws {
        guard byteCount >= 0, byteCount <= maximumEncodedArchiveBytes else {
            throw ProjectArchiveError.invalidArchive(
                "The backup is too large. Character Profiler accepts backups up to \(maximumEncodedArchiveBytes / 1024 / 1024) MiB."
            )
        }
    }

    static func validateImageByteCount(_ byteCount: Int, description: String = "image") throws {
        guard byteCount >= 0, byteCount <= maximumImageBytes else {
            throw ProjectArchiveError.invalidArchive(
                "An archived \(description) exceeds the \(maximumImageBytes / 1024 / 1024) MiB per-image limit."
            )
        }
    }

    static func checkedAdding(_ value: Int, to total: inout Int, description: String) throws {
        guard value >= 0 else {
            throw ProjectArchiveError.invalidArchive("The archive contains an invalid negative \(description) size.")
        }
        let (next, overflow) = total.addingReportingOverflow(value)
        guard !overflow else {
            throw ProjectArchiveError.invalidArchive("The archive's \(description) size overflowed its safety budget.")
        }
        total = next
    }

    static func validate(_ archive: ProjectArchive) throws {
        try validateCount(archive.project.characters.count, maximum: maximumCharacters, description: "characters")
        try validateCount(archive.project.relationships.count, maximum: maximumRelationships, description: "relationships")

        try validateText(archive.project.title, description: "story title")
        try validateText(archive.project.customGenre, description: "custom genre")
        try validateText(archive.project.premise, description: "story premise")

        var totalImageBytes = 0
        for character in archive.project.characters {
            try validateCount(character.sections.count, maximum: maximumSectionsPerCharacter, description: "profile sections for \(character.name)")
            try validateCount(character.lifeEvents.count, maximum: maximumLifeEventsPerCharacter, description: "life events for \(character.name)")
            try validateCount(character.promptResponses.count, maximum: maximumPromptResponsesPerCharacter, description: "Guide responses for \(character.name)")
            try validateCount(character.referenceImages.count, maximum: maximumReferenceImagesPerCharacter, description: "reference images for \(character.name)")
            try validateCount(character.visualFrames.count, maximum: maximumVisualFramesPerCharacter, description: "turnaround frames for \(character.name)")

            try validateText(character.name, description: "character name")
            try validateText(character.nickname, description: "character nickname")
            try validateText(character.summary, description: "character summary")
            try validateText(character.storyRole, description: "story role")
            try validateText(character.pronouns, description: "pronouns")
            try validateText(character.ageText, description: "age")
            try validateText(character.visualDescription, description: "appearance notes")

            if let data = character.profileImageData {
                try addImage(data, description: "profile image", total: &totalImageBytes)
            }
            if let data = character.generatedVisualData {
                try addImage(data, description: "canonical image", total: &totalImageBytes)
            }

            for section in character.sections {
                try validateCount(section.fields.count, maximum: maximumFieldsPerSection, description: "profile fields in \(section.title)")
                try validateText(section.title, description: "profile section title")
                for field in section.fields {
                    try validateText(field.label, description: "profile field label")
                    try validateText(field.value, description: "profile field value")
                }
            }

            for event in character.lifeEvents {
                try validateText(event.title, description: "life-event title")
                try validateText(event.whenText, description: "life-event date/age")
                try validateText(event.details, description: "life-event details")
                try validateText(event.impact, description: "life-event impact")
            }

            for response in character.promptResponses {
                try validateText(response.promptID, description: "Guide prompt identifier")
                try validateText(response.question, description: "Guide question")
                try validateText(response.answer, description: "Guide answer")
            }

            for reference in character.referenceImages {
                try validateText(reference.label, description: "reference-image label")
                try addImage(reference.imageData, description: "reference image", total: &totalImageBytes)
            }
            for frame in character.visualFrames {
                try addImage(frame.imageData, description: "turnaround frame", total: &totalImageBytes)
            }
        }

        for relationship in archive.project.relationships {
            try validateText(relationship.notes, description: "relationship notes")
        }
    }

    private static func validateCount(_ count: Int, maximum: Int, description: String) throws {
        guard count <= maximum else {
            throw ProjectArchiveError.invalidArchive(
                "The backup contains too many \(description) (maximum \(maximum))."
            )
        }
    }

    private static func validateText(_ value: String, description: String) throws {
        guard value.utf8.count <= maximumTextBytes else {
            throw ProjectArchiveError.invalidArchive(
                "An archived \(description) exceeds the \(maximumTextBytes / 1024 / 1024) MiB text limit."
            )
        }
    }

    private static func addImage(_ data: Data, description: String, total: inout Int) throws {
        try validateImageByteCount(data.count, description: description)
        try checkedAdding(data.count, to: &total, description: "visual data")
        guard total <= maximumTotalImageBytes else {
            throw ProjectArchiveError.invalidArchive(
                "The backup contains more than \(maximumTotalImageBytes / 1024 / 1024) MiB of visual data."
            )
        }
    }
}

extension ProjectArchive {
    /// Encodes only after structural/resource validation, then checks the actual JSON size as the
    /// final boundary. Archive format remains v1; these are acceptance limits, not schema changes.
    func safelyEncodedData() throws -> Data {
        try ArchiveResourcePolicy.validate(self)
        let data = try encodedData()
        try ArchiveResourcePolicy.validateEncodedByteCount(data.count)
        return data
    }

    /// Decodes a bounded in-memory archive. Resource limits are checked before the more expensive
    /// semantic graph validation so pathological collection counts do not reach graph traversal.
    static func safelyDecode(_ data: Data) throws -> ProjectArchive {
        try ArchiveResourcePolicy.validateEncodedByteCount(data.count)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let archive = try decoder.decode(ProjectArchive.self, from: data)
        try ArchiveResourcePolicy.validate(archive)
        try archive.validate()
        return archive
    }

    /// Preflights the file size before mapping it, then performs the same post-read check to guard
    /// against a file changing between metadata inspection and the read.
    static func safelyDecode(contentsOf url: URL) throws -> ProjectArchive {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resourceValues.fileSize {
            try ArchiveResourcePolicy.validateEncodedByteCount(fileSize)
        }
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        return try safelyDecode(data)
    }
}

private struct PersistenceFailureReporterKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

extension EnvironmentValues {
    /// Reports a persistence failure to an ancestor that remains on screen even when the editing
    /// workspace causing the save is being dismissed or replaced by another section.
    var reportPersistenceFailure: (String) -> Void {
        get { self[PersistenceFailureReporterKey.self] }
        set { self[PersistenceFailureReporterKey.self] = newValue }
    }
}

extension ModelContext {
    /// Persists the current unit of work or restores the context to its last committed state.
    ///
    /// Character Profiler performs user-visible edits directly in the main SwiftData context.
    /// A failed save must therefore never leave an insert, delete, or edit pending for a later
    /// unrelated save to commit accidentally.
    func saveOrRollback() throws {
        try PersistenceSafety.commit(
            save: { try save() },
            rollback: { rollback() }
        )
    }
}

extension CharacterProfile {
    /// Marks character-scoped author work as recently changed and propagates activity to the story.
    /// Story Library ordering is based on `StoryProject.updatedAt`, so child-record edits must touch
    /// both timestamps to keep the most recently worked-on project at the top of the library.
    func markModified(at date: Date = .now) {
        updatedAt = date
        project?.updatedAt = date
    }
}
