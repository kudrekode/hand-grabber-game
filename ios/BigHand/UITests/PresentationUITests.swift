import XCTest

@MainActor
final class PresentationUITests: XCTestCase {
    private func launch(_ scenario: String? = nil, shop: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        if let scenario { app.launchArguments += ["-presentation-scenario", scenario] }
        if shop { app.launchArguments += ["-shop"] }
        app.launch(); return app
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testHomeStartButtonFitsPortrait() {
        let app = launch()
        let play = app.buttons["LET’S CRUSH →"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        XCTAssertTrue(play.isHittable)
        XCTAssertLessThanOrEqual(play.frame.maxY, app.frame.maxY)
        capture("home-first-fold")
        play.tap()
        XCTAssertTrue(app.otherElements["gameTrack"].waitForExistence(timeout: 8))
    }
    func testPortraitImpactsGatesAndGiantHand() {
        continueAfterFailure = false
        for scenario in ["small", "large", "gate", "negativeGate", "giant"] {
            let app = launch(scenario)
            let track = app.otherElements["gameTrack"]
            XCTAssertTrue(track.waitForExistence(timeout: 8))
            capture("\(scenario)-approach")
            track.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            let expected = scenario == "small" ? "crushed 5" : scenario == "large" || scenario == "giant" ? "crushed 250" : scenario == "gate" ? "Size 30" : "Size 10"
            let changed = NSPredicate(format: "value CONTAINS %@", expected)
            expectation(for: changed, evaluatedWith: track)
            waitForExpectations(timeout: 40)
            capture("\(scenario)-after-impact")
            XCTAssertTrue(app.buttons["Pause game"].exists)
            app.terminate()
        }
        let app = launch("fail")
        let track = app.otherElements["gameTrack"]
        XCTAssertTrue(track.waitForExistence(timeout: 8)); track.tap()
        XCTAssertTrue(app.buttons["RETRY →"].waitForExistence(timeout: 40))
        capture("failed-collision-results")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Bus needed 360'")).firstMatch.exists)
    }
    func testRelativeTouchAndPauseResume() {
        let app = launch("movement")
        let track = app.otherElements["gameTrack"]
        XCTAssertTrue(track.waitForExistence(timeout: 8))
        let start = track.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        start.press(forDuration: 0.05, thenDragTo: track.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.55)))
        expectation(for: NSPredicate(format: "value CONTAINS 'position 84' OR value CONTAINS 'position 83' OR value CONTAINS 'position 85'"), evaluatedWith: track)
        waitForExpectations(timeout: 5)
        capture("touch-left-settled")
        app.buttons["Pause game"].tap()
        XCTAssertTrue(app.buttons["BACK TO CRUSHING →"].waitForExistence(timeout: 3))
        app.buttons["BACK TO CRUSHING →"].tap()
        XCTAssertTrue(track.waitForExistence(timeout: 3))
    }
    func testWorkshopBuyEquipAndUpgrade() {
        let app = launch(shop: true)
        XCTAssertTrue(app.staticTexts["UPGRADES"].waitForExistence(timeout: 8))
        capture("workshop-upgrades")
        app.buttons["Buy Starting Hand Size level 1 for 75 coins"].tap()
        XCTAssertTrue(app.staticTexts["1/8"].exists)
        let red = app.buttons["Unlock and equip Red Glove, 500 coins"]
        for _ in 0..<7 where !red.isHittable { app.swipeUp() }
        XCTAssertTrue(red.isHittable); capture("hand-collection-locked")
        red.tap()
        XCTAssertTrue(app.buttons["Red Glove, equipped"].exists)
        app.buttons["Equip Classic"].tap()
        XCTAssertTrue(app.buttons["Classic, equipped"].exists)
        capture("hand-collection-equipped")
        for _ in 0..<5 { app.swipeUp() }
        capture("hand-collection-robot-zombie-foam")
    }
}
