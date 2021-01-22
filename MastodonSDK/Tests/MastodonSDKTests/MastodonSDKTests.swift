import XCTest
@testable import MastodonSDK

final class MastodonSDKTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MastodonSDK().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
