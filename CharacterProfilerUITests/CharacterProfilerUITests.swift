// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest

final class CharacterProfilerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAuthorCanCreateStoryCharacterAndHistoryEntryThenDeleteHistoryEntry() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Character Profiler"].waitForExistence(timeout: 8))

        let storyTitle = "UI Story \(UUID().uuidString.prefix(8))"
        let characterName = "Elena UI \(UUID().uuidString.prefix(8))"
        let eventTitle = "Turning Point \(UUID().uuidString.prefix(8))"

        let newStory = app.buttons["New Story"]
        XCTAssertTrue(newStory.waitForExistence(timeout: 4))
        newStory.tap()
        XCTAssertTrue(app.navigationBars["New Story"].waitForExistence(timeout: 4))

        let projectTitle = app.textFields["Project title"]
        XCTAssertTrue(projectTitle.waitForExistence(timeout: 4))
        projectTitle.tap()
        projectTitle.typeText(storyTitle)

        let saveStory = app.buttons["Save"]
        XCTAssertTrue(saveStory.isEnabled)
        saveStory.tap()

        let storyRow = app.staticTexts[storyTitle]
        XCTAssertTrue(storyRow.waitForExistence(timeout: 6))
        storyRow.tap()
        XCTAssertTrue(app.navigationBars[storyTitle].waitForExistence(timeout: 4))

        let newCharacter = app.buttons["New Character"]
        XCTAssertTrue(newCharacter.waitForExistence(timeout: 4))
        newCharacter.tap()
        XCTAssertTrue(app.navigationBars["New Character"].waitForExistence(timeout: 4))

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 4))
        nameField.tap()
        nameField.typeText(characterName)

        let saveCharacter = app.buttons["Save"]
        XCTAssertTrue(saveCharacter.isEnabled)
        saveCharacter.tap()

        let characterRow = app.staticTexts[characterName]
        XCTAssertTrue(characterRow.waitForExistence(timeout: 6))
        characterRow.tap()
        XCTAssertTrue(app.navigationBars[characterName].waitForExistence(timeout: 4))

        let historySegment = app.segmentedControls.buttons["History"]
        XCTAssertTrue(historySegment.waitForExistence(timeout: 4))
        historySegment.tap()

        let addLifeEvent = app.buttons["Add Life Event"]
        XCTAssertTrue(addLifeEvent.waitForExistence(timeout: 4))
        addLifeEvent.tap()
        XCTAssertTrue(app.navigationBars["Add Life Event"].waitForExistence(timeout: 4))

        let eventTitleField = app.textFields["Event title"]
        XCTAssertTrue(eventTitleField.waitForExistence(timeout: 4))
        eventTitleField.tap()
        eventTitleField.typeText(eventTitle)

        let saveEvent = app.buttons["Save"]
        XCTAssertTrue(saveEvent.isEnabled)
        saveEvent.tap()

        XCTAssertTrue(app.staticTexts[eventTitle].waitForExistence(timeout: 6))

        let eventActions = app.buttons["Actions for \(eventTitle)"]
        XCTAssertTrue(eventActions.waitForExistence(timeout: 4))
        eventActions.tap()

        let deleteAction = app.buttons["Delete"]
        XCTAssertTrue(deleteAction.waitForExistence(timeout: 4))
        deleteAction.tap()

        let confirmDelete = app.buttons["Delete Life Event"]
        XCTAssertTrue(confirmDelete.waitForExistence(timeout: 4))
        confirmDelete.tap()

        XCTAssertFalse(app.staticTexts[eventTitle].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["No Life Events"].waitForExistence(timeout: 4))
    }
}
