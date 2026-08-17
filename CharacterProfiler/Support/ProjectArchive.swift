// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ProjectArchive: Codable {
    static let currentFormatVersion = 1

    var formatVersion: Int
    var exportedAt: Date
    var project: ArchivedProject

    init(project source: StoryProject, exportedAt: Date = .now) {
        formatVersion = Self.currentFormatVersion
        self.exportedAt = exportedAt

        let projectCharacterIDs = Set(source.characters.map(\.id))
        var relationshipByID: [UUID: CharacterRelationship] = [:]
        for character in source.characters {
            for relationship in character.allRelationships {
                guard let sourceID = relationship.source?.id,
                      let targetID = relationship.target?.id,
                      projectCharacterIDs.contains(sourceID),
                      projectCharacterIDs.contains(targetID) else { continue }
                relationshipByID[relationship.id] = relationship
            }
        }

        project = ArchivedProject(
            sourceID: source.id,
            title: source.title,
            genre: source.genre,
            customGenre: source.customGenre,
            premise: source.premise,
            createdAt: source.createdAt,
            updatedAt: source.updatedAt,
            characters: source.characters
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                .map(ArchivedCharacter.init),
            relationships: relationshipByID.values
                .sorted { $0.id.uuidString < $1.id.uuidString }
                .compactMap(ArchivedRelationship.init)
        )
    }

    func encodedData() throws -> Data {
        try validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> ProjectArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let archive = try decoder.decode(ProjectArchive.self, from: data)
        try archive.validate()
        return archive
    }

    /// Validates every identifier/invariant that is required to reconstruct a coherent story graph.
    /// Validation runs before restore inserts anything into SwiftData.
    func validate() throws {
        guard formatVersion == Self.currentFormatVersion else {
            throw ProjectArchiveError.unsupportedFormatVersion(formatVersion)
        }
        guard !project.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProjectArchiveError.invalidArchive("The story title is missing.")
        }

        let characterIDs = project.characters.map(\.sourceID)
        try requireUnique(characterIDs, description: "character identifiers")
        let characterIDSet = Set(characterIDs)

        for character in project.characters {
            guard !character.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ProjectArchiveError.invalidArchive("One of the archived characters has no name.")
            }

            try requireUnique(character.sections.map(\.sourceID), description: "profile section identifiers for \(character.name)")
            try requireUnique(character.lifeEvents.map(\.sourceID), description: "life-event identifiers for \(character.name)")
            try requireUnique(character.promptResponses.map(\.sourceID), description: "Guide response identifiers for \(character.name)")
            try requireUnique(character.referenceImages.map(\.sourceID), description: "reference-image identifiers for \(character.name)")
            try requireUnique(character.visualFrames.map(\.sourceID), description: "turnaround-frame identifiers for \(character.name)")
            try requireUnique(character.promptResponses.map(\.promptID), description: "Guide prompt identifiers for \(character.name)")
            try requireUnique(character.visualFrames.map(\.angle), description: "turnaround angles for \(character.name)")

            for section in character.sections {
                guard !section.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw ProjectArchiveError.invalidArchive("A profile section for \(character.name) has no title.")
                }
                try requireUnique(section.fields.map(\.sourceID), description: "profile field identifiers in \(section.title)")
                for field in section.fields where field.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw ProjectArchiveError.invalidArchive("A profile field in \(section.title) has no label.")
                }
            }

            for event in character.lifeEvents where event.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ProjectArchiveError.invalidArchive("A life event for \(character.name) has no title.")
            }
            for response in character.promptResponses where response.promptID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ProjectArchiveError.invalidArchive("A Guide response for \(character.name) has no prompt identifier.")
            }
            for reference in character.referenceImages where reference.imageData.isEmpty {
                throw ProjectArchiveError.invalidArchive("A reference image for \(character.name) contains no image data.")
            }
            for frame in character.visualFrames where frame.imageData.isEmpty {
                throw ProjectArchiveError.invalidArchive("A turnaround frame for \(character.name) contains no image data.")
            }
        }

        var relationshipIDs = Set<UUID>()
        for relationship in project.relationships {
            guard relationshipIDs.insert(relationship.sourceID).inserted else {
                throw ProjectArchiveError.invalidArchive("The archive contains duplicate relationship identifiers.")
            }
            guard relationship.sourceCharacterID != relationship.targetCharacterID else {
                throw ProjectArchiveError.invalidArchive("A relationship points from a character back to the same character.")
            }
            guard characterIDSet.contains(relationship.sourceCharacterID),
                  characterIDSet.contains(relationship.targetCharacterID) else {
                throw ProjectArchiveError.invalidArchive("A relationship points to a character that is not present in this story archive.")
            }
        }

        try validateArchivedFamilyGraph()
    }

    private func requireUnique<T: Hashable>(_ values: [T], description: String) throws {
        guard Set(values).count == values.count else {
            throw ProjectArchiveError.invalidArchive("The archive contains duplicate \(description).")
        }
    }

    /// Protects restore from hand-edited/corrupt archives containing direct ancestry loops.
    private func validateArchivedFamilyGraph() throws {
        var parentsByChild: [UUID: Set<UUID>] = [:]
        for relationship in project.relationships {
            switch relationship.kind {
            case .parent:
                parentsByChild[relationship.sourceCharacterID, default: []].insert(relationship.targetCharacterID)
            case .child:
                parentsByChild[relationship.targetCharacterID, default: []].insert(relationship.sourceCharacterID)
            default:
                continue
            }
        }

        func visitsAncestor(_ current: UUID, origin: UUID, visiting: inout Set<UUID>) -> Bool {
            guard visiting.insert(current).inserted else { return current == origin }
            defer { visiting.remove(current) }
            for parent in parentsByChild[current, default: []] {
                if parent == origin { return true }
                if visitsAncestor(parent, origin: origin, visiting: &visiting) { return true }
            }
            return false
        }

        for characterID in project.characters.map(\.sourceID) {
            var visiting = Set<UUID>()
            if visitsAncestor(characterID, origin: characterID, visiting: &visiting) {
                throw ProjectArchiveError.invalidArchive("The archived family graph contains an ancestry cycle.")
            }
        }
    }

    @MainActor
    func restore(in modelContext: ModelContext) throws -> StoryProject {
        try validate()

        // Restore is one unit of work. Callers should invoke it with a committed ModelContext so a
        // rollback can remove every staged object if reconstruction or persistence fails.
        let restoredProject = StoryProject(
            title: project.title,
            genre: project.genre,
            customGenre: project.customGenre,
            premise: project.premise,
            createdAt: project.createdAt,
            updatedAt: .now
        )
        modelContext.insert(restoredProject)

        var characterByArchiveID: [UUID: CharacterProfile] = [:]

        do {
            for archivedCharacter in project.characters {
                let character = CharacterProfile(
                    name: archivedCharacter.name,
                    nickname: archivedCharacter.nickname,
                    summary: archivedCharacter.summary,
                    storyRole: archivedCharacter.storyRole,
                    pronouns: archivedCharacter.pronouns,
                    ageText: archivedCharacter.ageText,
                    profileImageData: archivedCharacter.profileImageData,
                    visualDescription: archivedCharacter.visualDescription,
                    generatedVisualData: archivedCharacter.generatedVisualData,
                    createdAt: archivedCharacter.createdAt,
                    updatedAt: archivedCharacter.updatedAt,
                    project: restoredProject
                )
                modelContext.insert(character)
                restoredProject.characters.append(character)
                characterByArchiveID[archivedCharacter.sourceID] = character

                for archivedSection in archivedCharacter.sections {
                    let section = ProfileSection(
                        title: archivedSection.title,
                        sortOrder: archivedSection.sortOrder,
                        character: character
                    )
                    modelContext.insert(section)
                    character.sections.append(section)

                    for archivedField in archivedSection.fields {
                        let field = ProfileField(
                            label: archivedField.label,
                            value: archivedField.value,
                            sortOrder: archivedField.sortOrder,
                            section: section
                        )
                        modelContext.insert(field)
                        section.fields.append(field)
                    }
                }

                for archivedEvent in archivedCharacter.lifeEvents {
                    let event = LifeEvent(
                        title: archivedEvent.title,
                        kind: archivedEvent.kind,
                        whenText: archivedEvent.whenText,
                        details: archivedEvent.details,
                        impact: archivedEvent.impact,
                        sortOrder: archivedEvent.sortOrder,
                        createdAt: archivedEvent.createdAt,
                        character: character
                    )
                    modelContext.insert(event)
                    character.lifeEvents.append(event)
                }

                for archivedResponse in archivedCharacter.promptResponses {
                    let response = PromptResponse(
                        promptID: archivedResponse.promptID,
                        question: archivedResponse.question,
                        category: archivedResponse.category,
                        answer: archivedResponse.answer,
                        updatedAt: archivedResponse.updatedAt,
                        character: character
                    )
                    modelContext.insert(response)
                    character.promptResponses.append(response)
                }

                for archivedReference in archivedCharacter.referenceImages {
                    let reference = CharacterReferenceImage(
                        label: archivedReference.label,
                        sortOrder: archivedReference.sortOrder,
                        imageData: archivedReference.imageData,
                        createdAt: archivedReference.createdAt,
                        character: character
                    )
                    modelContext.insert(reference)
                    character.referenceImages.append(reference)
                }

                for archivedFrame in archivedCharacter.visualFrames {
                    let frame = CharacterVisualFrame(
                        angle: archivedFrame.angle,
                        imageData: archivedFrame.imageData,
                        generatedAt: archivedFrame.generatedAt,
                        character: character
                    )
                    modelContext.insert(frame)
                    character.visualFrames.append(frame)
                }
            }

            for archivedRelationship in project.relationships {
                guard let source = characterByArchiveID[archivedRelationship.sourceCharacterID],
                      let target = characterByArchiveID[archivedRelationship.targetCharacterID] else {
                    throw ProjectArchiveError.invalidArchive("A relationship could not be rebuilt because one of its characters is missing.")
                }
                let relationship = CharacterRelationship(
                    kind: archivedRelationship.kind,
                    notes: archivedRelationship.notes,
                    createdAt: archivedRelationship.createdAt,
                    source: source,
                    target: target
                )
                modelContext.insert(relationship)
                source.outgoingRelationships.append(relationship)
                target.incomingRelationships.append(relationship)
            }

            try modelContext.saveOrRollback()
            return restoredProject
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    static func suggestedFilename(for project: StoryProject) -> String {
        let parts = project.title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let stem = parts.isEmpty ? "Story" : parts.joined(separator: "-")
        return "\(stem).characterprofiler.json"
    }

    struct ArchivedProject: Codable {
        var sourceID: UUID
        var title: String
        var genre: StoryGenre
        var customGenre: String
        var premise: String
        var createdAt: Date
        var updatedAt: Date
        var characters: [ArchivedCharacter]
        var relationships: [ArchivedRelationship]
    }

    struct ArchivedCharacter: Codable {
        var sourceID: UUID
        var name: String
        var nickname: String
        var summary: String
        var storyRole: String
        var pronouns: String
        var ageText: String
        var profileImageData: Data?
        var visualDescription: String
        var generatedVisualData: Data?
        var createdAt: Date
        var updatedAt: Date
        var sections: [ArchivedSection]
        var lifeEvents: [ArchivedLifeEvent]
        var promptResponses: [ArchivedPromptResponse]
        var referenceImages: [ArchivedReferenceImage]
        var visualFrames: [ArchivedVisualFrame]

        init(_ source: CharacterProfile) {
            sourceID = source.id
            name = source.name
            nickname = source.nickname
            summary = source.summary
            storyRole = source.storyRole
            pronouns = source.pronouns
            ageText = source.ageText
            profileImageData = source.profileImageData
            visualDescription = source.visualDescription
            generatedVisualData = source.generatedVisualData
            createdAt = source.createdAt
            updatedAt = source.updatedAt
            sections = source.sortedSections.map(ArchivedSection.init)
            lifeEvents = source.sortedLifeEvents.map(ArchivedLifeEvent.init)
            promptResponses = source.promptResponses
                .sorted { $0.promptID < $1.promptID }
                .map(ArchivedPromptResponse.init)
            referenceImages = source.sortedReferenceImages.map(ArchivedReferenceImage.init)
            visualFrames = source.sortedVisualFrames.map(ArchivedVisualFrame.init)
        }
    }

    struct ArchivedSection: Codable {
        var sourceID: UUID
        var title: String
        var sortOrder: Int
        var fields: [ArchivedField]

        init(_ source: ProfileSection) {
            sourceID = source.id
            title = source.title
            sortOrder = source.sortOrder
            fields = source.sortedFields.map(ArchivedField.init)
        }
    }

    struct ArchivedField: Codable {
        var sourceID: UUID
        var label: String
        var value: String
        var sortOrder: Int

        init(_ source: ProfileField) {
            sourceID = source.id
            label = source.label
            value = source.value
            sortOrder = source.sortOrder
        }
    }

    struct ArchivedLifeEvent: Codable {
        var sourceID: UUID
        var title: String
        var kind: LifeEventKind
        var whenText: String
        var details: String
        var impact: String
        var sortOrder: Int
        var createdAt: Date

        init(_ source: LifeEvent) {
            sourceID = source.id
            title = source.title
            kind = source.kind
            whenText = source.whenText
            details = source.details
            impact = source.impact
            sortOrder = source.sortOrder
            createdAt = source.createdAt
        }
    }

    struct ArchivedPromptResponse: Codable {
        var sourceID: UUID
        var promptID: String
        var question: String
        var category: PromptCategory
        var answer: String
        var updatedAt: Date

        init(_ source: PromptResponse) {
            sourceID = source.id
            promptID = source.promptID
            question = source.question
            category = source.category
            answer = source.answer
            updatedAt = source.updatedAt
        }
    }

    struct ArchivedReferenceImage: Codable {
        var sourceID: UUID
        var label: String
        var sortOrder: Int
        var imageData: Data
        var createdAt: Date

        init(_ source: CharacterReferenceImage) {
            sourceID = source.id
            label = source.label
            sortOrder = source.sortOrder
            imageData = source.imageData
            createdAt = source.createdAt
        }
    }

    struct ArchivedVisualFrame: Codable {
        var sourceID: UUID
        var angle: VisualAngle
        var imageData: Data
        var generatedAt: Date

        init(_ source: CharacterVisualFrame) {
            sourceID = source.id
            angle = source.angle
            imageData = source.imageData
            generatedAt = source.generatedAt
        }
    }

    struct ArchivedRelationship: Codable {
        var sourceID: UUID
        var kind: RelationshipKind
        var notes: String
        var createdAt: Date
        var sourceCharacterID: UUID
        var targetCharacterID: UUID

        init?(_ source: CharacterRelationship) {
            guard let sourceCharacterID = source.source?.id,
                  let targetCharacterID = source.target?.id else { return nil }
            sourceID = source.id
            kind = source.kind
            notes = source.notes
            createdAt = source.createdAt
            self.sourceCharacterID = sourceCharacterID
            self.targetCharacterID = targetCharacterID
        }
    }
}

enum ProjectArchiveError: LocalizedError {
    case missingFileData
    case unsupportedFormatVersion(Int)
    case invalidArchive(String)

    var errorDescription: String? {
        switch self {
        case .missingFileData:
            "The selected file does not contain a readable Character Profiler archive."
        case .unsupportedFormatVersion(let version):
            "This backup uses Character Profiler archive format \(version), but this version of the app supports format \(ProjectArchive.currentFormatVersion)."
        case .invalidArchive(let message):
            "The Character Profiler backup is invalid. \(message)"
        }
    }
}

struct ProjectArchiveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var archive: ProjectArchive

    init(archive: ProjectArchive) {
        self.archive = archive
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw ProjectArchiveError.missingFileData
        }
        archive = try ProjectArchive.decode(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try archive.encodedData())
    }
}
