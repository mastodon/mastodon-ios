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
    
    func takeSnapshot(name: String) {
        let snapshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(
            uniformTypeIdentifier: "public.png",
            name: "\(name).\(UIDevice.current.name).png",
            payload: snapshot.pngRepresentation,
            userInfo: nil
        )
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // make tab display by tap it
    private func tapTab(app: XCUIApplication, tab: String) {
        let searchTab = app.tabBars.buttons[tab]
        if searchTab.exists { searchTab.tap() }
        
        let searchCell = app.collectionViews.cells[tab]
        if searchCell.exists { searchCell.tap() }
    }
    
    private func showTitleButtonMenu(app: XCUIApplication) async throws {
        let titleButton = app.navigationBars.buttons["TitleButton"].firstMatch
        XCTAssert(titleButton.waitForExistence(timeout: 5))
        titleButton.press(forDuration: 1.0)
        try await Task.sleep(nanoseconds: .second * 1)
    }

    private func snapshot(
        name: String,
        count: Int = 3,
        task: (_ app: XCUIApplication) async throws -> Void
    ) async rethrows {
        var app = XCUIApplication()
        
        // pass -1 to debug test case
        guard count >= 0 else {
            app.launch()
            try await task(app)
            takeSnapshot(name: name)
            return
        }
        
        // Light Mode
        for index in 0..<count {
            app.launch()
            try await task(app)

            let name = "\(name).light.\(index+1)"
            takeSnapshot(name: name)
        }
        
        // Dark Mode
        app = XCUIApplication()
        app.launchArguments.append("UIUserInterfaceStyleForceDark")
        for index in 0..<count {
            app.launch()
            try await task(app)

            let name = "\(name).dark.\(index+1)"
            takeSnapshot(name: name)
        }
    }
    
}

// MARK: - Home
extension MastodonUISnapshotTests {

    func testSnapshotHome() async throws {
        try await snapshot(name: "Home") { app in
            tapTab(app: app, tab: "Home")
            try await Task.sleep(nanoseconds: .second * 3)
        }
    }

}

// MARK: - Thread
extension MastodonUISnapshotTests {

    func testSnapshotThread() async throws {
        try await snapshot(name: "Thread") { app in
            let threadID = ProcessInfo.processInfo.environment["thread_id"]!
            try await coordinateToThread(app: app, id: threadID)
            try await Task.sleep(nanoseconds: .second * 5)
        }
    }
    
    // use debug entry goto thread scene by thread ID
    // assert the thread ID is valid for current sign in user server
    private func coordinateToThread(app: XCUIApplication, id: String) async throws {
        try await Task.sleep(nanoseconds: .second * 1)
        
        try await showTitleButtonMenu(app: app)
        
        let showMenu = app.collectionViews.buttons["Show…"].firstMatch
        XCTAssert(showMenu.waitForExistence(timeout: 3))
        showMenu.tap()
        try await Task.sleep(nanoseconds: .second * 1)
        
        let threadAction = app.collectionViews.buttons["Thread"].firstMatch
        XCTAssert(threadAction.waitForExistence(timeout: 3))
        threadAction.tap()
        try await Task.sleep(nanoseconds: .second * 1)
        
        let textField = app.alerts.textFields.firstMatch
        XCTAssert(textField.waitForExistence(timeout: 3))
        textField.typeText(id)
        try await Task.sleep(nanoseconds: .second * 1)
        
        let showAction = app.alerts.buttons["Show"].firstMatch
        XCTAssert(showAction.waitForExistence(timeout: 3))
        showAction.tap()
        try await Task.sleep(nanoseconds: .second * 1)
    }
    
}

// MARK: - Profile
extension MastodonUISnapshotTests {
    
    func testSnapshotProfile() async throws {
        try await snapshot(name: "Profile") { app in
            let profileID = ProcessInfo.processInfo.environment["profile_id"]!
            try await coordinateToProfile(app: app, id: profileID)
            try await Task.sleep(nanoseconds: .second * 5)
        }
    }
    
    // use debug entry goto thread scene by profile ID
    // assert the profile ID is valid for current sign in user server
    private func coordinateToProfile(app: XCUIApplication, id: String) async throws {
        try await Task.sleep(nanoseconds: .second * 1)

        try await showTitleButtonMenu(app: app)
        
        let showMenu = app.collectionViews.buttons["Show…"].firstMatch
        XCTAssert(showMenu.waitForExistence(timeout: 3))
        showMenu.tap()
        try await Task.sleep(nanoseconds: .second * 1)
        
        let profileAction = app.collectionViews.buttons["Profile"].firstMatch
        XCTAssert(profileAction.waitForExistence(timeout: 3))
        profileAction.tap()
        try await Task.sleep(nanoseconds: .second * 1)
        
        let textField = app.alerts.textFields.firstMatch
        XCTAssert(textField.waitForExistence(timeout: 3))
        textField.typeText(id)
        try await Task.sleep(nanoseconds: .second * 1)
        
        let showAction = app.alerts.buttons["Show"].firstMatch
        XCTAssert(showAction.waitForExistence(timeout: 3))
        showAction.tap()
        try await Task.sleep(nanoseconds: .second * 1)
    }
    
}


// MARK: - Server Rules
extension MastodonUISnapshotTests {
    
