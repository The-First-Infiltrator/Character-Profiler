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

    @MainActor
    func testProjectArchiveRoundTripPreservesWholeStoryAndCanRestoreTwice() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = StoryProject(
            title: "Ashes of the Crown",
            genre: .fantasy,
            premise: "A broken kingdom is forced to choose who should rebuild it."
        )
        context.insert(project)

        let elena = CharacterProfile(
            name: "Elena Vale",
            nickname: "Len",
            summary: "A former mercenary who distrusts magic.",
            storyRole: "Reluctant heir",
            pronouns: "she/her",
            ageText: "27",
            profileImageData: Data([1, 2, 3, 4]),
            visualDescription: "Black hair, weathered coat, scar through the left eyebrow.",
            generatedVisualData: Data([5, 6, 7]),
            project: project
        )
        let mara = CharacterProfile(name: "Mara Vale", storyRole: "Mother", project: project)
        context.insert(elena)
        context.insert(mara)
        project.characters.append(contentsOf: [elena, mara])

        let appearance = ProfileSection(title: "Appearance", sortOrder: 0, character: elena)
        let hair = ProfileField(label: "Hair", value: "Black, shoulder-length", sortOrder: 0, section: appearance)
        context.insert(appearance)
        context.insert(hair)
        appearance.fields.append(hair)
        elena.sections.append(appearance)

        let loss = LifeEvent(
            title: "Father killed in the border war",
            kind: .loss,
            whenText: "Age 21",
            details: "He died during the retreat from Grey Ford.",
            impact: "She stopped believing rank made anyone competent.",
            sortOrder: 0,
            character: elena
        )
        context.insert(loss)
        elena.lifeEvents.append(loss)

        let answer = PromptResponse(
            promptID: "fantasy.magic-attitude",
            question: "How does she feel about magic?",
            category: .world,
            answer: "Useful, dangerous, and never free.",
            character: elena
        )
        context.insert(answer)
        elena.promptResponses.append(answer)

        let reference = CharacterReferenceImage(
            label: "Face reference",
            sortOrder: 0,
            imageData: Data([9, 8, 7, 6]),
            character: elena
        )
        context.insert(reference)
        elena.referenceImages.append(reference)

        let frame = CharacterVisualFrame(
            angle: .frontRight,
            imageData: Data([4, 3, 2, 1]),
            character: elena
        )
        context.insert(frame)
        elena.visualFrames.append(frame)

        let relationship = CharacterRelationship(
            kind: .parent,
            notes: "Close, but they argue about duty.",
            source: elena,
            target: mara
        )
        context.insert(relationship)
        elena.outgoingRelationships.append(relationship)
        mara.incomingRelationships.append(relationship)
        try context.save()

        let originalProjectID = project.id
        let originalElenaID = elena.id
        let archive = ProjectArchive(project: project)
        XCTAssertEqual(archive.formatVersion, 1)
        XCTAssertEqual(archive.project.characters.count, 2)
        XCTAssertEqual(archive.project.relationships.count, 1)

        let data = try archive.encodedData()
        let decoded = try ProjectArchive.decode(data)
        let firstRestore = try decoded.restore(in: context)
        let secondRestore = try decoded.restore(in: context)

        XCTAssertNotEqual(firstRestore.id, originalProjectID)
        XCTAssertNotEqual(secondRestore.id, originalProjectID)
        XCTAssertNotEqual(firstRestore.id, secondRestore.id)
        XCTAssertEqual(firstRestore.title, project.title)
        XCTAssertEqual(firstRestore.genre, .fantasy)
        XCTAssertEqual(firstRestore.premise, project.premise)
        XCTAssertEqual(firstRestore.characters.count, 2)
        XCTAssertEqual(secondRestore.characters.count, 2)

        guard let restoredElena = firstRestore.characters.first(where: { $0.name == "Elena Vale" }),
              let restoredMara = firstRestore.characters.first(where: { $0.name == "Mara Vale" }) else {
            return XCTFail("Expected both archived characters to be restored")
        }

        XCTAssertNotEqual(restoredElena.id, originalElenaID)
        XCTAssertEqual(restoredElena.nickname, "Len")
        XCTAssertEqual(restoredElena.storyRole, "Reluctant heir")
        XCTAssertEqual(restoredElena.pronouns, "she/her")
        XCTAssertEqual(restoredElena.ageText, "27")
        XCTAssertEqual(restoredElena.profileImageData, Data([1, 2, 3, 4]))
        XCTAssertEqual(restoredElena.generatedVisualData, Data([5, 6, 7]))
        XCTAssertEqual(restoredElena.visualDescription, elena.visualDescription)
        XCTAssertEqual(restoredElena.sortedSections.first?.title, "Appearance")
        XCTAssertEqual(restoredElena.sortedSections.first?.sortedFields.first?.value, "Black, shoulder-length")
        XCTAssertEqual(restoredElena.sortedLifeEvents.first?.kind, .loss)
        XCTAssertEqual(restoredElena.sortedLifeEvents.first?.whenText, "Age 21")
        XCTAssertEqual(restoredElena.promptResponses.first?.answer, "Useful, dangerous, and never free.")
        XCTAssertEqual(restoredElena.sortedReferenceImages.first?.imageData, Data([9, 8, 7, 6]))
        XCTAssertEqual(restoredElena.sortedVisualFrames.first?.angle, .frontRight)
        XCTAssertEqual(restoredElena.sortedVisualFrames.first?.imageData, Data([4, 3, 2, 1]))

        XCTAssertEqual(restoredElena.allRelationships.count, 1)
        let restoredRelationship = restoredElena.allRelationships[0]
        XCTAssertEqual(restoredRelationship.kind(from: restoredElena), .parent)
        XCTAssertEqual(restoredRelationship.relatedCharacter(to: restoredElena)?.id, restoredMara.id)
        XCTAssertEqual(restoredRelationship.notes, "Close, but they argue about duty.")
    }

    @MainActor
    func testProjectArchiveRejectsUnsupportedFormatVersion() throws {
        let project = StoryProject(title: "Future Story", genre: .scienceFiction)
        var archive = ProjectArchive(project: project)
        archive.formatVersion = ProjectArchive.currentFormatVersion + 1

        XCTAssertThrowsError(try archive.validate()) { error in
            guard case ProjectArchiveError.unsupportedFormatVersion(let version) = error else {
                return XCTFail("Expected unsupported archive format error")
            }
            XCTAssertEqual(version, ProjectArchive.currentFormatVersion + 1)
        }
    }

    @MainActor
    func testProjectArchiveRejectsMissingIdentityData() {
        let untitled = ProjectArchive(project: StoryProject(title: "   "))
        XCTAssertThrowsError(try untitled.validate())

        let project = StoryProject(title: "Valid Story")
        project.characters.append(CharacterProfile(name: "   ", project: project))
        let unnamedCharacter = ProjectArchive(project: project)
        XCTAssertThrowsError(try unnamedCharacter.validate())
    }

    @MainActor
    func testProjectArchiveRejectsDuplicateCharacterIdentifiers() {
        let repeatedID = UUID()
        let project = StoryProject(title: "Duplicated Cast")
        project.characters = [
            CharacterProfile(id: repeatedID, name: "First", project: project),
            CharacterProfile(id: repeatedID, name: "Second", project: project)
        ]

        let archive = ProjectArchive(project: project)
        XCTAssertThrowsError(try archive.validate())
    }

    @MainActor
    func testProjectArchiveRejectsDuplicateRelationshipIdentifiers() {
        let project = StoryProject(title: "Duplicated Links")
        let first = CharacterProfile(name: "First", project: project)
        let second = CharacterProfile(name: "Second", project: project)
        project.characters = [first, second]
        let relationship = link(first, to: second, as: .friend)

        var archive = ProjectArchive(project: project)
        XCTAssertEqual(archive.project.relationships.count, 1)
        var duplicate = archive.project.relationships[0]
        duplicate.sourceID = relationship.id
        archive.project.relationships.append(duplicate)

        XCTAssertThrowsError(try archive.validate())
    }

    @MainActor
    func testProjectArchiveRejectsSemanticDuplicateRelationshipAcrossDirection() {
        let project = StoryProject(title: "Duplicated Meaning")
        let first = CharacterProfile(name: "First", project: project)
        let second = CharacterProfile(name: "Second", project: project)
        project.characters = [first, second]
        _ = link(first, to: second, as: .mentor)

        var archive = ProjectArchive(project: project)
        XCTAssertEqual(archive.project.relationships.count, 1)
        var duplicate = archive.project.relationships[0]
        duplicate.sourceID = UUID()
        let originalSource = duplicate.sourceCharacterID
        duplicate.sourceCharacterID = duplicate.targetCharacterID
        duplicate.targetCharacterID = originalSource
        duplicate.kind = duplicate.kind.inverse
        archive.project.relationships.append(duplicate)

        XCTAssertThrowsError(try archive.validate())
    }

    @MainActor
    func testProjectArchiveRejectsMultipleFamilyRelationshipsForSamePair() {
        let project = StoryProject(title: "Duplicated Family Meaning")
        let first = CharacterProfile(name: "First", project: project)
        let second = CharacterProfile(name: "Second", project: project)
        project.characters = [first, second]
        _ = link(first, to: second, as: .spouse)

        var archive = ProjectArchive(project: project)
        XCTAssertEqual(archive.project.relationships.count, 1)
        var secondFamilyLink = archive.project.relationships[0]
        secondFamilyLink.sourceID = UUID()
        secondFamilyLink.kind = .partner
        archive.project.relationships.append(secondFamilyLink)

        XCTAssertThrowsError(try archive.validate())
    }

    @MainActor
    func testProjectArchiveRejectsSelfAndMissingRelationshipEndpointsBeforeRestore() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = StoryProject(title: "Broken Links")
        let first = CharacterProfile(name: "First", project: project)
        let second = CharacterProfile(name: "Second", project: project)
        project.characters = [first, second]
        _ = link(first, to: second, as: .rival)

        var selfLinkArchive = ProjectArchive(project: project)
        selfLinkArchive.project.relationships[0].targetCharacterID = selfLinkArchive.project.relationships[0].sourceCharacterID
        XCTAssertThrowsError(try selfLinkArchive.restore(in: context))
        XCTAssertTrue(try context.fetch(FetchDescriptor<StoryProject>()).isEmpty)

        var missingEndpointArchive = ProjectArchive(project: project)
        missingEndpointArchive.project.relationships[0].targetCharacterID = UUID()
        XCTAssertThrowsError(try missingEndpointArchive.restore(in: context))
        XCTAssertTrue(try context.fetch(FetchDescriptor<StoryProject>()).isEmpty)
    }

    @MainActor
    func testProjectArchiveSuggestedFilenameIsPortable() {
        let project = StoryProject(title: "  Ashes: Crown / Part II?  ")
        XCTAssertEqual(ProjectArchive.suggestedFilename(for: project), "Ashes-Crown-Part-II.characterprofiler.json")
        XCTAssertEqual(ProjectArchive.suggestedFilename(for: StoryProject(title: "***")), "Story.characterprofiler.json")
    }

    func testVisualAnglesCoverFullTurnaround() {
        XCTAssertEqual(VisualAngle.allCases.count, 8)
        XCTAssertEqual(VisualAngle.front.degrees, 0)
        XCTAssertEqual(VisualAngle.back.degrees, 180)
        XCTAssertEqual(VisualAngle.frontLeft.degrees, 315)
    }
}
