// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest

final class CharacterProfilerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesLibraryAndOpensNewStoryEditor() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Character Profiler"].waitForExistence(timeout: 8))
        let newStory = app.buttons["New Story"]
        XCTAssertTrue(newStory.waitForExistence(timeout: 4))
        newStory.tap()
        XCTAssertTrue(app.navigationBars["New Story"].waitForExistence(timeout: 4))
    }
}
