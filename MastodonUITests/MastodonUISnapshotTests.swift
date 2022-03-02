//
//  MastodonUISnapshotTests.swift
//  MastodonUITests
//
//  Created by MainasuK on 2022-3-2.
//

import XCTest

extension UInt64 {
    static let second: UInt64 = 1_000_000_000
}

@MainActor
class MastodonUISnapshotTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    override class func tearDown() {
        super.tearDown()
        let app = XCUIApplication()
        print(app.debugDescription)
    }
    
}

extension MastodonUISnapshotTests {
    
    func testSmoke() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        
    }
    
}

extension MastodonUISnapshotTests {

    func testSnapshot() async throws {
        let app = XCUIApplication()
        app.launch()
        
        try await snapshotHome()
        try await snapshotSearch()
        try await snapshotProfile()
        
    }
    
    func snapshotHome() async throws {
        let app = XCUIApplication()
        app.launch()
        
        func tapTab() {
            XCTAssert(app.tabBars.buttons["Home"].exists)
            app.tabBars.buttons["Home"].tap()
        }
        
        tapTab()
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Home - 1")
        
        tapTab()
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Home - 2")
        
        tapTab()
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Home - 3")
    }
    
    func snapshotSearch() async throws {
        let app = XCUIApplication()
        app.launch()
        
        func tapTab() {
            XCTAssert(app.tabBars.buttons["Search"].exists)
            app.tabBars.buttons["Search"].tap()
        }
        
        tapTab()
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Search - 1")
        
        tapTab()
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Search - 2")
        
        tapTab()
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Search - 3")
    }
    
    func snapshotProfile() async throws {
        let app = XCUIApplication()
        app.launch()
        
        // Go to Search tab
        XCTAssert(app.tabBars.buttons["Search"].exists)
        app.tabBars.buttons["Search"].tap()
        
        // Tap and search user
        let searchField = app.navigationBars.searchFields.firstMatch
        XCTAssert(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("@dentaku@fnordon.de")
        
        // Tap the cell and display user profile
        let cell = app.tables.cells.firstMatch
        XCTAssert(cell.waitForExistence(timeout: 5))
        cell.tap()
        
        try await Task.sleep(nanoseconds: .second * 5)
        
        takeSnapshot(name: "Profile")
    }
    
}

extension MastodonUISnapshotTests {
    func takeSnapshot(name: String) {
        let snapshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: snapshot)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
