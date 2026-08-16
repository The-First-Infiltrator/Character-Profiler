// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftData

enum StoryGenre: String, CaseIterable, Identifiable, Codable {
    case fantasy
    case scienceFiction
    case romance
    case mystery
    case thriller
    case horror
    case historical
    case contemporary
    case adventure
    case crime
    case youngAdult
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fantasy: "Fantasy"
        case .scienceFiction: "Science Fiction"
        case .romance: "Romance"
        case .mystery: "Mystery"
        case .thriller: "Thriller"
        case .horror: "Horror"
        case .historical: "Historical Fiction"
        case .contemporary: "Contemporary"
        case .adventure: "Adventure"
        case .crime: "Crime"
        case .youngAdult: "Young Adult"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .fantasy: "wand.and.stars"
        case .scienceFiction: "sparkles.rectangle.stack"
        case .romance: "heart"
        case .mystery: "magnifyingglass"
        case .thriller: "bolt"
        case .horror: "moon.stars"
        case .historical: "building.columns"
        case .contemporary: "building.2"
        case .adventure: "map"
        case .crime: "shield.lefthalf.filled"
        case .youngAdult: "book"
        case .other: "square.grid.2x2"
        }
    }
}

enum RelationshipKind: String, CaseIterable, Identifiable, Codable {
    case parent
    case child
    case sibling
    case spouse
    case partner
    case friend
    case rival
    case mentor
    case student
    case colleague
    case enemy
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .parent: "Parent"
        case .child: "Child"
        case .sibling: "Sibling"
        case .spouse: "Spouse"
        case .partner: "Partner"
        case .friend: "Friend"
        case .rival: "Rival"
        case .mentor: "Mentor"
        case .student: "Student"
        case .colleague: "Colleague"
        case .enemy: "Enemy"
        case .other: "Other"
        }
    }

    var inverse: RelationshipKind {
        switch self {
        case .parent: .child
        case .child: .parent
        case .mentor: .student
        case .student: .mentor
        default: self
        }
    }

    var isFamily: Bool {
        switch self {
        case .parent, .child, .sibling, .spouse, .partner: true
        default: false
        }
    }
}

enum LifeEventKind: String, CaseIterable, Identifiable, Codable {
    case trauma
    case loss
    case milestone
    case achievement
    case relationship
    case conflict
    case education
    case career
    case adventure
    case relocation
    case secret
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .trauma: "Trauma"
        case .loss: "Loss"
        case .milestone: "Milestone"
        case .achievement: "Achievement"
        case .relationship: "Relationship"
        case .conflict: "Conflict"
        case .education: "Education"
        case .career: "Career"
        case .adventure: "Adventure"
        case .relocation: "Relocation"
        case .secret: "Secret"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .trauma: "heart.slash"
        case .loss: "cloud.rain"
        case .milestone: "flag.checkered"
        case .achievement: "trophy"
        case .relationship: "person.2"
        case .conflict: "bolt"
        case .education: "graduationcap"
        case .career: "briefcase"
        case .adventure: "map"
        case .relocation: "mappin.and.ellipse"
        case .secret: "lock"
        case .other: "circle"
        }
    }
}

enum PromptCategory: String, CaseIterable, Identifiable, Codable {
    case identity
    case appearance
    case personality
    case background
    case relationships
    case motivation
    case conflict
    case world
    case lifestyle
    case trauma
    case storyRole
    case secrets

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .identity: "Identity"
        case .appearance: "Appearance"
        case .personality: "Personality"
        case .background: "Background"
        case .relationships: "Relationships"
        case .motivation: "Motivation"
        case .conflict: "Conflict"
        case .world: "World"
        case .lifestyle: "Lifestyle"
        case .trauma: "Past & Trauma"
        case .storyRole: "Story Role"
        case .secrets: "Secrets"
        }
    }

    var icon: String {
        switch self {
        case .identity: "person.text.rectangle"
        case .appearance: "eye"
        case .personality: "brain.head.profile"
        case .background: "clock.arrow.circlepath"
        case .relationships: "person.2"
        case .motivation: "target"
        case .conflict: "bolt"
        case .world: "globe"
        case .lifestyle: "cup.and.saucer"
        case .trauma: "heart.slash"
        case .storyRole: "book.pages"
        case .secrets: "lock"
        }
    }
}

enum VisualAngle: String, CaseIterable, Identifiable, Codable {
    case front
    case frontRight
    case right
    case backRight
    case back
    case backLeft
    case left
    case frontLeft

    var id: String { rawValue }

    var degrees: Int {
        switch self {
        case .front: 0
        case .frontRight: 45
        case .right: 90
        case .backRight: 135
        case .back: 180
        case .backLeft: 225
        case .left: 270
        case .frontLeft: 315
        }
    }

