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
    
    private func tapTab(app: XCUIApplication, tab: String) {
        let searchTab = app.tabBars.buttons[tab]
        if searchTab.exists { searchTab.tap() }
        
        let searchCell = app.collectionViews.cells[tab]
        if searchCell.exists { searchCell.tap() }
    }

    func testSnapshot() async throws {
        let app = XCUIApplication()
        app.launch()
        
        try await testSnapshotHome()
        try await testSnapshotSearch()
        try await testSnapshotNotification()
        try await testSnapshotProfile()
        try await testSnapshotCompose()
    }
    
    func testSnapshotHome() async throws {
        let app = XCUIApplication()
        app.launch()
        
        tapTab(app: app, tab: "Home")
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Home - 1")
        
        tapTab(app: app, tab: "Home")
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Home - 2")
        
        tapTab(app: app, tab: "Home")
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Home - 3")
    }
    
    func testSnapshotSearch() async throws {
        let app = XCUIApplication()
        app.launch()
        
        tapTab(app: app, tab: "Search")
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Search - 1")
        
        tapTab(app: app, tab: "Search")
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Search - 2")
        
        tapTab(app: app, tab: "Search")
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Search - 3")
    }
    
    func testSnapshotNotification() async throws {
        let app = XCUIApplication()
        app.launch()
        
        tapTab(app: app, tab: "Notification")
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Notification - 1")
        
        tapTab(app: app, tab: "Notification")
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Notification - 2")
        
        tapTab(app: app, tab: "Notification")
        try await Task.sleep(nanoseconds: .second * 3)
        takeSnapshot(name: "Notification - 3")
    }
    
    func testSnapshotProfile() async throws {
        let username = ProcessInfo.processInfo.environment["username_snapshot"] ?? "Gargron"
        
        let app = XCUIApplication()
        app.launch()
        
        // Go to Search tab
        tapTab(app: app, tab: "Search")
        
        // Tap and search user
        let searchField = app.navigationBars.searchFields.firstMatch
        XCTAssert(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText(username)
        
        // Tap the cell and display user profile
        let cell = app.tables.cells.firstMatch
        XCTAssert(cell.waitForExistence(timeout: 5))
        cell.tap()
        
        try await Task.sleep(nanoseconds: .second * 5)
        
        takeSnapshot(name: "Profile")
    }
    
    func testSnapshotCompose() async throws {
        let app = XCUIApplication()
        app.launch()
        
        // open Compose scene
        let composeBarButtonItem = app.navigationBars.buttons["Compose"].firstMatch
        let composeCollectionViewCell = app.collectionViews.cells["Compose"]
        if composeBarButtonItem.waitForExistence(timeout: 5) {
            composeBarButtonItem.tap()
        } else if composeCollectionViewCell.waitForExistence(timeout: 5) {
            composeCollectionViewCell.tap()
        } else {
            XCTFail()
        }
                
        // type text
        let textView = app.textViews.firstMatch
        XCTAssert(textView.waitForExistence(timeout: 5))
        textView.tap()
        textView.typeText("Look at that view! #Athens ")
        
        // tap Add Attachment toolbar button
        let addAttachmentButton = app.buttons["Add Attachment"].firstMatch
        XCTAssert(addAttachmentButton.waitForExistence(timeout: 5))
        addAttachmentButton.tap()
        
        // tap Photo Library menu action
        let photoLibraryButton = app.buttons["Photo Library"].firstMatch
        XCTAssert(photoLibraryButton.waitForExistence(timeout: 5))
        photoLibraryButton.tap()
        
        // select the first photo
        let photo = app.images.containing(NSPredicate(format: "label BEGINSWITH 'Photo'")).element(boundBy: 0).firstMatch
        XCTAssert(photo.waitForExistence(timeout: 5))
        photo.tap()
        
        // tap Add barButtonItem
        let addBarButtonItem = app.navigationBars.buttons["Add"].firstMatch
        XCTAssert(addBarButtonItem.waitForExistence(timeout: 5))
        addBarButtonItem.tap()
        
        try await Task.sleep(nanoseconds: .second * 10)
        takeSnapshot(name: "Compose - 1")
        
        try await Task.sleep(nanoseconds: .second * 10)
        takeSnapshot(name: "Compose - 2")
        
        try await Task.sleep(nanoseconds: .second * 10)
        takeSnapshot(name: "Compose - 3")
    }
    
}

extension MastodonUISnapshotTests {
    
    // Please check the Documentation/Snapshot.md and run this test case in the command line
    func testSignInAccount() async throws {
        guard let domain = ProcessInfo.processInfo.environment["domain"] else {
            fatalError("env 'domain' missing")
        }
        guard let email = ProcessInfo.processInfo.environment["email"] else {
            fatalError("env 'email' missing")
        }
        guard let password = ProcessInfo.processInfo.environment["password"] else {
            fatalError("env 'password' missing")
        }
        try await signInApplication(
            domain: domain,
            email: email,
            password: password
        )
    }

