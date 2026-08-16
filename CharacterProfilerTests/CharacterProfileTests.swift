// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest
import SwiftData
@testable import CharacterProfiler

final class CharacterProfileTests: XCTestCase {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            StoryProject.self,
            CharacterProfile.self,
            ProfileSection.self,
            ProfileField.self,
            LifeEvent.self,
            PromptResponse.self,
            CharacterReferenceImage.self,
            CharacterVisualFrame.self,
            CharacterRelationship.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    func testDraftCreatesCharacterInsideStoryWithFlexibleSections() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = StoryProject(title: "The Brass Moon", genre: .fantasy)
        context.insert(project)
        var draft = ProfileDraft()
        draft.name = "Ada"
        draft.nickname = "The Analyst"
        draft.storyRole = "Reluctant cartographer"
        draft.sections = [SectionDraft(title: "Custom", fields: [FieldDraft(label: "Favourite Machine", value: "Difference Engine")])]
        let character = draft.save(to: nil, project: project, in: context)
        try context.save()
        XCTAssertEqual(character.name, "Ada")
        XCTAssertEqual(character.nickname, "The Analyst")
        XCTAssertEqual(character.project?.title, "The Brass Moon")
        XCTAssertEqual(character.sections.count, 1)
        XCTAssertEqual(character.sections.first?.fields.first?.label, "Favourite Machine")
    }

    @MainActor func testNameIsRequired() throws { XCTAssertFalse(ProfileDraft().isValid) }

    @MainActor
    func testFantasyGuideContainsGenreSpecificQuestion() throws {
        let project = StoryProject(title: "Quest", genre: .fantasy)
        let character = CharacterProfile(name: "Elena", project: project)
        let prompts = PromptEngine.suggestions(for: character, in: project, limit: 100)
        XCTAssertTrue(prompts.contains { $0.id == "fantasy.tavern" })
        XCTAssertFalse(prompts.contains { $0.id == "scifi.ai" })
    }

    @MainActor
    func testAnsweredPromptIsRemovedFromSuggestions() throws {
        let project = StoryProject(title: "Quest", genre: .fantasy)
        let character = CharacterProfile(name: "Elena", project: project)
        let response = PromptResponse(promptID: "fantasy.tavern", question: "Question", category: .lifestyle, answer: "She would rather explore outside the walls.", character: character)
        character.promptResponses.append(response)
        let prompts = PromptEngine.suggestions(for: character, in: project, limit: 100)
        XCTAssertFalse(prompts.contains { $0.id == "fantasy.tavern" })
    }

    @MainActor
    func testRelationshipReadsFromBothDirections() throws {
        let parent = CharacterProfile(name: "Mara")
        let child = CharacterProfile(name: "Jon")
        let relationship = CharacterRelationship(kind: .parent, source: parent, target: child)
        XCTAssertEqual(relationship.kind(from: parent), .parent)
        XCTAssertEqual(relationship.kind(from: child), .child)
        XCTAssertEqual(relationship.relatedCharacter(to: parent)?.name, "Jon")
        XCTAssertEqual(relationship.relatedCharacter(to: child)?.name, "Mara")
    }

    func testVisualAnglesCoverFullTurnaround() {
        XCTAssertEqual(VisualAngle.allCases.count, 8)
        XCTAssertEqual(VisualAngle.front.degrees, 0)
        XCTAssertEqual(VisualAngle.back.degrees, 180)
        XCTAssertEqual(VisualAngle.frontLeft.degrees, 315)
    }
}
