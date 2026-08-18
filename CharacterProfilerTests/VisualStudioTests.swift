// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest
import SwiftData
@testable import CharacterProfiler

final class VisualStudioTests: XCTestCase {
    @MainActor
    func testVisualWorkspaceSnapshotTracksCompletenessAndMissingAngles() {
        let character = CharacterProfile(name: "Elena", generatedVisualData: Data([1, 2, 3]))
        character.referenceImages.append(CharacterReferenceImage(label: "Face", sortOrder: 0, imageData: Data([4]), character: character))
        character.referenceImages.append(CharacterReferenceImage(label: "Clothes", sortOrder: 1, imageData: Data([5]), character: character))
        character.visualFrames.append(CharacterVisualFrame(angle: .front, imageData: Data([6]), character: character))
        character.visualFrames.append(CharacterVisualFrame(angle: .right, imageData: Data([7]), character: character))
        character.visualFrames.append(CharacterVisualFrame(angle: .back, imageData: Data([8]), character: character))

        let snapshot = VisualWorkspaceSnapshot(character: character)

        XCTAssertTrue(snapshot.hasCanonicalVisual)
        XCTAssertEqual(snapshot.referenceCount, 2)
        XCTAssertEqual(snapshot.completedAngleCount, 3)
        XCTAssertEqual(snapshot.turnaroundProgress, 3.0 / 8.0, accuracy: 0.0001)
        XCTAssertEqual(snapshot.missingAngles, [.frontRight, .backRight, .backLeft, .left, .frontLeft])
        XCTAssertFalse(snapshot.isTurnaroundComplete)
    }

    @MainActor
    func testVisualWorkspaceSnapshotTreatsDuplicateStoredAnglesAsOneView() {
        let character = CharacterProfile(name: "Elena")
        character.visualFrames.append(CharacterVisualFrame(angle: .front, imageData: Data([1]), character: character))
        character.visualFrames.append(CharacterVisualFrame(angle: .front, imageData: Data([2]), character: character))

        let snapshot = VisualWorkspaceSnapshot(character: character)

        XCTAssertEqual(snapshot.completedAngleCount, 1)
        XCTAssertEqual(snapshot.duplicateAngles, [.front])
        XCTAssertEqual(snapshot.missingAngles.count, 7)
    }

    func testVisualAngleNavigationWrapsAcrossAllEightSlots() {
        XCTAssertEqual(VisualAngle.front.advanced(by: -1), .frontLeft)
        XCTAssertEqual(VisualAngle.frontLeft.advanced(by: 1), .front)
        XCTAssertEqual(VisualAngle.right.advanced(by: 2), .back)
        XCTAssertEqual(VisualAngle.back.advanced(by: -2), .right)
    }

    func testReferenceReorderingMovesOneSlotAndClampsAtEnds() {
        let first = UUID()
        let second = UUID()
        let third = UUID()
        let ids = [first, second, third]

        XCTAssertEqual(VisualReferenceOrdering.reorderedIDs(ids, moving: second, by: -1), [second, first, third])
        XCTAssertEqual(VisualReferenceOrdering.reorderedIDs(ids, moving: second, by: 1), [first, third, second])
        XCTAssertEqual(VisualReferenceOrdering.reorderedIDs(ids, moving: first, by: -1), ids)
        XCTAssertEqual(VisualReferenceOrdering.reorderedIDs(ids, moving: third, by: 1), ids)
    }

    @MainActor
    func testCompleteTurnaroundReportsNoMissingAngles() {
        let character = CharacterProfile(name: "Elena", generatedVisualData: Data([1]))
        for angle in VisualAngle.allCases {
            character.visualFrames.append(CharacterVisualFrame(angle: angle, imageData: Data([UInt8(angle.degrees % 255)]), character: character))
        }

        let snapshot = VisualWorkspaceSnapshot(character: character)

        XCTAssertTrue(snapshot.isTurnaroundComplete)
        XCTAssertEqual(snapshot.completedAngleCount, 8)
        XCTAssertEqual(snapshot.turnaroundProgress, 1.0, accuracy: 0.0001)
        XCTAssertTrue(snapshot.missingAngles.isEmpty)
    }
}