    var displayName: String {
        switch self {
        case .front: "Front"
        case .frontRight: "Front Right"
        case .right: "Right Side"
        case .backRight: "Back Right"
        case .back: "Back"
        case .backLeft: "Back Left"
        case .left: "Left Side"
        case .frontLeft: "Front Left"
        }
    }

    var generationInstruction: String {
        "Show exactly the same character in a neutral full-body \(displayName.lowercased()) view at \(degrees) degrees. Keep identity, face, body proportions, hair, clothing, colours and equipment consistent. Plain unobtrusive background. This is a character turnaround reference, not a scene."
    }
}

@Model
final class StoryProject {
    @Attribute(.unique) var id: UUID
    var title: String
    var genreRaw: String
    var customGenre: String
    var premise: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CharacterProfile.project)
    var characters: [CharacterProfile]

    init(
        id: UUID = UUID(),
        title: String,
        genre: StoryGenre = .fantasy,
        customGenre: String = "",
        premise: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        characters: [CharacterProfile] = []
    ) {
        self.id = id
        self.title = title
        self.genreRaw = genre.rawValue
        self.customGenre = customGenre
        self.premise = premise
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.characters = characters
    }

    var genre: StoryGenre {
        get { StoryGenre(rawValue: genreRaw) ?? .other }
        set { genreRaw = newValue.rawValue }
    }

    var genreDisplayName: String {
        if genre == .other {
            let trimmed = customGenre.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? genre.displayName : trimmed
        }
        return genre.displayName
    }

    var sortedCharacters: [CharacterProfile] {
        characters.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

@Model
final class CharacterProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var nickname: String
    var summary: String
    var storyRole: String = ""
    var pronouns: String = ""
    var ageText: String = ""
    @Attribute(.externalStorage) var profileImageData: Data? = nil
    var visualDescription: String = ""
    @Attribute(.externalStorage) var generatedVisualData: Data? = nil
    var createdAt: Date
    var updatedAt: Date
    var project: StoryProject? = nil

    @Relationship(deleteRule: .cascade, inverse: \ProfileSection.character)
    var sections: [ProfileSection]

    @Relationship(deleteRule: .cascade, inverse: \LifeEvent.character)
    var lifeEvents: [LifeEvent] = []

    @Relationship(deleteRule: .cascade, inverse: \PromptResponse.character)
    var promptResponses: [PromptResponse] = []

    @Relationship(deleteRule: .cascade, inverse: \CharacterReferenceImage.character)
    var referenceImages: [CharacterReferenceImage] = []

    @Relationship(deleteRule: .cascade, inverse: \CharacterVisualFrame.character)
    var visualFrames: [CharacterVisualFrame] = []

    @Relationship(deleteRule: .cascade, inverse: \CharacterRelationship.source)
    var outgoingRelationships: [CharacterRelationship] = []

    @Relationship(deleteRule: .cascade, inverse: \CharacterRelationship.target)
    var incomingRelationships: [CharacterRelationship] = []

    init(
        id: UUID = UUID(),
        name: String,
        nickname: String = "",
        summary: String = "",
        storyRole: String = "",
        pronouns: String = "",
        ageText: String = "",
        profileImageData: Data? = nil,
        visualDescription: String = "",
        generatedVisualData: Data? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        project: StoryProject? = nil,
        sections: [ProfileSection] = [],
        lifeEvents: [LifeEvent] = [],
        promptResponses: [PromptResponse] = [],
        referenceImages: [CharacterReferenceImage] = [],
        visualFrames: [CharacterVisualFrame] = [],
        outgoingRelationships: [CharacterRelationship] = [],
        incomingRelationships: [CharacterRelationship] = []
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.summary = summary
        self.storyRole = storyRole
        self.pronouns = pronouns
        self.ageText = ageText
        self.profileImageData = profileImageData
        self.visualDescription = visualDescription
        self.generatedVisualData = generatedVisualData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.project = project
        self.sections = sections
        self.lifeEvents = lifeEvents
        self.promptResponses = promptResponses
        self.referenceImages = referenceImages
        self.visualFrames = visualFrames
        self.outgoingRelationships = outgoingRelationships
        self.incomingRelationships = incomingRelationships
    }

    var displayName: String {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedNickname.isEmpty ? name : "\(name) “\(trimmedNickname)”"
    }

    var sortedSections: [ProfileSection] {
        sections.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    var sortedLifeEvents: [LifeEvent] {
        lifeEvents.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.createdAt < $1.createdAt
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    var sortedReferenceImages: [CharacterReferenceImage] {
        referenceImages.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedVisualFrames: [CharacterVisualFrame] {
        visualFrames.sorted { $0.angle.degrees < $1.angle.degrees }
    }

    var allRelationships: [CharacterRelationship] {
        (outgoingRelationships + incomingRelationships).sorted {
            $0.relatedCharacter(to: self)?.name ?? "" < $1.relatedCharacter(to: self)?.name ?? ""
        }
    }

    var filledFieldCount: Int {
        sections.flatMap(\.fields).filter {
            !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
    }

    var completionScore: Double {
        var achieved = 0.0
        let total = 8.0
        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { achieved += 1 }
        if !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { achieved += 1 }
        if !storyRole.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { achieved += 1 }
        if profileImageData != nil { achieved += 1 }
        if filledFieldCount >= 5 { achieved += 1 }
        if !lifeEvents.isEmpty { achieved += 1 }
        if !allRelationships.isEmpty { achieved += 1 }
        if promptResponses.contains(where: { !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { achieved += 1 }
        return min(achieved / total, 1)
    }

    func response(for promptID: String) -> PromptResponse? {
        promptResponses.first { $0.promptID == promptID }
    }
}

@Model
final class CharacterReferenceImage {
    @Attribute(.unique) var id: UUID
    var label: String
    var sortOrder: Int
    @Attribute(.externalStorage) var imageData: Data
    var createdAt: Date
    var character: CharacterProfile?

    init(
        id: UUID = UUID(),
        label: String = "Reference",
        sortOrder: Int = 0,
        imageData: Data,
        createdAt: Date = .now,
        character: CharacterProfile? = nil
    ) {
        self.id = id
        self.label = label
        self.sortOrder = sortOrder
        self.imageData = imageData
        self.createdAt = createdAt
        self.character = character
    }
}

@Model
final class CharacterVisualFrame {
    @Attribute(.unique) var id: UUID
    var angleRaw: String
    @Attribute(.externalStorage) var imageData: Data
    var generatedAt: Date
    var character: CharacterProfile?

    init(
        id: UUID = UUID(),
        angle: VisualAngle,
        imageData: Data,
        generatedAt: Date = .now,
        character: CharacterProfile? = nil
    ) {
        self.id = id
        self.angleRaw = angle.rawValue
        self.imageData = imageData
        self.generatedAt = generatedAt
        self.character = character
    }

    var angle: VisualAngle {
        get { VisualAngle(rawValue: angleRaw) ?? .front }
        set { angleRaw = newValue.rawValue }
    }
}

@Model
final class LifeEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var kindRaw: String
    var whenText: String
    var details: String
    var impact: String
    var sortOrder: Int
    var createdAt: Date
    var character: CharacterProfile?

    init(
        id: UUID = UUID(),
        title: String,
        kind: LifeEventKind = .milestone,
        whenText: String = "",
        details: String = "",
        impact: String = "",
        sortOrder: Int = 0,
        createdAt: Date = .now,
        character: CharacterProfile? = nil
    ) {
        self.id = id
        self.title = title
        self.kindRaw = kind.rawValue
        self.whenText = whenText
        self.details = details
        self.impact = impact
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.character = character
    }

    var kind: LifeEventKind {
        get { LifeEventKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class PromptResponse {
    @Attribute(.unique) var id: UUID
    var promptID: String
    var question: String
    var categoryRaw: String
    var answer: String
    var updatedAt: Date
    var character: CharacterProfile?

    init(
        id: UUID = UUID(),
        promptID: String,
        question: String,
        category: PromptCategory,
        answer: String = "",
        updatedAt: Date = .now,
        character: CharacterProfile? = nil
    ) {
        self.id = id
        self.promptID = promptID
        self.question = question
        self.categoryRaw = category.rawValue
        self.answer = answer
        self.updatedAt = updatedAt
        self.character = character
    }

    var category: PromptCategory {
        get { PromptCategory(rawValue: categoryRaw) ?? .background }
        set { categoryRaw = newValue.rawValue }
    }
}

@Model
final class CharacterRelationship {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var notes: String
    var createdAt: Date
    var source: CharacterProfile?
    var target: CharacterProfile?

    init(
        id: UUID = UUID(),
        kind: RelationshipKind,
        notes: String = "",
        createdAt: Date = .now,
        source: CharacterProfile? = nil,
        target: CharacterProfile? = nil
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.source = source
        self.target = target
    }

    var kind: RelationshipKind {
        get { RelationshipKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    func relatedCharacter(to character: CharacterProfile) -> CharacterProfile? {
        if source?.id == character.id { return target }
        if target?.id == character.id { return source }
        return nil
    }

    func kind(from character: CharacterProfile) -> RelationshipKind {
        source?.id == character.id ? kind : kind.inverse
    }
}
