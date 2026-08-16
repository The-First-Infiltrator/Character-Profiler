// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest
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