final class AuthorWorkflowTests: XCTestCase {
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
    func testLifeEventOrderingMovesOneSlotAndClampsAtEnds() {
        let character = CharacterProfile(name: "Elena")
        let first = LifeEvent(title: "First", sortOrder: 0, character: character)
        let second = LifeEvent(title: "Second", sortOrder: 1, character: character)
        let third = LifeEvent(title: "Third", sortOrder: 2, character: character)
        character.lifeEvents = [first, second, third]

        LifeEventOrdering.move(second, by: 1, in: character)
        XCTAssertEqual(character.sortedLifeEvents.map(\.title), ["First", "Third", "Second"])

        LifeEventOrdering.move(first, by: -1, in: character)
        XCTAssertEqual(character.sortedLifeEvents.map(\.title), ["First", "Third", "Second"])

        LifeEventOrdering.normalize(in: character)
        XCTAssertEqual(character.sortedLifeEvents.map(\.sortOrder), [0, 1, 2])
    }

    @MainActor
    func testRelationshipEditingStoresCorrectInverseFromTargetPerspective() {
        let child = CharacterProfile(name: "Child")
        let parent = CharacterProfile(name: "Parent")
        let relationship = CharacterRelationship(kind: .parent, source: child, target: parent)
        child.outgoingRelationships.append(relationship)
        parent.incomingRelationships.append(relationship)

        XCTAssertEqual(relationship.kind(from: parent), .child)
        let stored = RelationshipEditingRules.storedKind(
            displayedKind: .mentor,
            for: relationship,
            viewedFrom: parent
        )
        XCTAssertEqual(stored, .student)
        relationship.kind = stored
        XCTAssertEqual(relationship.kind(from: parent), .mentor)
        XCTAssertEqual(relationship.kind(from: child), .student)
    }

    @MainActor
    func testFamilyValidationCanIgnoreTheRelationshipBeingEdited() {
        let child = CharacterProfile(name: "Child")
        let parent = CharacterProfile(name: "Parent")
        let relationship = CharacterRelationship(kind: .parent, source: child, target: parent)
        child.outgoingRelationships.append(relationship)
        parent.incomingRelationships.append(relationship)

        XCTAssertNotNil(
            FamilyRelationshipRules.validationMessage(source: child, target: parent, kind: .child)
        )
        XCTAssertNil(
            FamilyRelationshipRules.validationMessage(
                source: child,
                target: parent,
                kind: .child,
                excluding: relationship.id
            )
        )
    }

    @MainActor
    func testFamilyGraphReportsConflictingGenerationPaths() {
        let root = CharacterProfile(name: "Root")
        let parent = CharacterProfile(name: "Parent")
        let grandparent = CharacterProfile(name: "Grandparent")

        let first = CharacterRelationship(kind: .parent, source: root, target: parent)
        root.outgoingRelationships.append(first)
        parent.incomingRelationships.append(first)

        let second = CharacterRelationship(kind: .parent, source: parent, target: grandparent)
        parent.outgoingRelationships.append(second)
        grandparent.incomingRelationships.append(second)

        let conflicting = CharacterRelationship(kind: .spouse, source: root, target: grandparent)
        root.outgoingRelationships.append(conflicting)
        grandparent.incomingRelationships.append(conflicting)

        let snapshot = FamilyGraphSnapshot(root: root)
        XCTAssertTrue(snapshot.hasGenerationConflicts)
        XCTAssertFalse(snapshot.generationConflicts.isEmpty)
    }

    @MainActor
    func testLegacyMigrationCreatesOneImportedProjectAndIsIdempotent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let existing = StoryProject(title: "Existing Story", genre: .fantasy)
        let assigned = CharacterProfile(name: "Assigned", project: existing)
        let orphanOne = CharacterProfile(name: "Orphan One")
        let orphanTwo = CharacterProfile(name: "Orphan Two")
        context.insert(existing)
        context.insert(assigned)
        context.insert(orphanOne)
        context.insert(orphanTwo)
        existing.characters.append(assigned)
        try context.save()