    func signInApplication(
        domain: String,
        email: String,
        password: String
    ) async throws {
        let app = XCUIApplication()
        app.launch()

        // check in Onboarding or not
        let loginButton = app.buttons["Log In"].firstMatch
        let loginButtonExists = loginButton.waitForExistence(timeout: 5)
        
        // goto Onboarding scene if already sign-in
        if !loginButtonExists {
            let profileTabBarButton = app.tabBars.buttons["Profile"]
            XCTAssert(profileTabBarButton.waitForExistence(timeout: 3))
            profileTabBarButton.press(forDuration: 2)
            
            let addAccountCell = app.cells.containing(.staticText, identifier: "Add Account").firstMatch
            XCTAssert(addAccountCell.waitForExistence(timeout: 3))
            addAccountCell.tap()
        }
        
        // Tap login button
        XCTAssert(loginButtonExists)
        loginButton.tap()
        
        // type domain
        let domainTextField = app.textFields.firstMatch
        XCTAssert(domainTextField.waitForExistence(timeout: 5))
        domainTextField.tap()
        // Skip system keyboard swipe input guide
        skipKeyboardSwipeInputGuide(app: app)
        domainTextField.typeText(domain)
        XCUIApplication().keyboards.buttons["Done"].firstMatch.tap()
        
        // wait searching
        try await Task.sleep(nanoseconds: .second * 3)
        
        // tap server
        let cell = app.cells.containing(.staticText, identifier: domain).firstMatch
        XCTAssert(cell.waitForExistence(timeout: 5))
        cell.tap()
        
        // add system alert monitor
        // A. The monitor not works
        // addUIInterruptionMonitor(withDescription: "Authentication Alert") { alert in
        //     alert.buttons["Continue"].firstMatch.tap()
        //     return true
        // }
        
        // tap next button
        let nextButton = app.buttons.matching(NSPredicate(format: "enabled == true")).matching(identifier: "Next").firstMatch
        XCTAssert(nextButton.waitForExistence(timeout: 3))
        nextButton.tap()
        
        // wait authentication alert display
        try await Task.sleep(nanoseconds: .second * 3)
        
        // B. Workaround
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let continueButton = springboard.buttons["Continue"].firstMatch
        XCTAssert(continueButton.waitForExistence(timeout: 3))
        continueButton.tap()
        
        // wait OAuth webpage display
        try await Task.sleep(nanoseconds: .second * 10)
        
        let webview = app.webViews.firstMatch
        XCTAssert(webview.waitForExistence(timeout: 10))
        
        func tapAuthorizeButton() async throws -> Bool {
            let authorizeButton = webview.buttons["AUTHORIZE"].firstMatch
            if authorizeButton.exists {
                authorizeButton.tap()
                try await Task.sleep(nanoseconds: .second * 5)
                return true
            }
            return false
        }
        
        let isAuthorized = try await tapAuthorizeButton()
        if !isAuthorized {
            let emailTextField = webview.textFields["E-mail address"].firstMatch
            XCTAssert(emailTextField.waitForExistence(timeout: 10))
            emailTextField.tap()
            emailTextField.typeText(email)
            
            let passwordTextField = webview.secureTextFields["Password"].firstMatch
            XCTAssert(passwordTextField.waitForExistence(timeout: 3))
            passwordTextField.tap()
            passwordTextField.typeText(password)
            
            let goKeyboardButton = XCUIApplication().keyboards.buttons["Go"].firstMatch
            XCTAssert(goKeyboardButton.waitForExistence(timeout: 3))
            goKeyboardButton.tap()
            
            var retry = 0
            let retryLimit = 20
            while webview.exists {
                guard retry < retryLimit else {
                    fatalError("Cannot complete OAuth process")
                }
                retry += 1
                
                // will break due to webview dismiss
                _ = try await tapAuthorizeButton()

                print("Please enter the sign-in confirm code. Retry in 5s")
                try await Task.sleep(nanoseconds: .second * 5)
            }
        } else {
            // Done
        }

        print("OAuth finish")
    }
    
    private func skipKeyboardSwipeInputGuide(app: XCUIApplication) {
        let swipeInputLabel = app.staticTexts["Speed up your typing by sliding your finger across the letters to compose a word."].firstMatch
        guard swipeInputLabel.waitForExistence(timeout: 3) else { return }
        let continueButton = app.buttons["Continue"]
        continueButton.tap()
    }
}

extension MastodonUISnapshotTests {
    func takeSnapshot(name: String) {
        let snapshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(
            uniformTypeIdentifier: "public.png",
            name: "Screenshot-\(name)-\(UIDevice.current.name).png",
            payload: snapshot.pngRepresentation,
            userInfo: nil
        )
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
