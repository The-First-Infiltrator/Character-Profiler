// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest

final class CharacterProfilerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAuthorCanCreateStoryAndCharacter() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Character Profiler"].waitForExistence(timeout: 8))

        let storyTitle = "UI Story \(UUID().uuidString.prefix(8))"
        let characterName = "Elena UI \(UUID().uuidString.prefix(8))"

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

        XCTAssertTrue(app.staticTexts[characterName].waitForExistence(timeout: 6))
    }
}
