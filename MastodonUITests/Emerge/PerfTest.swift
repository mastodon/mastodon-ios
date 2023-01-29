import Foundation
import XCTest

@objc public protocol EMGPerfTest: NSObjectProtocol {
  
    /// This setup function is run once before all the iterations of the perf test. It can be used, for example, to
    /// log a test user in before doing some perf test that requires a logged in state. Do _not_ create an instance
    /// of XCUIApplication for the target app (i.e., XCUIApplication()) yourself. Only use the one provided, `app`.
    /// - Parameter app: a pre-launched instance of the target app. Note that it's passed as an XCUIElement,
    /// not an XCUIApplication (which is a subclass of XCUIElement), because its XCUIApplication methods shouldn't be used. Do not retain instances of this in your test class.
    func runInitialSetup(withApp app: XCUIElement)

    /// This function is run repeatedly to collect performance data. Do _not_ create an instance
    /// of XCUIApplication for the target app (i.e., XCUIApplication()) yourself. Only use the one provided, `app`.
    /// - Parameter app: a pre-launched instance of the target app. Note that it's passed as an XCUIElement,
    /// not an XCUIApplication (which is a subclass of XCUIElement), because its XCUIApplication methods shouldn't be used. Do not retain instances of this in your test class.
    func runIteration(withApp app: XCUIElement)

    // Environment variables to set when launching the app for setup (optional)
    @objc optional func launchEnvironmentForSetup() -> [String : String]

    // Environment variables to set when launching the app for each iteration (optional)
    @objc optional func launchEnvironmentForIterations() -> [String : String]

    // Launch arguments to use when launching the app for setup (optional)
    @objc optional func launchArgumentsForSetup() -> [String]

    // Launch arguments to use when launching the app for each iteration (optional)
    @objc optional func launchArgumentsForIterations() -> [String]
}
