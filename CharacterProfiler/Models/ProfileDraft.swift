// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftData

struct ProjectDraft: Equatable {
    var title: String = ""
    var genre: StoryGenre = .fantasy
    var customGenre: String = ""
    var premise: String = ""

    init() {}

    init(project: StoryProject) {
        title = project.title
        genre = project.genre
        customGenre = project.customGenre
        premise = project.premise
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(to project: StoryProject?, in modelContext: ModelContext) -> StoryProject {
        let target = project ?? StoryProject(title: title)
        if project == nil { modelContext.insert(target) }

        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.genre = genre
        target.customGenre = customGenre.trimmingCharacters(in: .whitespacesAndNewlines)
        target.premise = premise.trimmingCharacters(in: .whitespacesAndNewlines)
        target.updatedAt = .now
        return target
    }
}

struct ProfileDraft: Equatable {
    var name: String = ""
    var nickname: String = ""
    var summary: String = ""
    var storyRole: String = ""
    var pronouns: String = ""
    var ageText: String = ""
    var profileImageData: Data?
    var sections: [SectionDraft] = ProfileTemplate.defaultSections

    init() {}

    init(character: CharacterProfile) {
        name = character.name
        nickname = character.nickname
        summary = character.summary
        storyRole = character.storyRole
        pronouns = character.pronouns
        ageText = character.ageText
        profileImageData = character.profileImageData
        sections = character.sortedSections.map(SectionDraft.init)
    }

    /// Returns the first author-fixable validation problem instead of silently dropping malformed rows.
    var validationMessage: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "A character name is required."
        }

        for (sectionIndex, section) in sections.enumerated() {
            if section.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Section \(sectionIndex + 1) needs a name or must be removed."
            }
            for (fieldIndex, field) in section.fields.enumerated() {
                if field.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return "Field \(fieldIndex + 1) in \(section.title) needs a name or must be removed."
                }
            }
        }
        return nil
    }

    var isValid: Bool { validationMessage == nil }

    mutating func addSection() {
        sections.append(
            SectionDraft(
                title: "New Section",
                fields: [FieldDraft(label: "New Field", value: "")]
            )
        )
    }

    /// Reconciles the editable draft with existing SwiftData rows by stable UUID.
    ///
    /// Older versions deleted and recreated every profile section and field on each edit. Besides
    /// unnecessary churn, that changed persistent IDs even when the author merely corrected text.
    /// This implementation preserves existing rows, inserts only new rows, and deletes only rows
    /// the author actually removed.
    func save(
        to character: CharacterProfile?,
        project: StoryProject,
        in modelContext: ModelContext
    ) -> CharacterProfile {
        precondition(validationMessage == nil, "ProfileDraft.save called with invalid profile data")

        let target: CharacterProfile
        if let character {
            target = character
        } else {
            target = CharacterProfile(name: name, project: project)
            modelContext.insert(target)
        }

        target.project = project
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        target.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        target.storyRole = storyRole.trimmingCharacters(in: .whitespacesAndNewlines)
        target.pronouns = pronouns.trimmingCharacters(in: .whitespacesAndNewlines)
        target.ageText = ageText.trimmingCharacters(in: .whitespacesAndNewlines)
        target.profileImageData = profileImageData
        target.markModified()

        let existingSections = Dictionary(uniqueKeysWithValues: target.sections.map { ($0.id, $0) })
        var retainedSectionIDs = Set<UUID>()
        var orderedSections: [ProfileSection] = []

        for (sectionIndex, sectionDraft) in sections.enumerated() {
            let trimmedTitle = sectionDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let section: ProfileSection

            if let existing = existingSections[sectionDraft.id] {
                section = existing
            } else {
                section = ProfileSection(
                    id: sectionDraft.id,
                    title: trimmedTitle,
                    sortOrder: sectionIndex,
                    character: target
                )
                modelContext.insert(section)
            }

            retainedSectionIDs.insert(section.id)
            section.title = trimmedTitle
            section.sortOrder = sectionIndex
            section.character = target

            let existingFields = Dictionary(uniqueKeysWithValues: section.fields.map { ($0.id, $0) })
            var retainedFieldIDs = Set<UUID>()
            var orderedFields: [ProfileField] = []

            for (fieldIndex, fieldDraft) in sectionDraft.fields.enumerated() {
                let trimmedLabel = fieldDraft.label.trimmingCharacters(in: .whitespacesAndNewlines)
                let field: ProfileField

                if let existing = existingFields[fieldDraft.id] {
                    field = existing
                } else {
                    field = ProfileField(
                        id: fieldDraft.id,
                        label: trimmedLabel,
                        value: fieldDraft.value.trimmingCharacters(in: .whitespacesAndNewlines),
                        sortOrder: fieldIndex,
                        section: section
                    )
                    modelContext.insert(field)
                }

                retainedFieldIDs.insert(field.id)
                field.label = trimmedLabel
                field.value = fieldDraft.value.trimmingCharacters(in: .whitespacesAndNewlines)
                field.sortOrder = fieldIndex
                field.section = section
                orderedFields.append(field)
            }

            for field in section.fields where !retainedFieldIDs.contains(field.id) {
                modelContext.delete(field)
            }
            section.fields = orderedFields
            orderedSections.append(section)
        }

        for section in target.sections where !retainedSectionIDs.contains(section.id) {
            modelContext.delete(section)
        }
        target.sections = orderedSections

        return target
    }
}

struct SectionDraft: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var fields: [FieldDraft]

    init(id: UUID = UUID(), title: String, fields: [FieldDraft] = []) {
        self.id = id
        self.title = title
        self.fields = fields
    }

    init(section: ProfileSection) {
        id = section.id
        title = section.title
        fields = section.sortedFields.map(FieldDraft.init)
    }
}

struct FieldDraft: Identifiable, Equatable {
    var id = UUID()
    var label: String
    var value: String

    init(id: UUID = UUID(), label: String, value: String) {
        self.id = id
        self.label = label
        self.value = value
    }

    init(field: ProfileField) {
        id = field.id
        label = field.label
        value = field.value
    }
}
