// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftData

struct ProjectDraft {
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

struct ProfileDraft {
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

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    mutating func addSection() {
        sections.append(
            SectionDraft(
                title: "New Section",
                fields: [FieldDraft(label: "New Field", value: "")]
            )
        )
    }

    func save(
        to character: CharacterProfile?,
        project: StoryProject,
        in modelContext: ModelContext
    ) -> CharacterProfile {
        let target: CharacterProfile
        if let character {
            target = character
            for section in character.sections {
                modelContext.delete(section)
            }
            target.sections.removeAll()
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
        target.updatedAt = .now
        project.updatedAt = .now

        for (sectionIndex, sectionDraft) in sections.enumerated() {
            let trimmedTitle = sectionDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { continue }

            let section = ProfileSection(
                title: trimmedTitle,
                sortOrder: sectionIndex,
                character: target
            )
            modelContext.insert(section)
            target.sections.append(section)

            for (fieldIndex, fieldDraft) in sectionDraft.fields.enumerated() {
                let trimmedLabel = fieldDraft.label.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedLabel.isEmpty else { continue }

                let field = ProfileField(
                    label: trimmedLabel,
                    value: fieldDraft.value.trimmingCharacters(in: .whitespacesAndNewlines),
                    sortOrder: fieldIndex,
                    section: section
                )
                modelContext.insert(field)
                section.fields.append(field)
            }
        }

        return target
    }
}

struct SectionDraft: Identifiable {
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

struct FieldDraft: Identifiable {
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