    func testSnapshotServerRules() async throws {
        try await snapshot(name: "ServerRules") { app in
            let domain = "mastodon.social"
            try await coordinateToOnboarding(app: app, page: .serverRules(domain: domain))
            try await Task.sleep(nanoseconds: .second * 3)
        }
    }
    
}

// MARK: - Search
extension MastodonUISnapshotTests {

    func testSnapshotSearch() async throws {
        try await snapshot(name: "ServerRules") { app in
            tapTab(app: app, tab: "Search")
            try await Task.sleep(nanoseconds: .second * 3)
        }
    }
    
}

// MARK: - Compose
extension MastodonUISnapshotTests {

    func testSnapshotCompose() async throws {
        try await snapshot(name: "Compose") { app in
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
            
            // tap Browse menu action to add stub image
            let browseButton = app.buttons["Browse"].firstMatch
            XCTAssert(browseButton.waitForExistence(timeout: 5))
            browseButton.tap()
            
            try await Task.sleep(nanoseconds: .second * 10)
        }
    }
    
}

// MARK: Sign in
extension MastodonUISnapshotTests {
    
    // Please check the Documentation/Snapshot.md and run this test case in the command line
    func testSignInAccount() async throws {
        guard let domain = ProcessInfo.processInfo.environment["login_domain"] else {
            fatalError("env 'login_domain' missing")
        }
        guard let email = ProcessInfo.processInfo.environment["login_email"] else {
            fatalError("env 'login_email' missing")
        }
        guard let password = ProcessInfo.processInfo.environment["login_password"] else {
            fatalError("env 'login_password' missing")
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

        try await coordinateToOnboarding(app: app, page: .login(domain: domain))
        
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
    
    enum OnboardingPage {
        case welcome
        case login(domain: String)
        case serverRules(domain: String)
    }
    
    private func coordinateToOnboarding(app: XCUIApplication, page: OnboardingPage) async throws {
        // check in Onboarding or not
        let loginButton = app.buttons["Log In"].firstMatch
        try await Task.sleep(nanoseconds: .second * 3)
        let loginButtonExists = loginButton.exists
        
        // goto Onboarding scene if already sign-in
        if !loginButtonExists {
            try await showTitleButtonMenu(app: app)
            
            let showMenu = app.collectionViews.buttons["Show…"].firstMatch
            XCTAssert(showMenu.waitForExistence(timeout: 3))
            showMenu.tap()
            try await Task.sleep(nanoseconds: .second * 1)
            
            let welcomeAction = app.collectionViews.buttons["Welcome"].firstMatch
            XCTAssert(welcomeAction.waitForExistence(timeout: 3))
            welcomeAction.tap()
            try await Task.sleep(nanoseconds: .second * 1)
        }
        
        func type(domain: String) async throws {
            // type domain
            let domainTextField = app.textFields.firstMatch
            XCTAssert(domainTextField.waitForExistence(timeout: 5))
            domainTextField.tap()
            
            // Skip system keyboard swipe input guide
            try await skipKeyboardSwipeInputGuide(app: app)
            domainTextField.typeText(domain)
            XCUIApplication().keyboards.buttons["Done"].firstMatch.tap()
        }
        
        switch page {
        case .welcome:
            break
        case .login(let domain):
            // Tap login button
            XCTAssert(loginButtonExists)
            loginButton.tap()
            // type domain
            try await type(domain: domain)
            // add system alert monitor
            // A. The monitor not works
            // addUIInterruptionMonitor(withDescription: "Authentication Alert") { alert in
            //     alert.buttons["Continue"].firstMatch.tap()
            //     return true
            // }
            // tap next
            try await selectServerAndContinue(app: app, domain: domain)
            // wait authentication alert display
            try await Task.sleep(nanoseconds: .second * 3)
            // B. Workaround
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let continueButton = springboard.buttons["Continue"].firstMatch
            XCTAssert(continueButton.waitForExistence(timeout: 3))
            continueButton.tap()
        case .serverRules(let domain):
            // Tap sign up button
            let signUpButton = app.buttons["Get Started"].firstMatch
            XCTAssert(signUpButton.waitForExistence(timeout: 3))
            signUpButton.tap()
            // type domain
            try await type(domain: domain)
            // tap next
            try await selectServerAndContinue(app: app, domain: domain)
        }
    }
    
    private func selectServerAndContinue(app: XCUIApplication, domain: String) async throws {
        // wait searching
        try await Task.sleep(nanoseconds: .second * 3)
        
        // tap server
        let cell = app.cells.containing(.staticText, identifier: domain).firstMatch
        XCTAssert(cell.waitForExistence(timeout: 5))
        cell.tap()
        
        // tap next button
        let nextButton = app.buttons.matching(NSPredicate(format: "enabled == true")).matching(identifier: "Next").firstMatch
        XCTAssert(nextButton.waitForExistence(timeout: 3))
        nextButton.tap()
    }

    private func skipKeyboardSwipeInputGuide(app: XCUIApplication) async throws {
        let swipeInputLabel = app.staticTexts["Speed up your typing by sliding your finger across the letters to compose a word."].firstMatch
        try await Task.sleep(nanoseconds: .second * 3)
        guard swipeInputLabel.exists else { return }
        let continueButton = app.buttons["Continue"]
        continueButton.tap()
    }
    
}