        var projects = try context.fetch(FetchDescriptor<StoryProject>())
        var characters = try context.fetch(FetchDescriptor<CharacterProfile>())
        let imported = try XCTUnwrap(
            LegacyDataMigration.assignUnassignedCharacters(characters, projects: projects, in: context)
        )

        XCTAssertEqual(imported.title, "Imported Characters")
        XCTAssertEqual(Set(imported.characters.map(\.name)), Set(["Orphan One", "Orphan Two"]))
        XCTAssertEqual(assigned.project?.id, existing.id)

        projects = try context.fetch(FetchDescriptor<StoryProject>())
        characters = try context.fetch(FetchDescriptor<CharacterProfile>())
        let secondRun = try LegacyDataMigration.assignUnassignedCharacters(characters, projects: projects, in: context)

        XCTAssertNil(secondRun)
        XCTAssertEqual(projects.filter { $0.title == "Imported Characters" }.count, 1)
        XCTAssertTrue(characters.allSatisfy { $0.project != nil })
    }

    @MainActor
    func testLegacyMigrationDoesNotHijackAuthorStoryWithImportedCharactersTitle() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let authorStory = StoryProject(title: "Imported Characters", genre: .fantasy)
        let orphan = CharacterProfile(name: "Legacy Orphan")
        context.insert(authorStory)
        context.insert(orphan)
        try context.save()

        let imported = try XCTUnwrap(
            LegacyDataMigration.assignUnassignedCharacters(
                [orphan],
                projects: [authorStory],
                in: context
            )
        )

        XCTAssertNotEqual(imported.id, authorStory.id)
        XCTAssertEqual(imported.genre, .other)
        XCTAssertEqual(imported.customGenre, "Unassigned")
        XCTAssertTrue(authorStory.characters.isEmpty)
        XCTAssertEqual(orphan.project?.id, imported.id)
    }

    @MainActor
    func testCharacterSearchIncludesRelationshipNamesKindsAndNotes() {
        let elena = CharacterProfile(name: "Elena")
        let mara = CharacterProfile(name: "Mara Vale")
        let relationship = CharacterRelationship(
            kind: .mentor,
            notes: "Owes her a dangerous debt",
            source: elena,
            target: mara
        )
        elena.outgoingRelationships.append(relationship)
        mara.incomingRelationships.append(relationship)

        XCTAssertTrue(CharacterSearch.matches(elena, term: "Mara"))
        XCTAssertTrue(CharacterSearch.matches(elena, term: "mentor"))
        XCTAssertTrue(CharacterSearch.matches(elena, term: "dangerous debt"))
        XCTAssertFalse(CharacterSearch.matches(elena, term: "spaceship"))
    }

    @MainActor
    func testProfileDraftRejectsBlankSectionAndFieldLabels() {
        var draft = ProfileDraft()
        draft.name = "Elena"
        draft.sections = [SectionDraft(title: " ", fields: [])]
        XCTAssertNotNil(draft.validationMessage)

        draft.sections = [SectionDraft(title: "Appearance", fields: [FieldDraft(label: "  ", value: "Scar")])]
        XCTAssertNotNil(draft.validationMessage)
    }

    @MainActor
    func testProfileDraftPreservesSectionAndFieldIDsAcrossEdit() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = StoryProject(title: "Story")
        let character = CharacterProfile(name: "Elena", project: project)
        let section = ProfileSection(title: "Appearance", sortOrder: 0, character: character)
        let field = ProfileField(label: "Hair", value: "Black", sortOrder: 0, section: section)
        context.insert(project)
        context.insert(character)
        context.insert(section)
        context.insert(field)
        project.characters.append(character)
        character.sections.append(section)
        section.fields.append(field)
        try context.save()

        let sectionID = section.id
        let fieldID = field.id
        var draft = ProfileDraft(character: character)
        draft.sections[0].fields[0].value = "Silver"
        _ = draft.save(to: character, project: project, in: context)
        try context.saveOrRollback()

        XCTAssertEqual(character.sortedSections.first?.id, sectionID)
        XCTAssertEqual(character.sortedSections.first?.sortedFields.first?.id, fieldID)
        XCTAssertEqual(character.sortedSections.first?.sortedFields.first?.value, "Silver")
    }

    @MainActor
    func testCharacterModificationPropagatesToStoryActivityTimestamp() {
        let oldDate = Date(timeIntervalSince1970: 100)
        let newDate = Date(timeIntervalSince1970: 200)
        let project = StoryProject(title: "Story", updatedAt: oldDate)
        let character = CharacterProfile(name: "Elena", updatedAt: oldDate, project: project)

        character.markModified(at: newDate)

        XCTAssertEqual(character.updatedAt, newDate)
        XCTAssertEqual(project.updatedAt, newDate)
    }

    @MainActor
    func testArchiveRejectsDuplicateNestedProfileIdentifiers() {
        let repeatedID = UUID()
        let project = StoryProject(title: "Story")
        let character = CharacterProfile(name: "Elena", project: project)
        let first = ProfileSection(id: repeatedID, title: "Appearance", sortOrder: 0, character: character)
        let second = ProfileSection(id: repeatedID, title: "Secrets", sortOrder: 1, character: character)
        character.sections = [first, second]
        project.characters = [character]

        XCTAssertThrowsError(try ProjectArchive(project: project).validate())
    }

    @MainActor
    func testArchiveRejectsDuplicateTurnaroundAngles() {
        let project = StoryProject(title: "Story")
        let character = CharacterProfile(name: "Elena", project: project)
        character.visualFrames = [
            CharacterVisualFrame(angle: .front, imageData: Data([1]), character: character),
            CharacterVisualFrame(angle: .front, imageData: Data([2]), character: character)
        ]
        project.characters = [character]

        XCTAssertThrowsError(try ProjectArchive(project: project).validate())
    }

    private enum SyntheticPersistenceError: Error {
        case failed
    }

    @MainActor
    func testPersistenceSafetyRollsBackPendingMutationWhenCommitFails() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = StoryProject(title: "Story")
        let character = CharacterProfile(name: "Before", project: project)
        context.insert(project)
        context.insert(character)
        project.characters.append(character)
        try context.save()

        let characterID = character.id
        character.name = "After"

        XCTAssertThrowsError(
            try PersistenceSafety.commit(
                save: { throw SyntheticPersistenceError.failed },
                rollback: { context.rollback() }
            )
        )

        let fetched = try context.fetch(FetchDescriptor<CharacterProfile>())
        XCTAssertEqual(fetched.first(where: { $0.id == characterID })?.name, "Before")
    }

    @MainActor
    func testRelationshipKindDoesNotTreatUnrelatedCharacterAsEndpoint() {
        let source = CharacterProfile(name: "Source")
        let target = CharacterProfile(name: "Target")
        let unrelated = CharacterProfile(name: "Unrelated")
        let relationship = CharacterRelationship(kind: .parent, source: source, target: target)

        XCTAssertEqual(relationship.kind(from: source), .parent)
        XCTAssertEqual(relationship.kind(from: target), .child)
        XCTAssertEqual(relationship.kind(from: unrelated), .other)
    }

    @MainActor
    func testArchiveRejectsConflictingFamilyGenerationPaths() {
        let project = StoryProject(title: "Story")
        let root = CharacterProfile(name: "Root", project: project)
        let parent = CharacterProfile(name: "Parent", project: project)
        let grandparent = CharacterProfile(name: "Grandparent", project: project)
        project.characters = [root, parent, grandparent]

        let rootParent = CharacterRelationship(kind: .parent, source: root, target: parent)
        root.outgoingRelationships.append(rootParent)
        parent.incomingRelationships.append(rootParent)

        let parentGrandparent = CharacterRelationship(kind: .parent, source: parent, target: grandparent)
        parent.outgoingRelationships.append(parentGrandparent)
        grandparent.incomingRelationships.append(parentGrandparent)

        let conflict = CharacterRelationship(kind: .spouse, source: root, target: grandparent)
        root.outgoingRelationships.append(conflict)
        grandparent.incomingRelationships.append(conflict)

        XCTAssertThrowsError(try ProjectArchive(project: project).validate())
    }
}
