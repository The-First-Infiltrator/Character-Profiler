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
    private func link(_ source: CharacterProfile, to target: CharacterProfile, as kind: RelationshipKind) -> CharacterRelationship {
        let relationship = CharacterRelationship(kind: kind, source: source, target: target)
        source.outgoingRelationships.append(relationship)
        target.incomingRelationships.append(relationship)
        return relationship
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
        let prompts = PromptEngine.suggestions(for: character, in: project, limit: 200)
        XCTAssertTrue(prompts.contains { $0.id == "fantasy.tavern" })
        XCTAssertFalse(prompts.contains { $0.id == "scifi.ai" })
    }

    @MainActor
    func testAnsweredPromptIsRemovedFromSuggestions() throws {
        let project = StoryProject(title: "Quest", genre: .fantasy)
        let character = CharacterProfile(name: "Elena", project: project)
        let response = PromptResponse(promptID: "fantasy.tavern", question: "Question", category: .lifestyle, answer: "She would rather explore outside the walls.", character: character)
        character.promptResponses.append(response)
        let prompts = PromptEngine.suggestions(for: character, in: project, limit: 200)
        XCTAssertFalse(prompts.contains { $0.id == "fantasy.tavern" })
    }

    @MainActor
    func testGuideCatalogueIsSubstantiallyExpandedAndIDsAreUnique() {
        let ids = PromptEngine.catalogue.map(\.id)
        XCTAssertGreaterThanOrEqual(ids.count, 120)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    @MainActor
    func testGuideBalancesCategoriesInsteadOfRepeatingOneTheme() {
        let project = StoryProject(title: "Quest", genre: .fantasy)
        let character = CharacterProfile(name: "Elena", project: project)
        let suggestions = PromptEngine.detailedSuggestions(for: character, in: project, limit: 8)
        XCTAssertEqual(suggestions.count, 8)
        XCTAssertGreaterThanOrEqual(Set(suggestions.map(\.category)).count, 5)
        XCTAssertTrue(suggestions.allSatisfy { !$0.reason.isEmpty })
    }

    @MainActor
    func testGuideExplainsAdaptiveTraumaSuggestion() {
        let project = StoryProject(title: "Ashes", genre: .fantasy)
        let character = CharacterProfile(name: "Elena", project: project)
        character.lifeEvents.append(LifeEvent(title: "Lost her father", kind: .loss, details: "Killed during the war", character: character))
        let suggestions = PromptEngine.detailedSuggestions(for: character, in: project, limit: 12)
        let traumaSuggestion = suggestions.first { $0.id == "adaptive.after-trauma" }
        XCTAssertNotNil(traumaSuggestion)
        XCTAssertTrue(traumaSuggestion?.reason.lowercased().contains("trauma") == true || traumaSuggestion?.reason.lowercased().contains("loss") == true)
    }

    @MainActor
    func testGuideUsesRecordedCombatContextForFollowUp() {
        let project = StoryProject(title: "Ashes", genre: .fantasy)
        let character = CharacterProfile(name: "Elena", summary: "A former mercenary who survived a brutal war.", project: project)
        let suggestions = PromptEngine.detailedSuggestions(for: character, in: project, limit: 20)
        XCTAssertTrue(suggestions.contains { $0.id == "adaptive.after-battle" })
        XCTAssertTrue(suggestions.contains { $0.id == "adaptive.violence-line" })
    }

    @MainActor
    func testDevelopmentDepthRecognisesProfileDetail() {
        let character = CharacterProfile(name: "Elena")
        let appearance = ProfileSection(title: "Appearance", sortOrder: 0, character: character)
        let hair = ProfileField(label: "Hair", value: "Black, shoulder-length", sortOrder: 0, section: appearance)
        appearance.fields.append(hair)
        character.sections.append(appearance)
        let depth = PromptEngine.developmentDepths(for: character)
        XCTAssertGreaterThan(depth[.appearance, default: 0], 0)
    }

    @MainActor
    func testRelationshipReadsFromBothDirections() throws {
        let character = CharacterProfile(name: "Jon")
        let parent = CharacterProfile(name: "Mara")
        let relationship = CharacterRelationship(kind: .parent, source: character, target: parent)
        XCTAssertEqual(relationship.kind(from: character), .parent)
        XCTAssertEqual(relationship.kind(from: parent), .child)
        XCTAssertEqual(relationship.relatedCharacter(to: character)?.name, "Mara")
        XCTAssertEqual(relationship.relatedCharacter(to: parent)?.name, "Jon")
    }

    @MainActor
    func testFamilyGraphPlacesGenerationsFromExistingRelationships() {
        let root = CharacterProfile(name: "Elena")
        let parent = CharacterProfile(name: "Mara")
        let grandparent = CharacterProfile(name: "Iris")
        let sibling = CharacterProfile(name: "Tomas")
        let partner = CharacterProfile(name: "Ari")
        let child = CharacterProfile(name: "Nia")

        _ = link(root, to: parent, as: .parent)
        _ = link(parent, to: grandparent, as: .parent)
        _ = link(root, to: sibling, as: .sibling)
        _ = link(root, to: partner, as: .partner)
        _ = link(root, to: child, as: .child)

        let graph = FamilyGraphSnapshot(root: root)
        XCTAssertEqual(graph.generation(of: grandparent), -2)
        XCTAssertEqual(graph.generation(of: parent), -1)
        XCTAssertEqual(graph.generation(of: root), 0)
        XCTAssertEqual(graph.generation(of: sibling), 0)
        XCTAssertEqual(graph.generation(of: partner), 0)
        XCTAssertEqual(graph.generation(of: child), 1)
        XCTAssertEqual(graph.characters.count, 6)
        XCTAssertEqual(graph.edges.count, 5)
    }

    @MainActor
    func testFamilyRelationshipRulesRejectAncestryCycle() {
        let child = CharacterProfile(name: "Child")
        let parent = CharacterProfile(name: "Parent")
        let grandparent = CharacterProfile(name: "Grandparent")
        _ = link(child, to: parent, as: .parent)
        _ = link(parent, to: grandparent, as: .parent)

        XCTAssertNotNil(FamilyRelationshipRules.validationMessage(source: parent, target: child, kind: .parent))
        XCTAssertNotNil(FamilyRelationshipRules.validationMessage(source: grandparent, target: child, kind: .parent))
        XCTAssertNotNil(FamilyRelationshipRules.validationMessage(source: child, target: parent, kind: .child))
    }

    @MainActor
    func testFamilyRelationshipRulesRejectDuplicateLink() {
        let child = CharacterProfile(name: "Child")
        let parent = CharacterProfile(name: "Parent")
        _ = link(child, to: parent, as: .parent)
        XCTAssertEqual(
            FamilyRelationshipRules.validationMessage(source: child, target: parent, kind: .parent),
            "That relationship already exists."
        )
    }

    func testVisualAnglesCoverFullTurnaround() {
        XCTAssertEqual(VisualAngle.allCases.count, 8)
        XCTAssertEqual(VisualAngle.front.degrees, 0)
        XCTAssertEqual(VisualAngle.back.degrees, 180)
        XCTAssertEqual(VisualAngle.frontLeft.degrees, 315)
    }
}
